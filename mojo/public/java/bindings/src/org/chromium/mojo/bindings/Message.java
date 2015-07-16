// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.mojo.bindings;

import org.chromium.mojo.system.Handle;
import org.chromium.mojo.system.MessagePipeHandle;

import java.nio.ByteBuffer;
import java.util.List;

/**
 * A raw message to be sent/received from a {@link MessagePipeHandle}. Note that this can contain
 * any data, not necessarily a Mojo message with a proper header. See also {@link ServiceMessage}.
 */
public class Message {

    /**
     * The data of the message.
     */
    private final ByteBuffer mBuffer;

    /**
     * The handles of the message.
     */
    private final List<? extends Handle> mHandle;

    /**
     * This message interpreted as a message for a mojo service with an appropriate header.
     */
    private ServiceMessage mWithHeader = null;

    /**
     * Constructor.
     *
     * @param buffer The buffer containing the bytes to send. This must be a direct buffer.
     * @param handles The list of handles to send.
     */
    public Message(ByteBuffer buffer, List<? extends Handle> handles) {
        assert buffer.isDirect();
        mBuffer = buffer;
        mHandle = handles;
    }

    /**
     * The data of the message.
     */
    public ByteBuffer getData() {
        return mBuffer;
    }

    /**
     * The handles of the message.
     */
    public List<? extends Handle> getHandles() {
        return mHandle;
    }

    /**
     * Returns the message interpreted as a message for a mojo service.
     */
    public ServiceMessage asServiceMessage() {
        if (mWithHeader == null) {
            mWithHeader = new ServiceMessage(this);
        }
        return mWithHeader;
    }
}
