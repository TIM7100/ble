package com.phy.sdkdemo;

import android.os.Bundle;
import android.os.Environment;
import android.support.annotation.Nullable;
import android.support.v7.app.AppCompatActivity;
import android.text.TextUtils;
import android.view.View;
import android.widget.AdapterView;
import android.widget.EditText;
import android.widget.ListView;
import android.widget.TextView;
import android.widget.Toast;

import com.phy.ota.sdk.OTASDKUtils;
import com.phy.ota.sdk.firware.UpdateFirewareCallBack;

import java.io.File;
import java.util.ArrayList;
import java.util.List;

/**
 * AutoActivity
 *
 * @author:zhoululu
 * @date:2018/7/14
 */

public class AutoActivity extends AppCompatActivity implements UpdateFirewareCallBack{

    List<String> fileList;
    FileListAdapter fileListAdapter;

    String path = Environment.getExternalStorageDirectory().getPath();
    private String filePath;
    private TextView tips;
    private String address;

    private EditText macEdit;

    OTASDKUtils otasdkUtils;

    boolean isQuick = false;

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        setContentView(R.layout.activity_auto);

        isQuick = getIntent().getBooleanExtra("isQuick",false);

        macEdit = findViewById(R.id.mac_text);
        address = SdkDemoApplication.getApplication().getDevice().getDevice().getAddress();

        macEdit.setText(address);

        tips = findViewById(R.id.tips);

        ListView fileListView = findViewById(R.id.file_list);
        fileList = new ArrayList<String>();

        fileListAdapter = new FileListAdapter(this, R.layout.item_file_list);
        fileListView.setAdapter(fileListAdapter);

        otasdkUtils = new OTASDKUtils(getApplicationContext(),this);

        searchFile();

        fileListView.setOnItemClickListener(new AdapterView.OnItemClickListener() {
            @Override
            public void onItemClick(AdapterView<?> parent, View view, int position, long id) {
                filePath = path + "/" + fileList.get(position);

                tips.setText("start...");

                String mac = macEdit.getText().toString().trim();
                if(TextUtils.isEmpty(mac)){
                    Toast.makeText(AutoActivity.this,"address is null",Toast.LENGTH_SHORT).show();
                    return;
                }

                address = mac;

                if(fileList.get(position).toLowerCase().endsWith(".hex")){
                    otasdkUtils.updateFirware(address,filePath);
                }else{
                    otasdkUtils.updateResource(address,filePath);
                }
            }
        });

    }

    @Override
    public void onError(final int code) {
        runOnUiThread(new Runnable() {
            @Override
            public void run() {
                tips.setText("onError:"+code);
            }
        });
    }

    @Override
    public void onProcess(final float process) {
        runOnUiThread(new Runnable() {
            @Override
            public void run() {
                tips.setText("onProcess:"+process);
            }
        });
    }

    @Override
    public void onUpdateComplete() {
        runOnUiThread(new Runnable() {
            @Override
            public void run() {
                tips.setText("onUpdateComplete:");
            }
        });
    }

    private void searchFile(){

        fileList.clear();

        File file = new File(path);
        if(file.exists()){
            File[] listFiles = file.listFiles();
            for (File f : listFiles){
                if(f.getName().endsWith(".hex") || f.getName().endsWith(".hexe") || f.getName().endsWith(".res")) {
                    fileList.add(f.getName());
                    fileListAdapter.setData(fileList);
                }
            }
        }else {
            Toast.makeText(this,"sdcard not found",Toast.LENGTH_LONG).show();
        }
    }

}
