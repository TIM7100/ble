package com.phy.app.activity;

import android.Manifest;
import android.app.AlertDialog;
import android.app.Dialog;
import android.content.DialogInterface;
import android.os.Build;
import android.os.Environment;
import android.util.Log;
import android.view.View;
import android.widget.AdapterView;
import android.widget.ListView;
import android.widget.ProgressBar;
import android.widget.TextView;
import com.phy.app.R;
import com.phy.app.adapter.FileListAdapter;
import com.phy.app.app.PHYApplication;
import com.phy.app.beans.Connect;
import com.phy.app.ble.bean.FirmWareFile;
import com.phy.app.ble.bean.Partition;
import com.phy.app.util.Utils;
import com.phy.ota.sdk.OTASDKUtils;
import com.phy.ota.sdk.firware.UpdateFirewareCallBack;

import org.greenrobot.eventbus.Subscribe;
import org.greenrobot.eventbus.ThreadMode;
import java.io.File;
import java.util.ArrayList;
import java.util.List;
import pub.devrel.easypermissions.AfterPermissionGranted;
import pub.devrel.easypermissions.EasyPermissions;

/**
 * OTANewActivity
 *
 * @author:zhoululu
 * @date:2018/7/25
 */

public class OTANewActivity extends EventBusBaseActivity implements EasyPermissions.PermissionCallbacks,UpdateFirewareCallBack{

    List<String> fileList;
    FileListAdapter fileListAdapter;

    String path = Environment.getExternalStorageDirectory().getPath();
    private String filePath;

    private TextView opertionTV;
    private ProgressBar bar;

    private OTASDKUtils otasdkUtils;

    private String mac;
    private String otaMac;

    private boolean isOTAING;

    @Override
    public void initComponent() {
        setTitle(R.string.label_ota);

        opertionTV = findViewById(R.id.current_opertion);
        bar = findViewById(R.id.progress_bar);

        ListView fileListView = findViewById(R.id.file_list);
        fileList = new ArrayList<String>();

        fileListAdapter = new FileListAdapter(this,R.layout.item_file_list);
        fileListView.setAdapter(fileListAdapter);

        if(Build.VERSION.SDK_INT < Build.VERSION_CODES.M){
            searchFile();
        }else {
            initRequiredPermission();
        }

        if(PHYApplication.getBandUtil().isOTA()){
            mac = Utils.getOTAMac(PHYApplication.getApplication().getMac(),-1);
            otaMac = PHYApplication.getApplication().getMac();
        }else {
            otaMac = Utils.getOTAMac(PHYApplication.getApplication().getMac(),1);
            mac = PHYApplication.getApplication().getMac();
        }

        otasdkUtils = new OTASDKUtils(OTANewActivity.this, this);

        fileListView.setOnItemClickListener(new AdapterView.OnItemClickListener() {
            @Override
            public void onItemClick(AdapterView<?> parent, View view, int position, long id) {
                if(!isOTAING){
                    filePath = path+"/"+fileList.get(position);

                    if(fileList.get(position).endsWith(".res")){
                        updateResurece(filePath);
                    }else if(fileList.get(position).endsWith(".hex") || fileList.get(position).endsWith(".hexe")){
                        updateFirware(filePath);
                    }
                }

            }
        });
    }

    private void updateFirware(String file){
        isOTAING = true;
        opertionTV.setText("start...");
        otasdkUtils.updateFirware(PHYApplication.getApplication().getMac(),file);
    }

    private void updateResurece(final String file){

        FirmWareFile firmWareFile = new FirmWareFile(file);
        String message = "";
        for (int i=0;i<firmWareFile.getList().size();i++){
            Partition partition = firmWareFile.getList().get(i);
            message += "address:";
            message += partition.getAddress();
            message += "\n";

            message += "size:";
            message += partition.getPartitionLength();
            message += "\n";
        }

        AlertDialog.Builder builder = new AlertDialog.Builder(this);
        //    设置Title的内容
        builder.setTitle("Resource Update");
        //    设置Content来显示一个信息
        builder.setMessage(message);

        //    设置一个PositiveButton
        builder.setPositiveButton(getString(R.string.start_resource_update), new DialogInterface.OnClickListener(){
            @Override
            public void onClick(DialogInterface dialog, int which){
                isOTAING = true;
                opertionTV.setText("start...");
                otasdkUtils.updateResource(PHYApplication.getApplication().getMac(),file);

                dialog.dismiss();
            }
        });

        //Dialog dialog = builder.create();
        //dialog.setCanceledOnTouchOutside(false);

        builder.show();
    }

    @Override
    public void onError(final int i) {
        isOTAING = false;

        runOnUiThread(new Runnable() {
            @Override
            public void run() {
                opertionTV.setText("onError:"+i);
            }
        });
        Log.e(TAG, "onError: "+i );

        PHYApplication.getApplication().setMac(otaMac);
    }

    @Override
    public void onProcess(final float v) {
        Log.e(TAG, "onProcess: "+v );

        runOnUiThread(new Runnable() {
            @Override
            public void run() {
                opertionTV.setText("onProcess: "+v);
                bar.setProgress((int) v);
            }
        });
    }

    @Override
    public void onUpdateComplete() {
        isOTAING = false;

        Log.e(TAG, "onUpdateComplete: " );
        runOnUiThread(new Runnable() {
            @Override
            public void run() {
                opertionTV.setText("onUpdateComplete:");
            }
        });

        PHYApplication.getApplication().setMac(mac);
        PHYApplication.getBandUtil().connectDevice(mac);
    }

    @Override
    public int getContentLayout() {
        return R.layout.activity_ota;
    }

    private void searchFile(){

        fileList.clear();

        File file = new File(path);
        if(file.exists()){
            File[] listFiles = file.listFiles();
            for (File f : listFiles){
                if(f.getName().endsWith(".hex")  || f.getName().endsWith(".hexe")  || f.getName().endsWith(".res")) {
                    fileList.add(f.getName());
                    fileListAdapter.setData(fileList);
                }
            }
        }else {
            showToast("sdcard not found");
        }
    }

    @Subscribe(threadMode = ThreadMode.MAIN)
    public void onMessageEvent(Connect connect) {
        if(connect.isConnect()){
            Log.e("connect success","connected");

        }else{

        }
    }

    @AfterPermissionGranted(100)
    private void initRequiredPermission(){

        String[] permissions =new String[]{Manifest.permission.READ_EXTERNAL_STORAGE,Manifest.permission.WRITE_EXTERNAL_STORAGE};
        boolean hasPermissions = EasyPermissions.hasPermissions(this, permissions);
        if (!hasPermissions) {
            EasyPermissions.requestPermissions(this, getString(R.string.label_read_tips),100, permissions);
        }else {
            searchFile();
        }
    }

    @Override
    public void onRequestPermissionsResult(int requestCode, String[] permissions, int[] grantResults) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults);

        EasyPermissions.onRequestPermissionsResult(requestCode, permissions, grantResults, this);
    }

    @Override
    public void onPermissionsGranted(int requestCode, List<String> perms) {
        searchFile();
    }

    @Override
    public void onPermissionsDenied(int requestCode, List<String> perms) {
        showToast(R.string.label_read_tips);
    }

}
