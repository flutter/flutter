// Copyright 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.tools.findbugs.plugin;

/**
 * This class has synchronized(this) statement and is used to test
 * SynchronizedThisDetector.
 */
class SimpleSynchronizedThis {
    private int mCounter = 0;

    void synchronizedThis() {
        synchronized (this) {
            mCounter++;
        }
    }
}
