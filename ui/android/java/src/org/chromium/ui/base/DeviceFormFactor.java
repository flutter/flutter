// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.ui.base;

import android.content.Context;

import org.chromium.base.CalledByNative;

/**
 * UI utilities for accessing form factor information.
 */
public class DeviceFormFactor {

    /**
     * The minimum width that would classify the device as a tablet.
     */
    private static final int MINIMUM_TABLET_WIDTH_DP = 600;

    private static Boolean sIsTablet = null;

    /**
     * @param context Android's context
     * @return        Whether the app is should treat the device as a tablet for layout.
     */
    @CalledByNative
    public static boolean isTablet(Context context) {
        if (sIsTablet == null) {
            int minimumScreenWidthDp = context.getResources().getConfiguration().
                    smallestScreenWidthDp;
            sIsTablet = minimumScreenWidthDp >= MINIMUM_TABLET_WIDTH_DP;
        }
        return sIsTablet;
    }
}
