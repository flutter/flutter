// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.example.platformchannel;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.ContextWrapper;
import android.content.Intent;
import android.content.IntentFilter;
import android.os.BatteryManager;
import android.os.Build.VERSION;
import android.os.Build.VERSION_CODES;
import android.os.Bundle;

import io.flutter.app.FlutterActivity;
import io.flutter.plugin.common.FlutterEventChannel;
import io.flutter.plugin.common.FlutterEventChannel.EventSink;
import io.flutter.plugin.common.FlutterEventChannel.StreamHandler;
import io.flutter.plugin.common.FlutterMethodChannel;
import io.flutter.plugin.common.FlutterMethodChannel.MethodCallHandler;
import io.flutter.plugin.common.FlutterMethodChannel.Response;
import io.flutter.plugin.common.MethodCall;

public class MainActivity extends FlutterActivity {
  private static final String BATTERY_CHANNEL = "samples.flutter.io/battery";
  private static final String CHARGING_CHANNEL = "samples.flutter.io/charging";

  @Override
  public void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);

    new FlutterEventChannel(getFlutterView(), CHARGING_CHANNEL).setStreamHandler(
        new StreamHandler() {
          private BroadcastReceiver chargingStateChangeReceiver;
          @Override
          public void onListen(Object arguments, EventSink events) {
            chargingStateChangeReceiver = createChargingStateChangeReceiver(events);
            registerReceiver(
                chargingStateChangeReceiver, new IntentFilter(Intent.ACTION_BATTERY_CHANGED));
          }

          @Override
          public void onCancel(Object arguments) {
            unregisterReceiver(chargingStateChangeReceiver);
            chargingStateChangeReceiver = null;
          }
        }
    );

    new FlutterMethodChannel(getFlutterView(), BATTERY_CHANNEL).setMethodCallHandler(
        new MethodCallHandler() {
          @Override
          public void onMethodCall(MethodCall call, Response response) {
            if (call.method.equals("getBatteryLevel")) {
              int batteryLevel = getBatteryLevel();

              if (batteryLevel != -1) {
                response.success(batteryLevel);
              } else {
                response.error("UNAVAILABLE", "Battery level not available.", null);
              }
            } else {
              response.notImplemented();
            }
          }
        }
    );
  }

  private BroadcastReceiver createChargingStateChangeReceiver(final EventSink events) {
    return new BroadcastReceiver() {
      @Override
      public void onReceive(Context context, Intent intent) {
        int status = intent.getIntExtra(BatteryManager.EXTRA_STATUS, -1);

        if (status == BatteryManager.BATTERY_STATUS_UNKNOWN) {
          events.error("UNAVAILABLE", "Charging status unavailable", null);
        } else {
          boolean isCharging = status == BatteryManager.BATTERY_STATUS_CHARGING ||
                               status == BatteryManager.BATTERY_STATUS_FULL;
          events.success(isCharging ? "charging" : "discharging");
        }
      }
    };
  }

  private int getBatteryLevel() {
    int batteryLevel = -1;
    if (VERSION.SDK_INT >= VERSION_CODES.LOLLIPOP) {
      BatteryManager batteryManager = (BatteryManager) getSystemService(BATTERY_SERVICE);
      batteryLevel = batteryManager.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY);
    } else {
      Intent intent = new ContextWrapper(getApplicationContext()).
          registerReceiver(null, new IntentFilter(Intent.ACTION_BATTERY_CHANGED));
      batteryLevel = (intent.getIntExtra(BatteryManager.EXTRA_LEVEL, -1) * 100) /
          intent.getIntExtra(BatteryManager.EXTRA_SCALE, -1);
    }

    return batteryLevel;
  }
}
