// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.mojo.system.impl;

import android.util.Log;

import org.chromium.mojo.system.Core;
import org.chromium.mojo.system.Core.HandleSignals;
import org.chromium.mojo.system.Core.WaitResult;
import org.chromium.mojo.system.Handle;
import org.chromium.mojo.system.UntypedHandle;

/**
 * Implementation of {@link Handle}.
 */
abstract class HandleBase implements Handle {

    private static final String TAG = "HandleImpl";

    /**
     * The pointer to the scoped handle owned by this object.
     */
    private int mMojoHandle;

    /**
     * The core implementation. Will be used to delegate all behavior.
     */
    protected CoreImpl mCore;

    /**
     * Base constructor. Takes ownership of the passed handle.
     */
    HandleBase(CoreImpl core, int mojoHandle) {
        mCore = core;
        mMojoHandle = mojoHandle;
    }

    /**
     * Constructor for transforming {@link HandleBase} into a specific one. It is used to transform
     * an {@link UntypedHandle} into a typed one, or any handle into an {@link UntypedHandle}.
     */
    protected HandleBase(HandleBase other) {
        mCore = other.mCore;
        HandleBase otherAsHandleImpl = other;
        int mojoHandle = otherAsHandleImpl.mMojoHandle;
        otherAsHandleImpl.mMojoHandle = CoreImpl.INVALID_HANDLE;
        mMojoHandle = mojoHandle;
    }

    /**
     * @see org.chromium.mojo.system.Handle#close()
     */
    @Override
    public void close() {
        if (mMojoHandle != CoreImpl.INVALID_HANDLE) {
            // After a close, the handle is invalid whether the close succeed or not.
            int handle = mMojoHandle;
            mMojoHandle = CoreImpl.INVALID_HANDLE;
            mCore.close(handle);
        }
    }

    /**
     * @see org.chromium.mojo.system.Handle#wait(HandleSignals, long)
     */
    @Override
    public WaitResult wait(HandleSignals signals, long deadline) {
        return mCore.wait(this, signals, deadline);
    }

    /**
     * @see org.chromium.mojo.system.Handle#isValid()
     */
    @Override
    public boolean isValid() {
        return mMojoHandle != CoreImpl.INVALID_HANDLE;
    }

    /**
     * @see org.chromium.mojo.system.Handle#toUntypedHandle()
     */
    @Override
    public UntypedHandle toUntypedHandle() {
        return new UntypedHandleImpl(this);
    }

    /**
     * @see org.chromium.mojo.system.Handle#getCore()
     */
    @Override
    public Core getCore() {
        return mCore;
    }

    /**
     * @see Handle#releaseNativeHandle()
     */
    @Override
    public int releaseNativeHandle() {
        int result = mMojoHandle;
        mMojoHandle = CoreImpl.INVALID_HANDLE;
        return result;
    }

    /**
     * Getter for the native scoped handle.
     *
     * @return the native scoped handle.
     */
    int getMojoHandle() {
        return mMojoHandle;
    }

    /**
     * invalidate the handle. The caller must ensures that the handle does not leak.
     */
    void invalidateHandle() {
        mMojoHandle = CoreImpl.INVALID_HANDLE;
    }

    /**
     * Close the handle if it is valid. Necessary because we cannot let handle leak, and we cannot
     * ensure that every handle will be manually closed.
     *
     * @see java.lang.Object#finalize()
     */
    @Override
    protected final void finalize() throws Throwable {
        if (isValid()) {
            // This should not happen, as the user of this class should close the handle. Adding a
            // warning.
            Log.w(TAG, "Handle was not closed.");
            // Ignore result at this point.
            mCore.closeWithResult(mMojoHandle);
        }
        super.finalize();
    }

}
