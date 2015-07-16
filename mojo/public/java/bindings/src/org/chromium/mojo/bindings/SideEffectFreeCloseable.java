// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.mojo.bindings;

import java.io.Closeable;

/**
 * An implementation of closeable that doesn't do anything.
 */
public class SideEffectFreeCloseable implements Closeable {

    /**
     * @see java.io.Closeable#close()
     */
    @Override
    public void close() {
    }

}
