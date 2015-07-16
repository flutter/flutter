// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.mojo.system;

import org.chromium.mojo.system.Core.HandleSignals;

/**
 * A class which implements the {@link AsyncWaiter} allows asynchronously waiting on a background
 * thread.
 */
public interface AsyncWaiter {

    /**
     * Allows cancellation of an asyncWait operation.
     */
    interface Cancellable {
        /**
         * Cancels an asyncWait operation. Has no effect if the operation has already been canceled
         * or the callback has already been called.
         * <p>
         * Must be called from the same thread as {@link AsyncWaiter#asyncWait} was called from.
         */
        void cancel();
    }

    /**
     * Callback passed to {@link AsyncWaiter#asyncWait}.
     */
    public interface Callback {
        /**
         * Called when the handle is ready.
         */
        public void onResult(int result);

        /**
         * Called when an error occurred while waiting.
         */
        public void onError(MojoException exception);
    }

    /**
     * Asynchronously call wait on a background thread. The given {@link Callback} will be notified
     * of the result of the wait on the same thread as asyncWait was called.
     *
     * @return a {@link Cancellable} object that can be used to cancel waiting. The cancellable
     *         should only be used on the current thread, and becomes invalid once the callback has
     *         been notified.
     */
    Cancellable asyncWait(Handle handle, HandleSignals signals, long deadline, Callback callback);

}
