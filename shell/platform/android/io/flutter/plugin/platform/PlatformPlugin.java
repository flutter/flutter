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
import android.os.Build;
import android.view.HapticFeedbackConstants;
import android.view.SoundEffectConstants;
import android.view.View;

import io.flutter.plugin.common.ActivityLifecycleListener;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.MethodCall;

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
    public void onMethodCall(MethodCall call, Result result) {
        String method = call.method;
        Object arguments = call.arguments;
        try {
            if (method.equals("SystemSound.play")) {
                playSystemSound((String) arguments);
                result.success(null);
            } else if (method.equals("HapticFeedback.vibrate")) {
                vibrateHapticFeedback();
                result.success(null);
            } else if (method.equals("SystemChrome.setPreferredOrientations")) {
                setSystemChromePreferredOrientations((JSONArray) arguments);
                result.success(null);
            } else if (method.equals("SystemChrome.setApplicationSwitcherDescription")) {
                setSystemChromeApplicationSwitcherDescription((JSONObject) arguments);
                result.success(null);
            } else if (method.equals("SystemChrome.setEnabledSystemUIOverlays")) {
                setSystemChromeEnabledSystemUIOverlays((JSONArray) arguments);
                result.success(null);
            } else if (method.equals("SystemChrome.setSystemUIOverlayStyle")) {
                setSystemChromeSystemUIOverlayStyle((String) arguments);
                result.success(null);
            } else if (method.equals("SystemNavigator.pop")) {
                popSystemNavigator();
                result.success(null);
            } else if (method.equals("Clipboard.getData")) {
                result.success(getClipboardData((String) arguments));
            } else if (method.equals("Clipboard.setData")) {
                setClipboardData((JSONObject) arguments);
                result.success(null);
            } else {
                result.notImplemented();
            }
        } catch (JSONException e) {
            result.error("error", "JSON error: " + e.getMessage(), null);
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

    private void setSystemChromePreferredOrientations(JSONArray orientations) throws JSONException {
        int requestedOrientation = 0x00;
        int firstRequestedOrientation = 0x00;
        for (int index = 0; index < orientations.length(); index += 1) {
            if (orientations.getString(index).equals("DeviceOrientation.portraitUp")) {
                requestedOrientation |= 0x01;
            } else if (orientations.getString(index).equals("DeviceOrientation.landscapeLeft")) {
                requestedOrientation |= 0x02;
            } else if (orientations.getString(index).equals("DeviceOrientation.portraitDown")) {
                requestedOrientation |= 0x04;
            } else if (orientations.getString(index).equals("DeviceOrientation.landscapeRight")) {
                requestedOrientation |= 0x08;
            }
            if (firstRequestedOrientation == 0x00) {
                firstRequestedOrientation = requestedOrientation;
            }
        }
        switch (requestedOrientation) {
            case 0x00:
                mActivity.setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_UNSPECIFIED);
                break;
            case 0x01:
                mActivity.setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_PORTRAIT);
                break;
            case 0x02:
                mActivity.setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_LANDSCAPE);
                break;
            case 0x04:
                mActivity.setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_REVERSE_PORTRAIT);
                break;
            case 0x05:
                mActivity.setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_USER_PORTRAIT);
                break;
            case 0x08:
                mActivity.setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_REVERSE_LANDSCAPE);
                break;
            case 0x0a:
                mActivity.setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_USER_LANDSCAPE);
                break;
            case 0x0b:
                mActivity.setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_USER);
                break;
            case 0x0f:
                mActivity.setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_FULL_USER);
                break;
            case 0x03: // portraitUp and landscapeLeft
            case 0x06: // portraitDown and landscapeLeft
            case 0x07: // portraitUp, portraitDown, and landscapeLeft
            case 0x09: // portraitUp and landscapeRight
            case 0x0c: // portraitDown and landscapeRight
            case 0x0d: // portraitUp, portraitDown, and landscapeRight
            case 0x0e: // portraitDown, landscapeLeft, and landscapeRight
                // Android can't describe these cases, so just default to whatever the first
                // specified value was.
                switch (firstRequestedOrientation) {
                    case 0x01:
                        mActivity.setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_PORTRAIT);
                        break;
                    case 0x02:
                        mActivity.setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_LANDSCAPE);
                        break;
                    case 0x04:
                        mActivity.setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_REVERSE_PORTRAIT);
                        break;
                    case 0x08:
                        mActivity.setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_REVERSE_LANDSCAPE);
                        break;
                }
                break;
          }
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

        if (format == null || format.equals(kTextPlainFormat)) {
            JSONObject result = new JSONObject();
            result.put("text", clip.getItemAt(0).coerceToText(mActivity));
            return result;
        }

        return null;
    }

    private void setClipboardData(JSONObject data) throws JSONException {
        ClipboardManager clipboard = (ClipboardManager) mActivity.getSystemService(Context.CLIPBOARD_SERVICE);
        ClipData clip = ClipData.newPlainText("text label?", data.getString("text"));
        clipboard.setPrimaryClip(clip);
    }

    @Override
    public void onPostResume() {
        updateSystemUiOverlays();
    }
}
