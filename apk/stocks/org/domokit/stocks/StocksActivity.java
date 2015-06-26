// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.domokit.stocks;

import android.os.Bundle;

import org.domokit.sky.shell.SkyActivity;

/**
 * Main activity for Stocks.
 */
public class StocksActivity extends SkyActivity {
    /**
     * @see android.app.Activity#onCreate(android.os.Bundle)
     */
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        loadUrl("https://domokit.github.io/sky/sdk/lib/example/stocks/index.sky");
    }
}
