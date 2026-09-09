package com.phy.ota.sdk;

import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothGatt;
import android.bluetooth.BluetoothManager;
import android.content.Context;
import android.content.SharedPreferences;
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

import static android.content.Context.MODE_PRIVATE;


/**
 * BleUtils
 *
 * @date:2018/7/13
 */

public class OTAUtils {
    public static int MTU_SIZE = 23;

    private Context mContext;
    private BleScanner mBleScanner;
    private BluetoothGatt mBluetoothGatt;
    private BleCallBack mBleCallBack;
    private boolean isConnected;
    private boolean isQuick;

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

        SharedPreferences sp = mContext.getSharedPreferences("data",MODE_PRIVATE);
        String keyValue = sp.getString("AESKey","123");
        mBleCallBack.password = keyValue;
    }

    public void connectDevice(@NonNull String address){

        if(isConnected){
            Log.e("TAG", "connectDevice: 已经连上" );
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

    public void disConnectDevice(){
        if(isConnected && mBluetoothGatt != null){
            mBluetoothGatt.disconnect();
        }
    }

    public void close(){
        if(mBluetoothGatt != null){
            mBluetoothGatt.close();
        }
    }

    public void stopScan(){
        mBleScanner.stopScanDevice();
    }

    public void startOTA(){

        if(isConnected){
            if(BleUtils.checkIsOTA(mBluetoothGatt)){
                callBack.onOTA(true);
            }else{

                String command = "0102";
                boolean isResponse = false;
                if(isQuick){
                    command = "010201";
                    isResponse = true;
                }
                boolean success = sendCommand(mBluetoothGatt,command,isResponse);

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
                String command = "0103";
                boolean isResponse = false;
                if(isQuick){
                    command = "010301";
                    isResponse = true;
                }
                boolean success = sendCommand(mBluetoothGatt,command,isResponse);
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
                String command = "04";
                boolean isResponse = false;
                if(isQuick){
                    command = "0401";
                    isResponse = true;
                }
                boolean success = sendCommand(mBluetoothGatt,command,isResponse);
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

    public void updateFirmware(@NonNull String filePath,boolean isQuick,OTAType otaType){
        this.isQuick = isQuick;

        //检查设备是否已连接
        if(isConnected){
            //检查设备是否已经在OTA状态
            if(BleUtils.checkIsOTA(mBluetoothGatt)){

                FirmWareFile firmWareFile = new FirmWareFile(filePath,isQuick);
                if(firmWareFile.getCode() != 200){
                    callBack.onError(ErrorCode.FILE_ERROR);
                    return;
                }

                mBleCallBack.setFirmWareFile(firmWareFile,otaType);

                String command = "01"+ HexString.int2ByteString(firmWareFile.getList().size());
//                if(isQuick){
//                    command = command + "ff";
//                }else{
                    command = command + "00";
//                }
                sendCommand(mBluetoothGatt,command,true);

            }else{
                callBack.onError(ErrorCode.DEVICE_NOT_IN_OTA);
            }
        }else{
            callBack.onError(ErrorCode.DEVICE_NOT_CONNECT);
        }
    }

    public void updateFirmware(@NonNull String filePath,boolean isQuick){
        updateFirmware(filePath,isQuick,OTAType.OTA);
    }

    public void updateResource(@NonNull String filePath,boolean isQuick){
        this.isQuick = isQuick;

        //检查设备是否已连接
        if(isConnected){
            //检查设备是否已经在Resource状态
            if(BleUtils.checkIsOTA(mBluetoothGatt)){

                FirmWareFile firmWareFile = new FirmWareFile(filePath,isQuick);
                if(firmWareFile.getCode() != 200){
                    callBack.onError(ErrorCode.FILE_ERROR);
                    return;
                }

                mBleCallBack.setFirmWareFile(firmWareFile,OTAType.RESOURCE);

                String command = "01"+ HexString.int2ByteString(firmWareFile.getList().size());
//                if(isQuick){
//                    command = command + "ff";
//                }else{
                    command = command + "00";
//                }

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

    public boolean setPHY(){

        if(Build.VERSION.SDK_INT >= Build.VERSION_CODES.O){
            if(mBluetoothGatt != null){
                mBluetoothGatt.setPreferredPhy(BluetoothDevice.PHY_LE_2M,BluetoothDevice.PHY_LE_2M,BluetoothDevice.PHY_OPTION_NO_PREFERRED);
            }
        }else{
            return false;
        }

        return true;
    }

    private boolean sendCommand(BluetoothGatt bluetoothGatt, String commd,boolean respons){
        boolean success = BleUtils.sendOTACommand(bluetoothGatt,commd,respons);
        if(!success){
            callBack.onError(ErrorCode.OTA_SERVICE_NOT_FOUND);
        }

        return success;
    }

    public void startSecurity() {
        mBleCallBack.startSecurity(mBluetoothGatt);
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
            Log.e("TAG", "onError: ========="+code );
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

        @Override
        public void onReBootSuccess() {
            callBack.onRebootSuccess();
        }

        @Override
        public void onPhyUpdate(BluetoothGatt gatt, int txPhy, int rxPhy, int status) {
            callBack.onPhyUpdate();
        }

        @Override
        public void onStartSecurityData() {
            callBack.onStartSecurityData();
        }
    }
}
