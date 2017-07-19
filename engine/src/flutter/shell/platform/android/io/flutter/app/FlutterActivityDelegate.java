// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.app;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.content.pm.ApplicationInfo;
import android.content.res.Configuration;
import android.os.Build;
import android.os.Bundle;
import android.view.Window;
import android.view.WindowManager;
import android.view.WindowManager.LayoutParams;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.PluginRegistry;
import io.flutter.plugin.common.PluginRegistry.ActivityResultListener;
import io.flutter.plugin.common.PluginRegistry.Registrar;
import io.flutter.plugin.common.PluginRegistry.RequestPermissionResultListener;
import io.flutter.plugin.platform.PlatformPlugin;
import io.flutter.util.Preconditions;
import io.flutter.view.FlutterMain;
import io.flutter.view.FlutterView;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * Class that performs the actual work of tying Android {@link Activity}
 * instances to Flutter.
 *
 * <p>This exists as a dedicated class (as opposed to being integrated directly
 * into {@link FlutterActivity}) to facilitate applications that don't wish
 * to subclass {@code FlutterActivity}. The most obvious example of when this
 * may come in handy is if an application wishes to subclass the Android v4
 * support library's {@code FragmentActivity}.</p>
 *
 * <h3>Usage:</h3>
 * <p>To wire this class up to your activity, simply forward the events defined
 * in {@link FlutterActivityEvents} from your activity to an instance of this
 * class. Optionally, you can make your activity implement
 * {@link PluginRegistry} and/or {@link io.flutter.view.FlutterView.Provider}
 * and forward those methods to this class as well.</p>
 */
public final class FlutterActivityDelegate
        implements FlutterActivityEvents,
                   FlutterView.Provider,
                   PluginRegistry {
    /**
     * Specifies the mechanism by which Flutter views are created during the
     * operation of a {@code FlutterActivityDelegate}.
     *
     * <p>A delegate's view factory will be consulted during
     * {@link #onCreate(Bundle)}. If it returns {@code null}, then the delegate
     * will fall back to instantiating a new full-screen {@code FlutterView}.</p>
     */
    public interface ViewFactory {
        FlutterView createFlutterView(Context context);
    }

    private final Activity activity;
    private final ViewFactory viewFactory;
    private final Map<String, Object> pluginMap = new LinkedHashMap<>(0);
    private final List<RequestPermissionResultListener> requestPermissionResultListeners = new ArrayList<>(0);
    private final List<ActivityResultListener> activityResultListeners = new ArrayList<>(0);
    private final List<NewIntentListener> newIntentListeners = new ArrayList<>(0);
    private final List<UserLeaveHintListener> userLeaveHintListeners = new ArrayList<>(0);

    private FlutterView flutterView;

    public FlutterActivityDelegate(Activity activity, ViewFactory viewFactory) {
        this.activity = Preconditions.checkNotNull(activity);
        this.viewFactory = Preconditions.checkNotNull(viewFactory);
    }

    @Override
    public FlutterView getFlutterView() {
        return flutterView;
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

    @Override
    public boolean onRequestPermissionResult(
            int requestCode, String[] permissions, int[] grantResults) {
        for (RequestPermissionResultListener listener : requestPermissionResultListeners) {
            if (listener.onRequestPermissionResult(requestCode, permissions, grantResults)) {
                return true;
            }
        }
        return false;
    }

    @Override
    public boolean onActivityResult(int requestCode, int resultCode, Intent data) {
        for (ActivityResultListener listener : activityResultListeners) {
            if (listener.onActivityResult(requestCode, resultCode, data)) {
                return true;
            }
        }
        return false;
    }

    @Override
    public void onCreate(Bundle savedInstanceState) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            Window window = activity.getWindow();
            window.addFlags(LayoutParams.FLAG_DRAWS_SYSTEM_BAR_BACKGROUNDS);
            window.setStatusBarColor(0x40000000);
            window.getDecorView().setSystemUiVisibility(PlatformPlugin.DEFAULT_SYSTEM_UI);
        }

        String[] args = getArgsFromIntent(activity.getIntent());
        FlutterMain.ensureInitializationComplete(activity.getApplicationContext(), args);

        flutterView = viewFactory.createFlutterView(activity);
        if (flutterView == null) {
            flutterView = new FlutterView(activity);
            flutterView.setLayoutParams(
                    new LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT));
            activity.setContentView(flutterView);
        }

        if (loadIntent(activity.getIntent())) {
            return;
        }
        String appBundlePath = FlutterMain.findAppBundlePath(activity.getApplicationContext());
        if (appBundlePath != null) {
            flutterView.runFromBundle(appBundlePath, null);
        }
    }

    @Override
    public void onNewIntent(Intent intent) {
        // Only attempt to reload the Flutter Dart code during development. Use
        // the debuggable flag as an indicator that we are in development mode.
        if (!isDebuggable() || !loadIntent(intent)) {
            for (NewIntentListener listener : newIntentListeners) {
                if (listener.onNewIntent(intent)) {
                    return;
                }
            }
        }
    }

    private boolean isDebuggable() {
        return (activity.getApplicationInfo().flags & ApplicationInfo.FLAG_DEBUGGABLE) != 0;
    }

    @Override
    public void onPause() {
        if (flutterView != null) {
            flutterView.onPause();
        }
    }

    @Override
    public void onResume() {
    }

    @Override
    public void onPostResume() {
        if (flutterView != null) {
            flutterView.onPostResume();
        }
    }

    @Override
    public void onDestroy() {
        if (flutterView != null) {
            flutterView.destroy();
        }
    }

    @Override
    public boolean onBackPressed() {
        if (flutterView != null) {
            flutterView.popRoute();
            return true;
        }
        return false;
    }

    @Override
    public void onUserLeaveHint() {
    }

    @Override
    public void onTrimMemory(int level) {
        // Use a trim level delivered while the application is running so the
        // framework has a chance to react to the notification.
        if (level == TRIM_MEMORY_RUNNING_LOW) {
            flutterView.onMemoryPressure();
        }
    }

    @Override
    public void onLowMemory() {
        flutterView.onMemoryPressure();
    }

    @Override
    public void onConfigurationChanged(Configuration newConfig) {
    }

    private static String[] getArgsFromIntent(Intent intent) {
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

    private boolean loadIntent(Intent intent) {
        String action = intent.getAction();
        if (Intent.ACTION_RUN.equals(action)) {
            String route = intent.getStringExtra("route");
            String appBundlePath = intent.getDataString();
            if (appBundlePath == null) {
                // Fall back to the installation path if no bundle path
                // was specified.
                appBundlePath = FlutterMain.findAppBundlePath(activity.getApplicationContext());
            }
            if (route != null) {
                flutterView.setInitialRoute(route);
            }
            flutterView.runFromBundle(appBundlePath, intent.getStringExtra("snapshot"));
            return true;
        }

        return false;
    }

    private class FlutterRegistrar implements Registrar {
        private final String pluginKey;

        FlutterRegistrar(String pluginKey) {
            this.pluginKey = pluginKey;
        }

        @Override
        public Activity activity() {
            return activity;
        }

        @Override
        public BinaryMessenger messenger() {
            return flutterView;
        }

        @Override
        public FlutterView view() {
            return flutterView;
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
        @Override
        public Registrar publish(Object value) {
            pluginMap.put(pluginKey, value);
            return this;
        }

        @Override
        public Registrar addRequestPermissionResultListener(
                RequestPermissionResultListener listener) {
            requestPermissionResultListeners.add(listener);
            return this;
        }

        @Override
        public Registrar addActivityResultListener(ActivityResultListener listener) {
            activityResultListeners.add(listener);
            return this;
        }

        @Override
        public Registrar addNewIntentListener(NewIntentListener listener) {
            newIntentListeners.add(listener);
            return this;
        }

        @Override
        public Registrar addUserLeaveHintListener(UserLeaveHintListener listener) {
            userLeaveHintListeners.add(listener);
            return this;
        }
    }
}
