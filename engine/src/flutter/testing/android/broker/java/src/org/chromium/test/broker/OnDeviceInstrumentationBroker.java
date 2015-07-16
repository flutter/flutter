// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.test.broker;

import android.app.Activity;
import android.content.ComponentName;
import android.content.Intent;
import android.os.Bundle;
import android.util.Log;

/**
 * An Activity target for OnDeviceInstrumentationDriver that starts the specified
 * Instrumentation test.
 */
public class OnDeviceInstrumentationBroker extends Activity {

    public static final String EXTRA_INSTRUMENTATION_PACKAGE =
            "org.chromium.test.broker.OnDeviceInstrumentationBroker."
                    + "InstrumentationPackage";
    public static final String EXTRA_INSTRUMENTATION_CLASS =
            "org.chromium.test.broker.OnDeviceInstrumentationBroker."
                    + "InstrumentationClass";
    public static final String EXTRA_TARGET_ARGS =
            "org.chromium.test.broker.OnDeviceInstrumentationBroker.TargetArgs";
    public static final String EXTRA_TEST =
            "org.chromium.test.broker.OnDeviceInstrumentationBroker.Test";

    private static final String TAG = "OnDeviceInstrumentationBroker";

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        Log.d(TAG, "onCreate()");
    }

    @Override
    public void onStart() {
        super.onStart();

        Intent i = getIntent();
        String instrumentationPackage = i.getStringExtra(EXTRA_INSTRUMENTATION_PACKAGE);
        String instrumentationClass = i.getStringExtra(EXTRA_INSTRUMENTATION_CLASS);
        Bundle targetArgs = i.getBundleExtra(EXTRA_TARGET_ARGS);
        String test = i.getStringExtra(EXTRA_TEST);

        if (instrumentationPackage == null || instrumentationClass == null) {
            finish();
            return;
        }

        ComponentName instrumentationComponent =
                new ComponentName(instrumentationPackage, instrumentationClass);

        if (test != null) {
            targetArgs.putString("class", test);
        }

        startInstrumentation(instrumentationComponent, null, targetArgs);
        finish();
    }
}

