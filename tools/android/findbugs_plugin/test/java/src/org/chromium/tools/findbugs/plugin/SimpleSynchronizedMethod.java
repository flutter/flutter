// Copyright 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.tools.findbugs.plugin;

/**
 * This class has synchronized method and is used to test
 * SynchronizedMethodDetector.
 */
class SimpleSynchronizedMethod {
    private int mCounter = 0;

    synchronized void synchronizedMethod() {
        mCounter++;
    }
}
