// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.mojo.system;

/**
 * Base class for bit field used as flags.
 *
 * @param <F> the type of the flags.
 */
public abstract class Flags<F extends Flags<F>> {
    private int mFlags;
    private boolean mImmutable;

    /**
     * Dedicated constructor.
     *
     * @param flags initial value of the flag.
     */
    protected Flags(int flags) {
        mImmutable = false;
        mFlags = flags;
    }

    /**
     * @return the computed flag.
     */
    public int getFlags() {
        return mFlags;
    }

    /**
     * Change the given bit of this flag.
     *
     * @param value the new value of given bit.
     * @return this.
     */
    protected F setFlag(int flag, boolean value) {
        if (mImmutable) {
            throw new UnsupportedOperationException("Flags is immutable.");
        }
        if (value) {
            mFlags |= flag;
        } else {
            mFlags &= ~flag;
        }
        @SuppressWarnings("unchecked")
        F f = (F) this;
        return f;
    }

    /**
     * Makes this flag immutable. This is a non-reversable operation.
     */
    protected F immutable() {
        mImmutable = true;
        @SuppressWarnings("unchecked")
        F f = (F) this;
        return f;
    }

    /**
     * @see Object#hashCode()
     */
    @Override
    public int hashCode() {
        return mFlags;
    }

    /**
     * @see Object#equals(Object)
     */
    @Override
    public boolean equals(Object obj) {
        if (this == obj) return true;
        if (obj == null) return false;
        if (getClass() != obj.getClass()) return false;
        Flags<?> other = (Flags<?>) obj;
        if (mFlags != other.mFlags) return false;
        return true;
    }
}
