package com.phy.ota.sdk;

import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothGatt;
import android.bluetooth.BluetoothManager;
import android.content.Context;
import android.os.Build;
import android.support.annotation.NonNull;
import android.support.annotation.Nullable;
import android.util.Log;

import com.phy.ota.sdk.beans.OTAType;
import com.phy.ota.sdk.ble.BleCallBack;
import com.phy.ota.sdk.ble.BleScanner;
import com.phy.ota.sdk.ble.OTACallBack;
import com.phy.ota.sdk.ble.OTAUtilsCallBack;
import com.phy.ota.sdk.util.BleUtils;
import com.phy.ota.sdk.beans.ErrorCode;
import com.phy.ota.sdk.beans.FirmWareFile;
import com.phy.ota.sdk.util.HexString;


/**
 * BleUtils
 *
 * @date:2018/7/13
 */

public class OTAUtils {

    private Context mContext;
    private BleScanner mBleScanner;
    private BluetoothGatt mBluetoothGatt;
    private BleCallBack mBleCallBack;
    private boolean isConnected;

    private OTACallBack callBack;

    /**
     * 创建OTAUtils实例
     * @param context
     * @param callBack
     */
    public OTAUtils(Context context,OTACallBack callBack) {
        this.mContext = context;
        this.callBack = callBack;

        init();
    }

    private void init(){
        OTAUtilsCallBack otaUtilsCallBack = new OTAUtilsCallBackImpl();
        mBleScanner = new BleScanner(mContext,otaUtilsCallBack);

        mBleCallBack = new BleCallBack();
        mBleCallBack.setOtaUtilsCallBack(otaUtilsCallBack);
    }

    public void connectDevice(@NonNull String address){

        if(isConnected){
            callBack.onConnected(isConnected);
            return;
        }

        BluetoothManager mBluetoothManager = (BluetoothManager) mContext.getApplicationContext().getSystemService(Context.BLUETOOTH_SERVICE);
        BluetoothDevice device = mBluetoothManager.getAdapter().getRemoteDevice(address);

        mBluetoothGatt = device.connectGatt(mContext.getApplicationContext(),false,mBleCallBack);
    }

    public void starScan(){
        mBleScanner.scanDevice();
    }

    public void stopScan(){
        mBleScanner.stopScanDevice();
    }

    public void startOTA(){

        if(isConnected){
            if(BleUtils.checkIsOTA(mBluetoothGatt)){
                callBack.onOTA(true);
            }else{
                boolean success = sendCommand(mBluetoothGatt,"0102",false);
                if(success){
                    callBack.onOTA(false);
                }
            }
        }else{
            callBack.onError(ErrorCode.DEVICE_NOT_CONNECT);
        }
    }

    public void startResource(){

        if(isConnected){
            if(BleUtils.checkIsOTA(mBluetoothGatt)){
                callBack.onResource(true);
            }else{
                boolean success = sendCommand(mBluetoothGatt,"0103",false);
                if(success){
                    callBack.onResource(false);
                }
            }
        }else{
            callBack.onError(ErrorCode.DEVICE_NOT_CONNECT);
        }
    }

    public void reBoot(){
        if(isConnected){
            if(BleUtils.checkIsOTA(mBluetoothGatt)){
                boolean success = sendCommand(mBluetoothGatt,"04",false);
                if(success){
                    callBack.onReboot();
                }
            }else{
                callBack.onError(ErrorCode.DEVICE_NOT_IN_OTA);
            }
        }else{
            callBack.onError(ErrorCode.DEVICE_NOT_CONNECT);
        }
    }

    public void updateFirmware(@Nullable String filePath){
        //检查设备是否已连接
        if(isConnected){
            //检查设备是否已经在OTA状态
            if(BleUtils.checkIsOTA(mBluetoothGatt)){

                FirmWareFile firmWareFile = new FirmWareFile(filePath);
                if(firmWareFile.getCode() != 200){
                    callBack.onError(ErrorCode.FILE_ERROR);
                    return;
                }

                mBleCallBack.setFirmWareFile(firmWareFile,OTAType.OTA);

                sendCommand(mBluetoothGatt,"01"+ HexString.int2ByteString(firmWareFile.getList().size())+"00",true);

            }else{
                callBack.onError(ErrorCode.DEVICE_NOT_IN_OTA);
            }
        }else{
            callBack.onError(ErrorCode.DEVICE_NOT_CONNECT);
        }
    }

    public void updateResource(@NonNull String filePath){
        //检查设备是否已连接
        if(isConnected){
            //检查设备是否已经在Resource状态
            if(BleUtils.checkIsOTA(mBluetoothGatt)){

                FirmWareFile firmWareFile = new FirmWareFile(filePath);
                if(firmWareFile.getCode() != 200){
                    callBack.onError(ErrorCode.FILE_ERROR);
                    return;
                }

                mBleCallBack.setFirmWareFile(firmWareFile,OTAType.RESOURCE);

                String command = "01"+ HexString.int2ByteString(firmWareFile.getList().size())+ "00";

                sendCommand(mBluetoothGatt,command,true);

            }else{
                callBack.onError(ErrorCode.DEVICE_NOT_IN_OTA);
            }
        }else{
            callBack.onError(ErrorCode.DEVICE_NOT_CONNECT);
        }
    }

    /**
     * 取消OTA升级后，会和设备自动断开连接
     */
    public void cancleOTA(){
        if(checkOTA()){
            mBleCallBack.setCancle();
            mBluetoothGatt.disconnect();
        }
    }

    public boolean checkOTA(){
        if(isConnected){
            return BleUtils.checkIsOTA(mBluetoothGatt);
        }else {
            return false;
        }
    }

    /**
     * 设置OTA数据发送失败重试次数
     * @param times
     */
    public void setRetryTimes(int times){
        mBleCallBack.setRetryTimes(times);
    }

    private boolean sendCommand(BluetoothGatt bluetoothGatt, String commd,boolean respons){
        boolean success = BleUtils.sendOTACommand(bluetoothGatt,commd,respons);
        if(!success){
            callBack.onError(ErrorCode.OTA_SERVICE_NOT_FOUND);
        }

        return success;
    }

    private class OTAUtilsCallBackImpl implements OTAUtilsCallBack{

        @Override
        public void onDeviceSearch(BluetoothDevice device, int rssi, byte[] scanRecord) {
            callBack.onDeviceSearch(device,rssi,scanRecord);
        }

        @Override
        public void onConnectChange(boolean connect) {
            isConnected = connect;

            callBack.onConnected(connect);
        }

        @Override
        public void onProcess(float process) {
            callBack.onProcess(process);
        }

        @Override
        public void onError(int code) {

            callBack.onError(code);
        }

        @Override
        public void onOTAFinish() {

            callBack.onOTAFinish();
        }

        @Override
        public void onResourceFinish() {
            callBack.onResourceFinish();
        }
    }
}
