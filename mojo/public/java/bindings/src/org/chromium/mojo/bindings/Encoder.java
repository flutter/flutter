// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.mojo.bindings;

import org.chromium.mojo.bindings.Interface.Proxy.Handler;
import org.chromium.mojo.system.Core;
import org.chromium.mojo.system.Handle;
import org.chromium.mojo.system.MessagePipeHandle;
import org.chromium.mojo.system.Pair;

import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.charset.Charset;
import java.util.ArrayList;
import java.util.List;

/**
 * Helper class to encode a mojo struct. It keeps track of the output buffer, resizing it as needed.
 * It also keeps track of the associated handles, and the offset of the current data section.
 */
public class Encoder {

    /**
     * Container class for all state that must be shared between the main encoder and any used sub
     * encoder.
     */
    private static class EncoderState {

        /**
         * The core used to encode interfaces.
         */
        public final Core core;

        /**
         * The ByteBuffer to which the message will be encoded.
         */
        public ByteBuffer byteBuffer;

        /**
         * The list of encountered handles.
         */
        public final List<Handle> handles = new ArrayList<Handle>();

        /**
         * The current absolute position for the next data section.
         */
        public int dataEnd;

        /**
         * @param core the |Core| implementation used to generate handles. Only used if the data
         *            structure being encoded contains interfaces, can be |null| otherwise.
         * @param bufferSize A hint on the size of the message. Used to build the initial byte
         *            buffer.
         */
        private EncoderState(Core core, int bufferSize) {
            assert bufferSize % BindingsHelper.ALIGNMENT == 0;
            this.core = core;
            byteBuffer = ByteBuffer.allocateDirect(
                    bufferSize > 0 ? bufferSize : INITIAL_BUFFER_SIZE);
            byteBuffer.order(ByteOrder.LITTLE_ENDIAN);
            dataEnd = 0;
        }

        /**
         * Claim the given amount of memory at the end of the buffer, resizing it if needed.
         */
        public void claimMemory(int size) {
            dataEnd += size;
            growIfNeeded();
        }

        /**
         * Grow the associated ByteBuffer if needed.
         */
        private void growIfNeeded() {
            if (byteBuffer.capacity() >= dataEnd) {
                return;
            }
            int targetSize = byteBuffer.capacity() * 2;
            while (targetSize < dataEnd) {
                targetSize *= 2;
            }
            ByteBuffer newBuffer = ByteBuffer.allocateDirect(targetSize);
            newBuffer.order(ByteOrder.nativeOrder());
            byteBuffer.position(0);
            byteBuffer.limit(byteBuffer.capacity());
            newBuffer.put(byteBuffer);
            byteBuffer = newBuffer;
        }
    }

    /**
     * Default initial size of the data buffer. This must be a multiple of 8 bytes.
     */
    private static final int INITIAL_BUFFER_SIZE = 1024;

    /**
     * Base offset in the byte buffer for writing.
     */
    private int mBaseOffset;

    /**
     * The encoder state shared by the main encoder and all its sub-encoder.
     */
    private final EncoderState mEncoderState;

    /**
     * Returns the result message.
     */
    public Message getMessage() {
        mEncoderState.byteBuffer.position(0);
        mEncoderState.byteBuffer.limit(mEncoderState.dataEnd);
        return new Message(mEncoderState.byteBuffer, mEncoderState.handles);
    }

    /**
     * Constructor.
     *
     * @param core the |Core| implementation used to generate handles. Only used if the data
     *            structure being encoded contains interfaces, can be |null| otherwise.
     * @param sizeHint A hint on the size of the message. Used to build the initial byte buffer.
     */
    public Encoder(Core core, int sizeHint) {
        this(new EncoderState(core, sizeHint));
    }

    /**
     * Private constructor for sub-encoders.
     */
    private Encoder(EncoderState bufferInformation) {
        mEncoderState = bufferInformation;
        mBaseOffset = bufferInformation.dataEnd;
    }

    /**
     * Returns a new encoder that will append to the current buffer.
     */
    public Encoder getEncoderAtDataOffset(DataHeader dataHeader) {
        Encoder result = new Encoder(mEncoderState);
        result.encode(dataHeader);
        return result;
    }

    /**
     * Encode a {@link DataHeader} and claim the amount of memory required for the data section
     * (resizing the buffer if required).
     */
    public void encode(DataHeader s) {
        mEncoderState.claimMemory(BindingsHelper.align(s.size));
        encode(s.size, DataHeader.SIZE_OFFSET);
        encode(s.elementsOrVersion, DataHeader.ELEMENTS_OR_VERSION_OFFSET);
    }

    /**
     * Encode a byte at the given offset.
     */
    public void encode(byte v, int offset) {
        mEncoderState.byteBuffer.put(mBaseOffset + offset, v);
    }

    /**
     * Encode a boolean at the given offset.
     */
    public void encode(boolean v, int offset, int bit) {
        if (v) {
            byte encodedValue = mEncoderState.byteBuffer.get(mBaseOffset + offset);
            encodedValue |= 1 << bit;
            mEncoderState.byteBuffer.put(mBaseOffset + offset, encodedValue);
        }
    }

    /**
     * Encode a short at the given offset.
     */
    public void encode(short v, int offset) {
        mEncoderState.byteBuffer.putShort(mBaseOffset + offset, v);
    }

    /**
     * Encode an int at the given offset.
     */
    public void encode(int v, int offset) {
        mEncoderState.byteBuffer.putInt(mBaseOffset + offset, v);
    }

    /**
     * Encode a float at the given offset.
     */
    public void encode(float v, int offset) {
        mEncoderState.byteBuffer.putFloat(mBaseOffset + offset, v);
    }

    /**
     * Encode a long at the given offset.
     */
    public void encode(long v, int offset) {
        mEncoderState.byteBuffer.putLong(mBaseOffset + offset, v);
    }

    /**
     * Encode a double at the given offset.
     */
    public void encode(double v, int offset) {
        mEncoderState.byteBuffer.putDouble(mBaseOffset + offset, v);
    }

    /**
     * Encode a {@link Struct} at the given offset.
     */
    public void encode(Struct v, int offset, boolean nullable) {
        if (v == null) {
            encodeNullPointer(offset, nullable);
            return;
        }
        encodePointerToNextUnclaimedData(offset);
        v.encode(this);
    }

    /**
     * Encode a {@link Union} at the given offset.
     */
    public void encode(Union v, int offset, boolean nullable) {
        if (v == null && !nullable) {
            throw new SerializationException(
                    "Trying to encode a null pointer for a non-nullable type.");
        }
        if (v == null) {
            encode(0L, offset);
            encode(0L, offset + DataHeader.HEADER_SIZE);
            return;
        }
        v.encode(this, offset);
    }

    /**
     * Encodes a String.
     */
    public void encode(String v, int offset, boolean nullable) {
        if (v == null) {
            encodeNullPointer(offset, nullable);
            return;
        }
        final int arrayNullability = nullable
                ? BindingsHelper.ARRAY_NULLABLE : BindingsHelper.NOTHING_NULLABLE;
        encode(v.getBytes(Charset.forName("utf8")), offset, arrayNullability,
                BindingsHelper.UNSPECIFIED_ARRAY_LENGTH);
    }

    /**
     * Encodes a {@link Handle}.
     */
    public void encode(Handle v, int offset, boolean nullable) {
        if (v == null || !v.isValid()) {
            encodeInvalidHandle(offset, nullable);
        } else {
            encode(mEncoderState.handles.size(), offset);
            mEncoderState.handles.add(v);
        }
    }

    /**
     * Encode an {@link Interface}.
     */
    public <T extends Interface> void encode(T v, int offset, boolean nullable,
            Interface.Manager<T, ?> manager) {
        if (v == null) {
            encodeInvalidHandle(offset, nullable);
            encode(0, offset + BindingsHelper.SERIALIZED_HANDLE_SIZE);
            return;
        }
        if (mEncoderState.core == null) {
            throw new UnsupportedOperationException(
                    "The encoder has been created without a Core. It can't encode an interface.");
        }
        // If the instance is a proxy, pass the proxy's handle instead of creating a new stub.
        if (v instanceof Interface.Proxy) {
            Handler handler = ((Interface.Proxy) v).getProxyHandler();
            encode(handler.passHandle(), offset, nullable);
            encode(handler.getVersion(), offset + BindingsHelper.SERIALIZED_HANDLE_SIZE);
            return;
        }
        Pair<MessagePipeHandle, MessagePipeHandle> handles =
                mEncoderState.core.createMessagePipe(null);
        manager.bind(v, handles.first);
        encode(handles.second, offset, nullable);
        encode(manager.getVersion(), offset + BindingsHelper.SERIALIZED_HANDLE_SIZE);
    }

    /**
     * Encode an {@link InterfaceRequest}.
     */
    public <I extends Interface> void encode(InterfaceRequest<I> v, int offset, boolean nullable) {
        if (v == null) {
            encodeInvalidHandle(offset, nullable);
            return;
        }
        if (mEncoderState.core == null) {
            throw new UnsupportedOperationException(
                    "The encoder has been created without a Core. It can't encode an interface.");
        }
        encode(v.passHandle(), offset, nullable);
    }

    /**
     * Returns an {@link Encoder} suitable for encoding an array of pointer of the given length.
     */
    public Encoder encodePointerArray(int length, int offset, int expectedLength) {
        return encoderForArray(BindingsHelper.POINTER_SIZE, length, offset, expectedLength);
    }

    /**
     * Returns an {@link Encoder} suitable for encoding an array of union of the given length.
     */
    public Encoder encodeUnionArray(int length, int offset, int expectedLength) {
        return encoderForArray(BindingsHelper.UNION_SIZE, length, offset, expectedLength);
    }

    /**
     * Encodes an array of booleans.
     */
    public void encode(boolean[] v, int offset, int arrayNullability, int expectedLength) {
        if (v == null) {
            encodeNullPointer(offset, BindingsHelper.isArrayNullable(arrayNullability));
            return;
        }
        if (expectedLength != BindingsHelper.UNSPECIFIED_ARRAY_LENGTH
                && expectedLength != v.length) {
            throw new SerializationException("Trying to encode a fixed array of incorrect length.");
        }
        byte[] bytes = new byte[(v.length + 7) / BindingsHelper.ALIGNMENT];
        for (int i = 0; i < bytes.length; ++i) {
            for (int j = 0; j < BindingsHelper.ALIGNMENT; ++j) {
                int booleanIndex = BindingsHelper.ALIGNMENT * i + j;
                if (booleanIndex < v.length && v[booleanIndex]) {
                    bytes[i] |= (1 << j);
                }
            }
        }
        encodeByteArray(bytes, v.length, offset);
    }

    /**
     * Encodes an array of bytes.
     */
    public void encode(byte[] v, int offset, int arrayNullability, int expectedLength) {
        if (v == null) {
            encodeNullPointer(offset, BindingsHelper.isArrayNullable(arrayNullability));
            return;
        }
        if (expectedLength != BindingsHelper.UNSPECIFIED_ARRAY_LENGTH
                && expectedLength != v.length) {
            throw new SerializationException("Trying to encode a fixed array of incorrect length.");
        }
        encodeByteArray(v, v.length, offset);
    }

    /**
     * Encodes an array of shorts.
     */
    public void encode(short[] v, int offset, int arrayNullability, int expectedLength) {
        if (v == null) {
            encodeNullPointer(offset, BindingsHelper.isArrayNullable(arrayNullability));
            return;
        }
        encoderForArray(2, v.length, offset, expectedLength).append(v);
    }

    /**
     * Encodes an array of ints.
     */
    public void encode(int[] v, int offset, int arrayNullability, int expectedLength) {
        if (v == null) {
            encodeNullPointer(offset, BindingsHelper.isArrayNullable(arrayNullability));
            return;
        }
        encoderForArray(4, v.length, offset, expectedLength).append(v);
    }

    /**
     * Encodes an array of floats.
     */
    public void encode(float[] v, int offset, int arrayNullability, int expectedLength) {
        if (v == null) {
            encodeNullPointer(offset, BindingsHelper.isArrayNullable(arrayNullability));
            return;
        }
        encoderForArray(4, v.length, offset, expectedLength).append(v);
    }

    /**
     * Encodes an array of longs.
     */
    public void encode(long[] v, int offset, int arrayNullability, int expectedLength) {
        if (v == null) {
            encodeNullPointer(offset, BindingsHelper.isArrayNullable(arrayNullability));
            return;
        }
        encoderForArray(8, v.length, offset, expectedLength).append(v);
    }

    /**
     * Encodes an array of doubles.
     */
    public void encode(double[] v, int offset, int arrayNullability, int expectedLength) {
        if (v == null) {
            encodeNullPointer(offset, BindingsHelper.isArrayNullable(arrayNullability));
            return;
        }
        encoderForArray(8, v.length, offset, expectedLength).append(v);
    }

    /**
     * Encodes an array of {@link Handle}.
     */
    public void encode(Handle[] v, int offset, int arrayNullability, int expectedLength) {
        if (v == null) {
            encodeNullPointer(offset, BindingsHelper.isArrayNullable(arrayNullability));
            return;
        }
        Encoder e = encoderForArray(
                BindingsHelper.SERIALIZED_HANDLE_SIZE, v.length, offset, expectedLength);
        for (int i = 0; i < v.length; ++i) {
            e.encode(v[i], DataHeader.HEADER_SIZE + BindingsHelper.SERIALIZED_HANDLE_SIZE * i,
                    BindingsHelper.isElementNullable(arrayNullability));
        }
    }

    /**
     * Encodes an array of {@link Interface}.
     */
    public <T extends Interface> void encode(T[] v, int offset, int arrayNullability,
            int expectedLength, Interface.Manager<T, ?> manager) {
        if (v == null) {
            encodeNullPointer(offset, BindingsHelper.isArrayNullable(arrayNullability));
            return;
        }
        Encoder e = encoderForArray(
                BindingsHelper.SERIALIZED_INTERFACE_SIZE, v.length, offset, expectedLength);
        for (int i = 0; i < v.length; ++i) {
            e.encode(v[i], DataHeader.HEADER_SIZE + BindingsHelper.SERIALIZED_INTERFACE_SIZE * i,
                    BindingsHelper.isElementNullable(arrayNullability), manager);
        }
    }

    public Encoder encoderForMap(int offset) {
        encodePointerToNextUnclaimedData(offset);
        return getEncoderAtDataOffset(BindingsHelper.MAP_STRUCT_HEADER);
    }

    /**
     * Encodes a pointer to the next unclaimed memory and returns an encoder suitable to encode an
     * union at this location.
     */
    public Encoder encoderForUnionPointer(int offset) {
        encodePointerToNextUnclaimedData(offset);
        Encoder result = new Encoder(mEncoderState);
        result.mEncoderState.claimMemory(16);
        return result;
    }

    /**
     * Encodes an array of {@link InterfaceRequest}.
     */
    public <I extends Interface> void encode(InterfaceRequest<I>[] v, int offset,
            int arrayNullability, int expectedLength) {
        if (v == null) {
            encodeNullPointer(offset, BindingsHelper.isArrayNullable(arrayNullability));
            return;
        }
        Encoder e = encoderForArray(
                BindingsHelper.SERIALIZED_HANDLE_SIZE, v.length, offset, expectedLength);
        for (int i = 0; i < v.length; ++i) {
            e.encode(v[i], DataHeader.HEADER_SIZE + BindingsHelper.SERIALIZED_HANDLE_SIZE * i,
                    BindingsHelper.isElementNullable(arrayNullability));
        }
    }

    /**
     * Encodes a <code>null</code> pointer iff the object is nullable, raises an exception
     * otherwise.
     */
    public void encodeNullPointer(int offset, boolean nullable) {
        if (!nullable) {
            throw new SerializationException(
                    "Trying to encode a null pointer for a non-nullable type.");
        }
        mEncoderState.byteBuffer.putLong(mBaseOffset + offset, 0);
    }

    /**
     * Encodes an invalid handle iff the object is nullable, raises an exception otherwise.
     */
    public void encodeInvalidHandle(int offset, boolean nullable) {
        if (!nullable) {
            throw new SerializationException(
                    "Trying to encode an invalid handle for a non-nullable type.");
        }
        mEncoderState.byteBuffer.putInt(mBaseOffset + offset, -1);
    }

    /**
     * Claim the given amount of memory at the end of the buffer, resizing it if needed.
     */
    void claimMemory(int size) {
        mEncoderState.claimMemory(BindingsHelper.align(size));
    }

    private void encodePointerToNextUnclaimedData(int offset) {
        encode((long) mEncoderState.dataEnd - (mBaseOffset + offset), offset);
    }

    private Encoder encoderForArray(
            int elementSizeInByte, int length, int offset, int expectedLength) {
        if (expectedLength != BindingsHelper.UNSPECIFIED_ARRAY_LENGTH
                && expectedLength != length) {
            throw new SerializationException("Trying to encode a fixed array of incorrect length.");
        }
        return encoderForArrayByTotalSize(length * elementSizeInByte, length, offset);
    }

    private Encoder encoderForArrayByTotalSize(int byteSize, int length, int offset) {
        encodePointerToNextUnclaimedData(offset);
        return getEncoderAtDataOffset(
                new DataHeader(DataHeader.HEADER_SIZE + byteSize, length));
    }

    private void encodeByteArray(byte[] bytes, int length, int offset) {
        encoderForArrayByTotalSize(bytes.length, length, offset).append(bytes);
    }

    private void append(byte[] v) {
        mEncoderState.byteBuffer.position(mBaseOffset + DataHeader.HEADER_SIZE);
        mEncoderState.byteBuffer.put(v);
    }

    private void append(short[] v) {
        mEncoderState.byteBuffer.position(mBaseOffset + DataHeader.HEADER_SIZE);
        mEncoderState.byteBuffer.asShortBuffer().put(v);
    }

    private void append(int[] v) {
        mEncoderState.byteBuffer.position(mBaseOffset + DataHeader.HEADER_SIZE);
        mEncoderState.byteBuffer.asIntBuffer().put(v);
    }

    private void append(float[] v) {
        mEncoderState.byteBuffer.position(mBaseOffset + DataHeader.HEADER_SIZE);
        mEncoderState.byteBuffer.asFloatBuffer().put(v);
    }

    private void append(double[] v) {
        mEncoderState.byteBuffer.position(mBaseOffset + DataHeader.HEADER_SIZE);
        mEncoderState.byteBuffer.asDoubleBuffer().put(v);
    }

    private void append(long[] v) {
        mEncoderState.byteBuffer.position(mBaseOffset + DataHeader.HEADER_SIZE);
        mEncoderState.byteBuffer.asLongBuffer().put(v);
    }

}
