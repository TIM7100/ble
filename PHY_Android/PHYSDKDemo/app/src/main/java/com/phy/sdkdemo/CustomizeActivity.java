package com.phy.sdkdemo;

import android.bluetooth.BluetoothDevice;
import android.os.Bundle;
import android.os.Environment;
import android.support.annotation.Nullable;
import android.support.v7.app.AppCompatActivity;
import android.text.TextUtils;
import android.view.View;
import android.widget.EditText;
import android.widget.TextView;
import android.widget.Toast;

import com.phy.ota.sdk.ble.OTACallBack;
import com.phy.ota.sdk.OTAUtils;
import com.phy.sdkdemo.ble.BleUtils;

import java.io.File;

/**
 * CustomizeActivity
 *
 * @author:zhoululu
 * @date:2018/7/14
 */

public class CustomizeActivity extends AppCompatActivity{

    OTACallBack otaCallBack = new OTACallBack() {
        @Override
        public void onConnected(final boolean isConnected) {
            runOnUiThread(new Runnable() {
                @Override
                public void run() {
                    log.setText("onConnected:"+isConnected);
                }
            });
        }

        @Override
        public void onOTA(final boolean isConnected) {
            runOnUiThread(new Runnable() {
                @Override
                public void run() {
                    log.setText("onOTA:"+isConnected);
                }
            });
        }

        @Override
        public void onDeviceSearch(final BluetoothDevice device, int rssi, byte[] scanRecord) {
            runOnUiThread(new Runnable() {
                @Override
                public void run() {
                    log.setText("onDeviceSearch:"+device.getAddress());
                }
            });
        }

        @Override
        public void onProcess(final float process) {
            runOnUiThread(new Runnable() {
                @Override
                public void run() {
                    log.setText("onProcess:"+process);
                }
            });
        }

        @Override
        public void onError(final int code) {
            runOnUiThread(new Runnable() {
                @Override
                public void run() {
                    log.setText("onError:"+code);
                }
            });
        }

        @Override
        public void onOTAFinish() {
            runOnUiThread(new Runnable() {
                @Override
                public void run() {
                    log.setText("onOTAFinish:");
                }
            });
        }

        @Override
        public void onReboot() {
            runOnUiThread(new Runnable() {
                @Override
                public void run() {
                    log.setText("onReboot:");
                }
            });
        }

        @Override
        public void onResource(boolean isConnected) {

        }

        @Override
        public void onResourceFinish() {

        }
    };

    private OTAUtils otaUtils;
    private String mac;
    String filePath = Environment.getExternalStorageDirectory().getPath()+"/light2.hex" ;

    private TextView log;
    private EditText macEdit;
    private EditText fileEdit;

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        setContentView(R.layout.activity_customize);

        log = findViewById(R.id.log);
        macEdit = findViewById(R.id.mac_text);
        fileEdit = findViewById(R.id.file_text);

        otaUtils = new OTAUtils(getApplicationContext(),otaCallBack);

        String address = SdkDemoApplication.getApplication().getDevice().getDevice().getAddress();

        macEdit.setText(address);
        fileEdit.setText(filePath);
    }

    public void connect(View view){
        mac = macEdit.getText().toString().trim();
        if(TextUtils.isEmpty(mac)){
            Toast.makeText(this,"address is null",Toast.LENGTH_SHORT).show();
            return;
        }

        otaUtils.connectDevice(mac);
    }

    public void startOTA(View view){
        otaUtils.startOTA();
    }

    public void connectOTA(View view){
        otaUtils.connectDevice(BleUtils.getOTAMac(mac));
    }

    public void update(View view){
        filePath = fileEdit.getText().toString().trim();
        if(TextUtils.isEmpty(filePath)){
            Toast.makeText(this,"filePath is null",Toast.LENGTH_SHORT).show();
            return;
        }

        File file = new File(filePath);
        if(!file.exists()){
            if(TextUtils.isEmpty(filePath)){
                Toast.makeText(this,"file not found",Toast.LENGTH_SHORT).show();
                return;
            }
        }

        otaUtils.updateFirmware(filePath);
    }

    public void reBoot(View view){
        otaUtils.reBoot();
    }

    public void cancleUpdate(View view){
        otaUtils.cancleOTA();
    }
}
