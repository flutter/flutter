// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugin.platform;

import android.app.Activity;
import android.content.ClipboardManager;
import android.content.ClipData;
import android.content.ClipDescription;
import android.content.Context;
import android.content.Intent;
import android.content.pm.ActivityInfo;
import android.net.Uri;
import android.os.Build;
import android.view.HapticFeedbackConstants;
import android.view.SoundEffectConstants;
import android.view.View;

import io.flutter.plugin.common.ActivityLifecycleListener;
import io.flutter.plugin.common.FlutterMethodChannel.MethodCallHandler;
import io.flutter.plugin.common.FlutterMethodChannel.Response;
import io.flutter.plugin.common.MethodCall;

import org.chromium.base.PathUtils;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

/**
 * Android implementation of the platform plugin.
 */
public class PlatformPlugin implements MethodCallHandler, ActivityLifecycleListener {
    private final Activity mActivity;
    public static final int DEFAULT_SYSTEM_UI = View.SYSTEM_UI_FLAG_LAYOUT_STABLE
            | View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN;
    private static final String kTextPlainFormat = "text/plain";

    public PlatformPlugin(Activity activity) {
        mActivity = activity;
        mEnabledOverlays = DEFAULT_SYSTEM_UI;
    }

    @Override
    public void onMethodCall(MethodCall call, Response response) {
        String method = call.method;
        Object arguments = call.arguments;
        try {
            if (method.equals("SystemSound.play")) {
                playSystemSound((String) arguments);
                response.success(null);
            } else if (method.equals("HapticFeedback.vibrate")) {
                vibrateHapticFeedback();
                response.success(null);
            } else if (method.equals("UrlLauncher.launch")) {
                launchURL((String) arguments);
                response.success(null);
            } else if (method.equals("SystemChrome.setPreferredOrientations")) {
                setSystemChromePreferredOrientations((JSONArray) arguments);
                response.success(null);
            } else if (method.equals("SystemChrome.setApplicationSwitcherDescription")) {
                setSystemChromeApplicationSwitcherDescription((JSONObject) arguments);
                response.success(null);
            } else if (method.equals("SystemChrome.setEnabledSystemUIOverlays")) {
                setSystemChromeEnabledSystemUIOverlays((JSONArray) arguments);
                response.success(null);
            } else if (method.equals("SystemChrome.setSystemUIOverlayStyle")) {
                setSystemChromeSystemUIOverlayStyle((String) arguments);
                response.success(null);
            } else if (method.equals("SystemNavigator.pop")) {
                popSystemNavigator();
                response.success(null);
            } else if (method.equals("Clipboard.getData")) {
                response.success(getClipboardData((String) arguments));
            } else if (method.equals("Clipboard.setData")) {
                setClipboardData((JSONObject) arguments);
                response.success(null);
            } else if (method.equals("PathProvider.getTemporaryDirectory")) {
                response.success(getPathProviderTemporaryDirectory());
            } else if (method.equals("PathProvider.getApplicationDocumentsDirectory")) {
                response.success(getPathProviderApplicationDocumentsDirectory());
            } else {
                response.error("unknown", "Unknown method: " + method, null);
            }
        } catch (JSONException e) {
            response.error("error", "JSON error: " + e.getMessage(), null);
        }
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

    private void setSystemChromePreferredOrientations(JSONArray orientations) throws JSONException {
        // Currently the Android implementation only supports masks with zero or one
        // selected device orientations.
        int androidOrientation;
        if (orientations.length() == 0) {
            androidOrientation = ActivityInfo.SCREEN_ORIENTATION_UNSPECIFIED;
        } else if (orientations.getString(0).equals("DeviceOrientation.portraitUp")) {
            androidOrientation = ActivityInfo.SCREEN_ORIENTATION_PORTRAIT;
        } else if (orientations.getString(0).equals("DeviceOrientation.landscapeLeft")) {
            androidOrientation = ActivityInfo.SCREEN_ORIENTATION_LANDSCAPE;
        } else if (orientations.getString(0).equals("DeviceOrientation.portraitDown")) {
            androidOrientation = ActivityInfo.SCREEN_ORIENTATION_REVERSE_PORTRAIT;
        } else if (orientations.getString(0).equals("DeviceOrientation.landscapeRight")) {
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

    private JSONObject getClipboardData(String format) throws JSONException {
        ClipboardManager clipboard = (ClipboardManager) mActivity.getSystemService(Context.CLIPBOARD_SERVICE);
        ClipData clip = clipboard.getPrimaryClip();
        if (clip == null)
            return null;

        if ((format == null || format.equals(kTextPlainFormat)) &&
            clip.getDescription().hasMimeType(ClipDescription.MIMETYPE_TEXT_PLAIN)) {
            JSONObject result = new JSONObject();
            result.put("text", clip.getItemAt(0).getText().toString());
            return result;
        }

        return null;
    }

    private void setClipboardData(JSONObject data) throws JSONException {
        ClipboardManager clipboard = (ClipboardManager) mActivity.getSystemService(Context.CLIPBOARD_SERVICE);
        ClipData clip = ClipData.newPlainText("text label?", data.getString("text"));
        clipboard.setPrimaryClip(clip);
    }

    private String getPathProviderTemporaryDirectory() {
        return mActivity.getCacheDir().getPath();
    }

    private String getPathProviderApplicationDocumentsDirectory() {
        return PathUtils.getDataDirectory(mActivity);
    }

    @Override
    public void onPostResume() {
        updateSystemUiOverlays();
    }
}
