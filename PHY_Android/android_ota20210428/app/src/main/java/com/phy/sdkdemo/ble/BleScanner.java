package com.phy.sdkdemo.ble;

import android.annotation.TargetApi;
import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothManager;
import android.bluetooth.le.ScanCallback;
import android.bluetooth.le.ScanResult;
import android.content.Context;
import android.os.Build;
import android.util.Log;

import java.nio.ByteBuffer;
import java.nio.ByteOrder;

import no.nordicsemi.android.support.v18.scanner.BluetoothLeScannerCompat;

/**
 * （BLE）低功耗蓝牙扫描
 * Created by zhoululu on 2017/6/21.
 */

public class BleScanner {

    String TAG = getClass().getSimpleName();

    //private MyLeScanCallback leScanCallback;
    //private MyScanCallBack scanCallBack;

    private no.nordicsemi.android.support.v18.scanner.ScanCallback scanCallback = new no.nordicsemi.android.support.v18.scanner.ScanCallback() {

        /**
         * 扫描结果
         * @param callbackType 回调类型
         * @param result 结果
         */
        @Override
        public void onScanResult(int callbackType, no.nordicsemi.android.support.v18.scanner.ScanResult result) {
            if(BandUtil.bleCallBack != null){
                BandUtil.bleCallBack.onScanDevice(result.getDevice(),result.getRssi(),result.getScanRecord().getBytes());
            }else {
                throw  new RuntimeException("bleCallBack is null");
            }
        }

        @Override
        public void onScanFailed(int errorCode) {
            throw  new RuntimeException("Scan error");
        }
    };

    private Context context;

    public BleScanner(Context context) {
        this.context = context;
    }

    public void scanDevice(){

        BluetoothLeScannerCompat scanner = BluetoothLeScannerCompat.getScanner();
        scanner.startScan(scanCallback);
    }

    public void stopScanDevice(){
        BluetoothLeScannerCompat scanner = BluetoothLeScannerCompat.getScanner();
        scanner.stopScan(scanCallback);
    }

    class MyLeScanCallback implements BluetoothAdapter.LeScanCallback{

        @Override
        public void onLeScan(BluetoothDevice device, int rssi, byte[] scanRecord) {
            if(BandUtil.bleCallBack != null){
                BandUtil.bleCallBack.onScanDevice(device,rssi,scanRecord);

                Log.e(TAG, "onLeScan: " );

            }else {
                throw  new RuntimeException("bleCallBack is null");
            }
        }
    }

    @TargetApi(Build.VERSION_CODES.LOLLIPOP)
    class MyScanCallBack extends ScanCallback {
        @Override
        public void onScanResult(int callbackType, ScanResult result) {
            if (BandUtil.bleCallBack != null) {
                BandUtil.bleCallBack.onScanDevice(result.getDevice(), result.getRssi(), result.getScanRecord().getBytes());

                Log.e(TAG, "onScanResult: ");
            } else {
                throw new RuntimeException("bleCallBack is null");
            }
        }
    }



}
