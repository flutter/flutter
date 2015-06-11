// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.domokit.sky.shell;

import android.app.Activity;
import android.os.Build;
import android.os.Bundle;
import android.view.View;
import android.view.WindowManager;

/**
 * Base class for activities that use Sky.
 */
public class SkyActivity extends Activity {
    private TracingController mTracingController;
    private PlatformViewAndroid mView;

    /**
     * @see android.app.Activity#onCreate(android.os.Bundle)
     */
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            getWindow().addFlags(WindowManager.LayoutParams.FLAG_DRAWS_SYSTEM_BAR_BACKGROUNDS);
            getWindow().setStatusBarColor(0x40000000);
        }
        getWindow().getDecorView().setSystemUiVisibility(
                View.SYSTEM_UI_FLAG_LAYOUT_STABLE
                | View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN);

        SkyMain.ensureInitialized(getApplicationContext());
        mView = new PlatformViewAndroid(this);
        setContentView(mView);
        mTracingController = new TracingController(this);
    }

    /**
     * @see android.app.Activity#onDestroy()
     */
    @Override
    protected void onDestroy() {
        // Do we need to shut down Sky too?
        mTracingController.stop();
        super.onDestroy();
    }

    @Override
    public void onBackPressed() {
        if (mView != null) {
            mView.onBackPressed();
            // TODO(abarth): We should have some way to trigger the default
            // back behavior.
            return;
        }
        super.onBackPressed();
    }

    public void loadUrl(String url) {
        mView.loadUrl(url);
    }
}
