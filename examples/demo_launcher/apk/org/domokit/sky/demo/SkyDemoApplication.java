// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.domokit.sky.demo;

import android.content.Context;

import org.domokit.sky.shell.ResourceExtractor;
import org.domokit.sky.shell.SkyApplication;

/**
 * SkyDemo implementation of {@link android.app.Application}
 */
public class SkyDemoApplication extends SkyApplication {
    private static final String[] DEMO_RESOURCES = {
        "cards.skyx",
        "fitness.skyx",
        "game.skyx",
        "interactive_flex.skyx",
        "mine_digger.skyx",
        "stocks.skyx",
    };

    @Override
    protected void onBeforeResourceExtraction(ResourceExtractor extractor) {
        super.onBeforeResourceExtraction(extractor);
        extractor.addResources(DEMO_RESOURCES);
    }
}
