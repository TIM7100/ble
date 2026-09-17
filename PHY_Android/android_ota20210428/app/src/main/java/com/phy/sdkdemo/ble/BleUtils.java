package com.phy.sdkdemo.ble;

import java.nio.ByteBuffer;
import java.nio.ByteOrder;

/**
 * BleUtils
 *
 * @author:zhoululu
 * @date:2018/7/7
 */

public class BleUtils {

    /**
     * 获取OTA MAC地址
     * @param deviceAddress
     * @return
     */
    public static String getOTAMac(String deviceAddress){
        final String firstBytes = deviceAddress.substring(0, 15);
        final String lastByte = deviceAddress.substring(15); // assuming that the device address is correct
        final String lastByteIncremented = String.format("%02X", (Integer.valueOf(lastByte, 16) + 1) & 0xFF);

        return firstBytes + lastByteIncremented;
    }

    // return name String(successful) or null(failed)
    public static String parseDeviceName(byte[] scanRecord) {
        String ret = null;
        if (null == scanRecord) {
            return ret;
        }

        //ByteBuffer手动封装byte数组
        ByteBuffer buffer = ByteBuffer.wrap(scanRecord).order(ByteOrder.LITTLE_ENDIAN);
        while (buffer.remaining() > 2) {
            byte length = buffer.get();
            if (length == 0) {
                break;
            }

            byte type = buffer.get();
            length -= 1;
            switch (type) {
                case 0x01: // Flags
                    buffer.get(); // flags
                    length--;
                    break;
                case 0x02: // Partial list of 16-bit UUIDs
                case 0x03: // Complete list of 16-bit UUIDs
                case 0x14: // List of 16-bit Service Solicitation UUIDs
                    while (length >= 2) {
                        buffer.getShort();
                        length -= 2;
                    }
                    break;
                case 0x04: // Partial list of 32 bit service UUIDs
                case 0x05: // Complete list of 32 bit service UUIDs
                    while (length >= 4) {
                        buffer.getInt();
                        length -= 4;
                    }
                    break;
                case 0x06: // Partial list of 128-bit UUIDs
                case 0x07: // Complete list of 128-bit UUIDs
                case 0x15: // List of 128-bit Service Solicitation UUIDs
                    while (length >= 16) {
                        long lsb = buffer.getLong();
                        long msb = buffer.getLong();
                        length -= 16;
                    }
                    break;
                case 0x08: // Short local device name
                case 0x09: // Complete local device name
                    byte sb[] = new byte[length];
                    buffer.get(sb, 0, length);
                    length = 0;
                    ret = new String(sb).trim();
                    return ret;
                case (byte) 0xFF: // Manufacturer Specific Data
                    buffer.getShort();
                    length -= 2;
                    break;
                default: // skip
                    break;
            }
            if (length > 0) {
                if (buffer.position() + length > buffer.limit()){
                    return "越界";
                }
                buffer.position(buffer.position() + length);
            }
        }
        return ret;
    }
}
