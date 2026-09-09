package com.phy.ota.sdk;

import android.bluetooth.BluetoothDevice;
import android.content.Context;
import android.os.Build;
import android.support.annotation.NonNull;
import android.support.annotation.Nullable;
import android.util.Log;

import com.phy.ota.sdk.beans.ErrorCode;
import com.phy.ota.sdk.beans.OTAType;
import com.phy.ota.sdk.ble.OTACallBack;
import com.phy.ota.sdk.OTAUtils;
import com.phy.ota.sdk.firware.UpdateFirewareCallBack;
import com.phy.ota.sdk.util.BleUtils;

/**
 * OTASDKUtils
 *
 * @date:2018/7/13
 */

public class OTASDKUtils {

    private int STATUS = 0;
    private int START_OTA = 1;
    private int OTA_CONNECTING = 2;
    private int OTA_ING = 3;
    private int REBOOT = 4;
    private int START_RES = 5;
    private int RES_ING = 6;

    private OTACallBack otaCallBack;
    private OTAUtils otaUtils;
    private UpdateFirewareCallBack firewareCallBack;
    private String address;
    private String filePath;
    private OTAType otaType;

    public static final String VERSION = "1.0.7";

    /**
     * 创建OTASDKUtils方法
     * @param context
     * @param firewareCallBack
     */
    public OTASDKUtils(Context context,UpdateFirewareCallBack firewareCallBack) {
        this.firewareCallBack = firewareCallBack;

        otaCallBack = new OTACallBackImpl();
        otaUtils = new OTAUtils(context,otaCallBack);
    }

    public void updateFirware(@Nullable String address,@Nullable String filePath){
        this.address = address;
        this.filePath = filePath;
        this.otaType = OTAType.OTA;

        STATUS = 0;

        otaUtils.connectDevice(address);
    }

    public void updateResource(@NonNull String address, @NonNull String filePath){
        this.address = address;
        this.filePath = filePath;
        this.otaType = OTAType.RESOURCE;

        STATUS = 0;

        otaUtils.connectDevice(address);
    }

    public void setRetryTimes(int times){
        if(otaUtils != null){
            otaUtils.setRetryTimes(times);
        }
    }

    private void error(int code){
        STATUS = 0;
        firewareCallBack.onError(code);
    }

    private void success(){
        STATUS = 0;
        firewareCallBack.onUpdateComplete();
    }

    private class OTACallBackImpl implements OTACallBack{
        @Override
        public void onConnected(boolean isConnected) {
            if(isConnected){
                if(STATUS == 0){
                    if(otaType == OTAType.OTA){
                        otaUtils.startOTA();
                        STATUS = START_OTA;
                    }else if(otaType == OTAType.RESOURCE){
                        otaUtils.startResource();
                        STATUS = START_RES;
                    }

                }else if(STATUS == OTA_CONNECTING){
                    if(otaType == OTAType.OTA){
                        otaUtils.updateFirmware(filePath);
                        STATUS = OTA_ING;
                    }else if(otaType == OTAType.RESOURCE){
                        otaUtils.updateResource(filePath);
                        STATUS = RES_ING;
                    }

                }else{
                    Log.d("STATUS","error:"+STATUS);
                }
            }else{
                if(STATUS == START_OTA || STATUS == START_RES){
                    otaUtils.starScan();
                }else if(STATUS == OTA_CONNECTING){
                    error(ErrorCode.OTA_CONNTEC_ERROR);
                }else if(STATUS == REBOOT){
                    success();
                }else if(STATUS == OTA_ING || STATUS == RES_ING){
                    error(ErrorCode.OTA_CONNTEC_ERROR);
                }else{
                    error(ErrorCode.CONNECT_ERROR);
                }
            }
        }

        @Override
        public void onOTA(boolean isConnected) {
            if(isConnected){
                otaUtils.updateFirmware(filePath);
                STATUS = OTA_ING;
            }
        }

        @Override
        public void onDeviceSearch(BluetoothDevice device, int rssi, byte[] scanRecord) {
            if((STATUS == START_OTA || STATUS == START_RES) && device.getAddress().equals(BleUtils.getOTAMac(address))){
                otaUtils.stopScan();
                otaUtils.connectDevice(device.getAddress());

                STATUS = OTA_CONNECTING;
            }
        }

        @Override
        public void onProcess(float process) {
            firewareCallBack.onProcess(process);
        }

        @Override
        public void onError(int code) {
            Log.d("onError","error:"+code);
            error(code);
        }

        @Override
        public void onOTAFinish() {
            STATUS = REBOOT;
            otaUtils.reBoot();
        }

        @Override
        public void onResource(boolean isConnected) {
            if(isConnected){
                otaUtils.updateResource(filePath);
                STATUS = RES_ING;
            }
        }

        @Override
        public void onResourceFinish() {
            STATUS = REBOOT;
            otaUtils.reBoot();
        }

        @Override
        public void onReboot() {

        }
    }

}
