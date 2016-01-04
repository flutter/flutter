// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.domokit.sky.shell;

import android.app.Activity;
import android.content.Intent;
import android.content.res.Configuration;
import android.os.Build;
import android.os.Bundle;
import android.view.View;
import android.view.WindowManager;

import org.chromium.base.PathUtils;
import org.chromium.base.TraceEvent;
import org.chromium.mojom.sky.AppLifecycleState;
import org.chromium.mojom.sky.EventType;
import org.chromium.mojom.sky.InputEvent;

import org.domokit.activity.ActivityImpl;

import java.io.File;
import java.util.ArrayList;
import java.util.Locale;


/**
 * Base class for activities that use Sky.
 */
public class SkyActivity extends Activity {
    private TracingController mTracingController;
    private PlatformViewAndroid mView;

    private String[] getArgsFromIntent(Intent intent) {
        // Before adding more entries to this list, consider that arbitrary
        // Android applications can generate intents with extra data and that
        // there are many security-sensitive args in the binary.
        ArrayList<String> args = new ArrayList<String>();
        if (intent.getBooleanExtra("enable-checked-mode", false)) {
            args.add("--enable-checked-mode");
        }
        if (intent.getBooleanExtra("trace-startup", false)) {
            args.add("--trace-startup");
        }
        if (!args.isEmpty()) {
            String[] argsArray = new String[args.size()];
            return args.toArray(argsArray);
        }
        return null;
    }

    /**
     * @see android.app.Activity#onCreate(android.os.Bundle)
     */
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        PlatformViewAndroid.EdgeDims edgeDims = new PlatformViewAndroid.EdgeDims();

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            getWindow().addFlags(WindowManager.LayoutParams.FLAG_DRAWS_SYSTEM_BAR_BACKGROUNDS);
            getWindow().setStatusBarColor(0x40000000);
        }
        // TODO(abarth): We should get this value from the Android framework somehow.
        edgeDims.top = 25.0;
        // TODO(abarth): Unclear if we want to use fullscreen if we don't have
        // a transparent system bar.
        getWindow().getDecorView().setSystemUiVisibility(
                View.SYSTEM_UI_FLAG_LAYOUT_STABLE
                | View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN);

        String[] args = getArgsFromIntent(getIntent());
        SkyMain.ensureInitialized(getApplicationContext(), args);
        mView = new PlatformViewAndroid(this, edgeDims);
        ActivityImpl.setCurrentActivity(this);
        setContentView(mView);
        mTracingController = new TracingController(this);

        onSkyReady();
    }

    /**
     * @see android.app.Activity#onDestroy()
     */
    @Override
    protected void onDestroy() {
        if (mView != null) {
            mView.destroy();
        }
        // Do we need to shut down Sky too?
        mTracingController.stop();
        super.onDestroy();
    }

    @Override
    public void onBackPressed() {
        if (mView != null) {
            mView.getEngine().popRoute();
            return;
        }
        super.onBackPressed();
    }

    @Override
    protected void onPause() {
        super.onPause();
        if (mView != null) {
            mView.getEngine().onAppLifecycleStateChanged(AppLifecycleState.PAUSED);
        }
    }

    @Override
    protected void onResume() {
        super.onResume();
        ActivityImpl.onResumeActivity(this);
    }

    @Override
    protected void onPostResume() {
        super.onPostResume();
        if (mView != null) {
            mView.getEngine().onAppLifecycleStateChanged(AppLifecycleState.RESUMED);
        }
    }

    /**
      * Override this function to customize startup behavior.
      */
    protected void onSkyReady() {
        TraceEvent.instant("SkyActivity.onSkyReady");

        Locale locale = getResources().getConfiguration().locale;
        mView.getEngine().onLocaleChanged(locale.getLanguage(),
                                          locale.getCountry());

        if (loadIntent(getIntent())) {
            return;
        }
        File dataDir = new File(PathUtils.getDataDirectory(this));
        File appBundle = new File(dataDir, SkyApplication.APP_BUNDLE);
        if (appBundle.exists()) {
            mView.getEngine().runFromBundle(appBundle.getPath());
            return;
        }
    }

    protected void onNewIntent(Intent intent) {
        loadIntent(intent);
    }

    public boolean loadIntent(Intent intent) {
        String action = intent.getAction();

        if (Intent.ACTION_RUN.equals(action)) {
            mView.getEngine().runFromBundle(intent.getDataString());
            String route = intent.getStringExtra("route");
            if (route != null)
                mView.getEngine().pushRoute(route);
            return true;
        }

        return false;
    }

    public boolean loadBundleByName(String name) {
        File dataDir = new File(PathUtils.getDataDirectory(this));
        File bundle = new File(dataDir, name);
        if (!bundle.exists()) {
            return false;
        }
        mView.getEngine().runFromBundle(bundle.getPath());
        return true;
    }

    public void onConfigurationChanged(Configuration newConfig) {
	super.onConfigurationChanged(newConfig);

        Locale locale = getResources().getConfiguration().locale;
        mView.getEngine().onLocaleChanged(locale.getLanguage(),
                                          locale.getCountry());
    }
}
