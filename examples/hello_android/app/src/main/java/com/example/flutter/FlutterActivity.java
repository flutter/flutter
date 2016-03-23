// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.example.flutter;

import android.app.Activity;
import android.os.Bundle;

import org.chromium.base.PathUtils;
import org.domokit.sky.shell.SkyMain;
import org.domokit.sky.shell.PlatformViewAndroid;

import java.io.File;

public class FlutterActivity extends Activity {
    private PlatformViewAndroid flutterView;

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        SkyMain.ensureInitialized(getApplicationContext(), null);
        setContentView(R.layout.flutter_layout);

        flutterView = (PlatformViewAndroid) findViewById(R.id.flutter_view);
        File appBundle = new File(PathUtils.getDataDirectory(this), SkyMain.APP_BUNDLE);
        flutterView.runFromBundle(appBundle.getPath(), null);
    }

    @Override
    protected void onDestroy() {
        if (flutterView != null) {
            flutterView.destroy();
        }
        super.onDestroy();
    }
}
