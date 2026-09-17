#ifndef _CODE_FLASH_H_
#define _CODE_FLASH_H_

#include "types.h"

#define MAC_ADDRESS						0x4000
#define VERSION_LEN                     10
#define SAVE_FILE_INFO_ADDRESS          0x11040000		//文件信息地址（移出Bootloader区域）//�ļ���Ϣ��ַ
#define SAVE_FLASH_START_ADDRESS		0x11034000UL    //�ļ��洢��ʼ��ַ
#define SAVE_FLASH_END_ADDRESS			((uint32)0x1103F000UL)    //�ļ��洢������ַ

#define ONE_SECTOR_SIZE                 0x1000			//Flash һ�������Ĵ�СΪ0x1000 �� 4096Byte

#define file_deaes_success           0
#define file_deaes_continue          1


typedef enum {
	FILE_DOWNLOADED = 0,		//�ļ��������
	FILE_DOWNLOADING,			//�ļ�������
	FILE_DOWNLOAD_ERR,          //�ļ����ش���
	FILE_AES_ING				//�ļ�������
}FILE_STATE_t;

// ��ȡFLASH�б����ļ���״̬
typedef enum
{
	FILE_SUCCESS,
	FILE_ERR,
	GET_FILE_INFO_ERR,
	SAVE_FILE_ERROR,
	UPDATA_FILE_INFO_ERR
}FILE_ERROR_CODE_t;

typedef enum {
	HP_ERR = 0,
	HP_90X = 1,
	HP_95X = 2,
	HP_97X = 3
}HP9_SERIES_CODE_t;

//оƬ����
enum Type
{
    HP952XLK = 0,
    HP952XLC,
    HP952XLM,
    HP952XLY,

    HP953XLK,
    HP953XLC,
    HP953XLM,
    HP953XLY,

    HP955XLK,
    HP955XLC,
    HP955XLM,
    HP955XLY,

    HP902XLK,
    HP902XLC,
    HP902XLM,
    HP902XLY,

    HP903XLK,
    HP903XLC,
    HP903XLM,
    HP903XLY,

    HP905XLK,
    HP905XLC,
    HP905XLM,
    HP905XLY,

    HP972XLK,
    HP972XLC,
    HP972XLM,
    HP972XLY,

    HP973XLK,
    HP973XLC,
    HP973XLM,
    HP973XLY,

    HP975XLK,
    HP975XLC,
    HP975XLM,
    HP975XLY,

    Reserve_01,
    Reserve_02,
    Reserve_03,
    Reserve_04,

    Reserve_05,
    Reserve_06,
    Reserve_07,
    Reserve_08,

    Reserve_09,
    Reserve_10,
    Reserve_11,
    Reserve_12,

    HP95WXLK,
    HP95WXLC,
    HP95WXLM,
    HP95WXLY,

    HP97UXLK,
    HP97UXLC,
    HP97UXLM,
    HP97UXLY,

    /*23/12/18 new add*/
    HP97UAK,
    HP97UAC,
    HP97UAM,
    HP97UAY,

    //���ϵĲ��ܸ�,95U/97P[����]���ں���,993/99W
    HP95UXLK,
    HP95UXLC,
    HP95UXLM,
    HP95UXLY,

    HP97PXLK,
    HP97PXLC,
    HP97PXLM,
    HP97PXLY,

    HP993XLK,
    HP993XLC,
    HP993XLM,
    HP993XLY,

    /*23/12/19 new add*/
    HP99WXLK,
    HP99WXLC,
    HP99WXLM,
    HP99WXLY,
		
  	HP90WXLK,
    HP90WXLC,
    HP90WXLM,
    HP90WXLY,
	
	CMD_RESERVE = 0xFFFF,
};

void set_mac(void);

void erase_file_flash(uint16 data_size, uint16 data_count);
uint8 write_file_to_flash(uint32 offset, uint8* buff, uint16 size);
uint8 read_file_from_flash(uint32 offset_address, uint8* data_buff, uint16 read_size);
uint8 handle_aes_file(uint16 handle_count);
void read_phy_factory_chip_id(uint8 *id_buff);

uint8 check_file_info(void);
uint8 updata_file_info(char *version, FILE_STATE_t *state, uint8 k, uint8 c, uint8 m, uint8 y);
uint8 get_file_info(char *version, FILE_STATE_t *state);
void get_color_address(uint8 ChipAddress, uint32 *color_address, uint16 *color_sn_count);
void test_printf_file_data(uint32 read_num);

uint8 round_read_from_buff(uint16 offset_address, uint8* source_buff, uint8* target_buff, uint16 read_size);
uint8 distinguish_type_code(uint16 type_code);
#endif
