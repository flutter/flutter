// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.domokit.sky.shell;

import android.app.Application;

import io.flutter.view.FlutterMain;

/**
 * Sky implementation of {@link android.app.Application}, managing application-level global
 * initializations.
 */
public class SkyApplication extends Application {
    @Override
    public void onCreate() {
        super.onCreate();
        FlutterMain.startInitialization(this);
    }
}
