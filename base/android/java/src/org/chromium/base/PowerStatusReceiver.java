// Copyright 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.base;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;


/**
 * A BroadcastReceiver that listens to changes in power status and notifies
 * PowerMonitor.
 * It's instantiated by the framework via the application intent-filter
 * declared in its manifest.
 */
public class PowerStatusReceiver extends BroadcastReceiver {
    @Override
    public void onReceive(Context context, Intent intent) {
        PowerMonitor.onBatteryChargingChanged(intent);
    }
}
