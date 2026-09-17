/**************************************************************************************************
    OTA 固件本地版本管理 —— 实现
    镜像 file_handle.c：把 OTA 固件本地版本/状态存到 flash OTA_VERSION_INFO_ADDR，
    供 task9(固件OTA升级) 上报对比云端版本、决定是否下载。
**************************************************************************************************/
#include "OSAL.h"
#include "log.h"
#include "flash.h"
#include "stdint.h"
#include "string.h"
#include "OTAfile_handle.h"

//当前固件版本 修改else中的版本


// 读取当前版本槽(0x11041000)为纯10字节版本串；未初始化统一返回  当前出厂设置版本
uint8 ota_get_local_version(char *version)
{
    if (version != NULL)
    {
        uint8 v[OTA_VERSION_LEN] = {0};
        if (hal_flash_read(OTA_VERSION_INFO_ADDR, v, OTA_VERSION_LEN) == 0 && v[0] != 0xFF)
        {
            memcpy(version, v, OTA_VERSION_LEN);
        }
        else
        {
            memset(version, 0, OTA_VERSION_LEN);
            memcpy(version, "2609100919", OTA_VERSION_LEN);
        }
        return OTA_FILE_SUCCESS;
    }
    return OTA_GET_VERSION_ERR;
}

void ota_check_version_info(void)
{
    // 当前版本槽用纯10字节串，若为擦除态无需处理(读取时统一按0000000000处理)
}

uint8 ota_set_local_version(const char *version, uint8 state)
{
    if (version == NULL)
    {
        return OTA_SAVE_VERSION_ERR;
    }

    // 写入"待定版本"地址(0x11042000)，由boot在OTA成功后将其提升为当前版本(0x11041000)。
    // Ota失败时不会误改当前版本,但是OTA过程中断了会把程序弄跑飞
    uint8 v[OTA_VERSION_LEN] = {0};
    memcpy(v, version, OTA_VERSION_LEN);

    hal_flash_erase_sector(OTA_VERSION_PEND_ADDR);
    if (hal_flash_write(OTA_VERSION_PEND_ADDR, v, OTA_VERSION_LEN) != 0)
    {
        return OTA_SAVE_VERSION_ERR;
    }

    LOG("OTA pending version saved: %.10s, st:%d\n", v, state);
    return OTA_FILE_SUCCESS;
}