// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.domokit.gcm;

import android.os.Bundle;
import android.util.Log;

import java.util.Set;
import org.json.JSONObject;
import org.json.JSONException;

public class GcmListenerService extends com.google.android.gms.gcm.GcmListenerService {
    private static final String TAG = "GcmListenerService";

    @Override
    public void onMessageReceived(String from, Bundle data) {
        // Convert the data Bundle to JSON.
        JSONObject json = new JSONObject();
        Set<String> keys = data.keySet();
        for (String key : keys) {
            try {
                json.put(key, JSONObject.wrap(data.get(key)));
            } catch(JSONException e) {
                Log.d(TAG, "Failed to convert GCM message to JSON: " + e);
            }
        }

        RegistrationIntentService.notifyMessageReceived(from, json.toString());
    }
}
