// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.mojo.bindings;

import org.chromium.mojo.system.Handle;

import java.io.Closeable;

/**
 * Describes a class that owns a handle.
 *
 * @param <H> The type of the owned handle.
 */
public interface HandleOwner<H extends Handle> extends Closeable {

    /**
     * Pass the handle owned by this class.
     */
    public H passHandle();

    /**
     * @see java.io.Closeable#close()
     */
    @Override
    public void close();

}
