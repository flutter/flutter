// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.view;

import android.util.Log;

import java.util.Map;
import java.util.TreeMap;

/**
 * An registry for services.
 **/
class ServiceRegistry {
    private static final String TAG = "ServiceRegistry";
    private Map<String, ServiceFactory> mRegistrations;

    static final ServiceRegistry SHARED = new ServiceRegistry();

    // In addition to the shared registry, there is a per-view registry
    // maintained by the PlatformServiceProvider.
    ServiceRegistry() {
        mRegistrations = new TreeMap<String, ServiceFactory>();
    }

    void register(String interfaceName, ServiceFactory connector) {
        assert !mRegistrations.containsKey(interfaceName);
        assert connector != null;
        mRegistrations.put(interfaceName, connector);
    }

    ServiceFactory get(String interfaceName) {
        if (!mRegistrations.containsKey(interfaceName)) {
            Log.e(TAG, "Unknown service " + interfaceName);
        }
        return mRegistrations.get(interfaceName);
    }
}
