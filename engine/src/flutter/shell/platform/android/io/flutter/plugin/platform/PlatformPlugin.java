// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugin.platform;

import android.app.Activity;
import android.view.SoundEffectConstants;
import android.view.View;
import android.util.Log;

import org.json.JSONException;
import org.json.JSONObject;

import io.flutter.plugin.common.JSONMessageListener;
import io.flutter.view.FlutterView;

/**
 * Android implementation of the platform plugin.
 */
public class PlatformPlugin extends JSONMessageListener {
    private final Activity mActivity;

    public PlatformPlugin(Activity activity) {
        mActivity = activity;
    }

    @Override
    public JSONObject onJSONMessage(FlutterView view, JSONObject message) throws JSONException {
        if (message.getString("method").equals("SystemSound.play")) {
          playSystemSound(message.getJSONArray("args").getString(0));
          return null;
        }
        // TODO(abarth): We should throw an exception here that gets
        // transmitted back to Dart.
        return null;
    }

    void playSystemSound(String soundType) {
        if (soundType.equals("SystemSoundType.click")) {
            View view = mActivity.getWindow().getDecorView();
            view.playSoundEffect(SoundEffectConstants.CLICK);
        }
    }
}
