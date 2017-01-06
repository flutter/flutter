// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.app;

import android.app.Activity;
import android.content.Intent;
import android.os.Build;
import android.os.Bundle;
import android.view.Window;
import android.view.WindowManager;
import io.flutter.plugin.platform.PlatformPlugin;
import io.flutter.view.FlutterMain;
import io.flutter.view.FlutterView;
import java.util.ArrayList;
import org.chromium.base.TraceEvent;


/**
 * Base class for activities that use Flutter.
 */
public class FlutterActivity extends Activity {
    private FlutterView flutterView;

    private String[] getArgsFromIntent(Intent intent) {
        // Before adding more entries to this list, consider that arbitrary
        // Android applications can generate intents with extra data and that
        // there are many security-sensitive args in the binary.
        ArrayList<String> args = new ArrayList<String>();
        if (intent.getBooleanExtra("trace-startup", false)) {
            args.add("--trace-startup");
        }
        if (intent.getBooleanExtra("start-paused", false)) {
            args.add("--start-paused");
        }
        if (intent.getBooleanExtra("enable-dart-profiling", false)) {
            args.add("--enable-dart-profiling");
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

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            Window window = getWindow();
            window.addFlags(WindowManager.LayoutParams.FLAG_DRAWS_SYSTEM_BAR_BACKGROUNDS);
            window.setStatusBarColor(0x40000000);
            window.getDecorView().setSystemUiVisibility(PlatformPlugin.DEFAULT_SYSTEM_UI);
        }

        String[] args = getArgsFromIntent(getIntent());
        FlutterMain.ensureInitializationComplete(getApplicationContext(), args);
        flutterView = new FlutterView(this);
        setContentView(flutterView);

        onFlutterReady();
    }

    /**
     * @see android.app.Activity#onDestroy()
     */
    @Override
    protected void onDestroy() {
        if (flutterView != null) {
            flutterView.destroy();
        }
        super.onDestroy();
    }

    @Override
    public void onBackPressed() {
        if (flutterView != null) {
            flutterView.popRoute();
            return;
        }
        super.onBackPressed();
    }

    @Override
    protected void onPause() {
        super.onPause();
        if (flutterView != null) {
            flutterView.onPause();
        }
    }

    @Override
    protected void onPostResume() {
        super.onPostResume();
        if (flutterView != null) {
            flutterView.onPostResume();
        }
    }

    /**
      * Override this function to customize startup behavior.
      */
    protected void onFlutterReady() {
        TraceEvent.instant("FlutterActivity.onFlutterReady");

        if (loadIntent(getIntent())) {
            return;
        }
        String appBundlePath = FlutterMain.findAppBundlePath(getApplicationContext());
        if (appBundlePath != null) {
            flutterView.runFromBundle(appBundlePath, null);
            return;
        }
    }

    protected void onNewIntent(Intent intent) {
        loadIntent(intent);
    }

    public boolean loadIntent(Intent intent) {
        String action = intent.getAction();
        if (Intent.ACTION_RUN.equals(action)) {
            String route = intent.getStringExtra("route");
            String appBundlePath = intent.getDataString();
            if (appBundlePath == null) {
              // Fall back to the installation path if no bundle path
              // was specified.
              appBundlePath =
                  FlutterMain.findAppBundlePath(getApplicationContext());
            }
            flutterView.runFromBundle(appBundlePath,
                                intent.getStringExtra("snapshot"));
            if (route != null)
                flutterView.pushRoute(route);
            return true;
        }

        return false;
    }

    /**
     * Returns the Flutter view used by this activity, may be null before
     * onCreate was called.
     */
    public FlutterView getFlutterView() {
      return flutterView;
    }
}
