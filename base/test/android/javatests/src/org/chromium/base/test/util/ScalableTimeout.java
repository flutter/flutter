// Copyright 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.base.test.util;

/**
 * Utility class for scaling various timeouts by a common factor.
 * For example, to run tests under Valgrind, you might want the following:
 *   adb shell "echo 20.0 > /data/local/tmp/chrome_timeout_scale"
 */
public class ScalableTimeout {
    private static Double sTimeoutScale = null;
    private static final String PROPERTY_FILE = "/data/local/tmp/chrome_timeout_scale";

    public static long scaleTimeout(long timeout) {
        if (sTimeoutScale == null) {
            try {
                char[] data = TestFileUtil.readUtf8File(PROPERTY_FILE, 32);
                sTimeoutScale = Double.parseDouble(new String(data));
            } catch (Exception e) {
                // NumberFormatException, FileNotFoundException, IOException
                sTimeoutScale = 1.0;
            }
        }
        return (long) (timeout * sTimeoutScale);
    }
}
