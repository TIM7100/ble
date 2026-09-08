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


#ifndef _OTA_APP_SERVICE_H
#define _OTA_APP_SERVICE_H
#include "bcomdef.h"
#include "version.h"
#include "app_datetime.h"



//#define OTA_MODE_SELECT_REG 0x4000f034


//#define OTA_APP_SERVICE_VERSION "V2.0.1"




/****************************** 蓝牙回复APP数据格式 -- Start ********************************/
#define RP_HP9_BURN_FILE_UPDATA	                 "Updata"
#define RP_HP9_BURN_FILE_UPDATA_LEN                 6
#define RP_HP9_BURN_FILE_NEWEST                  "Newest"
#define RP_HP9_BURN_FILE_NEWEST_LEN                 6

#define RP_HP9_BURN_FILE_START_DOWNLOAD            "OK"
#define RP_HP9_BURN_FILE_START_DOWNLOAD_LEN         2   

#define RP_HP9_BURN_FILE_SAVE_SUCCESS 		    "Download_OK"
#define RP_HP9_BURN_FILE_SAVE_SUCCESS_LEN           11
//烧录升级芯片过程和结果 -- 上报
#define RP_BURN_CHIP_PROGRESS		"Progress:%03d"							//芯片升级进度上报			
#define RP_BURN_CHIP_PROGRESS_LEN         12
#define RP_BURN_CHIP_RESULT	        "Code:%d"								//芯片升级结果上报	
#define RP_BURN_CHIP_RESULT_LEN         6

/****************************** 蓝牙回复APP数据格式 -- End ********************************/


/****************************** 蓝牙单次传输时的数据大小 -- START ********************************/
#define ONCE_DOWNLOAD_SIZE    128				//单次下载的文件的大小

/****************************** APP下发数据命令码 ********************************/
enum 
{
	OTA_APP_CMD_VERSION = '1',
	OTA_APP_CMD_UPDATA = '2',
	OTA_APP_CMD_START_DOWN = '3'
};


/****************************** 蓝牙接收APP数据的数据格式 -- START ********************************/
#pragma pack(1)
typedef struct
{
	uint16_t len;								//本次接收数据的长度
	uint8 cmd;									//命令码	
	union
	{
		struct
		{
			uint8 num[2];						//分段文件的段号
			uint8 buff[ONCE_DOWNLOAD_SIZE];		//文件的数据
		} file_data;								
		
		struct
		{
			char version[10];
			datetime_t current_time;
		}file_version;								//传输的文件的版本和传输的时间, 在命令码为 OTA_APP_CMD_VERSION 时传输 
		
        struct
        {
            uint16 size;					//本次传输的文件分段的数量, 在命令码为 OTA_APP_CMD_UPDATA 时传输 
            uint8 k_count;
            uint8 c_count;
            uint8 m_count;
            uint8 y_count;
        }file_info;
	}p;		//parameter
//	uint8 buff[ONCE_DOWNLOAD_COUNT];
}ble_updata_info_t;
#pragma pack()
/****************************** 蓝牙接收APP数据的数据格式 -- END ********************************/

typedef uint8 (*ble_updata_change_CB_t)(uint8 result);						//下载文件结果回调函数

bStatus_t ota_app_AddService(ble_updata_change_CB_t app_CB);

void response(char* rsp_data, uint8 size);
#endif

