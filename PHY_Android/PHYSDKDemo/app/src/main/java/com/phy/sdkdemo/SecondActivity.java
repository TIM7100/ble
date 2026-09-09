package com.phy.sdkdemo;

import android.content.Intent;
import android.os.Bundle;
import android.os.Environment;
import android.os.Handler;
import android.support.annotation.Nullable;
import android.support.v7.app.AppCompatActivity;
import android.util.Log;
import android.view.View;
import android.widget.AdapterView;
import android.widget.ListView;
import android.widget.TextView;
import android.widget.Toast;
import com.phy.sdkdemo.ble.BandUtil;

import java.io.File;
import java.util.ArrayList;
import java.util.List;

/**
 * SecondActivity
 *
 * @author:zhoululu
 * @date:2018/7/3
 */

public class SecondActivity extends AppCompatActivity{

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        setContentView(R.layout.activity_second);
    }

    /*public void customize(View view){
        Intent intent = new Intent(this,CustomizeActivity.class);
        startActivity(intent);
    }*/

    /*public void auto(View view){
        Intent intent = new Intent(this,AutoActivity.class);
        intent.putExtra("isQuick",true);
        startActivity(intent);
    }*/

    public void normal(View view){
        Intent intent = new Intent(this,AutoActivity.class);
        intent.putExtra("isQuick",false);
        startActivity(intent);
    }

}
