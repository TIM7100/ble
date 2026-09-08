#include "OSAL.h"
#include "log.h"
#include "file_handle.h"
#include "flash.h"
#include "aes.h"
#include "stdint.h"

#pragma pack(1)
typedef struct _FILE_INFO_
{
	FILE_STATE_t state;				//文件状态：
	uint8 version[VERSION_LEN];
	uint32 start_addr;
	uint32 end_addr;
    uint8 k_sn_count;
    uint8 c_sn_count;
    uint8 m_sn_count;
    uint8 y_sn_count;
	
}File_Info_t;
#pragma pack()
File_Info_t file_info;

static uint32 end_address = 0;
char key[16] = {0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F};


void read_phy_factory_chip_id(uint8 *id_buff)
{
    // 直接从芯片出厂ID地址读取 8 字节
    for(int i=0; i<8; i++)
    {
        id_buff[i] = *((volatile uint8*)(CHIP_ID_FLASH_ADDRESS + i));
    }
}

void set_mac(void)
{
    uint8 chip_id[8] = {0};  
    
    // 读取原厂芯片ID
    read_phy_factory_chip_id(chip_id);
    
    hal_flash_erase_sector(MAC_ADDRESS);
    uint8 mac_buff[8] = {
        chip_id[0],
        chip_id[1],
        chip_id[2],
        chip_id[3],
        chip_id[4],
        chip_id[5],
        chip_id[6],
        chip_id[7]
    };
    
    hal_flash_write(MAC_ADDRESS, mac_buff, 8);
}

//void set_mac(void)
//{
//	
//	
//	uint8 mac_buff[8] = { 0x33, 0x44, 0x55, 0x66, 0x11, 0x22, 0x00, 0x00};
//	
////	hal_flash_erase_sector(MAC_ADDRESS);
//	hal_flash_write(MAC_ADDRESS, mac_buff, 8);
//}

void my_printfS_hex(uint8* data_buff, uint16 len)
{
	uint16 i;
	
    for (i = 0; i < len; i++)
    {
        LOG("%02X ",data_buff[i]);
    }

    LOG("\n");
}

void erase_file_flash(uint16 data_size, uint16 data_count)
{
	uint32 i;
	uint32 erase_count;
	uint32 erase_addr;
    
    end_address = data_size * data_count;
	//计算擦除扇区数
	erase_count = (data_size * data_count + ONE_SECTOR_SIZE - 1) / ONE_SECTOR_SIZE;
	for (i = 0; i < erase_count; i++)
	{
		erase_addr = SAVE_FLASH_START_ADDRESS + (i * ONE_SECTOR_SIZE);
		hal_flash_erase_sector(erase_addr);
	}
}

uint8 write_file_to_flash(uint32 offset, uint8* buff, uint16 size)
{
	if ((SAVE_FLASH_START_ADDRESS + offset) > SAVE_FLASH_END_ADDRESS)
	{
		return SAVE_FILE_ERROR;
	}
	
	if (hal_flash_write(SAVE_FLASH_START_ADDRESS + offset, buff, size) == 0)
	{
		//end_address += size;
		return 	FILE_SUCCESS;
	}
	return SAVE_FILE_ERROR;
}

uint8 read_file_from_flash(uint32 offset_address, uint8* data_buff, uint16 read_size)
{
	osal_memset(data_buff, 0, read_size);
	
	if ((SAVE_FLASH_START_ADDRESS + offset_address) > SAVE_FLASH_END_ADDRESS)
	{
		return SAVE_FILE_ERROR;
	}
	LOG("READ_FLASH: %08X  \n",SAVE_FLASH_START_ADDRESS + offset_address);
	if (hal_flash_read(SAVE_FLASH_START_ADDRESS + offset_address, data_buff, read_size) == 0)
	{		
		//my_printfS_hex(data_buff + read_size - 23, 23);
		return 	FILE_SUCCESS;
	}
	return SAVE_FILE_ERROR;
}


static uint8 read_file_info_flash(uint8* buff, uint16 size)
{
	LOG("Flash ADDR: %08X\n", SAVE_FILE_INFO_ADDRESS);
	if (hal_flash_read(SAVE_FILE_INFO_ADDRESS, buff, size) == 0)
	{
		return 	FILE_SUCCESS;
	}
	return SAVE_FILE_ERROR;
}

uint8 check_file_info(void)
{
	end_address = 0;
	
	read_file_info_flash((uint8 *)&file_info, sizeof(file_info));
	
	LOG("file:state:%d,  V:%s, addr:%08X\n",file_info.state, file_info.version, file_info.start_addr );
	if ((file_info.state != FILE_DOWNLOADED) || (file_info.version[0] == 0xFF) || (file_info.start_addr != SAVE_FLASH_START_ADDRESS))
	{
        LOG("file_info init\n");
		osal_memcpy(file_info.version, "0000000000", VERSION_LEN);
		file_info.state = FILE_DOWNLOAD_ERR;
		file_info.start_addr = SAVE_FLASH_START_ADDRESS;
		file_info.end_addr = SAVE_FLASH_START_ADDRESS;
        file_info.k_sn_count = 0;
        file_info.c_sn_count = 0;
        file_info.m_sn_count = 0;
        file_info.y_sn_count = 0;
		return FILE_ERR;
	}
	return FILE_SUCCESS;
}


uint8 updata_file_info(char *version, FILE_STATE_t *state, uint8 k, uint8 c, uint8 m, uint8 y)
{
	file_info.start_addr = SAVE_FLASH_START_ADDRESS;
	
	if (end_address != 0)
	{
		file_info.end_addr = SAVE_FLASH_START_ADDRESS + end_address;
        end_address = 0;
	}
	
    if (k != 0 || c != 0 || m != 0 || y != 0 )
    {
        if (k != 0)
        {
            file_info.k_sn_count = k;
        }
        if (c != 0)
        {
            file_info.c_sn_count = c;
        }
        if (m != 0)
        {
            file_info.m_sn_count = m;
        }
        if (y != 0)
        {
            file_info.y_sn_count = y;
        }
    }
    
	if ((version != NULL) || (state != NULL))
	{
		if (version != NULL)
		{
			osal_memcpy(file_info.version, version, VERSION_LEN);
		}
		if (state != NULL)
		{
            if ((*state == FILE_AES_ING) && (file_info.state == FILE_DOWNLOADED))
			{
            }
            else
            {
                file_info.state = *state;
            } 			
		}
        
		hal_flash_erase_sector(SAVE_FILE_INFO_ADDRESS);
		hal_flash_write(SAVE_FILE_INFO_ADDRESS, (uint8 *)&file_info, sizeof(file_info));
        LOG("update version:%010X, file_info.state: %d\n", file_info.version, file_info.state);
	}
	else
	{
		LOG("updata_file_info err\n");
		return UPDATA_FILE_INFO_ERR;
	}

	read_file_info_flash((uint8 *)&file_info, sizeof(file_info));

	if (file_info.start_addr != SAVE_FLASH_START_ADDRESS)		//|| (osal_memcmp(file_info.version, version, 10) != 0)
	{
		LOG("Init File Info state:%d,  V:%s, addr:%08X\n", *state, version, SAVE_FLASH_START_ADDRESS);
	
		osal_memcpy(file_info.version, "0000000000", VERSION_LEN);
		file_info.state = FILE_DOWNLOAD_ERR;
		file_info.start_addr = SAVE_FLASH_START_ADDRESS;
		file_info.end_addr = SAVE_FLASH_START_ADDRESS;
		return UPDATA_FILE_INFO_ERR;
	}
	return FILE_SUCCESS;
}

uint8 get_file_info(char *version, FILE_STATE_t *state)
{
	if (version != NULL || state != NULL)
	{
		read_file_info_flash((uint8 *)&file_info, sizeof(file_info));
		LOG("Read Flash Version: ");
		my_printfS_hex(file_info.version, VERSION_LEN);
		if (version != NULL)
		{
			osal_memcpy(version, file_info.version, VERSION_LEN);
			my_printfS_hex(file_info.version, VERSION_LEN);
		}
		if (state != NULL)
		{
			*state = file_info.state;			
		}
		return FILE_SUCCESS;
	}
	else
	{
		LOG("get_file_info err\n");
		return GET_FILE_INFO_ERR;
	}
}

/***********************************************************************************************************
 * @brief    将存放在Flash中的加密固件包，分段0x400进行解密后存放在 缓存地址SAVE_FLASH_END_ADDRESS，
 *           当凑齐0x1000后，将该段数据的原加密数据擦除后，写入解密后的数据。
 * @param    handle_count: 当前处理加密数据的数据段
 * @return   file_deaes_continue：加密的固件包还没处理完毕，还需要进行解密处理
 *           file_deaes_success：加密的固件包已经全部替换成解密后的固件包。
************************************************************************************************************/
uint8 handle_aes_file(uint16 handle_count)
{
//	static u16 deaes_count = 0;
	uint16  deaes_size = 0x400;
	uint8 data_buf[0x1000] = {0};
	uint32  deaes_data_save_addr =  SAVE_FLASH_END_ADDRESS + deaes_size * (handle_count % 4);
	
	uint32 offset_address = handle_count * deaes_size;
	uint32 handle_address = SAVE_FLASH_START_ADDRESS + offset_address;
	
	if (file_info.state == FILE_DOWNLOADED)
	{
		return file_deaes_success;
	}
	
	if (handle_count == 0)
	{
		hal_flash_erase_sector(deaes_data_save_addr);
	}
	if (handle_address < file_info.end_addr)
	{
		if ( ((handle_count % 4) == 0) && (handle_count != 0))
		{
			hal_flash_erase_sector(handle_address - 0x1000);
			hal_flash_read(deaes_data_save_addr, data_buf, 0x1000);
			hal_flash_write(handle_address - 0x1000, data_buf, 0x1000);
			hal_flash_erase_sector(deaes_data_save_addr);
		}
		read_file_from_flash(offset_address, data_buf, deaes_size);
		deAes(data_buf, deaes_size, key);
		
		hal_flash_write(deaes_data_save_addr, data_buf, deaes_size);
		
		return file_deaes_continue;
	}
	else 
	{
		handle_address = handle_address / 0x1000 * 0x1000;
		hal_flash_erase_sector(handle_address);
		hal_flash_read(SAVE_FLASH_END_ADDRESS, data_buf, 0x1000);
		hal_flash_write(handle_address, data_buf, 0x1000);
	}
	return file_deaes_success;
}

/***********************************************************************************
 * @brief    用来测试打印解密后的固件包的数据
 * @param    read_num: 每打印一次数据为512byte，该参数决定访问的文件的数据地址
 * @return   
************************************************************************************/
void test_printf_file_data(uint32 read_num)
{
	u32 i = 0;
	char data_buf[512] = {0};
	u32 offset_address = read_num * 512;
	u32 handle_address = SAVE_FLASH_START_ADDRESS + offset_address;
	
	LOG("read Address 0x%08X\n", SAVE_FLASH_START_ADDRESS + offset_address);
	LOG("file end Address 0x%08X\n", file_info.end_addr);
	if (handle_address > file_info.end_addr)
	{
		offset_address = ((file_info.end_addr - SAVE_FLASH_START_ADDRESS) / 512) * 512;
	}
	
	read_file_from_flash(offset_address, data_buf, 512);
	for (i = 0; i < 512; i++)
    {
		if ((i % 16) == 0)
		{
			LOG("\n");
		}
        LOG("%02X ",data_buf[i]);
    }
	LOG("\n"); 
}

void get_color_address(uint8 ChipAddress, uint32 *color_address, uint16 *color_sn_count)
{
    uint8 k = file_info.k_sn_count;
    uint8 c = file_info.c_sn_count;
    uint8 m = file_info.m_sn_count;
	  uint8 y = file_info.y_sn_count;
	
    
    if (ChipAddress == 0x60)
    {
        *color_address = 0;
	
        *color_sn_count = file_info.k_sn_count;
    }
    else if(ChipAddress == 0x62)
    {
        *color_address = k * 0xF00;
		
        *color_sn_count = file_info.c_sn_count;
    }
    else if(ChipAddress == 0x64)
    {
        *color_address = (k + c) * 0xF00;
		
        *color_sn_count = file_info.m_sn_count;
    }
    else if(ChipAddress == 0x66)
    {
        *color_address = (k + c + m) * 0xF00;
			
        *color_sn_count = file_info.y_sn_count;
    }
		
			LOG("K: %08lX\r\n", k);  //云端获取的各个颜色的套数
	  	LOG("C: %08lX\r\n", c);
		  LOG("M: %08lX\r\n", m);
		  LOG("Y: %08lX\r\n", y);
		
	  	
		
		
		
}

/*******************************************************
 * @brief    
 * @param    xxx:xxx
 * @return   
********************************************************/
uint8 round_read_from_buff(uint16 offset_address, uint8* source_buff, uint8* target_buff, uint16 read_size)
{
    osal_memcpy(target_buff, source_buff + offset_address, read_size);
	
    return 0;
}


uint8 distinguish_type_code(uint16 type_code)
{
    uint8 type_codetmp = 0;

    //判断95x、90x、97
    if (type_code <= HP955XLY || (type_code >= HP95WXLK && type_code <= HP95WXLY) || (type_code >= HP95UXLK && type_code <= HP95UXLY))
    {
        type_codetmp = HP_95X;
    }
    else if ((type_code >= HP902XLK && type_code <= HP905XLY) || (type_code >= HP90WXLK && type_code <= HP90WXLY))
    {
        type_codetmp = HP_90X;
    }
	else if((type_code >= HP972XLK && type_code <= HP975XLY) || (type_code >= HP97UXLK && type_code <= HP97UAY) || (type_code >= HP97PXLK && type_code <= HP97PXLY))
	{
		type_codetmp = HP_97X;
	}

    return type_codetmp;
}

