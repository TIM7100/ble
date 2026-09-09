package com.phy.sdkdemo;

import android.app.Application;

import com.phy.sdkdemo.ble.Device;

/**
 * SdkDemoApplication
 *
 * @author:zhoululu
 * @date:2018/7/8
 */

public class SdkDemoApplication extends Application{

    private static SdkDemoApplication application;
    private Device device;

    public Device getDevice() {
        return device;
    }

    public void setDevice(Device device) {
        this.device = device;
    }

    @Override
    public void onCreate() {
        super.onCreate();

        application = this;
    }

    public static SdkDemoApplication getApplication() {
        return application;
    }
}
