/**************************************************************************************************
    OTA 固件本地版本管理
    镜像 file_handle.c 的结构，用于 task9(固件OTA升级) 的本地版本存储/读取/对比。
    版本信息独立存放在 OTA_VERSION_INFO_ADDR，不占用 task8 的 SAVE_FILE_INFO_ADDRESS。
**************************************************************************************************/
#ifndef _OTA_FILE_HANDLE_H
#define _OTA_FILE_HANDLE_H

#include "types.h"

#define OTA_VERSION_LEN         10      // 版本字符串长度(与 file_handle 的 VERSION_LEN 一致)
#define OTA_VERSION_INFO_ADDR   0x11041000  // 当前固件版本信息flash地址(0x11040000之后、OTAE交换区之前，已确认空闲)
#define OTA_VERSION_PEND_ADDR   0x11042000  // 待定(待提升)固件版本flash地址：App在OTA前写入，boot成功后复制到当前版本

typedef enum
{
    OTA_FILE_DOWNLOADED = 0,    // 文件下载完成
    OTA_FILE_DOWNLOADING,       // 文件下载中
    OTA_FILE_DOWNLOAD_ERR,      // 文件下载错误
    OTA_FILE_AES_ING            // 文件解密中
} OTA_FILE_STATE_t;

typedef enum
{
    OTA_FILE_SUCCESS = 0,
    OTA_FILE_ERR,
    OTA_GET_VERSION_ERR,
    OTA_SAVE_VERSION_ERR
} OTA_FILE_ERROR_CODE_t;

typedef struct
{
    uint8 state;                    // OTA_FILE_STATE_t
    char  version[OTA_VERSION_LEN]; // 本地OTA固件版本字符串
    uint32 start_addr;              // 保留：版本区起始地址
    uint32 end_addr;                // 保留：版本区结束地址
} OTA_FileInfo_t;

// 读flash中版本信息，无效则初始化为 "0000000000" + ERR 状态
void  ota_check_version_info(void);
// 读取本地OTA版本到 version(长度OTA_VERSION_LEN)，返回 OTA_FILE_ERROR_CODE_t
uint8 ota_get_local_version(char *version);
// 写本地OTA版本+状态到flash，返回 OTA_FILE_ERROR_CODE_t
uint8 ota_set_local_version(const char *version, uint8 state);

#endif /* _OTA_FILE_HANDLE_H */