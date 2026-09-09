package com.phy.app.activity;

import android.content.Intent;
import android.os.Bundle;
import android.os.Handler;
import android.os.Message;
import android.support.annotation.Nullable;
import android.support.v7.app.AppCompatActivity;
import android.util.Log;

import com.phy.app.R;
import com.phy.app.ble.OperateConstant;
import com.phy.app.ble.util.HexString;

import java.io.UnsupportedEncodingException;
import java.nio.ByteBuffer;
import java.nio.charset.Charset;
import java.util.UUID;

/**
 * SplashActivity
 *
 * @author:zhoululu
 * @date:2018/4/13
 */

public class SplashActivity extends AppCompatActivity{

    private Handler handler = new Handler(){
        @Override
        public void handleMessage(Message msg) {
            if(msg.what == 1){
                Intent intent = new Intent(SplashActivity.this,MainActivity.class);
                startActivity(intent);

                finish();
            }
        }
    };

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        setContentView(R.layout.activity_splash);

        handler.sendEmptyMessageDelayed(1,2000);
    }


}
