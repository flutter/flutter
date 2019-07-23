// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter;

import static org.junit.Assert.assertTrue;

import android.text.TextUtils;
import org.junit.runner.RunWith;
import org.junit.Test;
import org.robolectric.annotation.Config;
import org.robolectric.RobolectricTestRunner;

/** Basic smoke test verifying that Robolectric is loaded and mocking out Android APIs. */
@Config(manifest=Config.NONE)
@RunWith(RobolectricTestRunner.class)
public class SmokeTest {
    @Test
    public void androidLibraryLoaded() {
        assertTrue(TextUtils.equals("xyzzy", "xyzzy"));
    }
}
