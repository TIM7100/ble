# 固件 OTA(task9) 本地版本对比 + 下载决策 —— 实现方案

## Context（背景）
- task8（HP9数据升级）已有完整的“本地版本 + 云端版本对比决定是否下载”机制：
  - 固件侧：`file_handle.c`（`BLEUpgrader/source/file_handle.c`）把版本号存 flash `0x11040000`，`get_file_info()` 读本地版本。
  - `components/profiles/ota_app/ota_app_service.c` 的 `OTA_APP_CMD_VERSION` 收到 App 下发的云端版本后，用 `get_file_info()` 对比，不一致回 `RP_HP9_BURN_FILE_UPDATA`，一致回 `RP_HP9_BURN_FILE_NEWEST`。
  - App 侧（test3）：`where(false)` 读云端 `ble` 集合版本 → 与本地 cached 版本比 → `createDownload()`。
- task9（固件OTA升级）**当前无**本地版本对比：`固件OTA升级` 无条件下载 IAP 云端固件 → 进入 OTA bootloader 烧录。
- 目标：让 task9 也具备“上报本地版本、与云端 IAP 版本对比、不同才下载”机制。
- 下位机核心函数按要求新建在 `E:\ble\SLB\HP9_90X\components\OTAEVENT\OTAfile_handle.c` 与 `.h`（镜像 task8 的 file_handle.c）。

## 约定（假设，可调整）
- 版本格式：沿用 task8 的 **10 字节字符串**（`VERSION_LEN=10`），可无缝复用对比逻辑。
- OTA 本地版本存储：flash 新建独立版本信息区 `0x11041000`（0x11040000 之后、OTA 交换区 0x11055000 之前，假定空闲，交由用户最终确认）。
- App 触发时机：点击“固件OTA升级”→ 先读云端 IAP 版本并发送给固件对比 → 相同则提示“已是最新版本”、不下载；不同才下载并 OTA。

---

## 一、固件侧（HP9_90X）

### 1. 新建 `components/OTAEVENT/OTAfile_handle.h`
镜像 `file_handle.h`，定义 OTA 专用的版本信息结构/常量/API：
```c
#ifndef _OTA_FILE_HANDLE_H
#define _OTA_FILE_HANDLE_H
#include "types.h"

#define OTA_VERSION_LEN        10
#define OTA_VERSION_INFO_ADDR  0x11041000   // OTA固件版本信息flash地址(需确认空闲)

typedef enum {
    OTA_FILE_DOWNLOADED = 0,
    OTA_FILE_DOWNLOADING,
    OTA_FILE_DOWNLOAD_ERR,
    OTA_FILE_AES_ING
} OTA_FILE_STATE_t;

typedef struct {
    OTA_FILE_STATE_t state;
    uint8 version[OTA_VERSION_LEN];
    uint32 start_addr;
    uint32 end_addr;
} OTA_FileInfo_t;

void  ota_check_version_info(void);                    // 读flash，无效则初始化
uint8 ota_get_local_version(char *version);            // 读本地版本(镜像 get_file_info)
uint8 ota_set_local_version(char *version, OTA_FILE_STATE_t *state); // 写版本+状态(镜像 updata_file_info)
#endif
```

### 2. 新建 `components/OTAEVENT/OTAfile_handle.c`
镜像 `file_handle.c` 实现：
- `ota_check_version_info()`：用 `hal_flash_read(OTA_VERSION_INFO_ADDR, &info, sizeof(info))` 读，若 state 无效或 version[0]==0xFF / start_addr 不符 → 初始化 `version="0000000000"`、state=ERR。
- `ota_get_local_version(char *version)`：读 flash 填充 version，返回成败。
- `ota_set_local_version(char *version, OTA_FILE_STATE_t *state)`：`hal_flash_erase_sector(OTA_VERSION_INFO_ADDR)` + `hal_flash_write(...)` 保存。
- 复用 `file_handle.h` 的 `VERSION_LEN` 逻辑（此处用本文件的 `OTA_VERSION_LEN`）。

### 3. 在现有 app OTA 服务中新增“版本对比”命令处理
- 在 `components/profiles/ota_app/ota_app_service.c` 的 `process_cmd()` 中，镜像现有 `OTA_APP_CMD_VERSION`（约 L245），新增处理分支：
  - App 下发的云端 OTA 版本 → `ota_get_local_version(current)`（来自 OTAfile_handle）→ `strncmp` 对比 → 相同回复 `RP_HP9_BURN_FILE_NEWEST`，不同回复 `RP_HP9_BURN_FILE_UPDATA`。
- 需要新增命令枚举值（如 `OTA_APP_CMD_OTA_VERSION`），并在 `ota_app_service.h` 声明；保持与 task8 命令字节编号不冲突。
- 编译：需把 `OTAfile_handle.c` 加入应用工程（参考 `file_handle.c` 的包含方式，main/构建脚本）。

---

## 二、App 侧（test3）

主要在 `e:\ble\SLB\test3\pages\index\index.vue`：

### 1. 查询/对比逻辑（固件OTA升级路径）
- 在 `where()` 的 `fw_ota_mode`（固件OTA）分支（现约 L419-536），**先不要无条件下载**：
  1. 已读取云端 IAP：`fw_ota_version`（云端版本）、`fw_ota_url`。
  2. **新增**：向固件 app OTA 服务发送“云端版本 → 对比”命令（复用连接的命令特征值 + 通知回调解析），取得 `UPDATA`/`NEWEST`。
     - 通过 `uni.writeBLECharacteristicValue` 发送云端版本命令，在 `onBLECharacteristicValueChange` 里解析回复。
  3. 若 `NEWEST`：`toast('已是最新版本')`，置 `fw_ota_mode=false`、`lockInterface=false`，返回（不下载、不 OTA）。
  4. 若 `UPDATA`（或超时/异常按需更新）：继续执行现有“云下载 → 触发OTA → 重连 → TxUpdate_Firmware”流程。

### 2. 触发 OTA 前的本地缓存版本更新
- OTA 成功后，把 `fw_ota_version` 存入本地缓存（`uni.setStorage`，镜像 task8 的做法），作为下次对比的基线（可选，若完全依赖固件返回值则忽略）。

### 3. 通知解析
- 在 `uni.onBLECharacteristicValueChange` 回调（约 L1167）里，除现有处理外，识别固件返回的 `RP_HP9_BURN_FILE_NEWEST`/`RP_HP9_BURN_FILE_UPDATA`（在 `fw_ota_mode` 下同样需要解析），填充一个标志供 `where()` 使用。

---

## 三、验证
1. 编译固件工程（确认 `OTAfile_handle.c` 被编译、`OTA_VERSION_INFO_ADDR` 不与其他区域冲突）。
2. 手机连接设备（正常运行模式）：
   - 云端 IAP 版本 ≠ 固件本地 OTA 版本 → 点“固件OTA升级”应正常走“下载→OTA”。
   - 云端 IAP 版本 == 固件本地 OTA 版本 → 应提示“已是最新版本”，不进入下载/OTA。
3. 用 test3 控制台日志确认：发送了版本对比命令、收到 NEWEST/UPDATA、并根据结果决定是否 `createDownload`/`TxUpdate_Firmware`。
4. 若本地版本未初始化，确认 `ota_check_version_info` 初始化为 `0000000000`（触发一次下载/升级）。

## 待确认项
- `OTA_VERSION_INFO_ADDR=0x11041000` 是否空闲无冲突（需用户根据实际 flash 布局确认/调整）。
- 版本对比命令的具体字节编号复用或新增，确保与固件、App 两侧一致。