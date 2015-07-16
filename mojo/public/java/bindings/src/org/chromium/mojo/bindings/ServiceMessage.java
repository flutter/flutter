// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.mojo.bindings;

import java.nio.ByteBuffer;
import java.nio.ByteOrder;

/**
 * Represents a {@link Message} which contains a {@link MessageHeader}. Deals with parsing the
 * {@link MessageHeader} for a message.
 */
public class ServiceMessage extends Message {

    private final MessageHeader mHeader;
    private Message mPayload;

    /**
     * Reinterpret the given |message| as a message with the given |header|. The |message| must
     * contain the |header| as the start of its raw data.
     */
    public ServiceMessage(Message baseMessage, MessageHeader header) {
        super(baseMessage.getData(), baseMessage.getHandles());
        assert header.equals(new org.chromium.mojo.bindings.MessageHeader(baseMessage));
        this.mHeader = header;
    }

    /**
     * Reinterpret the given |message| as a message with a header. The |message| must contain a
     * header as the start of it's raw data, which will be parsed by this constructor.
     */
    ServiceMessage(Message baseMessage) {
        this(baseMessage, new org.chromium.mojo.bindings.MessageHeader(baseMessage));
    }

    /**
     * @see Message#asServiceMessage()
     */
    @Override
    public ServiceMessage asServiceMessage() {
        return this;
    }

    /**
     * Returns the header of the given message. This will throw a {@link DeserializationException}
     * if the start of the message is not a valid header.
     */
    public MessageHeader getHeader() {
        return mHeader;
    }

    /**
     * Returns the payload of the message.
     */
    public Message getPayload() {
        if (mPayload == null) {
            ByteBuffer truncatedBuffer =
                    ((ByteBuffer) getData().position(getHeader().getSize())).slice();
            truncatedBuffer.order(ByteOrder.LITTLE_ENDIAN);
            mPayload = new Message(truncatedBuffer, getHandles());
        }
        return mPayload;
    }

    /**
     * Set the request identifier on the message.
     */
    void setRequestId(long requestId) {
        mHeader.setRequestId(getData(), requestId);
    }

}
