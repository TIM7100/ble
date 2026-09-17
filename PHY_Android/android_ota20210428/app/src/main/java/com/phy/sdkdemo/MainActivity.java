package com.phy.sdkdemo;

import android.Manifest;
import android.app.AlertDialog;
import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothManager;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.DialogInterface;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.SharedPreferences;
import android.nfc.Tag;
import android.os.Build;
import android.support.annotation.Nullable;
import android.support.v7.app.AppCompatActivity;
import android.os.Bundle;
import android.util.Log;
import android.view.Menu;
import android.view.MenuInflater;
import android.view.MenuItem;
import android.view.View;
import android.widget.AdapterView;
import android.widget.EditText;
import android.widget.ListView;
import android.widget.PopupMenu;
import android.widget.Toast;

import com.google.gson.Gson;
import com.phy.ota.sdk.OTASDKUtils;
import com.phy.sdkdemo.ble.BandUtil;
import com.phy.sdkdemo.ble.BleCallBack;
import com.phy.sdkdemo.ble.BleUtils;
import com.phy.sdkdemo.ble.Device;

import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.util.ArrayList;
import java.util.List;

import pub.devrel.easypermissions.AfterPermissionGranted;
import pub.devrel.easypermissions.EasyPermissions;

public class MainActivity extends AppCompatActivity implements EasyPermissions.PermissionCallbacks {

    private static final int REQUEST_ENABLE_BLUETOOTH = 1;
    private List<Device> deviceList;
    private DeviceListAdapter deviceAdapter;
    Device device;
    boolean isScanning;

    PopupMenu popupMenu = null;
    private OTASDKUtils otasdkUtils;

    BleCallBack callBack = new BleCallBack() {
        @Override
        public void onScanDevice(BluetoothDevice device, int rssi, byte[] scanRecord) {
            String realName = BleUtils.parseDeviceName(scanRecord);
            addDevice2List(new Device(device, rssi, 1, realName));
        }

        @Override
        public void onConnectDevice(boolean connect) {
            Log.e("MainActivity", "connect change");
        }
    };

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);


        final ListView deviceListView = findViewById(R.id.device_list);
        deviceList = new ArrayList<>();

        deviceAdapter = new DeviceListAdapter(this, R.layout.item_device_list);
        deviceListView.setAdapter(deviceAdapter);

        BandUtil.setBleCallBack(callBack);

        Log.e(getClass().getSimpleName(), "onCreate: " + String.format("%02X", (Integer.valueOf("00", 16) - 1) & 0xFF));

        deviceListView.setOnItemClickListener(new AdapterView.OnItemClickListener() {
            @Override
            public void onItemClick(AdapterView<?> parent, View view, int position, long id) {

                BandUtil.getBandUtil(getApplicationContext()).stopScanDevice();
                isScanning = false;

                device = (Device) deviceAdapter.getItem(position);

                SdkDemoApplication.getApplication().setDevice(device);
                //otasdkUtils.connectDevice(device.getDevice().getAddress());

                Intent intent = new Intent(MainActivity.this, AutoActivity.class);
                startActivity(intent);

                BandUtil.getBandUtil(getApplicationContext()).setMac(device.getDevice().getAddress());

            }
        });

        IntentFilter filter = new IntentFilter(BluetoothAdapter.ACTION_STATE_CHANGED);
        registerReceiver(receiver, filter);
    }

    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        MenuInflater inflater = getMenuInflater();
        inflater.inflate(R.menu.main, menu);
        return true;
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        switch (item.getItemId()) {
            case R.id.action_change://监听菜单按钮
                changeKey();
                break;

            case R.id.action_check:
                SharedPreferences sp = getSharedPreferences("data", MODE_PRIVATE);
                String keyValue = sp.getString("AESKey", "未设置，空的");
                Toast.makeText(MainActivity.this, keyValue, Toast.LENGTH_LONG).show();
                break;
        }
        return super.onOptionsItemSelected(item);
    }

    private void changeKey() {
        final EditText inputServer = new EditText(this);
        AlertDialog.Builder builder = new AlertDialog.Builder(this);
        builder.setTitle("请输入16字节密钥").setIcon(android.R.drawable.ic_dialog_info).setView(inputServer)
                .setNegativeButton("Cancel", null);
        builder.setPositiveButton("Ok", new DialogInterface.OnClickListener() {
            @Override
            public void onClick(DialogInterface dialog, int which) {
                String keyValue = inputServer.getText().toString();
                if (keyValue.length() == 32) {
                    Toast.makeText(MainActivity.this, keyValue, Toast.LENGTH_LONG).show();
                    SharedPreferences.Editor editor = getSharedPreferences("data", MODE_PRIVATE).edit();
                    editor.putString("AESKey", keyValue);
                    editor.commit();
                } else {
                    Toast.makeText(MainActivity.this, "数据长度不对", Toast.LENGTH_LONG).show();
                }
            }
        });
        builder.show();
    }

    @Override
    protected void onResume() {
        super.onResume();

        if (!isScanning) {
            checkSearchDevice();
            isScanning = true;
        }
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();

        BandUtil.getBandUtil(getApplicationContext()).stopScanDevice();
    }

    private void addDevice2List(Device device) {
        if (device.getDevice().getName() == null) return;
        if (!deviceList.contains(device)) {
            deviceList.add(device);

            deviceAdapter.setData(deviceList);
            deviceAdapter.notifyDataSetChanged();
        }
    }

    private void checkSearchDevice() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
            searchDevice();
        } else {
            initRequiredPermission();
        }
    }

    private void searchDevice() {
        deviceList.clear();
        deviceAdapter.setData(deviceList);

        if (isBleOpen()) {
            BandUtil.getBandUtil(getApplicationContext()).scanDevice();
        } else {
            Intent intent = new Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE);
            startActivityForResult(intent, REQUEST_ENABLE_BLUETOOTH);
        }
    }

    private boolean isBleOpen() {
        BluetoothManager mBluetoothManager = (BluetoothManager) getApplicationContext().getSystemService(Context.BLUETOOTH_SERVICE);
        if (mBluetoothManager == null) return false;
        BluetoothAdapter adapter = mBluetoothManager.getAdapter();
        if (adapter == null) return false;

        return adapter.isEnabled();
    }

    private BroadcastReceiver receiver = new BroadcastReceiver() {
        @Override
        public void onReceive(Context context, Intent intent) {
            final String action = intent.getAction();
            if (action.equals(BluetoothAdapter.ACTION_STATE_CHANGED)) {
                final int state = intent.getIntExtra(BluetoothAdapter.EXTRA_STATE,
                        BluetoothAdapter.ERROR);
                switch (state) {
                    case BluetoothAdapter.STATE_OFF:
                        BandUtil.getBandUtil(getApplicationContext()).stopScanDevice();
                        enableBluetooth(true);
                        break;
                    case BluetoothAdapter.STATE_TURNING_OFF:
                        break;
                    case BluetoothAdapter.STATE_ON:
                        //to check if BluetoothAdapter is enable by your code
                        searchDevice();//蓝牙打开
                        break;
                    case BluetoothAdapter.STATE_TURNING_ON:
                        break;
                    default:
                        break;
                }
            }
        }
    };

    /**
     * 启用蓝牙
     *
     * @param enable
     * @return
     */
    public boolean enableBluetooth(boolean enable) {
        BluetoothManager mBluetoothManager = (BluetoothManager) getApplicationContext().getSystemService(Context.BLUETOOTH_SERVICE);
        BluetoothAdapter mBluetoothAdapter = mBluetoothManager.getAdapter();
        if (mBluetoothAdapter == null) return false;
        if (enable) {
            if (!mBluetoothAdapter.isEnabled()) {
                return mBluetoothAdapter.enable();
            }
            return true;
        } else {
            if (mBluetoothAdapter.isEnabled()) {
                return mBluetoothAdapter.disable();
            }
            return false;
        }
    }

    @AfterPermissionGranted(100)
    private void initRequiredPermission() {
        String[] permissions = new String[]{Manifest.permission.ACCESS_FINE_LOCATION,
                Manifest.permission.ACCESS_COARSE_LOCATION,
                Manifest.permission.WRITE_EXTERNAL_STORAGE,
                Manifest.permission.READ_EXTERNAL_STORAGE};
        boolean hasPermissions = EasyPermissions.hasPermissions(this, permissions);
        if (!hasPermissions) {
            EasyPermissions.requestPermissions(this, "地理位置", 100, permissions);
        } else {
            searchDevice();//权限通过
        }
    }

    @Override
    public void onRequestPermissionsResult(int requestCode, String[] permissions, int[] grantResults) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults);

        EasyPermissions.onRequestPermissionsResult(requestCode, permissions, grantResults, this);
    }

    @Override
    public void onPermissionsGranted(int requestCode, List<String> perms) {
        searchDevice();//权限通过
    }

    @Override
    public void onPermissionsDenied(int requestCode, List<String> perms) {
        Toast.makeText(this, "location error", Toast.LENGTH_SHORT).show();
    }

}
