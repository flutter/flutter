// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.mojo.sensors;

import android.content.Context;

import org.chromium.mojo.system.MojoException;
import org.chromium.mojom.sensors.SensorListener;
import org.chromium.mojom.sensors.SensorService;

/**
 * Android implementation of Senors.
 */
public class SensorServiceImpl implements SensorService {
    private Context mContext;

    public SensorServiceImpl(Context context) {
        mContext = context;
    }

    @Override
    public void close() {}

    @Override
    public void onConnectionError(MojoException e) {}

    @Override
    public void addListener(int sensorType, SensorListener listener) {
        new SensorForwarder(mContext, sensorType, (SensorListener.Proxy) listener);
    }
}
