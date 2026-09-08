/**************************************************************************************************

    Phyplus Microelectronics Limited confidential and proprietary.
    All rights reserved.

    IMPORTANT: All rights of this software belong to Phyplus Microelectronics
    Limited ("Phyplus"). Your use of this Software is limited to those
    specific rights granted under  the terms of the business contract, the
    confidential agreement, the non-disclosure agreement and any other forms
    of agreements as a customer or a partner of Phyplus. You may not use this
    Software unless you agree to abide by the terms of these agreements.
    You acknowledge that the Software may not be modified, copied,
    distributed or disclosed unless embedded on a Phyplus Bluetooth Low Energy
    (BLE) integrated circuit, either as a product or is integrated into your
    products.  Other than for the aforementioned purposes, you may not use,
    reproduce, copy, prepare derivative works of, modify, distribute, perform,
    display or sell this Software and/or its documentation for any purposes.

    YOU FURTHER ACKNOWLEDGE AND AGREE THAT THE SOFTWARE AND DOCUMENTATION ARE
    PROVIDED AS IS WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESS OR IMPLIED,
    INCLUDING WITHOUT LIMITATION, ANY WARRANTY OF MERCHANTABILITY, TITLE,
    NON-INFRINGEMENT AND FITNESS FOR A PARTICULAR PURPOSE. IN NO EVENT SHALL
    PHYPLUS OR ITS SUBSIDIARIES BE LIABLE OR OBLIGATED UNDER CONTRACT,
    NEGLIGENCE, STRICT LIABILITY, CONTRIBUTION, BREACH OF WARRANTY, OR OTHER
    LEGAL EQUITABLE THEORY ANY DIRECT OR INDIRECT DAMAGES OR EXPENSES
    INCLUDING BUT NOT LIMITED TO ANY INCIDENTAL, SPECIAL, INDIRECT, PUNITIVE
    OR CONSEQUENTIAL DAMAGES, LOST PROFITS OR LOST DATA, COST OF PROCUREMENT
    OF SUBSTITUTE GOODS, TECHNOLOGY, SERVICES, OR ANY CLAIMS BY THIRD PARTIES
    (INCLUDING BUT NOT LIMITED TO ANY DEFENSE THEREOF), OR OTHER SIMILAR COSTS.

**************************************************************************************************/

/**************************************************************************************************
    Filename:       gpio_demo.c
    Revised:        $Date $
    Revision:       $Revision $


**************************************************************************************************/

/*********************************************************************
    INCLUDES
*/

#include "OSAL.h"
#include "log.h"

#include "gpio.h"
//#include "clock.h"

#include "myi2c.h"
#include "UpgraderHp9Serial.h"
#include "random.h"
#include "file_handle.h"
#include "crc16.h"
#include "app_datetime.h"


/******软件iic********/

#define Timeout 20

#define EEDATA_SN_ADDR       0x35000
#define SN_ADDR_STEP         0x1000
#define BACKDOOR_BASEADDR    0x25200
//#define SN_LEN               0xEF8

typedef struct HP9_SERIES_MAP{
	char *name;
	uint16 data_len;
}HP9_SERIES_MAP_t;
HP9_SERIES_MAP_t hp9_series_list[4] = {{NULL, 0}, {"90X", 0xE0}, {"95X", 0xE0}, {"97X", 0xE0}};


enum {
  SEND_80_CMD = 0x80,
  SEND_82_CMD = 0x82
};

static uint32 color_address_buf[4] = {0};   // 0: K; 1: C; 2: M; 3: Y
static uint32 color_address = 0;
static u16 color_sn_count = 0;


static u8 *tx_array  = NULL;//[0x100];
static u8 *iic_rxbuf = NULL;//[0x100];
static u8 rx_length_buf;                   //接收数据长度

static u8 hp9_series = 0;				   // 1 90X 2 95X 3 97X
static u8 array[10] = {0};				   //序列表
static u8 sn_data_buff[0xF00];			   //一套序列数据的缓存区
static u8 *upgrader_data = NULL; 	       //一套序列分组发送的缓存区, 堆栈开辟
static u16 upgrader_data_len = 0;
static u8 sn_num = 0;				       //序列表中，当前发送序列号
static u8 round_num = 0;			       //一套序列分组发送的下标
static u8 read_flash_flag = 1;

static u8 backdoor_data[130] = {0};
static u8 read_chip_addr = 0;      //该芯片地址


static u8 SelectIICAddr(void);     //遍历地址

static u8 update_sndata(u32 update_addr, const u8* sndata, u16 data_len);
static u8 update_typedata(void);
static u8 update_ctldata(void);
static u8 update_backdoor(u32 backdoor_addr, u8* backdoor);

static u8 read_oem_cmd(const u8* cmd_buf, u8 cmd_len);
static u8 read_oem_cmd_withdelay(u8* cmd_buf, u8 cmd_len, u32 delay_ms);

static u8 read_data_backdoor(void);
/************/

static void updata_print_hex(uint8_t* data_buff, uint16 len)
{
    uint16 i;

    for (i = 0; i < len; i++)
    {
        LOG("%02X ",data_buff[i]);
    }

    LOG("\n");
}

u8 heap_data_init(void)
{
	if (tx_array == NULL)
	{
		tx_array = (u8 *)osal_mem_alloc(0x100);
	}
	if (iic_rxbuf == NULL)
	{
		iic_rxbuf = (u8 *)osal_mem_alloc(0x100);
	}
	
	if (tx_array == NULL || iic_rxbuf == NULL)
	{
		LOG("heap_data_init err!!!\n");
		return ALLOC_DATA_ERROR;
	}
	else
	{
		osal_memset(tx_array, 0, 0x100);
		osal_memset(iic_rxbuf, 0, 0x100);
	}
//	LOG("________.........%08X...........___________\n", tx_array);
	return ALLOC_DATA_SUCCESS;
}

void heap_data_free(void)
{
	if (iic_rxbuf != NULL)
	{
		osal_mem_free(iic_rxbuf);
	}
	
	if (tx_array != NULL)
	{
		osal_mem_free(tx_array);
	}
	
	if (upgrader_data != NULL)
	{
		osal_mem_free(upgrader_data);
	}
	tx_array = NULL;
	iic_rxbuf = NULL;
	upgrader_data = NULL;
}

void get_sn_array(void)  //每套颜色sn刷新的套数
{
    random_array(array, color_sn_count);						//获取sn列表
}

void one_sn_data_init(void)
{
	sn_num = 0;
	round_num = 0;
	read_flash_flag = 1;
}

u8 upgrader_hp9_serial(void)
{
	u16 hp9_type = 0;
	char new_version[10] = {0}; //更新的flash版本 

    i2c_init();
	one_sn_data_init();
	if (heap_data_init() == ALLOC_DATA_ERROR)
	{
		return ALLOC_DATA_ERROR;
	}
	
    //1.确定需要读取的芯片的地址
    read_chip_addr = SelectIICAddr();                    //遍历地址，直到当前检测芯片回应
	if (read_chip_addr == 0x00)
	{
		return CHIP_SCAN_ADDRESS_ERR;
	}
	 LOG("Addr: %02X\n", read_chip_addr);
    get_color_address(read_chip_addr, &color_address, &color_sn_count);
	//2. 读后门数据
	if (read_data_backdoor() != 0)
	{
		return READ_BACKDOOR_DATA_ERR;
	}		
	get_file_info(new_version, NULL);
    
	//3. 提取后门数据中芯片类型，判断芯片系列是否为 当前设备支持的系列 SUPPORT_SERIES_NAME
	hp9_type = (backdoor_data[22] << 8) | backdoor_data[23];
	hp9_series = distinguish_type_code(hp9_type);
	LOG("HP_9X Type: %04X; Code: %d\n",hp9_type, hp9_series);
	if (osal_memcmp(SUPPORT_SERIES_NAME, hp9_series_list[hp9_series].name, 3) == 0)		//相同返回1
	{
		LOG("Type_Err\n");
		return CHIP_TYPE_ERR;
	}
	
	//4. 提取后门版本号，判断芯片版本是否为 最新版本
	if (osal_memcmp(backdoor_data, new_version, 10))     //对比版本号，判断是否需要更新
	{
		LOG("Newest\n");
		return CHIP_NEWEST_VERSION;
	}
	
	//5. 开辟对应系列 一套序列分组发送的缓存区
	upgrader_data_len = hp9_series_list[hp9_series].data_len;
	LOG("upgrader_data_len %02X\n", upgrader_data_len);
	upgrader_data = (u8 *)osal_mem_alloc(upgrader_data_len);
	if (upgrader_data == NULL)
	{
		LOG("alloc upgrader_data err!!!\n");
		return ALLOC_DATA_ERROR;
	}
	osal_memset(upgrader_data, 0, upgrader_data_len);

	return START_UPDATE_CHIP;
}

/****************************************************************************
* 函数名         ：backdoor_changesn
* 函数功能       ：刷新序列号，修改后门flash版本
* 输入           ：无
* 输出           ：无
****************************************************************************/
u8 backdoor_changesn(void)
{
	const u16 data_len = 0xF00;
//	const u16 data_len = 0x1E0;
//	const u8 section_size = 0xE0;
	static u32 flash_offset_addr = 0;
	u16 data_buff_offset = 0;
	static u8 send_round = 0;
	static u8 last_size = 0;
	int a;
	
//	read_chip_addr = SelectIICAddr();    
  char new_version[10] = {0}; //更新的flash版本

	osal_memset(upgrader_data, 0, upgrader_data_len);
    //Step1 刷新序列号区的数据
	LOG("num:%d\r\n", sn_num);
    if (sn_num < 2) 				            //需要刷新几套数据
    {
		if (read_flash_flag == 1)
		{
			send_round = (data_len - SUPPORT_LEN) / upgrader_data_len;                                   //整轮次数        
			last_size = (data_len - SUPPORT_LEN) % upgrader_data_len;   //最后空余轮的大小 
			
			
			flash_offset_addr = (array[sn_num] - 1) * data_len;
//			flash_offset_addr = (array[sn_num & 1] - 1) * data_len;
			
			a = read_file_from_flash(flash_offset_addr + color_address, sn_data_buff, data_len);
			read_flash_flag = 0;
			LOG("a:%d\r\n", a);
			LOG("offset_address:%d\r\n", flash_offset_addr + color_address);
			LOG("data_len:%d\r\n", data_len);
			/*
			for(int i = 0; i< data_len; i++)
			{
				LOG("0x%02X, ",sn_data_buff[i]);

			}
			Delay_ms(1000);
			*/
		}
		if (round_num <= send_round)
        {
			data_buff_offset = upgrader_data_len * round_num + 2;  // 02, E2, E
			if (round_num == send_round)
			{
				//ecb_aes_file_from_flash(data_buff_offset + flash_offset_addr, upgrader_data, last_size);
				round_read_from_buff(data_buff_offset, sn_data_buff, upgrader_data, last_size);
//				print_hex((sn_data_buff + data_buff_offset - 10), last_size + 10);
//				print_hex(upgrader_data, last_size);
				
				
				if (update_sndata(EEDATA_SN_ADDR + (SN_ADDR_STEP * sn_num +  upgrader_data_len * round_num), upgrader_data, last_size) != 0)
				{
					LOG("update_sndata err\n");
					return UPDATE_SNDATA_FAILED;
				}
			}
			else
			{
				//ecb_aes_file_from_flash(data_buff_offset + flash_offset_addr, upgrader_data, section_size);
				round_read_from_buff(data_buff_offset, sn_data_buff, upgrader_data, upgrader_data_len);
				if (update_sndata(EEDATA_SN_ADDR + (SN_ADDR_STEP * sn_num +  upgrader_data_len * round_num), upgrader_data, upgrader_data_len) != 0)
//				if (update_sndata(EEDATA_SN_ADDR + (SN_ADDR_STEP * (sn_num & 1) + upgrader_data_len * round_num), upgrader_data, upgrader_data_len) != 0)
				
				{
					LOG("update_sndata err\n");
					return UPDATE_SNDATA_FAILED;
				}
				round_num++;
				return ONCE_SEND_DELAY_100MS;
			}
		}		

        sn_num++;
		read_flash_flag = 1;
		round_num = 0;
        return SEND_ONE_SN_SUCCESS;
    }


	
    //Step2 发送命令,使芯片内部从已刷新数据中刷新程序所需数据(耗时...)
	if (sn_num == 2)
	{
		if (update_typedata() != ONCE_SEND_DELAY_100MS)
		{
			sn_num = 0;
			//heap_data_free();
			LOG("UPDATA_TYPEDATA_FAILED\r\n");
			return UPDATE_TYPEDATA_FAILED;
		}
		sn_num++;
		return ONCE_SEND_DELAY_100MS;
	}
    
	//Step3 发送命令,使芯片内部刷新 更新替换区域与控制区域 UpDataCtlInfo
	if (sn_num == 3)
	{  
		if (update_ctldata() != ONCE_SEND_DELAY_100MS)
		{
			sn_num = 0;
//			heap_data_free();
			LOG("UPDATA_TYPEDATA_FAILED\r\n");
			return UPDATE_CTLDATA_FAILED;
		}
		sn_num++;
		return ONCE_SEND_DELAY_100MS;
	}


	//Step4 发送后门数据,刷新后门数据版本
	get_file_info(new_version, NULL);
	osal_memcpy(backdoor_data, new_version, 10);
	if (update_backdoor(BACKDOOR_BASEADDR, backdoor_data) != BACKDOOR_CHANGE_SUCCESS)
	{
		LOG("UPDATE_BACKDOOR_FAILED\r\n");
		sn_num = 0;
//		heap_data_free();
		return UPDATE_BACKDOOR_FAILED;
	}
	
    sn_num = 0;
//	heap_data_free();
    LOG("SUCCESS\r\n");
    return BACKDOOR_CHANGE_SUCCESS;
}




static u8 SelectIICAddr(void)
{
    u8 ChipAddr = 0;

    if (IIC_SendData(0x60, NULL, 0) == I2C_OK)
    {
        ChipAddr = 0x60;
	   	color_address = color_address_buf[0];

    }
    else if (IIC_SendData(0x62, NULL, 0) == I2C_OK)
    {
			ChipAddr = 0x62;
    	color_address = color_address_buf[1];

    }
    else if (IIC_SendData(0x64, NULL, 0) == I2C_OK)
    {
        ChipAddr = 0x64;
	  	color_address = color_address_buf[2];

    }
    else if (IIC_SendData(0x66, NULL, 0) == I2C_OK)
    {
        ChipAddr = 0x66;
	    	color_address = color_address_buf[3];
		
    }
    	if (ChipAddr != 0)
    	{
    		if (IIC_SendData(ChipAddr, NULL, 0) == I2C_OK)
    		{
    		}
    		else
    		{
    			ChipAddr = 0;
    		}
	}
    return ChipAddr;
}



/****************************************************************************
   * 函数名         ：update_sndata
   * 函数功能       ：更新SN序列号数据
   * 输入           ：u32 update_addr 要更新的地址
                                            u8* sndata 要更新的数据
                                            u16 data_len 数据长度
   * 输出           ：0：成功
   ****************************************************************************/
static u8 update_sndata(u32 update_addr, const u8* sndata, u16 data_len)
{
    const u8 update_sndata_type = 0x01;
    const u8 change_sn_cmd = 0x7D;
    u32 target_addr;
	
	osal_memset(tx_array, 0, 0x100);	
	tx_array[0] = 0x40;
	tx_array[1] = change_sn_cmd;

	//升级类型与反码-刷新序列号区
	tx_array[3] = update_sndata_type;    //rx_buf[0]
	tx_array[4] = ~update_sndata_type;   //rx_buf[1]

	//烧录序列号的地址
	target_addr = update_addr;
	tx_array[5] = (u8)(target_addr >> 24);    //rx_buf[2]
	tx_array[6] = (u8)(target_addr >> 16);    //rx_buf[3]
	tx_array[7] = (u8)(target_addr >> 8);     //rx_buf[4]
	tx_array[8] = (u8)target_addr;                //rx_buf[5]

	//烧录的大小
	tx_array[9] = (u8)(data_len >> 8);     //rx_buf[6]
	tx_array[10] = (u8)data_len;               //rx_buf[7]

	//烧录的数据
	osal_memcpy(tx_array + 11, sndata, data_len);

	//烧录的命令有效数据长度
	tx_array[2] = 8 + data_len;

//	updata_print_hex(tx_array, 16);
	if (read_oem_cmd(tx_array, tx_array[2] + 3) != 0)
	{
		return 1;
	}

	if ((iic_rxbuf[0] != (u8)update_sndata_type) || (iic_rxbuf[1] != (u8)(~update_sndata_type)) || (iic_rxbuf[2] != 0x00))
	{
		LOG("X1");
		return 1;
	}
    return 0;
}


/****************************************************************************
* 函数名         ：update_typedata
* 函数功能       ：更新Type数据
* 输入           ：无
* 输出           ： 0：成功
****************************************************************************/
static u8 update_typedata(void)
{
    u8 chip_update_typedata[7] = {0x40, 0x7D, 0x04, 0x02, 0xFD, 0, 0};

    //注意需要确定芯片型号
    chip_update_typedata[5] = hp9_series;   // 1 90X 2 95X 3 97X
//    ReadOem_Cmd_WithDelay(UpDataTypeData, 7, 1000);
    read_oem_cmd_withdelay(chip_update_typedata, 7, 1000);
    if ((iic_rxbuf[0] != 2) || (iic_rxbuf[1] != 0xFD) || (iic_rxbuf[2] != 0))
    {
        return UPDATE_TYPEDATA_FAILED;
    }

    return ONCE_SEND_DELAY_100MS;
}


/****************************************************************************
* 函数名         ：update_ctldata
* 函数功能       ：更新ctl数据
* 输入           ：无
* 输出           ： 0：成功
****************************************************************************/
static u8 update_ctldata(void)
{
    u8 chip_update_ctldata[7] = {0x40, 0x7D, 0x04, 0x03, 0xFC, 0, 0};

    read_oem_cmd_withdelay(chip_update_ctldata, 7, 10);
    if ((iic_rxbuf[0] != 3) || (iic_rxbuf[1] != 0xFC) || (iic_rxbuf[2] != 0))
    {
        return UPDATE_CTLDATA_FAILED;
    }

    return ONCE_SEND_DELAY_100MS;
}


/****************************************************************************
* 函数名         ：update_backdoor
* 函数功能       ：更新后门数据
* 输入           ：u32 backdoor_addr        后门地址
                                    u8* backdoor                要更新的后门数据
* 输出           ： 0：成功
****************************************************************************/
static u8 update_backdoor(u32 backdoor_addr, u8* backdoor)
{
    const u8 update_backdoor_cmd = 0x04;
    const u8 change_sn_cmd = 0x7D;
    const u8 section_size = 0x80;

    osal_memset(tx_array, 0, 0x100);
    tx_array[0] = 0x40;
    tx_array[1] = change_sn_cmd;

    //升级类型与反码-刷新序列号区
    tx_array[3] = update_backdoor_cmd;    //rx_buf[0]
    tx_array[4] = ~update_backdoor_cmd;   //rx_buf[1]

    //烧录序列号的地址
    tx_array[5] = (u8)(backdoor_addr >> 24);    //rx_buf[2]
    tx_array[6] = (u8)(backdoor_addr >> 16);    //rx_buf[3]
    tx_array[7] = (u8)(backdoor_addr >> 8);     //rx_buf[4]
    tx_array[8] = (u8)backdoor_addr;                //rx_buf[5]

    //烧录的大小
    tx_array[9] = (u8)(section_size >> 8);     //rx_buf[6]
    tx_array[10] = (u8)section_size;               //rx_buf[7]

    //烧录的数据
    osal_memcpy(tx_array + 11, backdoor, section_size);

    //烧录的命令有效数据长度
    tx_array[2] = 8 + section_size;

    read_oem_cmd_withdelay(tx_array, tx_array[2] + 3, 0x20);
//	updata_print_hex(iic_rxbuf, 128);
    if ((iic_rxbuf[0] != (u8)update_backdoor_cmd) || (iic_rxbuf[1] != (u8)(~update_backdoor_cmd)) || (iic_rxbuf[2] != 0))
    {
        LOG("ReadDataBackDoor_Fail\r\n");
        return UPDATE_BACKDOOR_FAILED;
    }
    return BACKDOOR_CHANGE_SUCCESS;
}


/****************************************************************************
* 函数名         ：read_data_backdoor
* 函数功能       ：读后门数据
* 输入           ：无
* 输出           ： 0：成功
****************************************************************************/
static u8 read_data_backdoor(void)
{
    u8 array_readbackdoor[7] = {0x40, 0x78, 0x04, 0x2A, 0xED, 0xAB, 0x72};


    LOG("ReadBackDoor\n");
//    read_oem_cmd(tx_array, 7);
    
	if (read_oem_cmd(array_readbackdoor, 7) != 0)
	{
		Delay_ms(200);
		if (read_oem_cmd(array_readbackdoor, 7) != 0)
		{
			return 1;
		}
	}

	osal_memcpy(backdoor_data, iic_rxbuf, 128);
//    if ((iic_rxbuf[0] != (u8)update_backdoor) || (iic_rxbuf[1] != (u8)(~update_backdoor)) || (iic_rxbuf[2] != 0))
//    {
//        return 1;
//    }

    return 0;
}




/****************************************************************************
* 函数名         ：read_oem_cmd
* 函数功能       ：读OEM指令
* 输入           ：u8* cmd_buf  要发送的指令
                   u8 cmd_len 指令长度
* 输出           ：无
****************************************************************************/
static u8 read_oem_cmd(const u8* cmd_buf, u8 cmd_len)
{
    int i;
    u8 cnt;
	u8 array_buf[0x100]   = {0};
	u8 re_data_buf[0x100] = {0};
    u8 receive_len_buf[2];
    u16 cal_crc_temp;
    u16 data_crc_temp;


	if (array_buf == NULL || re_data_buf == NULL)
	{
		LOG("read_oem_cmd alloc data err!!!\n");
		return 1;
	}
    osal_memset(iic_rxbuf, 0, 0x100);

    //计算发送命令的CRC
    array_buf[0] = cmd_buf[1];           //5A
    for (i = 0; i < cmd_len - 3; i++)
    {
        array_buf[i + 1] = cmd_buf[3 + i]; //01 00
    }
    cal_crc_temp = GetCrc16((const u8*)array_buf, cmd_len - 2);

    //-------------------------------------
    //将传进的命令加上CRC，存到tx_array中
    for (i = 0; i < cmd_len; i++)
    {
        array_buf[i] = cmd_buf[i];
    }
    array_buf[cmd_len] = (u8)(cal_crc_temp >> 8);
    array_buf[cmd_len + 1] = (u8)(cal_crc_temp);


   updata_print_hex(array_buf, 20);
		
    cnt = 0;
    while (IIC_SendData(read_chip_addr, array_buf, cmd_len + 2) != I2C_OK) //发送一组命令 (0x60, 0x40, 0x5A, 0x02, 0x01, 0x00, CRC_H, CRC_L)
    {
        Delay_us(500);
        if (cnt++ >= Timeout)
        {
            LOG("read cmd data err\n");
            return 1;
        }
    }
	
//	LOG("%02X\n", SEND_80_CMD);
    cnt = 0;
    while (IIC_RecData(read_chip_addr, SEND_80_CMD, receive_len_buf, 2) != I2C_OK)//发送一组命令 (60, 80)并接收状态码与回应长度 (61, toner_status, rx_count)
    {
        Delay_us(500);
        if (cnt++ >= Timeout)
        {
			updata_print_hex(receive_len_buf, 2);
            LOG("read 80 data err\n");
            return 2;
        }

    }
	updata_print_hex(receive_len_buf, 2);
	
    rx_length_buf = receive_len_buf[1];
    cnt = 0;
//	LOG("%02X\n", SEND_82_CMD);
    while (IIC_RecData(read_chip_addr, SEND_82_CMD, re_data_buf, rx_length_buf) != I2C_OK)//发送一组命令 (60, 82)并接收回应数据 (61,xx,xx,xx)
    {
        Delay_us(500);
        if (cnt++ >= Timeout)
        {
            LOG("read 82 data err\n");
            return 2;
        }

    }
	   updata_print_hex(re_data_buf, rx_length_buf);
    //----------------------------------------------------------------------------------
    //校验接收数据的CRC
    //----------------------------------------------------------------------------------
    if (rx_length_buf < 2)
    {
        LOG("Data_Receive_Failed_1!!! \n");
        return 3;
    }
    array_buf[0] = receive_len_buf[0];               //回应数据CRC计算第一位, toner_status;
    for (i = 0; i < rx_length_buf - 2; i++)          //回应数据前rx_count - 2个数据(最后两位为CRC)
    {
        array_buf[i + 1] = re_data_buf[i];
    }

    //计算CRC并校验
    cal_crc_temp = GetCrc16((const u8*)array_buf, rx_length_buf - 1);
//	LOG("cal_crc_temp:%X", cal_crc_temp);
    data_crc_temp = (re_data_buf[rx_length_buf - 2] << 8) + re_data_buf[rx_length_buf - 1];
    if (cal_crc_temp != data_crc_temp)
    {
        LOG("Data_Receive_Failed_2!!! \n");
        return 4;
    }

    //接收数据存放到iic_rxbuf中
    for (i = 0; i < rx_length_buf; i++)
    {
        iic_rxbuf[i] = re_data_buf[i];
    }

	LOG("\n");
    return 0;
}



/****************************************************************************
* 函数名         ：read_oem_cmd_withdelay
* 函数功能       ：读OEM指令并等待
* 输入           ：u8* cmd_buf 要发送的指令
                                    u8 cmd_len 指令长度
                                    u32 delay_ms 等待时长
* 输出           ：无
****************************************************************************/
static u8 read_oem_cmd_withdelay(u8* cmd_buf, u8 cmd_len, u32 delay_ms)
{
    int i;
    u8 cnt;

	u8 array_buf[0x100]   = {0};
	u8 re_data_buf[0x100] = {0};
	
    u8 receive_len_buf[2];
    u16 cal_crc_temp;
    u16 data_crc_temp; 

	
	if (array_buf == NULL || re_data_buf == NULL)
	{
		LOG("read_oem_cmd alloc data err!!!\n");
		return 1;
	}
    osal_memset(iic_rxbuf, 0, 0x100);
	
    //计算发送命令的CRC
    array_buf[0] = cmd_buf[1];           //5A
    for (i = 0; i < cmd_len - 3; i++)
    {
        array_buf[i + 1] = cmd_buf[3 + i]; //01 00
    }
    cal_crc_temp = GetCrc16(array_buf, cmd_len - 2);

    //-------------------------------------
    //将传进的命令加上CRC，存到tx_array中
    for (i = 0; i < cmd_len; i++)
    {
        array_buf[i] = cmd_buf[i];
    }
    array_buf[cmd_len] = (u8)(cal_crc_temp >> 8);
    array_buf[cmd_len + 1] = (u8)(cal_crc_temp);

    //--------------------------------------
    cnt = 0;
	updata_print_hex(array_buf, cmd_len + 2);
    while (IIC_SendData(read_chip_addr, array_buf, cmd_len + 2) != I2C_OK)//发送一组命令 (0x60, 0x40, 0x5A, 0x02, 0x01, 0x00)
    {
        Delay_us(500);
        if (cnt++ >= Timeout)
        {
            LOG("read cmd data err\n");
            return 1;
        }
    }
    //======================
    Delay_ms(delay_ms);
    //======================

    //发送一组命令 (60, 80)并//接收状态码与回应长度 (61, toner_status, rx_count)
    cnt = 0;
	LOG("%02X\n", SEND_80_CMD);
    while (IIC_RecData(read_chip_addr, SEND_80_CMD, receive_len_buf, 2) != I2C_OK)
    {
        Delay_us(500);
        if (cnt++ >= Timeout)
        {
			LOG("read 80 data err\n");
			updata_print_hex(receive_len_buf, 2);
            return 2;
        }
    }
	updata_print_hex(receive_len_buf, 2);
    //发送一组命令 (60, 82)并//接收回应数据 (61,xx,xx,xx)
    cnt = 0;
    rx_length_buf = receive_len_buf[1];
	LOG("%02X\n", SEND_82_CMD);
    while (IIC_RecData(read_chip_addr, SEND_82_CMD, re_data_buf, rx_length_buf) != I2C_OK)
    {
        Delay_us(500);
        if (cnt++ >= Timeout)
        {
			updata_print_hex(receive_len_buf, rx_length_buf);
			LOG("read 82 data err\n");
            return 3;
        }
    }
	updata_print_hex(receive_len_buf, rx_length_buf);
    //----------------------------------------------------------------------------------
    //校验接收数据的CRC
    //----------------------------------------------------------------------------------
    if (rx_length_buf < 2)
    {
        LOG("Data_Receive_Failed1!!! \n");
        return 4;
    }
    array_buf[0] = receive_len_buf[0];               //回应数据CRC计算第一位, toner_status;
    for (i = 0; i < rx_length_buf - 2; i++)          //回应数据前rx_count - 2个数据(最后两位为CRC)
    {
        array_buf[i + 1] = re_data_buf[i];
    }

    //计算CRC并校验
    cal_crc_temp = GetCrc16(array_buf, rx_length_buf - 1);

    data_crc_temp = (re_data_buf[rx_length_buf - 2] << 8) + re_data_buf[rx_length_buf - 1];
    if (cal_crc_temp != data_crc_temp)
    {
        LOG("Data_Receive_Failed2!!! \n");
        return 5;
    }

    //接收数据存放到iic_rxbuf中
    for (i = 0; i < rx_length_buf; i++)
    {
        iic_rxbuf[i] = re_data_buf[i];
    }
    return 0;
}
