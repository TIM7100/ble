package com.phy.app.activity;

import android.Manifest;
import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.os.Build;
import android.os.Handler;
import android.os.Message;
import android.text.TextUtils;
import android.util.Log;
import android.view.KeyEvent;
import android.view.View;
import android.widget.AdapterView;
import android.widget.ListView;
import android.widget.TextView;
import android.widget.Toast;

import com.phy.app.R;
import com.phy.app.adapter.DeviceListAdapter;
import com.phy.app.app.PHYApplication;
import com.phy.app.beans.BleEvent;
import com.phy.app.beans.Connect;
import com.phy.app.beans.Device;
import com.phy.app.ble.OperateConstant;
import com.phy.app.util.LogUtil;
import com.phy.app.util.Utils;

import org.greenrobot.eventbus.Subscribe;
import org.greenrobot.eventbus.ThreadMode;

import java.util.ArrayList;
import java.util.Date;
import java.util.List;
import java.util.Set;

import pub.devrel.easypermissions.AfterPermissionGranted;
import pub.devrel.easypermissions.EasyPermissions;

/**
 * SearchDeviceActivity
 *
 * @author:zhoululu
 * @date:2018/4/13
 */

public class SearchDeviceActivity extends EventBusBaseActivity implements EasyPermissions.PermissionCallbacks,View.OnClickListener{

    private static final int STOP_SEARCH = 100;
    private static final int SYNC_TIME = 200;

    private List<Device> deviceList;
    private boolean isScaning = false;
    private boolean isConnecting = false;
    private TextView searchTV;
    private DeviceListAdapter deviceAdapter;
    private Device device;

    private Handler handler = new Handler(){
        @Override
        public void handleMessage(Message msg) {

            if (msg.what == STOP_SEARCH){
                PHYApplication.getBandUtil().stopScanDevice();
                searchTV.setText(getString(R.string.label_start_search));

                isScaning = false;
                if(deviceList.size() < 1){
                    Toast.makeText(SearchDeviceActivity.this,getText(R.string.device_search_fail),Toast.LENGTH_SHORT).show();
                }
            }else if(msg.what == SYNC_TIME){
                PHYApplication.getBandUtil().syncTime(new Date());

                PHYApplication.getApplication().setMac(device.getDevice().getAddress());
                PHYApplication.getApplication().setName(device.getDevice().getName());
                finish();
            }
        }
    };

    private BroadcastReceiver mBluetoothReceiver = new BroadcastReceiver() {

        @Override
        public void onReceive(Context context, Intent intent) {
            int blueState = intent.getIntExtra(BluetoothAdapter.EXTRA_STATE, 0);
            if (blueState==BluetoothAdapter.STATE_ON){
                checkSearchDevice();
            }
        }
    };

    @Override
    public void initComponent() {
        setTitle(R.string.search_title);

        searchTV = toolbar.findViewById(R.id.right_text);
        searchTV.setVisibility(View.VISIBLE);
        searchTV.setOnClickListener(this);

        ListView deviceListView = findViewById(R.id.device_list);
        deviceList = new ArrayList<>();

        deviceAdapter = new DeviceListAdapter(this,R.layout.item_device_list);
        deviceListView.setAdapter(deviceAdapter);

        deviceListView.setOnItemClickListener(new AdapterView.OnItemClickListener() {
            @Override
            public void onItemClick(AdapterView<?> parent, View view, int position, long id) {

                if(isScaning){
                    isScaning = false;
                    PHYApplication.getBandUtil().stopScanDevice();
                    handler.removeCallbacksAndMessages(null);

                    searchTV.setText(getString(R.string.label_start_search));
                }

                device = (Device) deviceAdapter.getItem(position);

                if(!isConnecting){

                    if(!Utils.blutheIsOpen()){
                        showToast(R.string.label_bluetooth_closed);
                    }else{

                        PHYApplication.getBandUtil().connectDevice(device.getDevice().getAddress());

                        isConnecting = true;
                    }
                }
            }
        });

        IntentFilter filter = new IntentFilter();
        filter.addAction(BluetoothAdapter.ACTION_STATE_CHANGED);
        registerReceiver(mBluetoothReceiver,filter);

        checkSearchDevice();
    }

    @Override
    public int getContentLayout() {
        return R.layout.activity_search_device;
    }

    @Override
    public void onClick(View v) {
        if(!isScaning){
            searchTV.setText(getString(R.string.label_stop_search));
            checkSearchDevice();
        }else {
            isScaning = false;
            searchTV.setText(getString(R.string.label_start_search));
            PHYApplication.getBandUtil().stopScanDevice();
        }
    }

    @Subscribe(threadMode = ThreadMode.MAIN)
    public void onMessageEvent(Device device) {
        Log.e("device",device.getDevice().getAddress() + "#"+device.getDevice().getName());

        if(!deviceList.contains(device) && !TextUtils.isEmpty(device.getDevice().getName())){
            addDevice2List(device);
        }
    }

    @Subscribe(threadMode = ThreadMode.MAIN)
    public void onMessageEvent(Connect connect) {
        isConnecting = false;

        if(connect.isConnect()){
            Log.d(TAG, "connect success");
            handler.sendEmptyMessageDelayed(SYNC_TIME,1000);
        }else {
            showToast(R.string.label_connect_fail);
        }
    }

    /*@Subscribe(threadMode = ThreadMode.MAIN)
    public void onMessageEvent(BleEvent event) {
        if(event.getOperate().equals(OperateConstant.SYNC_TIME)){
            Log.d(TAG, "sync success");
            PHYApplication.getApplication().setMac(device.getDevice().getAddress());
            finish();
        }
    }*/

    private void addDevice2List(Device device){
        deviceList.add(device);
        deviceAdapter.setData(deviceList);
        deviceAdapter.notifyDataSetChanged();
    }

    private void checkSearchDevice(){
        if(Build.VERSION.SDK_INT < Build.VERSION_CODES.M){
            searchDevice();
        }else {
            initRequiredPermission();
        }
    }

    private void searchDevice(){
        if(!Utils.blutheIsOpen()){
            Utils.openBlutheActivity(this);
            return;
        }

        deviceList.clear();
        deviceAdapter.setData(deviceList);

        BluetoothAdapter mBluetoothAdapter = BluetoothAdapter.getDefaultAdapter();
        Set<BluetoothDevice> pairedDevices = mBluetoothAdapter.getBondedDevices();
        if (pairedDevices.size() > 0) {
            for (BluetoothDevice device : pairedDevices) {
                Log.d("bonded device",device.getAddress());

                addDevice2List(new Device(device, 0, 0));
            }
        }

        if(!isScaning){

            searchTV.setText(getString(R.string.label_stop_search));

            PHYApplication.getBandUtil().scanDevice();
            isScaning = true;

            handler.sendEmptyMessageDelayed(STOP_SEARCH,20000);
        }
    }

    @AfterPermissionGranted(100)
    private void initRequiredPermission(){
        String[] permissions =new String[]{Manifest.permission.ACCESS_FINE_LOCATION,Manifest.permission.ACCESS_COARSE_LOCATION};
        boolean hasPermissions = EasyPermissions.hasPermissions(this, permissions);
        if (!hasPermissions) {
            EasyPermissions.requestPermissions(this, getString(R.string.label_location_tips),100, permissions);
        }else {
            searchDevice();
        }
    }

    @Override
    public void onRequestPermissionsResult(int requestCode, String[] permissions, int[] grantResults) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults);

        EasyPermissions.onRequestPermissionsResult(requestCode, permissions, grantResults, this);
    }

    @Override
    public void onPermissionsGranted(int requestCode, List<String> perms) {
        searchDevice();
    }

    @Override
    public void onPermissionsDenied(int requestCode, List<String> perms) {
        showToast(R.string.label_location_tips);
    }


    @Override
    protected void onDestroy() {
        super.onDestroy();
        unregisterReceiver(mBluetoothReceiver);

        deviceList.clear();
        if(isScaning){
            PHYApplication.getBandUtil().stopScanDevice();
            isScaning = false;
        }

        handler.removeCallbacksAndMessages(null);
    }

    @Override
    public boolean onSupportNavigateUp() {
        if(isConnecting){
            showToast(R.string.label_connecting_tips);
        }else {
            onBackPressed();
        }

        return true;
    }

    @Override
    public boolean onKeyDown(int keyCode, KeyEvent event) {

        if ((keyCode == KeyEvent.KEYCODE_BACK) && isConnecting) {
            showToast(R.string.label_connecting_tips);
            return false;
        }

        return super.onKeyDown(keyCode, event);
    }

}
