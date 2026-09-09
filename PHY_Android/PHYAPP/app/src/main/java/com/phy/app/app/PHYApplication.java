package com.phy.app.app;

import android.app.Application;

import com.phy.app.ble.BandUtil;
import com.phy.app.thread.ComparePriority;

import java.util.concurrent.Executor;
import java.util.concurrent.PriorityBlockingQueue;
import java.util.concurrent.ThreadPoolExecutor;
import java.util.concurrent.TimeUnit;

/**
 * PUYApplication
 *
 * @author:zhoululu
 * @date:2018/4/14
 */

public class PHYApplication extends Application{

    private static BandUtil bandUtil;
    private String mac;
    private String name;
    private boolean connect;
    private static PHYApplication application;

    @Override
    public void onCreate() {
        super.onCreate();

        application = this;

        bandUtil = BandUtil.getBandUtil(this);
        bandUtil.setBandBleCallBack(BandBleCallBackImpl.getBandBleCallBack());

    }

    public static PHYApplication getApplication(){
        return application;
    }

    public String getMac() {
        return mac;
    }

    public void setMac(String mac) {
        this.mac = mac;
    }

    public static BandUtil getBandUtil() {
        return bandUtil;
    }

    public boolean isConnect() {
        return connect;
    }

    public void setConnect(boolean connect) {
        this.connect = connect;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }
}
