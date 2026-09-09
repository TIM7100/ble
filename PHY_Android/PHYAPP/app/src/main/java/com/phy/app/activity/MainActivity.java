package com.phy.app.activity;

import android.content.Intent;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.os.Handler;
import android.os.Message;
import android.support.v7.app.AppCompatActivity;
import android.os.Bundle;
import android.util.Log;
import android.view.View;
import android.widget.Button;
import android.widget.TextView;

import com.phy.app.R;
import com.phy.app.app.PHYApplication;
import com.phy.app.beans.BleEvent;
import com.phy.app.beans.Connect;
import com.phy.app.ble.OperateConstant;
import com.phy.app.ble.bean.LightColor;
import com.phy.app.ble.core.BleCore;
import com.phy.app.ble.util.HexString;
import com.phy.app.ble.util.Util;
import com.phy.app.util.LogUtil;

import org.greenrobot.eventbus.Subscribe;
import org.greenrobot.eventbus.ThreadMode;

import java.util.Date;

public class MainActivity extends EventBusBaseActivity {

    private TextView connectTV;
    private TextView macTV;
    private TextView versionTV;
    private Button reBootButton;
    private int leds = 0;
    private VersionHandle handle = new VersionHandle();

    @Override
    public void initComponent() {
        connectTV = findViewById(R.id.text_connect);
        macTV = findViewById(R.id.device_mac);
        versionTV = findViewById(R.id.app_version);
        reBootButton = findViewById(R.id.reboot_button);

        versionTV.setText(getString(R.string.app_version,getVersion()));
    }

    @Override
    public int getContentLayout() {
        return R.layout.activity_main;
    }

    @Subscribe(threadMode = ThreadMode.MAIN)
    public void onMessageEvent(Connect connect) {
        setText(connect.isConnect());
    }

    @Override
    protected void onResume() {
        super.onResume();

        setText(PHYApplication.getApplication().isConnect());
    }

    private String getVersion(){
        PackageManager manager = getPackageManager();
        try {
            PackageInfo info = manager.getPackageInfo(getPackageName(),0);
            return info.versionName;
        } catch (PackageManager.NameNotFoundException e) {
            e.printStackTrace();
            return "1.0";
        }
    }

    private void setText(boolean isConnect){
        if(isConnect){
            connectTV.setText(R.string.disconnect_device);
            macTV.setText(getString(R.string.connected_device,PHYApplication.getApplication().getMac()));
        }else {
            connectTV.setText(R.string.connect_device);
            macTV.setText(R.string.unconnected_device);
        }

        setBootLoad(isConnect);
    }

    private void setBootLoad(boolean isConnect){
        if(isConnect){
            if(PHYApplication.getBandUtil().isOTA()){
                versionTV.setText(getString(R.string.app_ota_bootload_version,getVersion()));
                reBootButton.setVisibility(View.VISIBLE);
            }else{
                handle.sendEmptyMessageDelayed(1,1000);
                reBootButton.setVisibility(View.INVISIBLE);
            }
        }else{
            versionTV.setText(getString(R.string.app_version,getVersion()));
            reBootButton.setVisibility(View.INVISIBLE);
        }
    }

    @Subscribe(threadMode = ThreadMode.MAIN)
    public void onMessageEvent(BleEvent event) {
        if(event.getOperate().equals(OperateConstant.LED_SETTING)){
            if(leds == 2){
                PHYApplication.getBandUtil().ledSetting(0,LightColor.GREE);
                leds --;
            }else if(leds == 1){
                PHYApplication.getBandUtil().ledSetting(0,LightColor.BLUE);
                leds --;
            }
        }else if(event.getOperate().equals(OperateConstant.BOOT_LOAD_VERSION)){
            byte[] data = (byte[]) event.getObject();
            byte[] bytes = new byte[data.length-7];
            System.arraycopy(data,7,bytes,0,bytes.length);

            Log.e("chars",new String(bytes).trim());
            versionTV.setText(getString(R.string.app_bootload_version,getVersion(),new String(bytes).trim()));
        }
    }

    private boolean checkIsConnected(){
        if(!PHYApplication.getApplication().isConnect()){
            showToast(R.string.label_unconnect_device);
            return false;
        }
        return true;
    }

    public void goSearch(View view){
        if(PHYApplication.getApplication().isConnect()){
            PHYApplication.getBandUtil().disConnectDevice();
        }else{
            Intent intent = new Intent(this,SearchDeviceActivity.class);
            startActivity(intent);
        }
    }

    public void go2Gsensor(View view){
        if(!checkIsConnected()){
            return;
        }

        Intent intent = new Intent(this,GsensorActivity.class);
        startActivity(intent);
    }

    public void go2HeartRate(View view){
        if(!checkIsConnected()){
            return;
        }

        Intent intent = new Intent(this,HearRateActivity.class);
        startActivity(intent);
    }

    public void go2LED(View view){
        if(!checkIsConnected()){
            return;
        }

        Intent intent = new Intent(this,LEDActivity.class);
        startActivityForResult(intent,100);
    }

    public void go2Push(View view){
        if(!checkIsConnected()){
            return;
        }

        Intent intent = new Intent(this,PushActivity.class);
        startActivity(intent);
    }

    public void go2KeyBoard(View view){

        showToast("暂未实现");

        /*if(!checkIsConnected()){
            return;
        }

        Intent intent = new Intent(this,KeyBoardActivity.class);
        startActivity(intent);*/
    }

    public void go2OTA(View view){
        if(!checkIsConnected()){
            return;
        }

        if(!Util.checkIsCanOTA(BleCore.bluetoothGatt)){
            showToast("设备不能进行OTA升级");
            return;
        }

        Intent intent = new Intent(this,OTANewActivity.class);
        startActivity(intent);
    }

    public void reBoot(View view){

        Log.d("reBoot","reBoot");

        PHYApplication.getBandUtil().startReBoot();
        handle.sendEmptyMessageDelayed(2,1000);
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        if(requestCode == 100){
            leds = 3;

            PHYApplication.getBandUtil().ledSetting(0,LightColor.RED);
            leds --;
        }
    }


    @Override
    protected void onDestroy() {
        super.onDestroy();

        handle.removeCallbacksAndMessages(null);
        /*if((PHYApplication.getApplication().isConnect())){
            PHYApplication.getBandUtil().disConnectDevice();
        }*/
    }

    public static class VersionHandle extends Handler{
        @Override
        public void handleMessage(Message msg) {
            if(msg.what == 1){
                PHYApplication.getBandUtil().getBootLoadVersion();
            }else if(msg.what == 2){
                PHYApplication.getBandUtil().disConnectDevice();
            }
        }
    }


}
