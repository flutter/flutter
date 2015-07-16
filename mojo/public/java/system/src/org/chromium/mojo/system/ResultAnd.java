// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.mojo.system;

/**
 * Container that contains a mojo result and a value.
 *
 * @param <A> the type of the value.
 */
public class ResultAnd<A> {
    private final int mMojoResult;
    private final A mValue;

    public ResultAnd(int result, A value) {
        this.mMojoResult = result;
        this.mValue = value;
    }

    /**
     * Returns the mojo result.
     */
    public int getMojoResult() {
        return mMojoResult;
    }

    /**
     * Returns the value.
     */
    public A getValue() {
        return mValue;
    }
}
