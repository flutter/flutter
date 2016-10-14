// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugin.platform;

import android.app.Activity;
import android.content.Intent;
import android.content.pm.ActivityInfo;
import android.net.Uri;
import android.os.Build;
import android.view.HapticFeedbackConstants;
import android.view.SoundEffectConstants;
import android.view.View;
import io.flutter.plugin.common.ActivityLifecycleListener;
import io.flutter.plugin.common.JSONMessageListener;
import io.flutter.view.FlutterView;
import org.chromium.base.PathUtils;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

/**
 * Android implementation of the platform plugin.
 */
public class PlatformPlugin extends JSONMessageListener implements ActivityLifecycleListener {
    private final Activity mActivity;
    public static final int DEFAULT_SYSTEM_UI = View.SYSTEM_UI_FLAG_LAYOUT_STABLE
            | View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN;

    public PlatformPlugin(Activity activity) {
        mActivity = activity;
        mEnabledOverlays = DEFAULT_SYSTEM_UI;
    }

    @Override
    public JSONObject onJSONMessage(FlutterView view, JSONObject message) throws JSONException {
        String method = message.getString("method");
        JSONArray args = message.getJSONArray("args");
        if (method.equals("SystemSound.play")) {
            playSystemSound(args.getString(0));
        } else if (method.equals("HapticFeedback.vibrate")) {
            vibrateHapticFeedback();
        } else if (method.equals("UrlLauncher.launch")) {
            launchURL(args.getString(0));
        } else if (method.equals("SystemChrome.setPreferredOrientations")) {
            setSystemChromePreferredOrientatations(args.getJSONArray(0));
        } else if (method.equals("SystemChrome.setApplicationSwitcherDescription")) {
            setSystemChromeApplicationSwitcherDescription(args.getJSONObject(0));
        } else if (method.equals("SystemChrome.setEnabledSystemUIOverlays")) {
            setSystemChromeEnabledSystemUIOverlays(args.getJSONArray(0));
        } else if (method.equals("SystemChrome.setSystemUIOverlayStyle")) {
            setSystemChromeSystemUIOverlayStyle(args.getString(0));
        } else if (method.equals("SystemNavigator.pop")) {
            popSystemNavigator();
        } else if (method.equals("PathProvider.getTemporaryDirectory")) {
            return getPathProviderTemporaryDirectory();
        } else if (method.equals("PathProvider.getApplicationDocumentsDirectory")) {
            return getPathProviderApplicationDocumentsDirectory();
        } else {
            // TODO(abarth): We should throw an exception here that gets
            // transmitted back to Dart.
        }
        return null;
    }

    private void playSystemSound(String soundType) {
        if (soundType.equals("SystemSoundType.click")) {
            View view = mActivity.getWindow().getDecorView();
            view.playSoundEffect(SoundEffectConstants.CLICK);
        }
    }

    private void vibrateHapticFeedback() {
        View view = mActivity.getWindow().getDecorView();
        view.performHapticFeedback(HapticFeedbackConstants.LONG_PRESS);
    }

    private void launchURL(String url) {
        try {
            Intent launchIntent = new Intent(Intent.ACTION_VIEW);
            launchIntent.setData(Uri.parse(url));
            mActivity.startActivity(launchIntent);
        } catch (java.lang.Exception exception) {
            // Ignore parsing or ActivityNotFound errors
        }
    }

    private void setSystemChromePreferredOrientatations(JSONArray orientatations) throws JSONException {
        // Currently the Android implementation only supports masks with zero or one
        // selected device orientations.
        int androidOrientation;
        if (orientatations.length() == 0) {
            androidOrientation = ActivityInfo.SCREEN_ORIENTATION_UNSPECIFIED;
        } else if (orientatations.getString(0).equals("DeviceOrientation.portraitUp")) {
            androidOrientation = ActivityInfo.SCREEN_ORIENTATION_PORTRAIT;
        } else if (orientatations.getString(0).equals("DeviceOrientation.landscapeLeft")) {
            androidOrientation = ActivityInfo.SCREEN_ORIENTATION_LANDSCAPE;
        } else if (orientatations.getString(0).equals("DeviceOrientation.portraitDown")) {
            androidOrientation = ActivityInfo.SCREEN_ORIENTATION_REVERSE_PORTRAIT;
        } else if (orientatations.getString(0).equals("DeviceOrientation.landscapeRight")) {
            androidOrientation = ActivityInfo.SCREEN_ORIENTATION_REVERSE_LANDSCAPE;
        } else {
            return;
        }

        mActivity.setRequestedOrientation(androidOrientation);
    }

    private void setSystemChromeApplicationSwitcherDescription(JSONObject description) throws JSONException {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.LOLLIPOP) {
            return;
        }

        int color = description.getInt("primaryColor");
        if (color != 0) { // 0 means color isn't set, use system default
            color = color | 0xFF000000; // color must be opaque if set
        }

        mActivity.setTaskDescription(
                new android.app.ActivityManager.TaskDescription(
                        description.getString("label"),
                        null,
                        color
                )
        );
    }

    private int mEnabledOverlays;

    private void setSystemChromeEnabledSystemUIOverlays(JSONArray overlays) throws JSONException {
        int enabledOverlays = DEFAULT_SYSTEM_UI
            | View.SYSTEM_UI_FLAG_FULLSCREEN
            | View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
            | View.SYSTEM_UI_FLAG_HIDE_NAVIGATION;

         if (overlays.length() == 0) {
             enabledOverlays |= View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY;
         }

        for (int i = 0; i < overlays.length(); ++i) {
            String overlay = overlays.getString(i);
            if (overlay.equals("SystemUiOverlay.top")) {
                enabledOverlays &= ~View.SYSTEM_UI_FLAG_FULLSCREEN;
            } else if (overlay.equals("SystemUiOverlay.bottom"))  {
                enabledOverlays &= ~View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION;
                enabledOverlays &= ~View.SYSTEM_UI_FLAG_HIDE_NAVIGATION;
            }
        }

        mEnabledOverlays = enabledOverlays;
        updateSystemUiOverlays();
    }

    private void updateSystemUiOverlays() {
        mActivity.getWindow().getDecorView().setSystemUiVisibility(mEnabledOverlays);
    }

    private void setSystemChromeSystemUIOverlayStyle(String style) {
        // You can change the navigation bar color (including translucent colors)
        // in Android, but you can't change the color of the navigation buttons,
        // so LIGHT vs DARK effectively isn't supported in Android.
    }

    private void popSystemNavigator() {
        mActivity.finish();
    }

    private JSONObject getPathProviderTemporaryDirectory() throws JSONException {
        JSONObject result = new JSONObject();
        result.put("path", mActivity.getCacheDir().getPath());
        return result;
    }

    private JSONObject getPathProviderApplicationDocumentsDirectory() throws JSONException {
        JSONObject result = new JSONObject();
        result.put("path", PathUtils.getDataDirectory(mActivity));
        return result;
    }

    @Override
    public void onPostResume() {
        updateSystemUiOverlays();
    }
}
