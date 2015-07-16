// Copyright 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.tools.findbugs.plugin;

/**
 * This class is used to test SynchronizedMethodDetector
 */
class SimpleSynchronizedStaticMethod {
    private static int sCounter = 0;

    static synchronized void synchronizedStaticMethod() {
        sCounter++;
    }
}
