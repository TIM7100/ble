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

public class AutoActivity extends AppCompatActivity implements UpdateFirewareCallBack {

    List<String> fileList;
    FileListAdapter fileListAdapter;

    String path = Environment.getExternalStorageDirectory().getPath();
    private String filePath;
    private TextView tips;
    private String address;

    private EditText macEdit;

    OTASDKUtils otasdkUtils;

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        setContentView(R.layout.activity_auto);

        macEdit = findViewById(R.id.mac_text);
        address = SdkDemoApplication.getApplication().getDevice().getDevice().getAddress();

        macEdit.setText(address);

        tips = findViewById(R.id.tips);

        ListView fileListView = findViewById(R.id.file_list);
        fileList = new ArrayList<String>();

        fileListAdapter = new FileListAdapter(this, R.layout.item_file_list);
        fileListView.setAdapter(fileListAdapter);

        otasdkUtils = new OTASDKUtils(getApplicationContext(), this);

        searchFile();

        fileListView.setOnItemClickListener(new AdapterView.OnItemClickListener() {
            @Override
            public void onItemClick(AdapterView<?> parent, View view, int position, long id) {
                filePath = path + "/" + fileList.get(position);

                tips.setText("start...");

                String mac = macEdit.getText().toString().trim();
                if (TextUtils.isEmpty(mac)) {
                    Toast.makeText(AutoActivity.this, "address is null", Toast.LENGTH_SHORT).show();
                    return;
                }

                address = mac;

                if (fileList.get(position).toLowerCase().endsWith(".hex")
                        || fileList.get(position).toLowerCase().endsWith(".hex16")) {
                    otasdkUtils.updateFirware(address, filePath);
                } else if (fileList.get(position).toLowerCase().endsWith(".hexe16")) {
                    otasdkUtils.updateSecurityFirware(address, filePath);
                } else {
                    otasdkUtils.updateResource(address, filePath);
                }
            }
        });

    }

    @Override
    public void onError(final int code) {
        runOnUiThread(new Runnable() {
            @Override
            public void run() {
                tips.setText("onError:" + code);
            }
        });
    }

    @Override
    public void onProcess(final float process) {
        runOnUiThread(new Runnable() {
            @Override
            public void run() {
                tips.setText("onProcess:" + process);
            }
        });
    }

    @Override
    public void onUpdateComplete() {
        runOnUiThread(new Runnable() {
            @Override
            public void run() {
                tips.setText("onUpdateComplete:");
                Toast.makeText(getApplicationContext(), "升级成功", Toast.LENGTH_LONG);
                AutoActivity.this.finish();
            }
        });
    }

    private void searchFile() {

        fileList.clear();

        File file = new File(path);
        if (file.exists()) {
            File[] listFiles = file.listFiles();
            for (File f : listFiles) {
                if (f.getName().endsWith(".hex16")
                        || f.getName().endsWith(".hex")
                        || f.getName().endsWith(".hexe")
                        || f.getName().endsWith(".res")
                        || f.getName().endsWith(".hexe16")) {
                    fileList.add(f.getName());
                    fileListAdapter.setData(fileList);
                }
            }
        } else {
            Toast.makeText(this, "sdcard not found", Toast.LENGTH_LONG).show();
        }
    }

}
