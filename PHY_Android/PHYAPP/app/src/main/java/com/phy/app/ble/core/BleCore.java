package com.phy.app.ble.core;

import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothGatt;
import android.bluetooth.BluetoothGattCharacteristic;
import android.bluetooth.BluetoothGattDescriptor;
import android.bluetooth.BluetoothGattService;
import android.bluetooth.BluetoothManager;
import android.bluetooth.BluetoothProfile;
import android.content.Context;
import android.util.Log;

import com.phy.app.ble.BandUtil;
import com.phy.app.ble.BleAnalyze;
import com.phy.app.ble.BleGattCallBack;
import com.phy.app.ble.BandGattCallBack;
import com.phy.app.ble.OTAImpl;
import com.phy.app.ble.OperateConstant;
import com.phy.app.ble.bean.Message;
import com.phy.app.ble.bean.MessageType;
import com.phy.app.ble.util.HexString;
import com.phy.app.ble.util.Util;
import com.phy.app.util.LogUtil;

import java.util.List;
import java.util.UUID;

/**
 * Created by zhoululu on 2017/6/21.
 */

public class BleCore implements BleGattCallBack {

    private Context context;
    private List<byte[]> msgList;
    public static BluetoothGatt bluetoothGatt;
    private MessageType type;
    private byte[] commond = null;

    //private static OTAImpl otaImpl;

    private int retryTimes;
    private String macAddress;
    private boolean isWantConnect;

    public BleCore(Context context) {
        this.context = context;
    }

    /*public void setOtaCallBack(OTAImpl otaCallBack1) {
        otaImpl = otaCallBack1;

        otaImpl.setBluetoothGatt(bluetoothGatt);
        sendOTACommand("01"+HexString.int2ByteString(otaImpl.getFirmWareFile().getList().size())+"00",true);
    }*/

    public void connect(String mac){

        macAddress = mac;
        isWantConnect = true;

        BluetoothManager mBluetoothManager = (BluetoothManager) context.getApplicationContext().getSystemService(Context.BLUETOOTH_SERVICE);
        BluetoothDevice device = mBluetoothManager.getAdapter().getRemoteDevice(mac);

        bluetoothGatt = device.connectGatt(context.getApplicationContext(),false, BandGattCallBack.getGattCallBack());

        BandGattCallBack.getGattCallBack().setBleGattCallBack(this);
    }

    public void disConnect(){
        if (bluetoothGatt != null){
            isWantConnect = false;
            bluetoothGatt.disconnect();
        }
    }

    public static void enableNotifications(){
        BluetoothGattService bluetoothGattService = bluetoothGatt.getService(UUID.fromString(OperateConstant.SERVICE_UUID));

       if(bluetoothGattService == null){
           enableIndicateNotifications();
           return;
       }

        BluetoothGattCharacteristic bluetoothGattCharacteristic = bluetoothGattService.getCharacteristic(UUID.fromString(OperateConstant.CHARACTERISTIC_WRITE_UUID));

        if(bluetoothGattCharacteristic == null){
            return;
        }

        bluetoothGatt.setCharacteristicNotification(bluetoothGattCharacteristic,true);

        BluetoothGattDescriptor bluetoothGattDescriptor = bluetoothGattCharacteristic.getDescriptor(UUID.fromString(OperateConstant.DESCRIPTOR_UUID));
        if(bluetoothGattDescriptor == null){
            return;
        }

        bluetoothGattDescriptor.setValue(BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE);
        bluetoothGatt.writeDescriptor(bluetoothGattDescriptor);
    }

    public static void enableIndicateNotifications(){

        //在OTA模式，不开启
        if(Util.checkIsOTA(bluetoothGatt)){
            return;
        }

        BluetoothGattService bluetoothGattService = bluetoothGatt.getService(UUID.fromString(OperateConstant.SERVICE_OTA_UUID));

        if(bluetoothGattService == null){
            return;
        }

        BluetoothGattCharacteristic bluetoothGattCharacteristic = bluetoothGattService.getCharacteristic(UUID.fromString(OperateConstant.CHARACTERISTIC_OTA_INDICATE_UUID));
        if(bluetoothGattCharacteristic == null){
            return;
        }

        boolean success = bluetoothGatt.setCharacteristicNotification(bluetoothGattCharacteristic,true);

        BluetoothGattDescriptor bluetoothGattDescriptor = bluetoothGattCharacteristic.getDescriptor(UUID.fromString(OperateConstant.DESCRIPTOR_UUID));
        if(bluetoothGattDescriptor == null){
            return;
        }

        bluetoothGattDescriptor.setValue(BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE);
        bluetoothGatt.writeDescriptor(bluetoothGattDescriptor);
    }

    public void getBattery(){

        BluetoothGattService bluetoothGattService = bluetoothGatt.getService(UUID.fromString(OperateConstant.SERVICE_BATTERY_UUID));
        if(bluetoothGattService == null){
            return;
        }

        BluetoothGattCharacteristic bluetoothGattCharacteristic = bluetoothGattService.getCharacteristic(UUID.fromString(OperateConstant.CHARACTERISTIC_BATTERY_READ_UUID));
        if(bluetoothGattCharacteristic == null){
            return;
        }

        bluetoothGatt.readCharacteristic(bluetoothGattCharacteristic);

    }

    public void sendMsg(String title,String msg, MessageType type){

        Message message = new Message(title,msg);
        msgList = message.getMsgList();

        this.type = type;

        byte[] command = null;

        if(type == MessageType.PHONEIN || type == MessageType.PHONEEND){
            command = genMsgBytes(0);
        }else{
            command = genMsgBytes(1);
        }

        sendMsg(command);
    }

    private void sendMsg(byte[] command){
        sendCommand((byte) 0x38,command);
    }

    private byte[] genMsgBytes(int status){
        int size = msgList.get(0).length+1;
        byte[] command = new byte[size];

        command[0] = (byte)(type.getType() | status << 6);

        System.arraycopy(msgList.get(0),0,command,1,msgList.get(0).length);

        return command;
    }

    public void sendCommand(byte method,byte[] data){

        byte[] commandnd = genCommand(method,data);

        BluetoothGattService bluetoothGattService = bluetoothGatt.getService(UUID.fromString(OperateConstant.SERVICE_UUID));
        if(bluetoothGattService == null){
            Log.e("service", "service is null");
            return;
        }
        BluetoothGattCharacteristic bluetoothGattCharacteristic = bluetoothGattService.getCharacteristic(UUID.fromString(OperateConstant.CHARACTERISTIC_WRITE_UUID));

        if(bluetoothGattCharacteristic == null){
            return;
        }

        bluetoothGattCharacteristic.setValue(commandnd);
        bluetoothGatt.writeCharacteristic(bluetoothGattCharacteristic);

        Log.d("send commond", HexString.parseStringHex(commandnd));

    }

    private byte[] genCommand(byte method,byte[] data){
        byte csn = Util.getCSN();
        byte verifyByte;
        byte[] command;

        if(data == null){
            command = new byte[3];
            verifyByte = Util.genVerifyByte(method,csn);
            command[0] = method;
            command[1] = csn;
            command[2] = verifyByte;
        }else {
            command = new byte[3+data.length];
            verifyByte = Util.genVerifyByte(method,csn,data);
            command[0] = method;
            command[1] = csn;
            System.arraycopy(data,0,command,2,data.length);
            command[command.length-1] = verifyByte;
        }

        return command;
    }

    public void startOTA(){
        sendOTACommand("0102",false);

        BandUtil.bandBleCallBack.onResponse(OperateConstant.START_OTA,null);

    }

    public void getBootLoadVersion(){
        sendOTACommand("0200",true);
    }

    public void startReBoot(){
        sendOTACommand("04",false);
    }

    public boolean isOTA(){
        if(bluetoothGatt != null){
            return Util.checkIsOTA(bluetoothGatt);
        }
        return false;
    }

    private void sendOTACommand(String commd,boolean respons){
        BluetoothGattService bluetoothGattService = bluetoothGatt.getService(UUID.fromString(OperateConstant.SERVICE_OTA_UUID));
        if(bluetoothGattService == null){
            Log.e(" OTA service", "service is null");
            return;
        }

        BluetoothGattCharacteristic bluetoothGattCharacteristic = bluetoothGattService.getCharacteristic(UUID.fromString(OperateConstant.CHARACTERISTIC_OTA_WRITE_UUID));
        if(bluetoothGattCharacteristic == null){
            return;
        }

        if(!respons){
            bluetoothGattCharacteristic.setWriteType(BluetoothGattCharacteristic.WRITE_TYPE_NO_RESPONSE);
        }else{
            bluetoothGattCharacteristic.setWriteType(BluetoothGattCharacteristic.WRITE_TYPE_DEFAULT);
        }
        bluetoothGattCharacteristic.setValue(HexString.parseHexString(commd));
        bluetoothGatt.writeCharacteristic(bluetoothGattCharacteristic);

        Log.d("send ota commond", commd);

       // LogUtil.getLogUtilInstance().save("send ota commond: "+commd);
    }

    @Override
    public void onConnectionStateChange(BluetoothGatt gatt, int status, int newState) {
        if(newState == BluetoothProfile.STATE_CONNECTED){
            gatt.discoverServices();

            retryTimes = 0;
            isWantConnect = false;
        }else if(newState == BluetoothProfile.STATE_DISCONNECTED){

            if(gatt != null){
                gatt.close();
            }

            if(isWantConnect){
                retryTimes++;
                if(retryTimes > 2){
                    BandUtil.bandBleCallBack.onConnectDevice(false);

                    retryTimes = 0;
                    isWantConnect = false;
                }else{
                    connect(macAddress);
                }
            }else {
                BandUtil.bandBleCallBack.onConnectDevice(false);
            }


        }
    }

    @Override
    public void onCharacteristicRead(BluetoothGatt gatt, BluetoothGattCharacteristic characteristic, int status) {

        if(characteristic.getUuid().toString().equals(OperateConstant.CHARACTERISTIC_BATTERY_READ_UUID) && status == 0){
            BleAnalyze.batteryDataAnalysis(characteristic.getValue());
            Log.d("battery", HexString.parseStringHex(characteristic.getValue()));

        }
    }

    @Override
    public void onCharacteristicWrite(BluetoothGatt gatt, BluetoothGattCharacteristic characteristic, int status) {

        if(characteristic.getUuid().toString().equals(OperateConstant.CHARACTERISTIC_WRITE_UUID) && status == 0){

            if(commond != null){
                sendMsg(commond);
            }
        }else if(characteristic.getUuid().toString().equals(OperateConstant.CHARACTERISTIC_OTA_WRITE_UUID)){

            /*LogUtil.getLogUtilInstance().save("send ota commond uuid: "+characteristic.getUuid().toString());

            if(otaImpl != null)
                otaImpl.onCharacteristicWrite(gatt, characteristic,status);*/
        }else if(characteristic.getUuid().toString().equals(OperateConstant.CHARACTERISTIC_OTA_DATA_WRITE_UUID)){

            /*LogUtil.getLogUtilInstance().save("send ota data uuid: "+characteristic.getUuid().toString());

            if(otaImpl != null)
                otaImpl.onCharacteristicWrite(gatt, characteristic,status);*/
        }

    }

    @Override
    public void onCharacteristicChanged(BluetoothGatt gatt, BluetoothGattCharacteristic characteristic) {
        String uuid = characteristic.getUuid().toString();

        if(uuid.equals(OperateConstant.CHARACTERISTIC_WRITE_UUID)){

            Log.d("response", HexString.parseStringHex(characteristic.getValue()));

            byte[] response = characteristic.getValue();
            if(response[0] == 0x38){
                if(msgList.size() > 0){
                    msgList.remove(0);
                }

                if(response[2] == 0){
                    if(msgList.size() > 0){
                        msgList.clear();
                    }

                    BleAnalyze.bleDataAnalysis(characteristic.getValue());

                    commond = null;
                }else if(response[2] == 1){

                    if(msgList.size() >1){
                        commond = genMsgBytes(3);
                    }else if(msgList.size() == 1){
                        commond = genMsgBytes(2);
                    }
                }

            }else{
                BleAnalyze.bleDataAnalysis(characteristic.getValue());
            }
        }else if(uuid.equals(OperateConstant.CHARACTERISTIC_OTA_INDICATE_UUID)){
            /*Log.d("OTA", HexString.parseStringHex(characteristic.getValue()));

            if(otaImpl != null){
                otaImpl.onCharacteristicChanged(gatt, characteristic);
            }*/

            BleAnalyze.bootLoadDataAnalysis(characteristic.getValue());

            Log.d("response OTA", HexString.parseStringHex(characteristic.getValue()));

        }
    }

    @Override
    public void onDescriptorWrite(BluetoothGatt gatt, BluetoothGattDescriptor descriptor, int status) {
        if(OperateConstant.CHARACTERISTIC_WRITE_UUID.equals(descriptor.getCharacteristic().getUuid().toString())){
            enableIndicateNotifications();
        }
    }
}

