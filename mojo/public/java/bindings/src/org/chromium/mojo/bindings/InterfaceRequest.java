// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.mojo.bindings;

import org.chromium.mojo.system.MessagePipeHandle;

/**
 * One end of the message pipe representing a request to create an implementation to be bound to it.
 * The other end of the pipe is bound to a proxy, which can be used immediately, while the
 * InterfaceRequest is being sent.
 * <p>
 * InterfaceRequest are built using |Interface.Manager|.
 *
 * @param <P> the type of the remote interface proxy.
 */
public class InterfaceRequest<P extends Interface> implements HandleOwner<MessagePipeHandle> {

    /**
     * The handle which will be sent and will be connected to the implementation.
     */
    private final MessagePipeHandle mHandle;

    /**
     * Constructor.
     *
     * @param handle the handle which will be sent and will be connected to the implementation.
     */
    InterfaceRequest(MessagePipeHandle handle) {
        mHandle = handle;
    }

    /**
     * @see HandleOwner#passHandle()
     */
    @Override
    public MessagePipeHandle passHandle() {
        return mHandle.pass();
    }

    /**
     * @see java.io.Closeable#close()
     */
    @Override
    public void close() {
        mHandle.close();
    }

    /**
     * Returns an {@link InterfaceRequest} that wraps the given handle. This method is not type safe
     * and should be avoided unless absolutely necessary.
     */
    @SuppressWarnings("rawtypes")
    public static InterfaceRequest asInterfaceRequestUnsafe(MessagePipeHandle handle) {
        return new InterfaceRequest(handle);
    }
}
