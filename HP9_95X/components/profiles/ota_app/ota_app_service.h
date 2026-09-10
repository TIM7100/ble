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




/****************************** �����ظ�APP���ݸ�ʽ -- Start ********************************/
#define RP_HP9_BURN_FILE_UPDATA	                 "Updata"
#define RP_HP9_BURN_FILE_UPDATA_LEN                 6
#define RP_HP9_BURN_FILE_NEWEST                  "Newest"
#define RP_HP9_BURN_FILE_NEWEST_LEN                 6

#define RP_HP9_BURN_FILE_START_DOWNLOAD            "OK"
#define RP_HP9_BURN_FILE_START_DOWNLOAD_LEN         2   

#define RP_HP9_BURN_FILE_SAVE_SUCCESS 		    "Download_OK"
#define RP_HP9_BURN_FILE_SAVE_SUCCESS_LEN           11
//��¼����оƬ���̺ͽ�� -- �ϱ�
#define RP_BURN_CHIP_PROGRESS		"Progress:%03d"							//оƬ���������ϱ�			
#define RP_BURN_CHIP_PROGRESS_LEN         12
#define RP_BURN_CHIP_RESULT	        "Code:%d"								//оƬ��������ϱ�	
#define RP_BURN_CHIP_RESULT_LEN         6

/****************************** �����ظ�APP���ݸ�ʽ -- End ********************************/


/****************************** �������δ���ʱ�����ݴ�С -- START ********************************/
#define ONCE_DOWNLOAD_SIZE    128				//�������ص��ļ��Ĵ�С

/****************************** APP�·����������� ********************************/
enum 
{
	OTA_APP_CMD_VERSION = '1',
	OTA_APP_CMD_UPDATA = '2',
	OTA_APP_CMD_START_DOWN = '3',
	OTA_APP_CMD_OTA_VERSION = '4',		//对比OTA固件本地版本
	OTA_APP_CMD_OTA_SAVE_VERSION = '5',	//OTA成功后回写本地版本
	OTA_APP_CMD_OTA_GET_VERSION = '6'	//返回本地OTA固件版本(10字节)
};


/****************************** ��������APP���ݵ����ݸ�ʽ -- START ********************************/
#pragma pack(1)
typedef struct
{
	uint16_t len;								//���ν������ݵĳ���
	uint8 cmd;									//������	
	union
	{
		struct
		{
			uint8 num[2];						//�ֶ��ļ��Ķκ�
			uint8 buff[ONCE_DOWNLOAD_SIZE];		//�ļ�������
		} file_data;								
		
		struct
		{
			char version[10];
			datetime_t current_time;
		}file_version;								//������ļ��İ汾�ʹ����ʱ��, ��������Ϊ OTA_APP_CMD_VERSION ʱ���� 
		
        struct
        {
            uint16 size;					//���δ�����ļ��ֶε�����, ��������Ϊ OTA_APP_CMD_UPDATA ʱ���� 
            uint8 k_count;
            uint8 c_count;
            uint8 m_count;
            uint8 y_count;
        }file_info;
	}p;		//parameter
//	uint8 buff[ONCE_DOWNLOAD_COUNT];
}ble_updata_info_t;
#pragma pack()
/****************************** ��������APP���ݵ����ݸ�ʽ -- END ********************************/

typedef uint8 (*ble_updata_change_CB_t)(uint8 result);						//�����ļ�����ص�����

bStatus_t ota_app_AddService(ble_updata_change_CB_t app_CB);

void response(char* rsp_data, uint8 size);
#endif

