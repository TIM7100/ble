package com.phy.app.activity;

import android.os.Bundle;
import android.support.annotation.Nullable;
import android.util.Log;

import org.greenrobot.eventbus.EventBus;
import org.greenrobot.eventbus.Subscribe;
import org.greenrobot.eventbus.ThreadMode;

/**
 * EventBusBaseActivity
 *
 * @author:zhoululu
 * @date:2018/4/13
 */

public abstract class EventBusBaseActivity extends BaseActivity{

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        register(this);
    }


    @Override
    protected void onDestroy() {
        super.onDestroy();

        unregister(this);
    }

    @Subscribe(threadMode= ThreadMode.MAIN)
    public void onMessageEvent(String event) {

    }


    private void register(Object object){

        if (!EventBus.getDefault().isRegistered(object)) {
            EventBus.getDefault().register(object);

            Log.e(TAG, "register: ");
        }
    }

    private void unregister(Object object){
        if (EventBus.getDefault().isRegistered(object)){
            EventBus.getDefault().unregister(object);

            Log.e(TAG, "unregister");
        }
    }
}
