# test3 自动升级链路（每次连接自动 固件OTA→HP9数据，删除按钮，OTA后提示手动重连）

## Context（背景）
- 现在 test3 连接后，固件 OTA 与 HP9 数据升级需两个按钮手动触发（`startUpgrade(false/true)`，都在 `where()` 按 `fw_ota_mode` 分支区分）。
- 用户要求：连接成功后**自动先做固件OTA、再做HP9数据升级**，删除两个按钮。
- 反馈澄清：
  1. OTA 升级后会重启断开，**不做自动重连**，只提示"固件升级完成，请重新连接"。
  2. 用户重连后，**仍走和直接连接完全一样的流程**（再次检测固件OTA版本 → 因已升级为最新 → 跳过 → 再做HP9数据升级）。

## 核心思路（无跨连接状态）
- 因为固件/HP9 流程都是**版本门控**（本地≠云端才动作），天然幂等：
  - 每次真正的"连接成功"都调用同一个 `autoCheckAndUpgrade()`。
  - 固件需升级 → OTA（重启）→ 提示手动重连 → 会话结束。
  - 固件已最新 → 直接继续 HP9 数据升级（同会话）。
  - 重连后同样进 `autoCheckAndUpgrade()`，此时固件已最新 → 跳过OTAT → 直接做HP9。
- 用一个 `auto_chain` 标志让 `where()` 在"固件已最新"时自动接续 HP9 分支。

## 实现

### 1. 新增 data
- `auto_chain: false`

### 2. 连接成功触发（`getBLEDeviceCharacteristics` success，现约 L1058 `getFwVersions()` 后）
```js
setTimeout(()=>{ this.autoCheckAndUpgrade(); }, 800);
```

### 3. 新增方法
```js
autoCheckAndUpgrade(){
  this.auto_chain = true;
  this.fw_ota_mode = true;      // 先固件OTA
  this.where();                  // where()内按 auto_chain 接续
}
```

### 4. 改 `where()` 固件OTA分支的"已最新"处（现 compareOtaVersion → Newest → toast+return）
- 当前：Newest → `toast('已是最新版本，无需升级'); fw_ota_mode=false; lockInterface=false; return;`
- 改为：Newest 时若 `auto_chain` → `fw_ota_mode=false; this.where();`（自动接续HP9分支）；否则维持原提示。

### 5. HP9数据升级分支
- 复用现有 HP9 分支（查询ble→对比→下载→TxUpdate）。
- 在 HP9 分支结束（正常完成或"已最新"）后：`this.auto_chain = false;`
- （若固件需 OTA 已重启，不会走到这里；重连后会重新以 auto_chain=true 进入。）

### 6. 删除按钮
- 模板 `L46-L53` 的 `mode-select` 两块按钮整块删除。
- `startUpgrade()` 若不再被引用可一并删除并清理。

### 7. 固件OTA完成提示（`TxUpdate_Firmware` 成功分支）
- 发送 REBOOT 后：`that.toast('固件升级完成，请重新连接');`（提示用户手动重连，不自动重连）。

## 复用的现有函数（不改逻辑）
- `where()`（L404）、`compareOtaVersion()`、`createDownload()`、`TxUpdate()`、`TxUpdate_Firmware()`
- 连接链路 `getBLEDeviceCharacteristics`(L1017) success
- `TxUpdate_Firmware` 成功处加 toast

## 关键注意
- 仅是"固件已最新"时用 `auto_chain` 接管跳转到 HP9；不新增自动重连。
- OTA 会重启，故"固件需升级"时本次会话不会做 HP9，等用户重连后再走同一流程（此时固件最新→直接HP9）。
- `auto_chain` 每次连接都置 true，配合版本门控保证幂等、不重复下载。

## 验证
1. 连接→自动固件OTA检测；需升级→自动下载+OTA→设备重启→提示"固件升级完成，请重新连接"。
2. 固件已最新→连接→直接自动做HP9数据升级。
3. OTA后用户手动重连→走同一流程→固件已最新→自动做HP9数据升级。
4. 两个按钮消失；日志可见 auto_chain 流程。