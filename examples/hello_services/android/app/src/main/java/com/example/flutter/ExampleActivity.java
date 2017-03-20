// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.example.flutter;

import android.app.Activity;
import android.content.Context;
import android.content.pm.PackageManager;
import android.location.Location;
import android.location.LocationManager;
import android.os.Bundle;
import android.view.View;
import android.widget.Button;
import android.widget.TextView;

import io.flutter.plugin.common.FlutterMethodChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.view.FlutterMain;
import io.flutter.view.FlutterView;

import java.util.Arrays;

public class ExampleActivity extends Activity {
    private static final String TAG = "ExampleActivity";

    private FlutterView flutterView;
    private FlutterMethodChannel randomChannel;

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        FlutterMain.ensureInitializationComplete(getApplicationContext(), null);
        setContentView(R.layout.hello_services_layout);

        flutterView = (FlutterView) findViewById(R.id.flutter_view);
        flutterView.runFromBundle(FlutterMain.findAppBundlePath(getApplicationContext()), null);

        FlutterMethodChannel locationChannel = new FlutterMethodChannel(flutterView, "location");
        randomChannel = new FlutterMethodChannel(flutterView, "random");

        locationChannel.setMethodCallHandler(new FlutterMethodChannel.MethodCallHandler() {
            @Override
            public void onMethodCall(MethodCall methodCall, FlutterMethodChannel.Response response) {
                if (methodCall.method.equals("getLocation")) {
                    getLocation((String) methodCall.arguments, response);
                } else {
                    response.error("unknown method", "Unknown method: " + methodCall.method, null);
                }
            }
        });

        Button getRandom = (Button) findViewById(R.id.get_random);
        getRandom.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) { getRandom(); }
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
    protected void onPostResume() {
        super.onPostResume();
        flutterView.onPostResume();
    }

    private void getRandom() {
        randomChannel.invokeMethod("getRandom", Arrays.asList(1, 1000), new FlutterMethodChannel.Response() {
            TextView textView = (TextView) findViewById(R.id.random_value);

            @Override
            public void success(Object result) {
                textView.setText(result.toString());
            }

            @Override
            public void error(String code, String message, Object details) {
                textView.setText("Error: " + message);
            }
        });
    }

    private void getLocation(String provider, FlutterMethodChannel.Response response) {
        String locationProvider;
        if (provider.equals("network")) {
            locationProvider = LocationManager.NETWORK_PROVIDER;
        } else if (provider.equals("gps")) {
            locationProvider = LocationManager.GPS_PROVIDER;
        } else {
            response.error("unknown provider", "Unknown location provider: " + provider, null);
            return;
        }

        String permission = "android.permission.ACCESS_FINE_LOCATION";
        if (checkCallingOrSelfPermission(permission) == PackageManager.PERMISSION_GRANTED) {
            LocationManager locationManager = (LocationManager) getSystemService(Context.LOCATION_SERVICE);
            Location location = locationManager.getLastKnownLocation(locationProvider);
            if (location != null) {
                response.success(Arrays.asList(location.getLatitude(), location.getLongitude()));
            } else {
                response.error("location unavailable", "Location is not available", null);
            }
        } else {
            response.error("access error", "Location permissions not granted", null);
        }
    }
}
