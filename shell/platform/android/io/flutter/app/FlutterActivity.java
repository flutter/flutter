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
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.PluginRegistry;
import io.flutter.plugin.common.PluginRegistry.Registrar;
import io.flutter.plugin.platform.PlatformPlugin;
import io.flutter.view.FlutterMain;
import io.flutter.view.FlutterView;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * Base class for activities that use Flutter.
 */
public class FlutterActivity extends Activity implements PluginRegistry {
    private final Map<String, Object> pluginMap = new LinkedHashMap<>(0);
    private final List<RequestPermissionResultListener> requestPermissionResultListeners = new ArrayList<>(0);
    private final List<ActivityResultListener> activityResultListeners = new ArrayList<>(0);
    private final List<NewIntentListener> newIntentListeners = new ArrayList<>(0);
    private final List<UserLeaveHintListener> userLeaveHintListeners = new ArrayList<>(0);
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
        if (intent.getBooleanExtra("use-test-fonts", false)) {
            args.add("--use-test-fonts");
        }
        if (intent.getBooleanExtra("enable-dart-profiling", false)) {
            args.add("--enable-dart-profiling");
        }
        if (intent.getBooleanExtra("enable-software-rendering", false)) {
            args.add("--enable-software-rendering");
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

    @Override
    public boolean hasPlugin(String key) {
        return pluginMap.containsKey(key);
    }

    @Override
    @SuppressWarnings("unchecked")
    public <T> T valuePublishedByPlugin(String pluginKey) {
        return (T) pluginMap.get(pluginKey);
    }

    @Override
    public Registrar registrarFor(String pluginKey) {
        if (pluginMap.containsKey(pluginKey)) {
            throw new IllegalStateException("Plugin key " + pluginKey + " is already in use");
        }
        pluginMap.put(pluginKey, null);
        return new FlutterRegistrar(pluginKey);
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
        if (loadIntent(getIntent())) {
            return;
        }
        String appBundlePath = FlutterMain.findAppBundlePath(getApplicationContext());
        if (appBundlePath != null) {
            flutterView.runFromBundle(appBundlePath, null);
            return;
        }
    }

    public void onRequestPermissionsResult(int requestCode, String[] permissions, int[] grantResults) {
        for (RequestPermissionResultListener listener : requestPermissionResultListeners) {
            if (listener.onRequestPermissionResult(requestCode, permissions, grantResults)) {
                return;
            }
        }
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        for (ActivityResultListener listener : activityResultListeners) {
            if (listener.onActivityResult(requestCode, resultCode, data)) {
                return;
            }
        }
    }

    @Override
    protected void onNewIntent(Intent intent) {
        if (!loadIntent(intent)) {
            for (NewIntentListener listener : newIntentListeners) {
                if (listener.onNewIntent(intent)) {
                    return;
                }
            }
        }
    }

    @Override
    public void onUserLeaveHint() {
        for (UserLeaveHintListener listener : userLeaveHintListeners) {
            listener.onUserLeaveHint();
        }
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
     * @return The FlutterView.
     */
    public FlutterView getFlutterView() {
      return flutterView;
    }

    @Override
    public void onTrimMemory(int level) {
        // Use a trim level delivered while the application is running so the
        // framework has a chance to react to the notification.
        if (level == TRIM_MEMORY_RUNNING_LOW)
            flutterView.onMemoryPressure();
    }

    private class FlutterRegistrar implements Registrar  {
        private final String pluginKey;

        FlutterRegistrar(String pluginKey) {
            this.pluginKey = pluginKey;
        }

        public Activity activity() {
            return FlutterActivity.this;
        }

        public BinaryMessenger messenger() {
            return getFlutterView();
        }

        /**
         * Publishes a value associated with the plugin being registered.
         *
         * <p>The published value is available to interested clients via
         * {@link PluginRegistry#valuePublishedByPlugin(String)}.</p>
         *
         * <p>Publication should be done only when there is an interesting value
         * to be shared with other code. This would typically be an instance of
         * the plugin's main class itself that must be wired up to receive
         * notifications or events from an Android API.
         *
         * <p>Overwrites any previously published value.</p>
         */
        public Registrar publish(Object value) {
            pluginMap.put(pluginKey, value);
            return this;
        }

        public Registrar addRequestPermissionResultListener(RequestPermissionResultListener listener) {
            requestPermissionResultListeners.add(listener);
            return this;
        }

        public Registrar addActivityResultListener(ActivityResultListener listener) {
            activityResultListeners.add(listener);
            return this;
        }

        public Registrar addNewIntentListener(NewIntentListener listener) {
            newIntentListeners.add(listener);
            return this;
        }

        public Registrar addUserLeaveHintListener(UserLeaveHintListener listener) {
            userLeaveHintListeners.add(listener);
            return this;
        }
    };
}
