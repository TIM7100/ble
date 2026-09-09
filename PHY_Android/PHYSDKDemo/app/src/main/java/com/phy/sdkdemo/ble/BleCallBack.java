package com.phy.sdkdemo.ble;

import android.bluetooth.BluetoothDevice;

/**
 * BleCallBack
 *
 * @author:zhoululu
 * @date:2018/7/3
 */

public interface BleCallBack {

    public void onScanDevice(BluetoothDevice device, int rssi, byte[] scanRecord);
    public void onConnectDevice(boolean connect);

}
