package com.phy.sdkdemo.ble;

/**
 * BleUtils
 *
 * @author:zhoululu
 * @date:2018/7/7
 */

public class BleUtils {

    public static String getOTAMac(String deviceAddress){
        final String firstBytes = deviceAddress.substring(0, 15);
        final String lastByte = deviceAddress.substring(15); // assuming that the device address is correct
        final String lastByteIncremented = String.format("%02X", (Integer.valueOf(lastByte, 16) + 1) & 0xFF);

        return firstBytes + lastByteIncremented;
    }
}
