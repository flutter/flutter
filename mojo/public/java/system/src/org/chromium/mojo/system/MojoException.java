// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.mojo.system;

/**
 * Exception for the core mojo API.
 */
public class MojoException extends RuntimeException {

    private final int mCode;

    /**
     * Constructor.
     */
    public MojoException(int code) {
        mCode = code;
    }

    /**
     * Constructor.
     */
    public MojoException(Throwable cause) {
        super(cause);
        mCode = MojoResult.UNKNOWN;
    }

    /**
     * The mojo result code associated with this exception. See {@link MojoResult} for possible
     * values.
     */
    public int getMojoResult() {
        return mCode;
    }

    /**
     * @see Object#toString()
     */
    @Override
    public String toString() {
        return "MojoResult(" + mCode + "): " + MojoResult.describe(mCode);
    }
}
