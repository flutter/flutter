// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.connectivityexample;

import static org.junit.Assert.assertNotNull;
import static org.junit.Assert.assertNull;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.spy;

import android.content.Context;
import android.net.ConnectivityManager;
import io.flutter.plugins.connectivity.Connectivity;
import io.flutter.plugins.connectivity.ConnectivityBroadcastReceiver;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.RuntimeEnvironment;
import org.robolectric.annotation.Config;

@RunWith(RobolectricTestRunner.class)
public class ActivityTest {
  private ConnectivityManager connectivityManager;

  @Before
  public void setUp() {
    connectivityManager =
        (ConnectivityManager)
            RuntimeEnvironment.application.getSystemService(Context.CONNECTIVITY_SERVICE);
  }

  @Test
  @Config(sdk = 24, manifest = Config.NONE)
  public void networkCallbackNewApi() {
    Context context = RuntimeEnvironment.application;
    Connectivity connectivity = spy(new Connectivity(connectivityManager));
    ConnectivityBroadcastReceiver broadcastReceiver =
        spy(new ConnectivityBroadcastReceiver(context, connectivity));

    broadcastReceiver.onListen(any(), any());
    assertNotNull(broadcastReceiver.getNetworkCallback());
  }

  @Test
  @Config(sdk = 23, manifest = Config.NONE)
  public void networkCallbackLowApi() {
    Context context = RuntimeEnvironment.application;
    Connectivity connectivity = spy(new Connectivity(connectivityManager));
    ConnectivityBroadcastReceiver broadcastReceiver =
        spy(new ConnectivityBroadcastReceiver(context, connectivity));

    broadcastReceiver.onListen(any(), any());
    assertNull(broadcastReceiver.getNetworkCallback());
  }
}
