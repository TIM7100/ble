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
    Filename:       simpleBLEPeripheral.c
    Revised:
    Revision:

    Description:    This file contains the Simple BLE Peripheral sample application


**************************************************************************************************/
/*********************************************************************
    INCLUDES
*/
#include "bcomdef.h"
#include "rf_phy_driver.h"
#include "global_config.h"
#include "OSAL.h"
#include "OSAL_PwrMgr.h"
#include "gatt.h"
#include "hci.h"
#include "gapgattserver.h"
#include "gattservapp.h"
#include "ota_app_service.h"
#include "peripheral.h"
#include "gapbondmgr.h"
#include "pwrmgr.h"
#include "gpio.h"
#include "simpleBLEPeripheral.h"
#include "ll.h"
#include "ll_hw_drv.h"
#include "ll_def.h"
#include "hci_tl.h"
#include "gatt_profile_uuid.h"
#include "led_light.h"
#include "file_handle.h"
#include "key.h"
#include "UpgraderHp9Serial.h"
#include "random.h"
#include <stdio.h>
/*********************************************************************
    MACROS
*/
//#define LOG(...)
/*********************************************************************
    CONSTANTS
*/

// How often to perform periodic event
#define SBP_PERIODIC_EVT_PERIOD                   5000

#define DEVINFO_SYSTEM_ID_LEN             8
#define DEVINFO_SYSTEM_ID                 0


#define DEFAULT_DISCOVERABLE_MODE             GAP_ADTYPE_FLAGS_GENERAL

// Minimum connection interval (units of 1.25ms, 80=100ms) if automatic parameter update request is enabled
#define DEFAULT_DESIRED_MIN_CONN_INTERVAL     24//32//80

// Maximum connection interval (units of 1.25ms, 800=1000ms) if automatic parameter update request is enabled
#define DEFAULT_DESIRED_MAX_CONN_INTERVAL     800//48//800

// Slave latency to use if automatic parameter update request is enabled
#define DEFAULT_DESIRED_SLAVE_LATENCY         0

// Supervision timeout value (units of 10ms, 1000=10s) if automatic parameter update request is enabled
#define DEFAULT_DESIRED_CONN_TIMEOUT          500//1000

// Whether to enable automatic parameter update request when a connection is formed
#define DEFAULT_ENABLE_UPDATE_REQUEST         TRUE

// Connection Pause Peripheral time value (in seconds)
#define DEFAULT_CONN_PAUSE_PERIPHERAL         6

#define INVALID_CONNHANDLE                    0xFFFF

// Default passcode
#define DEFAULT_PASSCODE                      0//19655

// Length of bd addr as a string
#define B_ADDR_STR_LEN                        15

#define RESOLVING_LIST_ENTRY_NUM              10

//LED Pin
#define GPIO_GREEN    P11
#define GPIO_BLUE     P18
#define GPIO_RED      P7

//外部写入名称地址
#define DEVICE_NAME_FLASH_ADDR  0x110FF000


/*********************************************************************
    TYPEDEFS
*/
typedef enum {
	OFTEN_GREEN,
	OFTEN_RED,
	FLASH_GREEN,
	FLASH_RED,
    FLASH_GREEN_RED
}LED_STATE_t;

 LED_STATE_t light_state;


/*********************************************************************
    GLOBAL VARIABLES
*/
perStatsByChan_t g_perStatsByChanTest;

/*********************************************************************
    EXTERNAL VARIABLES
*/
volatile uint8_t g_current_advType = LL_ADV_CONNECTABLE_UNDIRECTED_EVT;

extern CONST uint8 ota_ServiceUUID[ATT_UUID_SIZE];
//extern wtnrTest_t wtnrTest;
extern l2capSARDbugCnt_t g_sarDbgCnt;
extern uint32 g_osal_mem_allo_cnt;
extern uint32 g_osal_mem_free_cnt;

extern uint32 counter_tracking;

extern uint32 g_counter_traking_avg;
extern uint32 g_counter_traking_cnt;
extern uint32_t  g_TIM2_IRQ_TIM3_CurrCount;
extern uint32_t  g_TIM2_IRQ_to_Sleep_DeltTick;
extern uint32_t  g_osal_tick_trim;
extern uint32_t  g_TIM2_IRQ_PendingTick;
extern uint32_t  g_TIM2_wakeup_delay;

/*********************************************************************
    EXTERNAL FUNCTIONS
*/


/*********************************************************************
    LOCAL VARIABLES
*/
static uint8 simpleBLEPeripheral_TaskID;   // Task ID for internal task/event processing

static gaprole_States_t gapProfileState = GAPROLE_INIT;

//// GAP - SCAN RSP data (max size = 31 bytes)
static uint8 scanRspData[] =
{
    // complete name
    0x12,   // length of this data
    GAP_ADTYPE_LOCAL_NAME_COMPLETE,
    0x46,   // 'F'
    0x46,   // 'F'
    0x46,   // 'F'
    0x46,   // 'F'
    0x46,   // 'F'
    0x46,   // 'F'
    0x46,   // 'F'
    0x46,   // 'F'
    0x46,   // 'F'
    0x46,   // 'F'
    0x46,   // 'F'
    0x46,   // 'F'
    0x46,   // 'F'
    0x46,   // 'F'
    0x46,   // 'F'
    0x46,   // 'F'
    0x46,   // 'F'


    // connection interval range	连接间隔
    0x05,   // length of this data
    GAP_ADTYPE_SLAVE_CONN_INTERVAL_RANGE,
    LO_UINT16( DEFAULT_DESIRED_MIN_CONN_INTERVAL ),   // 100ms
    HI_UINT16( DEFAULT_DESIRED_MIN_CONN_INTERVAL ),
    LO_UINT16( DEFAULT_DESIRED_MAX_CONN_INTERVAL ),   // 1s
    HI_UINT16( DEFAULT_DESIRED_MAX_CONN_INTERVAL ),

    // Tx power level	发射功率
    0x02,   // length of this data
    GAP_ADTYPE_POWER_LEVEL,
    0       // 0dBm
};


// advert data for iBeacon
static uint8 advertData[] =
{
    0x02,   // length of this data
    GAP_ADTYPE_FLAGS,
    DEFAULT_DISCOVERABLE_MODE | GAP_ADTYPE_FLAGS_BREDR_NOT_SUPPORTED,
	0x11, 				//
	GAP_ADTYPE_128BIT_COMPLETE, 				
	0,					//	ota_ServiceUUID[0], 
	0,					//	ota_ServiceUUID[1],
	0,					//	ota_ServiceUUID[2],
	0,					//	ota_ServiceUUID[3],
	0,					//	ota_ServiceUUID[4],
	0,					//	ota_ServiceUUID[5],
	0,					//	ota_ServiceUUID[6],
	0,					//	ota_ServiceUUID[7],
	0,					//	ota_ServiceUUID[8],
	0,					//	ota_ServiceUUID[9], 
	0,					//	ota_ServiceUUID[10],
	0,					//	ota_ServiceUUID[11],
	0,					//	ota_ServiceUUID[12],
	0,					//	ota_ServiceUUID[13],
	0,					//	ota_ServiceUUID[14],
	0,					//	ota_ServiceUUID[15],
	0x04,
	GAP_ADTYPE_MANUFACTURER_SPECIFIC,
	0,
	0,
	0,
	0,
	0,
	0,
	0
};


//// GAP GATT Attributes
static uint8 attDeviceName[GAP_DEVICE_NAME_LEN] = "MX -- 97X";


// Advers
static uint8 SeriesName[4] = SUPPORT_SERIES_NAME;

//LED PIN Init
static gpio_pin_e led_pins[3] = {GPIO_GREEN, GPIO_BLUE, GPIO_RED};

//test file parameter
static uint16 printf_count = 0;
/*********************************************************************
    LOCAL FUNCTIONS
*/
static void simpleBLEPeripheral_ProcessOSALMsg( osal_event_hdr_t* pMsg );
static void peripheralStateNotificationCB( gaprole_States_t newState );
static void peripheralStateReadRssiCB( int8 rssi  );
static uint8 ota_ble_updata_app_CB(uint8 result);		//APP下发的固件信息处理回调函数

void check_PerStatsProcess(void);
char* bdAddr2Str( uint8* pAddr );

/*********************************************************************
    PROFILE CALLBACKS
*/

// GAP Role Callbacks
static gapRolesCBs_t simpleBLEPeripheral_PeripheralCBs =
{
    peripheralStateNotificationCB,  // Profile State Change Callbacks
    peripheralStateReadRssiCB       // When a valid RSSI is read from controller (not used by application)
};
#if (DEF_GAPBOND_MGR_ENABLE==1)
//GAP Bond Manager Callbacks, add 2017-11-15
static gapBondCBs_t simpleBLEPeripheral_BondMgrCBs =
{
    NULL,                     // Passcode callback (not used by application)
    NULL                      // Pairing / Bonding state Callback (not used by application)
};
#endif




/*********************************************************************
    PUBLIC FUNCTIONS
*/

/*********************************************************************
    @fn      SimpleBLEPeripheral_Init

    @brief   Initialization function for the Simple BLE Peripheral App Task.
            This is called during initialization and should contain
            any application specific initialization (ie. hardware
            initialization/setup, table initialization, power up
            notificaiton ... ).

    @param   task_id - the ID assigned by OSAL.  This ID should be
                      used to send messages and set timers.

    @return  none
*/
void SimpleBLEPeripheral_Init( uint8 task_id )					//修改的重点
{
    simpleBLEPeripheral_TaskID = task_id;
    // Setup the GAP
    VOID GAP_SetParamValue( TGAP_CONN_PAUSE_PERIPHERAL, DEFAULT_CONN_PAUSE_PERIPHERAL );
    // Setup the GAP Peripheral Role Profile
    {
        // device starts advertising upon initialization
        uint8 initial_advertising_enable = FALSE;
        uint8 enable_update_request = DEFAULT_ENABLE_UPDATE_REQUEST;
        uint8 advChnMap = GAP_ADVCHAN_37 | GAP_ADVCHAN_38 | GAP_ADVCHAN_39;
        // By setting this to zero, the device will go into the waiting state after
        // being discoverable for 30.72 second, and will not being advertising again
        // until the enabler is set back to TRUE
        uint16 gapRole_AdvertOffTime = 0;
        uint16 desired_min_interval = DEFAULT_DESIRED_MIN_CONN_INTERVAL;
        uint16 desired_max_interval = DEFAULT_DESIRED_MAX_CONN_INTERVAL;
        uint16 desired_slave_latency = DEFAULT_DESIRED_SLAVE_LATENCY;
        uint16 desired_conn_timeout = DEFAULT_DESIRED_CONN_TIMEOUT;
        uint8 peerPublicAddr[] =
        {
            0x01,
            0x02,
            0x03,
            0x04,
            0x05,
            0x06
        };
        uint8 advType =g_current_advType;// LL_ADV_NONCONNECTABLE_UNDIRECTED_EVT;//LL_ADV_SCANNABLE_UNDIRECTED_EVT;//LL_ADV_CONNECTABLE_LDC_DIRECTED_EVT;//;    // it seems a  bug to set GAP_ADTYPE_ADV_NONCONN_IND = 0x03
        GAPRole_SetParameter( GAPROLE_ADV_EVENT_TYPE, sizeof( uint8 ), &advType );
        GAPRole_SetParameter(GAPROLE_ADV_DIRECT_ADDR, sizeof(peerPublicAddr), peerPublicAddr);
        // set adv channel map
        GAPRole_SetParameter(GAPROLE_ADV_CHANNEL_MAP, sizeof(uint8), &advChnMap);
        // Set the GAP Role Parameters
        GAPRole_SetParameter( GAPROLE_ADVERT_ENABLED, sizeof( uint8 ), &initial_advertising_enable );
        GAPRole_SetParameter( GAPROLE_ADVERT_OFF_TIME, sizeof( uint16 ), &gapRole_AdvertOffTime );
        osal_memcpy(&scanRspData[2], attDeviceName, 0x11);													//扫描回应的设备名
        GAPRole_SetParameter( GAPROLE_SCAN_RSP_DATA, sizeof ( scanRspData ), scanRspData );					//扫描应答数据			广播扫描接收的数据格式length+type+value
				osal_memcpy(&advertData[5], ota_ServiceUUID, 16);
				osal_memcpy(&advertData[23], SeriesName, 3);
				//GAPRole_SetParameter( GAPROLE_BD_ADDR, 6, mac_buff);												//设置mac地址
        GAPRole_SetParameter( GAPROLE_ADVERT_DATA, sizeof( advertData ), advertData );						//广播数据
        GAPRole_SetParameter( GAPROLE_PARAM_UPDATE_ENABLE, sizeof( uint8 ), &enable_update_request );
        GAPRole_SetParameter( GAPROLE_MIN_CONN_INTERVAL, sizeof( uint16 ), &desired_min_interval );
        GAPRole_SetParameter( GAPROLE_MAX_CONN_INTERVAL, sizeof( uint16 ), &desired_max_interval );
        GAPRole_SetParameter( GAPROLE_SLAVE_LATENCY, sizeof( uint16 ), &desired_slave_latency );
        GAPRole_SetParameter( GAPROLE_TIMEOUT_MULTIPLIER, sizeof( uint16 ), &desired_conn_timeout );
    }
    // Set the GAP Characteristics
    GGS_SetParameter( GGS_DEVICE_NAME_ATT, GAP_DEVICE_NAME_LEN, attDeviceName );					//设置GAP服务的设备名字参数
    // Set advertising interval
    {
        uint16 advInt = 800;//2400;//1600;//1600;//800;//1600;   // actual time = advInt * 625us
        GAP_SetParamValue( TGAP_LIM_DISC_ADV_INT_MIN, advInt );
        GAP_SetParamValue( TGAP_LIM_DISC_ADV_INT_MAX, advInt );
        GAP_SetParamValue( TGAP_GEN_DISC_ADV_INT_MIN, advInt );
        GAP_SetParamValue( TGAP_GEN_DISC_ADV_INT_MAX, advInt );
    }
    #if(DEF_GAPBOND_MGR_ENABLE==1)				//绑定管理器，在魔术棒里面修改，目前为0
    // Setup the GAP Bond Manager, add 2017-11-15
    {
        uint32 passkey = DEFAULT_PASSCODE;
        uint8 pairMode = GAPBOND_PAIRING_MODE_WAIT_FOR_REQ;
        uint8 mitm = TRUE;
        uint8 ioCap = GAPBOND_IO_CAP_NO_INPUT_NO_OUTPUT;
        uint8 bonding = TRUE;
        GAPBondMgr_SetParameter( GAPBOND_DEFAULT_PASSCODE, sizeof ( uint32 ), &passkey );
        GAPBondMgr_SetParameter( GAPBOND_PAIRING_MODE, sizeof ( uint8 ), &pairMode );
        GAPBondMgr_SetParameter( GAPBOND_MITM_PROTECTION, sizeof ( uint8 ), &mitm );
        GAPBondMgr_SetParameter( GAPBOND_IO_CAPABILITIES, sizeof ( uint8 ), &ioCap );
        GAPBondMgr_SetParameter( GAPBOND_BONDING_ENABLED, sizeof ( uint8 ), &bonding );
    }
    #endif
    // Initialize GATT attributes			添加服务和其回调函数
    GGS_AddService( GATT_ALL_SERVICES );            // GAP			   可以通过该函数修改设备名
    GATTServApp_AddService( GATT_ALL_SERVICES );    // GATT attributes 默认不动
	//自定义的服务，修改的主要内容
    ota_app_AddService(ota_ble_updata_app_CB);

    #if (1)
    {
        uint8 mtuSet = 134;
        llInitFeatureSet2MPHY(TRUE);
        llInitFeatureSetDLE(TRUE);
        ATT_SetMTUSizeMax(mtuSet);
        LOG("[2Mbps | DLE | MTU %d] \n",mtuSet);
    }
    #else
    ATT_SetMTUSizeMax(23);
    llInitFeatureSet2MPHY(FALSE);
    llInitFeatureSetDLE(FALSE);
    #endif
    // Setup a delayed profile startup
    osal_set_event( simpleBLEPeripheral_TaskID, SBP_START_DEVICE_EVT );
    // for receive HCI complete message
    GAP_RegisterForHCIMsgs(simpleBLEPeripheral_TaskID);// register ID
	light_init(led_pins, 3);
	app_datetime_init();
	//my_key_init(simpleBLEPeripheral_TaskID);
}

/*********************************************************************
    @fn      SimpleBLEPeripheral_ProcessEvent

    @brief   Simple BLE Peripheral Application Task event processor.  This function
            is called to process all events for the task.  Events
            include timers, messages and any other user defined events.

    @param   task_id  - The OSAL assigned task ID.
    @param   events - events to process.  This is a bit map and can
                     contain more than one event.

    @return  events not processed
*/
uint16 SimpleBLEPeripheral_ProcessEvent( uint8 task_id, uint16 events )
{
    VOID task_id; // OSAL required parameter that isn't used in this function
	static uint8 flash_flag = 1;
	static uint16 progress_count = 0;
	static uint8 sn_count = 0;
	uint8 return_code = 0;
	char response_buff[10] = {0};
	uint8 file_state = 0;
	
    if ( events & SYS_EVENT_MSG )
    {
        uint8* pMsg;
				LOG("SYS_EVENT_MSG\n");
        if ( (pMsg = osal_msg_receive( simpleBLEPeripheral_TaskID )) != NULL )
        {
            simpleBLEPeripheral_ProcessOSALMsg( (osal_event_hdr_t*)pMsg );
            // Release the OSAL message
            VOID osal_msg_deallocate( pMsg );
        }
        // return unprocessed events
        return (events ^ SYS_EVENT_MSG);
    }

    if ( events & SBP_START_DEVICE_EVT )
    {
		LOG("SBP_START_DEVICE_EVT\n");
        // Start the Device
        VOID GAPRole_StartDevice( &simpleBLEPeripheral_PeripheralCBs );	
        #if(DEF_GAPBOND_MGR_ENABLE==1)
        // Start Bond Manager, 2017-11-15
        VOID GAPBondMgr_Register( &simpleBLEPeripheral_BondMgrCBs );
        #endif
        // Set timer for first periodic event
        HCI_LE_ReadResolvingListSizeCmd();
        return ( events ^ SBP_START_DEVICE_EVT );
    }

    
    if ( events & SBP_LIGHT_STATE_EVT)
    {
		switch(light_state)
		{
		case OFTEN_RED:					//红灯亮，表示芯片存储的文件异常
			LIGHT_ONLY_RED_ON;
			break;
		case OFTEN_GREEN:				//绿灯亮，表示芯片存储的文件正常
			LIGHT_ONLY_GREEN_ON;
			break;
		case FLASH_GREEN:				//绿灯闪烁，代表连接蓝牙后文件更新下载成功
			if (flash_flag)
			{
				LIGHT_ONLY_GREEN_ON;
			}
			else 
			{
				LIGHT_ALL_OFF;
			}
			flash_flag = !flash_flag;
			break;
		case FLASH_RED:					//红灯闪烁，代表连接蓝牙后文件更新下载失败
			if (flash_flag)
			{
				LIGHT_ONLY_RED_ON;
			}
			else 
			{
				LIGHT_ALL_OFF;
			}
			flash_flag = !flash_flag;
			break;
        case FLASH_GREEN_RED:
            if (flash_flag)
			{
                LIGHT_ALL_OFF;
				LIGHT_ONLY_RED_ON;
			}
			else 
			{
				LIGHT_ALL_OFF;
                LIGHT_ONLY_GREEN_ON;
			}
            flash_flag = !flash_flag;
			break;
		}
        return ( events ^ SBP_LIGHT_STATE_EVT);
    }
    
    if (events & SBP_FILE_AES_EVT)              //将下载的加密升级包进行解密的事件
    {
		if (handle_aes_file(printf_count) == file_deaes_continue)
		{
			LOG("Handle File Num %d\n", printf_count);
			osal_start_timerEx(simpleBLEPeripheral_TaskID, SBP_FILE_AES_EVT, 100);
			printf_count++;
		}
		else
		{
			file_state = FILE_DOWNLOADED;
			updata_file_info(NULL, &file_state, 0, 0, 0, 0);				        //把文件运行状态写入Flash
			printf_count = 0;
			response(RP_HP9_BURN_FILE_SAVE_SUCCESS, RP_HP9_BURN_FILE_SAVE_SUCCESS_LEN);
            
            //打印解密后的升级包的首 尾，各512字节

			test_printf_file_data(0);
			test_printf_file_data(0xa8);
#if SBP_KEY_BURN_EVT
            /* 初始化按键 */
            my_key_init(simpleBLEPeripheral_TaskID);                                //按键检测事件
#endif
            osal_stop_timerEx(simpleBLEPeripheral_TaskID, SBP_FILE_AES_EVT);
			osal_start_timerEx(simpleBLEPeripheral_TaskID, SBP_AUTO_BURN_EVT, 90);  //自动检测事件
		}	
        return (events ^ SBP_FILE_AES_EVT);
    }
    
    
#if SBP_KEY_BURN_EVT	
	if (events & SBP_KEY_BURN_EVT)													//按键事件，触发升级判断
	{		
		LOG("Key press Start\n");		
		light_state = FLASH_GREEN;													//按下按键开始升级芯片时，绿灯闪烁
		heap_data_free();		
		set_random_seed();															//根据当前时间，设置随机种子
				
		return_code = upgrader_hp9_serial();										//读取芯片OEM数据，来判断芯片是否需要升级
		if (return_code != START_UPDATE_CHIP)
		{
			if (return_code == CHIP_NEWEST_VERSION)
			{
				light_state = OFTEN_GREEN;											//芯片为最新版本，不需要升级，绿灯常亮
			}
			else
			{
				light_state = OFTEN_RED;											//升级失败，红灯常亮
			}
			
			sprintf(response_buff, RP_BURN_CHIP_RESULT, return_code);
			response(response_buff, RP_BURN_CHIP_RESULT_LEN);
		}
		else 																		
		{
			progress_count = 0;
			sn_count = 0;
			osal_start_timerEx(simpleBLEPeripheral_TaskID, SBP_HANDLE_FILE, 90);	//开启升级事件
		}
		return (events ^ SBP_KEY_BURN_EVT);
	}
#endif	
	if (events & SBP_AUTO_BURN_EVT)													     //自动升级事件，根据遍历芯片地址来判断是否接触到芯片
	{				       
		heap_data_free();                                                                //将芯片升级时需要使用的参数堆空间先释放
		light_state = FLASH_GREEN;                                                       //芯片连接成功，且拥有最新的升级包
		return_code = upgrader_hp9_serial();										     //读取芯片OEM数据，来判断芯片是否需要升级
		if (return_code == CHIP_SCAN_ADDRESS_ERR)
		{
			osal_start_timerEx(simpleBLEPeripheral_TaskID, SBP_AUTO_BURN_EVT, 90); 
		}
		else if (return_code == START_UPDATE_CHIP)
		{
            light_state = FLASH_GREEN_RED;											     //接触到芯片，开始升级，红绿灯交替闪烁
			get_sn_array();
			progress_count = 0;
			sn_count = 0;
            osal_stop_timerEx(simpleBLEPeripheral_TaskID, SBP_AUTO_BURN_EVT);
			osal_start_timerEx(simpleBLEPeripheral_TaskID, SBP_UPDATING_CHIP_EVT, 70);   //开启升级事件
		}
		else 																		
		{
            if (return_code == CHIP_NEWEST_VERSION)
            {
                light_state = OFTEN_GREEN;											//芯片为最新版本，不需要升级，绿灯常亮
            }
            else
            {
                light_state = OFTEN_RED;											//升级失败，红灯常亮
            }
            sprintf(response_buff, RP_BURN_CHIP_RESULT, return_code);
            response(response_buff, RP_BURN_CHIP_RESULT_LEN);
            osal_start_timerEx(simpleBLEPeripheral_TaskID, SBP_AUTO_BURN_EVT, 1000); 
		}
		return (events ^ SBP_AUTO_BURN_EVT);
	}
    
    //升级事件，开始运行芯片升级算法
	if (events & SBP_UPDATING_CHIP_EVT)												    
	{
        /*
         * 芯片升级时，需要传输10套SN号给芯片，每套SN号大小为 0xF00。
         * 每套SN号分成 n小份每小份为0xE0，每次成功发送一次（0xE0）数据给芯片后，都需要延时一小会
         * 该延时办法：结束该事件，并在指定的时间后重新激活事件来达成延时的目的
         */
        LOG("SBP_UPDATING_CHIP_EVT\n");
		return_code = backdoor_changesn();
		if (return_code == ONCE_SEND_DELAY_100MS)								  			
		{
			if (progress_count == 0)
			{
				sprintf(response_buff, RP_BURN_CHIP_PROGRESS, 0);
				response(response_buff, RP_BURN_CHIP_PROGRESS_LEN);
			}
			progress_count++;															
			osal_start_timerEx(simpleBLEPeripheral_TaskID, SBP_UPDATING_CHIP_EVT, 10);
		}
		else if(return_code == SEND_ONE_SN_SUCCESS)						          //成功发送完一套数据的返回标志
		{
			sn_count++;													          //发送一套SN成功，切换到下一套数据的进度显示分区-- 0、20、40、60....200
			progress_count = sn_count * 100;
			sprintf(response_buff, RP_BURN_CHIP_PROGRESS, progress_count / 2);
			response(response_buff, RP_BURN_CHIP_PROGRESS_LEN);			          //上传升级芯片进度
			osal_start_timerEx(simpleBLEPeripheral_TaskID, SBP_UPDATING_CHIP_EVT, 10);  //下一次发送数据时间间隔为90ms
		}
		else 																	  //十套SN数据发送完毕，根据返回码判断是否升级成功
		{
			if (return_code == BACKDOOR_CHANGE_SUCCESS)
			{
				light_state = OFTEN_GREEN;										  //芯片升级成功，绿灯常亮		
			}
			else																  	
			{
				light_state = OFTEN_RED;										  //芯片升级失败，红灯常亮  
			}
			sn_count = 0;
			sprintf(response_buff, RP_BURN_CHIP_RESULT, return_code);
			response(response_buff, RP_BURN_CHIP_RESULT_LEN);
			osal_start_timerEx(simpleBLEPeripheral_TaskID, SBP_AUTO_BURN_EVT, 1000); 
		}
		return ( events ^ SBP_UPDATING_CHIP_EVT );
	}

    if (events & SBP_RTC_TEST_EVT)
    {
		app_datetime_sync_handler();											   //校准系统时间，1分钟内需要校准一次，用于充当随机数的随机种子
        osal_start_timerEx(simpleBLEPeripheral_TaskID, SBP_RTC_TEST_EVT, 5000);
        return (events ^ SBP_RTC_TEST_EVT);
    }
	
	

    // enable adv
    if ( events & SBP_RESET_ADV_EVT )										
    {
		LOG("GAPROLE_ADVERT_ENABLED\n");
        uint8 initial_advertising_enable = TRUE;
        GAPRole_SetParameter( GAPROLE_ADVERT_ENABLED, sizeof( uint8 ), &initial_advertising_enable );       //设置广播使能参数
        return ( events ^ SBP_RESET_ADV_EVT );
    }

    //广播阶段时，红灯闪烁且其他升级任务停止使用
    return 0;
}


/******************************************************************************
 * @brief    蓝牙数据传输结果回调函数，
 * @param    result: FILE_DOWNLOADED -- 已成功接收蓝牙传输的文件，使能按键触发
 *         		     FILE_DOWNLOAD_ERR -- 接收蓝牙传输的文件失败，触发红灯闪烁状态
 * @return   0
********************************************************************************/
static uint8 ota_ble_updata_app_CB(uint8 result)
{
	osal_start_timerEx(simpleBLEPeripheral_TaskID, SBP_RTC_TEST_EVT, 10);		//开启系统时钟校准事件
	if (result == FILE_AES_ING)
	{
		light_state = FLASH_RED;	
		osal_start_timerEx(simpleBLEPeripheral_TaskID, SBP_FILE_AES_EVT, 50);
	}
	else if(result == FILE_DOWNLOAD_ERR)
	{
		light_state = FLASH_RED;
	}
	else if (result == FILE_DOWNLOADED)
	{
	//	light_state = FLASH_GREEN;
#if SBP_KEY_BURN_EVT
		/* 初始化按键 */
		my_key_init(simpleBLEPeripheral_TaskID);
#endif
        osal_start_timerEx(simpleBLEPeripheral_TaskID, SBP_AUTO_BURN_EVT, 90); 
	}
	
	return 0;
}


/*********************************************************************
    @fn      simpleBLEPeripheral_ProcessOSALMsg

    @brief   Process an incoming task message.

    @param   pMsg - message to process

    @return  none
*/
static void simpleBLEPeripheral_ProcessOSALMsg( osal_event_hdr_t* pMsg )
{
    hciEvt_CmdComplete_t* pHciMsg;

    switch ( pMsg->event )
    {
    case HCI_GAP_EVENT_EVENT:
    {
        switch( pMsg->status )
        {
        case HCI_COMMAND_COMPLETE_EVENT_CODE:
            pHciMsg = (hciEvt_CmdComplete_t*)pMsg;
            LOG("==> HCI_COMMAND_COMPLETE_EVENT_CODE: %x\n", pHciMsg->cmdOpcode);
            //safeToDealloc = gapProcessHCICmdCompleteEvt( (hciEvt_CmdComplete_t *)pMsg );
            break;

        default:
            //safeToDealloc = FALSE;  // Send to app
            break;
        }
    }
    }
}
/*********************************************************************
    @fn      peripheralStateReadRssiCB

    @brief   Notification from the profile of a state change.

    @param   newState - new state

    @return  none
*/
static void peripheralStateReadRssiCB( int8  rssi )
{
//    notifyBuf[15]++;
//    notifyBuf[16]=rssi;
//    notifyBuf[17]=HI_UINT16(g_conn_param_foff);
//    notifyBuf[18]=LO_UINT16(g_conn_param_foff);;
//    notifyBuf[19]=g_conn_param_carrSens;
}

/*********************************************************************
    @fn      peripheralStateNotificationCB

    @brief   Notification from the profile of a state change.

    @param   newState - new state

    @return  none
**********************************************************************/
static void peripheralStateNotificationCB( gaprole_States_t newState )
{
    switch ( newState )
    {
    case GAPROLE_STARTED:			//GAP配置完成，准备开启广播
    {
         LOG("START GAPROLE_STARTED");
        uint8 ownAddress[B_ADDR_LEN];
        uint8 str_addr[14]= {0};
        uint8 initial_advertising_enable = FALSE;//true
        GAPRole_GetParameter(GAPROLE_BD_ADDR, ownAddress);
        #if(0)
        uint8 systemId[DEVINFO_SYSTEM_ID_LEN];
        // use 6 bytes of device address for 8 bytes of system ID value
        systemId[0] = ownAddress[0];
        systemId[1] = ownAddress[1];
        systemId[2] = ownAddress[2];
        // set middle bytes to zero
        systemId[4] = 0x00;
        systemId[3] = 0x00;
        // shift three bytes up
        systemId[7] = ownAddress[5];
        systemId[6] = ownAddress[4];
        systemId[5] = ownAddress[3];
        DevInfo_SetParameter(DEVINFO_SYSTEM_ID, DEVINFO_SYSTEM_ID_LEN, systemId);
        #endif
		

//          osal_memcpy(&attDeviceName[3], (uint8*)0x1101C000, 7);
				
//        osal_memcpy(&str_addr[0],bdAddr2Str(ownAddress),14);
//        osal_memcpy(&scanRspData[9], &str_addr[4],10);
//        osal_memcpy(&attDeviceName[7], &str_addr[4],10);

        osal_memcpy(&str_addr[0],bdAddr2Str((uint8*)0x11043000),14);
        osal_memcpy(&scanRspData[11], &str_addr[6],5);
        osal_memcpy(&attDeviceName[9], &str_addr[6],5);
				
			

        GAPRole_SetParameter( GAPROLE_SCAN_RSP_DATA, sizeof ( scanRspData ), scanRspData );
        // Set the GAP Characteristics
        GGS_SetParameter( GGS_DEVICE_NAME_ATT, GAP_DEVICE_NAME_LEN, attDeviceName );
				
        GAPRole_SetParameter( GAPROLE_ADVERT_ENABLED, sizeof( uint8 ), &initial_advertising_enable );

        osal_set_event(simpleBLEPeripheral_TaskID, SBP_RESET_ADV_EVT);				//使能广播
    }
    break;

    case GAPROLE_ADVERTISING:				//广播阶段，将之前连接蓝牙的操作清除
    {
        LOG("START GAPROLE_ADVERTISING");
       // osal_start_timerEx(simpleBLEPeripheral_TaskID, SBP_PERIODIC_EVT, 100);
        check_file_info();
        light_state = FLASH_RED;					
		osal_start_reload_timer(simpleBLEPeripheral_TaskID, SBP_LIGHT_STATE_EVT, 200);
        osal_stop_timerEx(simpleBLEPeripheral_TaskID, SBP_RTC_TEST_EVT);
        osal_stop_timerEx(simpleBLEPeripheral_TaskID, SBP_AUTO_BURN_EVT);
        osal_stop_timerEx(simpleBLEPeripheral_TaskID, SBP_FILE_AES_EVT);
    }
    break;

    case GAPROLE_CONNECTED:
        HCI_PPLUS_ConnEventDoneNoticeCmd(simpleBLEPeripheral_TaskID, NULL);
        break;

    case GAPROLE_CONNECTED_ADV:
        break;

    case GAPROLE_WAITING:
        break;

    case GAPROLE_WAITING_AFTER_TIMEOUT:
        break;

    case GAPROLE_ERROR:
        break;

    default:
        break;
    }

    gapProfileState = newState;
    LOG("[GAP ROLE %d]\n",newState);
    VOID gapProfileState;
}

/*********************************************************************
    @fn      bdAddr2Str

    @brief   Convert Bluetooth address to string. Only needed when
           LCD display is used.

    @return  none
*/
char* bdAddr2Str( uint8* pAddr )
{
    uint8       i;
    char        hex[] = "0123456789ABCDEF";
    static char str[B_ADDR_STR_LEN];
    char*        pStr = str;
    *pStr++ = '0';
    *pStr++ = 'x';
    // Start from end of addr
    pAddr += B_ADDR_LEN;

    for ( i = B_ADDR_LEN; i > 0; i-- )
    {
        *pStr++ = hex[*--pAddr >> 4];
        *pStr++ = hex[*pAddr & 0x0F];
    }

    *pStr = 0;
    return str;
}


void check_PerStatsProcess(void)
{
    perStats_t perStats;
    uint16_t perRxNumTotal=0;
    uint16_t perRxCrcErrTotal=0;
    uint16_t perTxNumTotal=0;
    uint16_t perTxAckTotal=0;
    uint16_t perRxToCntTotal=0;
    uint16_t perConnEvtTotal=0;
    LOG("[PER STATS Notify]\r");
    LOG("----- ch connN rxNum rxCrc rxToN txAck txRty \r");

    for(uint8 i=0; i<37; i++)
    {
        LL_PLUS_PerStasReadByChn(i,&perStats);
        LOG("[PER] %02d %05d %05d %05d %05d %05d %05d\n",i,perStats.connEvtCnt,
            perStats.rxNumPkts,
            perStats.rxNumCrcErr,
            perStats.rxToCnt,
            perStats.TxNumAck,
            perStats.txNumRetry);
        perConnEvtTotal+= perStats.connEvtCnt;
        perRxNumTotal+= perStats.rxNumPkts;
        perRxCrcErrTotal+= perStats.rxNumCrcErr;
        perRxToCntTotal+= perStats.rxToCnt;
        perTxAckTotal+= perStats.TxNumAck;
        perTxNumTotal+= perStats.txNumRetry;
    }

    LOG("TOTAL ch connN rxNum rxCrc rxToN txAck txRty \r");
    LOG("\n[PER] -- %05d %05d %05d %05d %05d %05d\n",perConnEvtTotal,
        perRxNumTotal,
        perRxCrcErrTotal,
        perRxToCntTotal,
        perTxAckTotal,
        perTxNumTotal);
    LL_PLUS_PerStatsReset();
}

/*********************************************************************
*********************************************************************/
