// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.app;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.util.Log;
import io.flutter.plugin.common.*;
import io.flutter.view.FlutterNativeView;
import io.flutter.view.FlutterView;
import io.flutter.view.TextureRegistry;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

public class FlutterPluginRegistry
  implements PluginRegistry,
             PluginRegistry.RequestPermissionResultListener,
             PluginRegistry.RequestPermissionsResultListener,
             PluginRegistry.ActivityResultListener,
             PluginRegistry.NewIntentListener,
             PluginRegistry.UserLeaveHintListener,
             PluginRegistry.ViewDestroyListener {
    private static final String TAG = "FlutterPluginRegistry";

    private Activity mActivity;
    private Context mAppContext;
    private FlutterNativeView mNativeView;
    private FlutterView mFlutterView;

    private final Map<String, Object> mPluginMap = new LinkedHashMap<>(0);
    private final List<RequestPermissionsResultListener> mRequestPermissionsResultListeners = new ArrayList<>(0);
    private final List<ActivityResultListener> mActivityResultListeners = new ArrayList<>(0);
    private final List<NewIntentListener> mNewIntentListeners = new ArrayList<>(0);
    private final List<UserLeaveHintListener> mUserLeaveHintListeners = new ArrayList<>(0);
    private final List<ViewDestroyListener> mViewDestroyListeners = new ArrayList<>(0);

    public FlutterPluginRegistry(FlutterNativeView nativeView, Context context) {
        mNativeView = nativeView;
        mAppContext = context;
    }

    @Override
    public boolean hasPlugin(String key) {
        return mPluginMap.containsKey(key);
    }

    @Override
    @SuppressWarnings("unchecked")
    public <T> T valuePublishedByPlugin(String pluginKey) {
        return (T) mPluginMap.get(pluginKey);
    }

    @Override
    public Registrar registrarFor(String pluginKey) {
        if (mPluginMap.containsKey(pluginKey)) {
            throw new IllegalStateException("Plugin key " + pluginKey + " is already in use");
        }
        mPluginMap.put(pluginKey, null);
        return new FlutterRegistrar(pluginKey);
    }

    public void attach(FlutterView flutterView, Activity activity) {
        mFlutterView = flutterView;
        mActivity = activity;
    }

    public void detach() {
        mFlutterView = null;
        mActivity = null;
    }

    private class FlutterRegistrar implements Registrar {
        private final String pluginKey;

        FlutterRegistrar(String pluginKey) {
            this.pluginKey = pluginKey;
        }

        @Override
        public Activity activity() {
            return mActivity;
        }

        @Override
        public Context context() {
            return mAppContext;
        }

        @Override
        public BinaryMessenger messenger() {
            return mNativeView;
        }

        @Override
        public TextureRegistry textures() {
            return mFlutterView;
        }

        @Override
        public FlutterView view() {
            return mFlutterView;
        }

        @Override
        public Registrar publish(Object value) {
            mPluginMap.put(pluginKey, value);
            return this;
        }

        @Override
        @Deprecated
        public Registrar addRequestPermissionResultListener(
                final RequestPermissionResultListener listener) {
            return addRequestPermissionsResultListener(new RequestPermissionsResultListener() {
                @Override
                public boolean onRequestPermissionsResult(int requestCode, String[] permissions, int[] grantResults) {
                    return listener.onRequestPermissionResult(requestCode, permissions, grantResults);
                }
            });
        }

        @Override
        public Registrar addRequestPermissionsResultListener(
                RequestPermissionsResultListener listener) {
            mRequestPermissionsResultListeners.add(listener);
            return this;
        }

        @Override
        public Registrar addActivityResultListener(ActivityResultListener listener) {
            mActivityResultListeners.add(listener);
            return this;
        }

        @Override
        public Registrar addNewIntentListener(NewIntentListener listener) {
            mNewIntentListeners.add(listener);
            return this;
        }

        @Override
        public Registrar addUserLeaveHintListener(UserLeaveHintListener listener) {
            mUserLeaveHintListeners.add(listener);
            return this;
        }

        @Override
        public Registrar addViewDestroyListener(ViewDestroyListener listener) {
            mViewDestroyListeners.add(listener);
            return this;
        }
    }

    @Override
    public boolean onRequestPermissionsResult(int requestCode, String[] permissions, int[] grantResults) {
        for (RequestPermissionsResultListener listener : mRequestPermissionsResultListeners) {
            if (listener.onRequestPermissionsResult(requestCode, permissions, grantResults)) {
                return true;
            }
        }
        return false;
    }

    @Deprecated
    @Override
    public boolean onRequestPermissionResult(int requestCode, String[] permissions, int[] grantResults) {
      return onRequestPermissionsResult(requestCode, permissions, grantResults);
    }

    @Override
    public boolean onActivityResult(int requestCode, int resultCode, Intent data) {
        for (ActivityResultListener listener : mActivityResultListeners) {
            if (listener.onActivityResult(requestCode, resultCode, data)) {
                return true;
            }
        }
        return false;
    }

    @Override
    public boolean onNewIntent(Intent intent) {
        for (NewIntentListener listener : mNewIntentListeners) {
            if (listener.onNewIntent(intent)) {
                return true;
            }
        }
        return false;
    }

    @Override
    public void onUserLeaveHint() {
        for (UserLeaveHintListener listener : mUserLeaveHintListeners) {
            listener.onUserLeaveHint();
        }
    }

    @Override
    public boolean onViewDestroy(FlutterNativeView view) {
        boolean handled = false;
        for (ViewDestroyListener listener : mViewDestroyListeners) {
            if (listener.onViewDestroy(view)) {
                handled = true;
            }
        }
        return handled;
    }
}
