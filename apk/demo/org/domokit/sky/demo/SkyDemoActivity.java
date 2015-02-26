// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.domokit.sky.demo;

import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;

import org.domokit.sky.shell.SkyActivity;

/**
 * Main activity for SkyDemo.
 */
public class SkyDemoActivity extends SkyActivity {
    /**
     * @see android.app.Activity#onCreate(android.os.Bundle)
     */
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        String url = "https://domokit.github.io/home";
        Intent intent = getIntent();
        if (Intent.ACTION_VIEW.equals(intent.getAction())) {
            Uri skyUri = intent.getData();
            Uri httpsUri = skyUri.buildUpon().scheme("https").build();
            // This is a hack to disable https for local testing.
            // getHost may be null if we're passed a non-normalized url.
            if (skyUri.getHost() != null
                    && skyUri.getHost().equals("localhost")) {
                httpsUri = skyUri.buildUpon().scheme("http").build();
            }
            url = httpsUri.toString();
        }

        loadUrl(url);
    }
}
