// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.domokit.sky.shell;

import android.app.Activity;
import android.os.Bundle;

/**
 * Base class for activities that use Sky.
 */
public class SkyActivity extends Activity {
    private PlatformView mView;

    /**
     * @see android.app.Activity#onCreate(android.os.Bundle)
     */
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        SkyMain.ensureInitialized(getApplicationContext());
        mView = new PlatformView(this);
        setContentView(mView);
    }

    public void loadUrl(String url) {
        mView.loadUrl(url);
    }
}
