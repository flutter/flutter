// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.connectivity;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.net.ConnectivityManager;
import android.net.Network;
import android.os.Build;
import android.os.Handler;
import android.os.Looper;
import io.flutter.plugin.common.EventChannel;

/**
 * The ConnectivityBroadcastReceiver receives the connectivity updates and send them to the UIThread
 * through an {@link EventChannel.EventSink}
 *
 * <p>Use {@link
 * io.flutter.plugin.common.EventChannel#setStreamHandler(io.flutter.plugin.common.EventChannel.StreamHandler)}
 * to set up the receiver.
 */
public class ConnectivityBroadcastReceiver extends BroadcastReceiver
    implements EventChannel.StreamHandler {
  private Context context;
  private Connectivity connectivity;
  private EventChannel.EventSink events;
  private Handler mainHandler = new Handler(Looper.getMainLooper());
  private ConnectivityManager.NetworkCallback networkCallback;
  public static final String CONNECTIVITY_ACTION = "android.net.conn.CONNECTIVITY_CHANGE";

  public ConnectivityBroadcastReceiver(Context context, Connectivity connectivity) {
    this.context = context;
    this.connectivity = connectivity;
  }

  @Override
  public void onListen(Object arguments, EventChannel.EventSink events) {
    this.events = events;
    if (android.os.Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
      networkCallback =
          new ConnectivityManager.NetworkCallback() {
            @Override
            public void onAvailable(Network network) {
              sendEvent();
            }

            @Override
            public void onLost(Network network) {
              sendEvent();
            }
          };
      connectivity.getConnectivityManager().registerDefaultNetworkCallback(networkCallback);
    } else {
      context.registerReceiver(this, new IntentFilter(CONNECTIVITY_ACTION));
    }
  }

  @Override
  public void onCancel(Object arguments) {
    if (android.os.Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
      if (networkCallback != null) {
        connectivity.getConnectivityManager().unregisterNetworkCallback(networkCallback);
        networkCallback = null;
      }
    } else {
      context.unregisterReceiver(this);
    }
  }

  @Override
  public void onReceive(Context context, Intent intent) {
    if (events != null) {
      events.success(connectivity.getNetworkType());
    }
  }

  public ConnectivityManager.NetworkCallback getNetworkCallback() {
    return networkCallback;
  }

  private void sendEvent() {
    Runnable runnable =
        new Runnable() {
          @Override
          public void run() {
            events.success(connectivity.getNetworkType());
          }
        };
    mainHandler.post(runnable);
  }
}
