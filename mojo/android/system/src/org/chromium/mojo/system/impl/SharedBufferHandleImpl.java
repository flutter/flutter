// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.mojo.system.impl;

import org.chromium.mojo.system.SharedBufferHandle;

import java.nio.ByteBuffer;

/**
 * Implementation of {@link SharedBufferHandle}.
 */
class SharedBufferHandleImpl extends HandleBase implements SharedBufferHandle {

    /**
     * @see HandleBase#HandleBase(CoreImpl, int)
     */
    SharedBufferHandleImpl(CoreImpl core, int mojoHandle) {
        super(core, mojoHandle);
    }

    /**
     * @see HandleBase#HandleBase(HandleBase)
     */
    SharedBufferHandleImpl(HandleBase handle) {
        super(handle);
    }

    /**
     * @see org.chromium.mojo.system.SharedBufferHandle#pass()
     */
    @Override
    public SharedBufferHandle pass() {
        return new SharedBufferHandleImpl(this);
    }

    /**
     * @see SharedBufferHandle#duplicate(DuplicateOptions)
     */
    @Override
    public SharedBufferHandle duplicate(DuplicateOptions options) {
        return mCore.duplicate(this, options);
    }

    /**
     * @see SharedBufferHandle#map(long, long, MapFlags)
     */
    @Override
    public ByteBuffer map(long offset, long numBytes, MapFlags flags) {
        return mCore.map(this, offset, numBytes, flags);
    }

    /**
     * @see SharedBufferHandle#unmap(ByteBuffer)
     */
    @Override
    public void unmap(ByteBuffer buffer) {
        mCore.unmap(buffer);
    }

}
