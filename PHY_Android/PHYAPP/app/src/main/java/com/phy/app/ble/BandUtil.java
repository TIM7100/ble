package com.phy.app.ble;

import android.content.Context;
import android.util.Log;

import com.phy.app.ble.bean.FirmWareFile;
import com.phy.app.ble.bean.LightColor;
import com.phy.app.ble.bean.MessageType;
import com.phy.app.ble.core.BleCore;

import java.util.Calendar;
import java.util.Date;

/**
 * Created by zhoululu on 2017/6/21.
 */

public class BandUtil {

    private static BandUtil bandUtil;
    public static BandBleCallBack bandBleCallBack;

    private BleScanner mBleScanner;
    private static BleCore mBleCore;

    private BandUtil(Context context) {
        mBleScanner = new BleScanner(context);
        mBleCore = new BleCore(context);
    }

    public static BandUtil getBandUtil(Context context){
        if(bandUtil == null){
            synchronized (BandUtil.class){
                if(bandUtil == null){
                    bandUtil = new BandUtil(context);
                }
            }
        }
        return bandUtil;
    }

    public void scanDevice(){
        mBleScanner.scanDevice();
    }

    public void stopScanDevice(){
      mBleScanner.stopScanDevice();
    }

    public void connectDevice(String macAddress){
        mBleCore.connect(macAddress);
    }

    public void syncTime(final Date date){


        Calendar calendar = Calendar.getInstance();
        calendar.setTime(date);

        byte[] dateArray = new byte[6];
        dateArray[0] = (byte) (calendar.get(Calendar.YEAR)%100);
        dateArray[1] = (byte) (calendar.get(Calendar.MONTH)+1);
        dateArray[2] = (byte) calendar.get(Calendar.DAY_OF_MONTH);
        dateArray[3] = (byte) calendar.get(Calendar.HOUR_OF_DAY);
        dateArray[4] = (byte) calendar.get(Calendar.MINUTE);
        dateArray[5] = (byte) calendar.get(Calendar.SECOND);

        mBleCore.sendCommand((byte) 0x02, dateArray);
    }

    public void disConnectDevice(){
        mBleCore.disConnect();
    }

    public void getBattery(){
        mBleCore.getBattery();
    }

    public void startGsensor(){
        mBleCore.sendCommand((byte) 0x23,null);
    }

    public void stopGsensor(){
        mBleCore.sendCommand((byte) 0x24,null);
    }

    public void ledSetting(final int brightness, final LightColor color){
        mBleCore.sendCommand((byte) 0x30,new byte[]{(byte) brightness, (byte) color.getColor()});
    }

    public void startHeartRate(){
        mBleCore.sendCommand((byte) 0x21,null);
    }

    public void stopHeartRate(){
        mBleCore.sendCommand((byte) 0x22,null);
    }

    public void sendMsg(final String title, final String msg, final MessageType type){

        mBleCore.sendMsg(title,msg,type);
    }

    public void getBootLoadVersion(){
        mBleCore.getBootLoadVersion();
    }

    public boolean isOTA(){
        return mBleCore.isOTA();
    }

    /*public void startOTA(){
        mBleCore.startOTA();
    }*/

    public void startReBoot(){
        mBleCore.startReBoot();
    }

    /*public void updateFirmware(String mac,String filePath,OTACallBack callBack1){
        FirmWareFile firmWareFile = new FirmWareFile(filePath);
        if(firmWareFile.getCode() == 200){
            Log.e("loadFile","success");
            OTAImpl otaImpl = new OTAImpl(firmWareFile);
            mBleCore.setOtaCallBack(otaImpl);

            callBack = callBack1;
        }else{
            Log.e("loadFile","faile:"+firmWareFile.getCode());
        }
    }*/

    public static OTACallBack callBack;

    public void setBandBleCallBack(BandBleCallBack bandBleCallBack1) {
        bandBleCallBack = bandBleCallBack1;
    }

}
