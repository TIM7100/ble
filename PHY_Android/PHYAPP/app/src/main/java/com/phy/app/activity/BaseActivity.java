package com.phy.app.activity;


import android.app.ActivityManager;
import android.content.Context;
import android.content.res.Configuration;
import android.content.res.Resources;
import android.os.Build;
import android.os.Bundle;
import android.support.annotation.Nullable;
import android.support.annotation.StringRes;
import android.support.v7.app.AppCompatActivity;
import android.support.v7.widget.Toolbar;
import android.view.View;
import android.view.WindowManager;
import android.widget.TextView;
import android.widget.Toast;

import com.phy.app.R;

import org.greenrobot.eventbus.EventBus;
import org.greenrobot.eventbus.Subscribe;
import org.greenrobot.eventbus.ThreadMode;


/**
 * Created by zhoululu on 2017/4/14.
 */

public abstract class BaseActivity extends AppCompatActivity {
    public Toolbar toolbar;

    public String TAG = getClass().getSimpleName();

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setStatusBarLigntMode();

        setContentView(getContentLayout());
        toolbar = (Toolbar) findViewById(R.id.TOOLBAR);

        if (toolbar!=null){
            setSupportActionBar(toolbar);
            getSupportActionBar().setDisplayShowTitleEnabled(false);
            getSupportActionBar().setDisplayHomeAsUpEnabled(true);
        }

        initComponent();

    }

    public boolean onSupportNavigateUp() {
        onBackPressed();
        return true;
    }

    private void setStatusBarLigntMode(){
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            getWindow().getDecorView().setSystemUiVisibility(View.SYSTEM_UI_FLAG_LIGHT_STATUS_BAR);
        }
    }
    private void setStatusBarDarkMode(){
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            getWindow().getDecorView().setSystemUiVisibility(View.SYSTEM_UI_FLAG_VISIBLE);
        }
    }
    public  abstract void initComponent();
    public  abstract int getContentLayout();

    public void setStatusBarColor(int color) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            getWindow().setStatusBarColor(color);
            getWindow().addFlags(WindowManager.LayoutParams.FLAG_TRANSLUCENT_STATUS);
        }
    }

    public void setStatusBarColorOnly(int color) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            getWindow().setStatusBarColor(color);
        }
    }

    public void clearStatusBarColor() {
        setStatusBarColor(android.R.color.transparent);
        setStatusBarDarkMode();
    }


    public void setTitle(String t) {
        if (toolbar != null) {
            ((TextView) toolbar.findViewById(R.id.title)).setText(t);
        }
    }

    public void setTitle(int t) {
        setTitle(getString(t));
    }

    public void setNavigationIcon(int icon){
        if(toolbar != null){
            toolbar.setNavigationIcon(icon);
        }
    }

    public void setDisplayHomeAsUpEnabled(boolean f) {
        getSupportActionBar().setDisplayHomeAsUpEnabled(f);
    }

    public void showToast(  String text){
        Toast.makeText(this, text,Toast.LENGTH_SHORT).show();
    }

    public void showToast(@StringRes  int resId){
        showToast(getString(resId));
    }


    @Override
    public Resources getResources() {

        Resources res = super.getResources();
        Configuration config=new Configuration();
        config.setToDefaults();
        res.updateConfiguration(config,res.getDisplayMetrics());
        return res;
    }
}
