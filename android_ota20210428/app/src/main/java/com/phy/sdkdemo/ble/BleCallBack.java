package com.phy.sdkdemo.ble;

import android.bluetooth.BluetoothDevice;

/**
 * BleCallBack
 *
 * @author:zhoululu
 * @date:2018/7/3
 */

public interface BleCallBack {

    /**
     * 扫描设备
     * @param device 蓝牙设备
     * @param rssi 信号强度
     * @param scanRecord 扫描记录
     */
    public void onScanDevice(BluetoothDevice device, int rssi, byte[] scanRecord);

    /**
     * 连接设备
     * @param connect 连接结果 true or false
     */
    public void onConnectDevice(boolean connect);

}
