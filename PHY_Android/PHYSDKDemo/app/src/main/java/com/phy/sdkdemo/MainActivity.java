package com.phy.sdkdemo;

import android.Manifest;
import android.bluetooth.BluetoothDevice;
import android.content.Intent;
import android.os.Build;
import android.os.Handler;
import android.os.Message;
import android.support.v7.app.AppCompatActivity;
import android.os.Bundle;
import android.util.Log;
import android.view.View;
import android.widget.AdapterView;
import android.widget.ListView;
import android.widget.Toast;

import com.phy.sdkdemo.ble.BandUtil;
import com.phy.sdkdemo.ble.BleCallBack;
import com.phy.sdkdemo.ble.Device;

import java.util.ArrayList;
import java.util.List;

import pub.devrel.easypermissions.AfterPermissionGranted;
import pub.devrel.easypermissions.EasyPermissions;

public class MainActivity extends AppCompatActivity implements EasyPermissions.PermissionCallbacks{

    private List<Device> deviceList;
    private DeviceListAdapter deviceAdapter;
    Device device;

    boolean isScanning;

    BleCallBack callBack = new BleCallBack() {
        @Override
        public void onScanDevice(BluetoothDevice device, int rssi, byte[] scanRecord) {
            Log.e("device=", device.getAddress()+"**"+device.getName()+"");

            addDevice2List(new Device(device,rssi,1));
        }

        @Override
        public void onConnectDevice(boolean connect) {

            Log.e("MainActivity","connect change");

            if(connect){
                Intent intent = new Intent(MainActivity.this,SecondActivity.class);
                startActivity(intent);

                BandUtil.getBandUtil(getApplicationContext()).setMac(device.getDevice().getAddress());

                finish();

            }else{
                Log.e("MainActivity","connect error");
            }
        }
    };

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        final ListView deviceListView = findViewById(R.id.device_list);
        deviceList = new ArrayList<>();

        deviceAdapter = new DeviceListAdapter(this,R.layout.item_device_list);
        deviceListView.setAdapter(deviceAdapter);

        BandUtil.setBleCallBack(callBack);

        Log.e(getClass().getSimpleName(), "onCreate: "+ String.format("%02X", (Integer.valueOf("00", 16) - 1) & 0xFF));

        deviceListView.setOnItemClickListener(new AdapterView.OnItemClickListener() {
            @Override
            public void onItemClick(AdapterView<?> parent, View view, int position, long id) {

                BandUtil.getBandUtil(getApplicationContext()).stopScanDevice();
                isScanning = false;

                device = (Device) deviceAdapter.getItem(position);

                SdkDemoApplication.getApplication().setDevice(device);

                Intent intent = new Intent(MainActivity.this,SecondActivity.class);
                startActivity(intent);

                BandUtil.getBandUtil(getApplicationContext()).setMac(device.getDevice().getAddress());

            }
        });

    }

    @Override
    protected void onResume() {
        super.onResume();

        if(!isScanning){
            checkSearchDevice();
            isScanning = true;
        }
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();

        BandUtil.getBandUtil(getApplicationContext()).stopScanDevice();
    }

    private void addDevice2List(Device device){

        if(!deviceList.contains(device)){
            deviceList.add(device);
            deviceAdapter.setData(deviceList);
            deviceAdapter.notifyDataSetChanged();
        }
    }

    private void checkSearchDevice(){
        if(Build.VERSION.SDK_INT < Build.VERSION_CODES.M){
            searchDevice();
        }else {
            initRequiredPermission();
        }
    }

    private void searchDevice(){

        deviceList.clear();
        deviceAdapter.setData(deviceList);

        BandUtil.getBandUtil(getApplicationContext()).scanDevice();

    }

    @AfterPermissionGranted(100)
    private void initRequiredPermission(){
        String[] permissions =new String[]{Manifest.permission.ACCESS_FINE_LOCATION,Manifest.permission.ACCESS_COARSE_LOCATION,Manifest.permission.WRITE_EXTERNAL_STORAGE,Manifest.permission.READ_EXTERNAL_STORAGE};
        boolean hasPermissions = EasyPermissions.hasPermissions(this, permissions);
        if (!hasPermissions) {
            EasyPermissions.requestPermissions(this, "地理位置",100, permissions);
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
        Toast.makeText(this,"location error",Toast.LENGTH_SHORT).show();
    }


}
