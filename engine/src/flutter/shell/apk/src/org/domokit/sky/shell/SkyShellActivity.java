// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.domokit.sky.shell;

import android.app.Activity;
import android.os.Bundle;

/**
 * Main activity for SkyShell.
 */
public class SkyShellActivity extends Activity {
    /**
     * @see android.app.Activity#onCreate(android.os.Bundle)
     */
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        SkyMain.ensureInitialized(getApplicationContext());
        setContentView(new PlatformView(this));
    }
}
