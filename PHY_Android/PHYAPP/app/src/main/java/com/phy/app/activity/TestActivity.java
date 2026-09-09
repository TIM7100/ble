package com.phy.app.activity;

import android.app.Activity;
import android.os.Bundle;
import android.support.annotation.Nullable;

import com.phy.app.R;

import java.lang.reflect.AccessibleObject;

/**
 * TestActivity
 *
 * @author:zhoululu
 * @date:2018/5/4
 */

public class TestActivity extends Activity{

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        setContentView(R.layout.activity_test);
    }
}
