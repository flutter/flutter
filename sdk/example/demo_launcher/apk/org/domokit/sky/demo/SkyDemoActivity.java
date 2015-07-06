// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.domokit.sky.demo;

import android.content.Intent;

import org.domokit.sky.shell.SkyActivity;

/**
 * Main activity for SkyDemo.
 */
public class SkyDemoActivity extends SkyActivity {
    @Override
    protected void onSkyReady() {
        Intent intent = getIntent();
        String action = intent.getAction();

        if (Intent.ACTION_VIEW.equals(action)) {
            String bundleName = intent.getStringExtra("bundleName");
            if (bundleName != null && loadBundleByName(bundleName)) {
                return;
            }
            loadUrl(intent.getDataString());
            return;
        }

        super.onSkyReady();
    }
}
