package com.phy.app.app;

import android.bluetooth.BluetoothDevice;

import com.phy.app.beans.BleEvent;
import com.phy.app.beans.Connect;
import com.phy.app.beans.Device;
import com.phy.app.beans.UpdateFirmwareEvent;
import com.phy.app.ble.BandBleCallBack;

import org.greenrobot.eventbus.EventBus;

/**
 * BandBleCallBackImpl
 *
 * @author:zhoululu
 * @date:2018/4/14
 */

public class BandBleCallBackImpl implements BandBleCallBack{

    private static BandBleCallBackImpl bandBleCallBack;

    private BandBleCallBackImpl(){}

    public static BandBleCallBackImpl getBandBleCallBack(){
        if(bandBleCallBack == null){
            bandBleCallBack = new BandBleCallBackImpl();
        }

        return bandBleCallBack;
    }

    @Override
    public void onScanDevice(BluetoothDevice device, int rssi, byte[] scanRecord) {

        Device device1 = new Device(device,rssi,1);
        EventBus.getDefault().post(device1);

    }

    @Override
    public void onConnectDevice(boolean connect) {
        EventBus.getDefault().post(new Connect(connect));

        PHYApplication.getApplication().setConnect(connect);
    }

    @Override
    public void onResponse(String operate, Object object) {
        EventBus.getDefault().post(new BleEvent(operate,object));
    }

}
