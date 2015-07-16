// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.mojo.bindings;

import java.nio.ByteBuffer;

/**
 * Header information for a message.
 */
public class MessageHeader {

    private static final int SIMPLE_MESSAGE_SIZE = 16;
    private static final int SIMPLE_MESSAGE_VERSION = 0;
    private static final DataHeader SIMPLE_MESSAGE_STRUCT_INFO =
            new DataHeader(SIMPLE_MESSAGE_SIZE, SIMPLE_MESSAGE_VERSION);

    private static final int MESSAGE_WITH_REQUEST_ID_SIZE = 24;
    private static final int MESSAGE_WITH_REQUEST_ID_VERSION = 1;
    private static final DataHeader MESSAGE_WITH_REQUEST_ID_STRUCT_INFO =
            new DataHeader(MESSAGE_WITH_REQUEST_ID_SIZE, MESSAGE_WITH_REQUEST_ID_VERSION);

    private static final int TYPE_OFFSET = 8;
    private static final int FLAGS_OFFSET = 12;
    private static final int REQUEST_ID_OFFSET = 16;

    /**
     * Flag for a header of a simple message.
     */
    public static final int NO_FLAG = 0;

    /**
     * Flag for a header of a message that expected a response.
     */
    public static final int MESSAGE_EXPECTS_RESPONSE_FLAG = 1 << 0;

    /**
     * Flag for a header of a message that is a response.
     */
    public static final int MESSAGE_IS_RESPONSE_FLAG = 1 << 1;

    private final DataHeader mDataHeader;
    private final int mType;
    private final int mFlags;
    private long mRequestId;

    /**
     * Constructor for the header of a message which does not have a response.
     */
    public MessageHeader(int type) {
        mDataHeader = SIMPLE_MESSAGE_STRUCT_INFO;
        mType = type;
        mFlags = 0;
        mRequestId = 0;
    }

    /**
     * Constructor for the header of a message which have a response or being itself a response.
     */
    public MessageHeader(int type, int flags, long requestId) {
        assert mustHaveRequestId(flags);
        mDataHeader = MESSAGE_WITH_REQUEST_ID_STRUCT_INFO;
        mType = type;
        mFlags = flags;
        mRequestId = requestId;
    }

    /**
     * Constructor, parsing the header from a message. Should only be used by {@link Message}
     * itself.
     */
    MessageHeader(Message message) {
        Decoder decoder = new Decoder(message);
        mDataHeader = decoder.readDataHeader();
        validateDataHeader(mDataHeader);
        mType = decoder.readInt(TYPE_OFFSET);
        mFlags = decoder.readInt(FLAGS_OFFSET);
        if (mustHaveRequestId(mFlags)) {
            if (mDataHeader.size < MESSAGE_WITH_REQUEST_ID_SIZE) {
                throw new DeserializationException("Incorrect message size, expecting at least "
                        + MESSAGE_WITH_REQUEST_ID_SIZE
                        + " for a message with a request identifier, but got: " + mDataHeader.size);

            }
            mRequestId = decoder.readLong(REQUEST_ID_OFFSET);
        } else {
            mRequestId = 0;
        }
    }

    /**
     * Returns the size in bytes of the serialization of the header.
     */
    public int getSize() {
        return mDataHeader.size;
    }

    /**
     * Returns the type of the message.
     */
    public int getType() {
        return mType;
    }

    /**
     * Returns the flags associated to the message.
     */
    public int getFlags() {
        return mFlags;
    }

    /**
     * Returns if the message has the given flag.
     */
    public boolean hasFlag(int flag) {
        return (mFlags & flag) == flag;
    }

    /**
     * Returns if the message has a request id.
     */
    public boolean hasRequestId() {
        return mustHaveRequestId(mFlags);
    }

    /**
     * Return the request id for the message. Must only be called if the message has a request id.
     */
    public long getRequestId() {
        assert hasRequestId();
        return mRequestId;
    }

    /**
     * Encode the header.
     */
    public void encode(Encoder encoder) {
        encoder.encode(mDataHeader);
        encoder.encode(getType(), TYPE_OFFSET);
        encoder.encode(getFlags(), FLAGS_OFFSET);
        if (hasRequestId()) {
            encoder.encode(getRequestId(), REQUEST_ID_OFFSET);
        }
    }

    /**
     * Returns true if the header has the expected flags. Only considers flags this class knows
     * about in order to allow this class to work with future version of the header format.
     */
    public boolean validateHeader(int expectedFlags) {
        int knownFlags = getFlags() & (MESSAGE_EXPECTS_RESPONSE_FLAG | MESSAGE_IS_RESPONSE_FLAG);
        return knownFlags == expectedFlags;
    }

    /**
     * Returns true if the header has the expected type and flags. Only consider flags this class
     * knows about in order to allow this class to work with future version of the header format.
     */
    public boolean validateHeader(int expectedType, int expectedFlags) {
        return getType() == expectedType && validateHeader(expectedFlags);
    }

    /**
     * @see Object#hashCode()
     */
    @Override
    public int hashCode() {
        final int prime = 31;
        int result = 1;
        result = prime * result + ((mDataHeader == null) ? 0 : mDataHeader.hashCode());
        result = prime * result + mFlags;
        result = prime * result + (int) (mRequestId ^ (mRequestId >>> 32));
        result = prime * result + mType;
        return result;
    }

    /**
     * @see Object#equals(Object)
     */
    @Override
    public boolean equals(Object object) {
        if (object == this) return true;
        if (object == null) return false;
        if (getClass() != object.getClass()) return false;

        MessageHeader other = (MessageHeader) object;
        return (BindingsHelper.equals(mDataHeader, other.mDataHeader)
                && mFlags == other.mFlags
                && mRequestId == other.mRequestId
                && mType == other.mType);
    }

    /**
     * Set the request id on the message contained in the given buffer.
     */
    void setRequestId(ByteBuffer buffer, long requestId) {
        assert mustHaveRequestId(buffer.getInt(FLAGS_OFFSET));
        buffer.putLong(REQUEST_ID_OFFSET, requestId);
        mRequestId = requestId;
    }

    /**
     * Returns whether a message with the given flags must have a request Id.
     */
    private static boolean mustHaveRequestId(int flags) {
        return (flags & (MESSAGE_EXPECTS_RESPONSE_FLAG | MESSAGE_IS_RESPONSE_FLAG)) != 0;
    }

    /**
     * Validate that the given {@link DataHeader} can be the data header of a message header.
     */
    private static void validateDataHeader(DataHeader dataHeader) {
        if (dataHeader.elementsOrVersion < SIMPLE_MESSAGE_VERSION) {
            throw new DeserializationException("Incorrect number of fields, expecting at least "
                    + SIMPLE_MESSAGE_VERSION + ", but got: " + dataHeader.elementsOrVersion);
        }
        if (dataHeader.size < SIMPLE_MESSAGE_SIZE) {
            throw new DeserializationException(
                    "Incorrect message size, expecting at least " + SIMPLE_MESSAGE_SIZE
                    + ", but got: " + dataHeader.size);
        }
        if (dataHeader.elementsOrVersion == SIMPLE_MESSAGE_VERSION
                && dataHeader.size != SIMPLE_MESSAGE_SIZE) {
            throw new DeserializationException("Incorrect message size for a message with "
                    + SIMPLE_MESSAGE_VERSION + " fields, expecting " + SIMPLE_MESSAGE_SIZE
                    + ", but got: " + dataHeader.size);
        }
        if (dataHeader.elementsOrVersion == MESSAGE_WITH_REQUEST_ID_VERSION
                && dataHeader.size != MESSAGE_WITH_REQUEST_ID_SIZE) {
            throw new DeserializationException("Incorrect message size for a message with "
                    + MESSAGE_WITH_REQUEST_ID_VERSION + " fields, expecting "
                    + MESSAGE_WITH_REQUEST_ID_SIZE + ", but got: " + dataHeader.size);
        }
    }

}
