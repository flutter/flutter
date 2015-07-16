// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.domokit.sky.shell;

import android.util.Log;

import java.util.Map;
import java.util.TreeMap;

/**
 * An registry for services.
 **/
public class ServiceRegistry {
    private static final String TAG = "ServiceRegistry";
    private Map<String, ServiceFactory> mRegistrations;

    public static final ServiceRegistry SHARED = new ServiceRegistry();

    private ServiceRegistry() {
        mRegistrations = new TreeMap<String, ServiceFactory>();
    }

    public void register(String interfaceName, ServiceFactory connector) {
        assert !mRegistrations.containsKey(interfaceName);
        assert connector != null;
        mRegistrations.put(interfaceName, connector);
    }

    public ServiceFactory get(String interfaceName) {
        if (!mRegistrations.containsKey(interfaceName)) {
            Log.e(TAG, "Unknown service " + interfaceName);
        }
        return mRegistrations.get(interfaceName);
    }
}
