// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package dummy;

import android.app.Activity;

/**
 * Dummy activity to build apk.
 *
 * This class is created to ensure that proguard will produce two separate warnings.
 */
public class DummyActivity extends Activity {
    private static void doBadThings1() {
        try {
            sun.misc.Unsafe.getUnsafe();
        } catch (Exception e) {
            throw new Error(e);
        }
    }

    private static void doBadThings2() {
        sun.reflect.Reflection.getCallerClass(2);
    }
}
