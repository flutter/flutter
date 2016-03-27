// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.example.flutter;

import android.app.Activity;
import android.content.Context;
import android.location.Location;
import android.location.LocationManager;
import android.os.Bundle;
import android.util.Log;
import android.view.View;
import android.widget.Button;
import android.widget.TextView;

import org.chromium.base.PathUtils;
import org.domokit.activity.ActivityImpl;
import org.domokit.sky.shell.SkyMain;
import org.domokit.sky.shell.PlatformViewAndroid;

import java.io.File;
import org.json.JSONException;
import org.json.JSONObject;

public class ExampleActivity extends Activity {
    private static final String TAG = "ExampleActivity";

    private PlatformViewAndroid flutterView;

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        SkyMain.ensureInitialized(getApplicationContext(), null);
        setContentView(R.layout.flutter_layout);

        flutterView = (PlatformViewAndroid) findViewById(R.id.flutter_view);
        File appBundle = new File(PathUtils.getDataDirectory(this), SkyMain.APP_BUNDLE);
        flutterView.runFromBundle(appBundle.getPath(), null);

        flutterView.addOnMessageListener("getLocation",
            new PlatformViewAndroid.OnMessageListener() {
                @Override
                public String onMessage(String message) {
                    return onGetLocation(message);
                }
            });

        Button getRandom = (Button) findViewById(R.id.get_random);
        getRandom.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                sendGetRandom();
            }
        });
    }

    @Override
    protected void onDestroy() {
        if (flutterView != null) {
            flutterView.destroy();
        }
        super.onDestroy();
    }

    @Override
    protected void onPause() {
        super.onPause();
        flutterView.onPause();
    }

    @Override
    protected void onResume() {
        super.onResume();
        flutterView.onResume();
    }

    private void sendGetRandom() {
        JSONObject message = new JSONObject();
        try {
            message.put("min", 1);
            message.put("max", 1000);
        } catch (JSONException e) {
            Log.e(TAG, "JSON exception", e);
            return;
        }

        flutterView.sendToFlutter("getRandom", message.toString(),
            new PlatformViewAndroid.MessageReplyCallback() {
                @Override
                public void onReply(String json) {
                    onRandomReply(json);
                }
            });
    }

    private void onRandomReply(String json) {
        double value;
        try {
            JSONObject reply = new JSONObject(json);
            value = reply.getDouble("value");
        } catch (JSONException e) {
            Log.e(TAG, "JSON exception", e);
            return;
        }

        TextView randomValue = (TextView) findViewById(R.id.random_value);
        randomValue.setText(Double.toString(value));
    }

    private String onGetLocation(String json) {
        String provider;
        try {
            JSONObject message = new JSONObject(json);
            provider = message.getString("provider");
        } catch (JSONException e) {
            Log.e(TAG, "JSON exception", e);
            return null;
        }

        String locationProvider;
        if (provider.equals("network")) {
            locationProvider = LocationManager.NETWORK_PROVIDER;
        } else if (provider.equals("gps")) {
            locationProvider = LocationManager.GPS_PROVIDER;
        } else {
            return null;
        }

        LocationManager locationManager =
            (LocationManager) getSystemService(Context.LOCATION_SERVICE);
        Location location = locationManager.getLastKnownLocation(locationProvider);

        JSONObject reply = new JSONObject();
        try {
            reply.put("latitude", location.getLatitude());
            reply.put("longitude", location.getLongitude());
        } catch (JSONException e) {
            Log.e(TAG, "JSON exception", e);
            return null;
        }

        return reply.toString();
    }
}
