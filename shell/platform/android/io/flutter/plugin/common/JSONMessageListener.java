// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugin.common;

import android.util.Log;

import org.json.JSONException;
import org.json.JSONObject;

import io.flutter.view.FlutterView;

public abstract class JSONMessageListener implements FlutterView.OnMessageListener {
    static final String TAG = "FlutterView";

    @Override
    public String onMessage(FlutterView view, String message) {
        try {
            JSONObject response = onJSONMessage(view, new JSONObject(message));
            if (response == null)
                return null;
            return response.toString();
        } catch (JSONException e) {
            Log.e(TAG, "JSON exception", e);
            return null;
        }
    }

    public abstract JSONObject onJSONMessage(FlutterView view, JSONObject message) throws JSONException;
}
