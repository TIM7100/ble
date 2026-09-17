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

#include "bcomdef.h"
#include <stdio.h>
#include <string.h>
#include "OSAL.h"
#include "linkdb.h"
#include "att.h"
#include "gatt.h"
#include "gatt_uuid.h"
#include "gatt_profile_uuid.h"
#include "peripheral.h"
#include "gattservapp.h"
#include "clock.h"
#include "ota_app_service.h"
#include "log.h"
#include "error.h"
#include "ll.h"
#include "file_handle.h"
#include "OTAfile_handle.h"
#include "flash.h"
//#include "random.h"

static ble_updata_change_CB_t ble_updata_app_CBs = NULL;


CONST uint8 ota_ServiceUUID[ATT_UUID_SIZE] =
{0x38, 0x37, 0x36, 0x35, 0x34, 0x33, 0x32, 0x31, 0x30, 0x01, 0x50, 0x11, 0x16, 0x07, 0x24, 0x20};

//command characteristic
CONST uint8 ota_CommandUUID[ATT_UUID_SIZE] =
{0x38, 0x37, 0x36, 0x35, 0x34, 0x33, 0x32, 0x31, 0x30, 0x02, 0x50, 0x11, 0x16, 0x07, 0x24, 0x20};

// Response characteristic
CONST uint8 ota_ResponseUUID[ATT_UUID_SIZE] =
{0x38, 0x37, 0x36, 0x35, 0x34, 0x33, 0x32, 0x31, 0x30, 0x03, 0x50, 0x11, 0x16, 0x07, 0x24, 0x20};

// Uart characteristic
CONST uint8 ota_UartUUID[ATT_UUID_SIZE] =
{0x38, 0x37, 0x36, 0x35, 0x34, 0x33, 0x32, 0x31, 0x30, 0x04, 0x50, 0x11, 0x16, 0x07, 0x24, 0x20};



static CONST gattAttrType_t ota_Service = {ATT_UUID_SIZE, ota_ServiceUUID};

static uint8 ota_CommandProps = GATT_PROP_WRITE;
static uint8 ota_CommandValue = 0;

// OTA response Characteristic
static uint8 ota_ResponseProps = GATT_PROP_NOTIFY;
static uint8 ota_ResponseValue = 0;
static gattCharCfg_t ota_ResponseCCCD[GATT_MAX_NUM_CONN];

static uint8 ota_UartProps = GATT_PROP_WRITE_NO_RSP;
static uint8 ota_UartValue = 0;

extern void LL_ENC_AES128_Encrypt(uint8* key, uint8* plaintext, uint8* ciphertext);
extern uint32_t g_ota_sec_key[4];

#define OTA_COMMAND_HANDLE 2
#define OTA_UART_HANDLE    7
#define OTA_RSP_HANDLE 4
#define OTA_DATA_HANDLE 7
static gattAttribute_t ota_AttrTbl[] =
{
    //OTA Service
    {
        {ATT_BT_UUID_SIZE, primaryServiceUUID}, /* type */
        GATT_PERMIT_READ,                       /* permissions */
        0,                                      /* handle */
        (uint8*)& ota_Service                   /* pValue */
    },

    //OTA Command Declaration           特性声明
    {
        {ATT_BT_UUID_SIZE, characterUUID},
        GATT_PERMIT_READ,
        0,
        &ota_CommandProps              //性质为写值        0
    },

    //OTA Command Value                 //特性值 具体的数值
    {
        {ATT_UUID_SIZE, ota_CommandUUID},
        GATT_PERMIT_WRITE,
        0,
        &ota_CommandValue
    },

    // OTA response Declaration         该特性为回应特性
    {
        {ATT_BT_UUID_SIZE, characterUUID},
        GATT_PERMIT_READ,
        0,
        &ota_ResponseProps
    },

    //response Value
    {
        {ATT_UUID_SIZE, ota_ResponseUUID},
        GATT_PERMIT_READ,
        0,
        &ota_ResponseValue
    },

    // OTA response Client Characteristic Configuration
    {
        {ATT_BT_UUID_SIZE, clientCharCfgUUID},                  //0x2902
        GATT_PERMIT_READ | GATT_PERMIT_WRITE,
        0,
        (uint8*)ota_ResponseCCCD
    },

    //Uart Declaration          特性声明
    {
        {ATT_BT_UUID_SIZE, characterUUID},
        GATT_PERMIT_READ,
        0,
        &ota_UartProps                  //性质为写值       0
    },

    //OTA Uart Value                    //特性值 具体的数值
    {
        {ATT_UUID_SIZE, ota_UartUUID},
        GATT_PERMIT_WRITE,
        0,
        &ota_UartValue
    },


};


bool s_reboot_flg = false;

//该结构体用于记录下载时，所需要的各种参数
#define ERR_COUNT  64
typedef struct
{
    uint16 count;
    uint16 previous_num;
    uint16 err_num[ERR_COUNT];
    uint8  err_index;
	char  get_version[11];
} ota_file_info;

ota_file_info download_file_info;

static uint8 ota_ReadAttrCB(uint16 connHandle, gattAttribute_t* pAttr,
                            uint8* pValue, uint16* pLen, uint16 offset, uint8 maxLen);
static bStatus_t ota_WriteAttrCB(uint16 connHandle, gattAttribute_t* pAttr,
                                 uint8* pValue, uint16 len, uint16 offset);

static bStatus_t sendNotify(attHandleValueNoti_t* pNoti);
static void handle_file_first(uint16_t current_num, uint8* data_buff, uint16_t len);
static void handle_file_again(uint16_t current_num, uint8* data_buff, uint16_t len);


//static uint8 read_file_from_flash(uint16_t count, uint16_t size, uint8 *buff, uint8 buff_size);

CONST gattServiceCBs_t ota_ProfileCBs =
{
    ota_ReadAttrCB,  // Read callback function pointer
    ota_WriteAttrCB, // Write callback function pointer
    NULL             // Authorization callback function pointer
};

/*response format:*/
/*Byte  value*/
/*0     error code*/
/*1~19  response data payload*/
void response(char* rsp_data, uint8 size)
{
    attHandleValueNoti_t notif;
//  uint8 i;

    osal_memset(&notif, 0, sizeof(notif));
//    if (size > 20)
//        return;

    notif.len = size;
    osal_memcpy(notif.value, rsp_data, size);
    LOG("rsp: %s\n", notif.value);
    sendNotify(&notif);
}

void __attribute__((weak)) ui_firmware_upgrade(void);
//static void ota_disconnect_link(void)
//{
//    LL_Disconnect(0, LL_DISCONNECT_REMOTE_DEV_POWER_OFF);
//    WaitMs(500);
//}

static void process_cmd(uint8* cmdbuf, uint8 size)
{
    uint16_t i = 0;
	ble_updata_info_t cmd = {0};
	static char current_version[10] = {0};
    uint8 rsp[11] = {0};
    static uint8 file_write_count = 0;                  //记录文件申请下载失败段落数据的次数，若5次内还没下载成功，则表明数据下载失败
    uint16_t current_num = 0;                           //当前下载文件的段号
	FILE_STATE_t download_state = FILE_DOWNLOADED;
    

    if (size > sizeof(cmd))
    {
        return;
    } 

    cmd.len = size - 1;
    osal_memcpy(&cmd.cmd, cmdbuf, size);
    LOG("Len:%d\n", size);

    switch (cmd.cmd) // switch (cmdbuf[0])
    {
    case OTA_APP_CMD_VERSION:               			//获得APP下发的固件版本‘1’
    {
		get_file_info(current_version, NULL);
		
		LOG("Location Version ");
		print_hex((uint8 *)current_version, 10);
		LOG("Cloud Version ");
		print_hex((uint8 *)cmd.p.file_version.version, 10);
		cmd.p.file_version.current_time.year = (cmd.p.file_version.current_time.year >> 8) | (cmd.p.file_version.current_time.year << 8);
		app_datetime_set(cmd.p.file_version.current_time);

        //判断版本是否需要更新，回复不同的响应
        if (strncmp((const char*)cmd.p.file_version.version, current_version, VERSION_LEN) != 0)
        {
			strncpy(current_version, cmd.p.file_version.version, VERSION_LEN);		//保存待下载文件版本号
           // osal_memcpy(rsp, "Updata", 6);			 
            response(RP_HP9_BURN_FILE_UPDATA, RP_HP9_BURN_FILE_UPDATA_LEN);			                //接收到的版本不一样，需要更新
        }
        else       
        {
        //    osal_memcpy(rsp, "Newest", 6);
            response(RP_HP9_BURN_FILE_NEWEST, RP_HP9_BURN_FILE_NEWEST_LEN);
			ble_updata_app_CBs(download_state);			//当前保存文件为最新版本，直接执行后续操作
        }
    }
    break;

    case OTA_APP_CMD_OTA_VERSION:               			//'4' 对比OTA固件本地版本
    {
        static char ota_current_version[OTA_VERSION_LEN] = {0};
        ota_get_local_version(ota_current_version);

        LOG("OTA Try Version ");
        print_hex((uint8 *)cmd.p.file_version.version, OTA_VERSION_LEN);
        LOG("OTA Local Version ");
        print_hex((uint8 *)ota_current_version, OTA_VERSION_LEN);

        //判断版本是否需要更新，回复不同的响应
        if (strncmp((const char*)cmd.p.file_version.version, ota_current_version, OTA_VERSION_LEN) != 0)
        {
            response(RP_HP9_BURN_FILE_UPDATA, RP_HP9_BURN_FILE_UPDATA_LEN);      //版本不一致，需要更新
        }
        else
        {
            response(RP_HP9_BURN_FILE_NEWEST, RP_HP9_BURN_FILE_NEWEST_LEN);      //版本一致，已是最新
        }
    }
    break;

    case OTA_APP_CMD_OTA_SAVE_VERSION:              	//'5' OTA成功后回写本地版本
    {
        uint8 ota_st = OTA_FILE_DOWNLOADED;
        ota_set_local_version(cmd.p.file_version.version, ota_st);
        response(RP_HP9_BURN_FILE_START_DOWNLOAD, RP_HP9_BURN_FILE_START_DOWNLOAD_LEN);
    }
    break;

    case OTA_APP_CMD_OTA_GET_VERSION:              	//'6' 返回本地OTA固件版本(10字节)
    {
        uint8 ota_v[OTA_VERSION_LEN + 1];
        osal_memset(ota_v, 0, sizeof(ota_v));
        ota_get_local_version((char *)ota_v);
        response((char *)ota_v, OTA_VERSION_LEN);
    }
    break;

    case OTA_APP_CMD_UPDATA:    						//获取下载次数 '2'
    {
        download_file_info.count = (cmd.p.file_info.size >> 8) | (cmd.p.file_info.size << 8);
		LOG("size: %02X, K: %02X, C: %02X, M: %02X, Y: %02X\n", download_file_info.count, cmd.p.file_info.k_count, cmd.p.file_info.c_count, cmd.p.file_info.m_count, cmd.p.file_info.y_count);
        erase_file_flash(ONCE_DOWNLOAD_SIZE, download_file_info.count);       //擦除当前HP9文件的存储区的内容
		
		download_state = FILE_DOWNLOADING;
		updata_file_info(NULL, &download_state, cmd.p.file_info.k_count, cmd.p.file_info.c_count, cmd.p.file_info.m_count, cmd.p.file_info.y_count);
		
      //  osal_memcpy(rsp, "OK", 2);
        response(RP_HP9_BURN_FILE_START_DOWNLOAD, RP_HP9_BURN_FILE_START_DOWNLOAD_LEN);
    }
    break;

    case OTA_APP_CMD_START_DOWN:    					//开始下载数据 '3'
    {
        current_num = cmd.p.file_data.num[0] << 8 | cmd.p.file_data.num[1];
        LOG("Page Num: %d\n", current_num);
        LOG("Last Page Num: %d\n", download_file_info.previous_num);

        if (current_num > download_file_info.count)             //写入的次数 大于 文件分段次数，表示数据下载完成
        {
            if (download_file_info.err_index == 0)              //写入失败的数据段数量为0，则代表文件完整接收
            {
				download_state = FILE_AES_ING;
				updata_file_info(current_version, &download_state, 0, 0, 0, 0);				//把文件运行状态写入Flash
                
                osal_memset(&download_file_info.previous_num, 0, sizeof(download_file_info) - 2);
                file_write_count = 0;
				ble_updata_app_CBs(download_state);
            }
            else
            {
                uint8 err_rsp[ERR_COUNT * 2 + 4] = {'E', 'R', 'R', ':', 0};
				if ((file_write_count >= 5) || (download_file_info.err_index >= ERR_COUNT))
				{
					LOG("Download File ERR\n");
					download_state = FILE_DOWNLOAD_ERR;
					updata_file_info(NULL, &download_state, 0, 0, 0, 0);
					ble_updata_app_CBs(download_state);					//回调函数，告知文件下载失败
					break;
				}
                osal_memcpy(err_rsp + 4, (u8 *)download_file_info.err_num, download_file_info.err_index * 2);
                response(err_rsp, download_file_info.err_index * 2 + 4);
                for (i = 0; i < download_file_info.err_index; i++)
                {
                    LOG("%d,", download_file_info.err_num[i]);
                }
                LOG("\n");
                download_file_info.previous_num = download_file_info.err_num[0];
                file_write_count += 1;
            }
            break;
        }

        if (file_write_count == 0)      //文件为第一次下载
        {
            handle_file_first(current_num, cmd.p.file_data.buff, cmd.len - 2);
        }
        else                            //处理文件第一次下载时丢失的包
        {
            handle_file_again(current_num, cmd.p.file_data.buff, cmd.len - 2);
        }
    }
    break;
    default:
    {
        // rsp = PPlus_ERR_OTA_UNKNOW_CMD;
        osal_memcpy(rsp, "NO_CMD", 6);
        response(rsp, 6);
		break;
    }
    }

}

static void handleConnStatusCB(uint16 connHandle, uint8 changeType)
{
    // Make sure this is not loopback connection
//    LOG("handleConnStatusCB %x, %d\n", connHandle, changeType);
    if (connHandle != LOOPBACK_CONNHANDLE)
    {
        // Reset Client Char Config if connection has dropped
        if ((changeType == LINKDB_STATUS_UPDATE_REMOVED) ||
                ((changeType == LINKDB_STATUS_UPDATE_STATEFLAGS) &&
                 (!linkDB_Up(connHandle))))
        {
            GATTServApp_InitCharCfg(connHandle, ota_ResponseCCCD);

            if (s_reboot_flg)
            {
                hal_system_soft_reset();
            }
        }
        else
        {
            s_reboot_flg = false;
        }
    }
}

static bStatus_t sendNotify(attHandleValueNoti_t* pNoti)
{
    uint16 connHandle;
    uint16 value;
    GAPRole_GetParameter(GAPROLE_CONNHANDLE, &connHandle);
    value = GATTServApp_ReadCharCfg(connHandle, ota_ResponseCCCD);

    if (connHandle == INVALID_CONNHANDLE)
    {
        return bleIncorrectMode;
    }

    // If notifications enabled
    if (value & GATT_CLIENT_CFG_NOTIFY)
    {
        // Set the handle
        pNoti->handle = ota_AttrTbl[OTA_RSP_HANDLE].handle;
        // Send the Indication
        return GATT_Notification(connHandle, pNoti, FALSE);
    }

    return bleIncorrectMode;
}

static uint8 ota_ReadAttrCB(uint16 connHandle, gattAttribute_t* pAttr,
                            uint8* pValue, uint16* pLen, uint16 offset, uint8 maxLen)
{
    bStatus_t status = ATT_ERR_READ_NOT_PERMITTED;
    LOG("ReadAttrCB\n");

    // If attribute permissions require authorization to read, return error
    if (gattPermitAuthorRead(pAttr->permissions))
    {
        // Insufficient authorization
        return (ATT_ERR_INSUFFICIENT_AUTHOR);
    }

    return (status);
}

static bStatus_t ota_WriteAttrCB(uint16 connHandle, gattAttribute_t* pAttr,
                                 uint8* pValue, uint16 len, uint16 offset)
{
    bStatus_t status = SUCCESS;
    //uint8 notifyApp = 0xFF;
    // If attribute permissions require authorization to write, return error
    if (gattPermitAuthorWrite(pAttr->permissions))
    {
        // Insufficient authorization
        return (ATT_ERR_INSUFFICIENT_AUTHOR);
    }

    if (pAttr->type.len == ATT_BT_UUID_SIZE)
    {
        // 16-bit UUID
        uint16 uuid = BUILD_UINT16(pAttr->type.uuid[0], pAttr->type.uuid[1]);

        if (uuid == GATT_CLIENT_CHAR_CFG_UUID)
        {
            status = GATTServApp_ProcessCCCWriteReq(connHandle, pAttr, pValue, len,
                                                    offset, GATT_CLIENT_CFG_NOTIFY);

            if (status == SUCCESS)
            {
                uint16 charCfg = BUILD_UINT16(pValue[0], pValue[1]);
                LOG("CCCD set: [%d]\n", charCfg);
//                s_ota_app.notify_en = (charCfg == 1);
            }
        }
    }
    else            //数据的接收的UUID是16位
    {
        //LOG("WR:%d\n", pAttr->handle);
        LOG("\n");
        // 128-bit UUID Command
        if (pAttr->handle == ota_AttrTbl[OTA_COMMAND_HANDLE].handle || pAttr->handle == ota_AttrTbl[OTA_UART_HANDLE].handle)
        {
            process_cmd(pValue, len);
        }
    }

    return (status);
}

//用于初始化时，注册UUID和其回调函数
bStatus_t ota_app_AddService(ble_updata_change_CB_t app_CB)
{
    uint8 status = SUCCESS;
    // Register with Link DB to receive link status change callback
    VOID linkDB_Register(handleConnStatusCB);
//    load_ota_version();
    GATTServApp_InitCharCfg(INVALID_CONNHANDLE, ota_ResponseCCCD);
    // Register GATT attribute list and CBs with GATT Server App
    status = GATTServApp_RegisterService(ota_AttrTbl,
                                         GATT_NUM_ATTRS(ota_AttrTbl),
                                         &ota_ProfileCBs);
    ble_updata_app_CBs = app_CB;
    if (status != SUCCESS)
    {
        LOG("Add OTA service failed!\n");
    }

    return (status);
}

static uint8 save_file_to_flash(uint16 num, uint8 *buff, uint16 size)
{
    uint16 offset_addr = (num - 1) * ONCE_DOWNLOAD_SIZE;

    return write_file_to_flash(offset_addr, buff, size);
}

static void handle_file_first(uint16_t current_num, uint8* data_buff, uint16_t len)
{
    int16_t count = 0;

//  if (current_num == 1)
//  {
//      osal_memset(&download_file_info.previous_num, 0, sizeof(download_file_info) - 2);
//  }
    count  = current_num - download_file_info.previous_num;     //计算包的下载是否有偏差
    if (count < 1)
    {
        return;
    }
    while (count > 1)
    {
        count--;
        download_file_info.err_num[download_file_info.err_index++] = current_num - count;
    }

    if (save_file_to_flash(current_num, data_buff, len) != SAVE_FILE_ERROR)               //数据写入成功
    {
        LOG("Write %d Success\n ", current_num);
        download_file_info.previous_num = current_num;
    }
    else                                                                                  //数据写入失败
    {
        LOG("Write %d ERR\n ", current_num);
        download_file_info.err_num[download_file_info.err_index++] = current_num;
    }
}

static void handle_file_again(uint16_t current_num, uint8* data_buff, uint16_t len)
{
    uint8 i;
    uint8 index = 0;
    uint16_t err_num[ERR_COUNT];

    if (save_file_to_flash(current_num, data_buff, len) != SAVE_FILE_ERROR)              //数据写入成功
    {
        LOG("Write %d Success\n ", current_num);
        for (i = 0; i < download_file_info.err_index; i++)
        {
            if (download_file_info.err_num[i] == current_num)
            {
//              download_file_info.err_num[i] = 0;
//              index = download_file_info.err_index - 1;
            }
            else
            {
                err_num[index++] = download_file_info.err_num[i];
            }
        }
        download_file_info.err_index = index;
        osal_memcpy(download_file_info.err_num, err_num, index);
    }
    else                                                                                  //数据写入失败
    {
        LOG("Write %d ERR\n ", current_num);
    }
}
