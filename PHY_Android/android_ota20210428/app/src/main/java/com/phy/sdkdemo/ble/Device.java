package com.phy.sdkdemo.ble;

import android.bluetooth.BluetoothDevice;

/**
 * Device
 *
 * @author:zhoululu
 * @date:2018/4/13
 */

public class Device {

    private BluetoothDevice device;
    private int rssi;
    private int broadcastType;
    private String realName;

    public Device(BluetoothDevice device, int rssi, int broadcastType,String realName){
        this.device = device;
        this.rssi = rssi;
        this.broadcastType = broadcastType;
        this.realName = realName;
    }

    public BluetoothDevice getDevice() {
        return device;
    }

    public int getRssi() {
        return rssi;
    }

    public int getBroadcastType() {
        return broadcastType;
    }

    public String getRealName(){
        return realName;
    }

    @Override
    public boolean equals(Object o) {
        if (o instanceof Device) {
            final Device that = (Device) o;
            return device.getAddress().equals(that.device.getAddress());
        }
        return super.equals(o);
    }

}
