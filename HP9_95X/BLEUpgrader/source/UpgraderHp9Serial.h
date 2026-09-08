#ifndef __UPGRADERHP9_H__
#define __UPGRADERHP9_H__

#include "types.h"

#define SUPPORT_SERIES_NAME                "95X"
#define SUPPORT_LEN                					46 //90X:12 95X:46 97X:86
enum{
	BACKDOOR_CHANGE_SUCCESS = 0,
	UPDATE_SNDATA_FAILED = 1,
	UPDATE_TYPEDATA_FAILED = 2,
	UPDATE_CTLDATA_FAILED = 3,
	UPDATE_BACKDOOR_FAILED = 4,
	
	START_UPDATE_CHIP = 5,
	CHIP_SCAN_ADDRESS_ERR,
	CHIP_NEWEST_VERSION,
	READ_BACKDOOR_DATA_ERR,
	CHIP_TYPE_ERR,
	ONCE_SEND_DELAY_100MS,
	SEND_ONE_SN_SUCCESS,
	
	ALLOC_DATA_SUCCESS,
	ALLOC_DATA_ERROR
//	ONCE_SN_SEND = 2
};




u8 heap_data_init(void);
void heap_data_free(void);
void i2c_init(void);
void get_sn_array(void);
u8 upgrader_hp9_serial(void);
u8 backdoor_changesn(void);

#endif /* HEARTRATE_H */
