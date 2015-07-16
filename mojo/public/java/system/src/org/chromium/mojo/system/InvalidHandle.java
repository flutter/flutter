// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.mojo.system;

import org.chromium.mojo.system.Core.HandleSignals;
import org.chromium.mojo.system.Core.WaitResult;
import org.chromium.mojo.system.DataPipe.ConsumerHandle;
import org.chromium.mojo.system.DataPipe.ProducerHandle;

import java.nio.ByteBuffer;
import java.util.List;

/**
 * A handle that will always be invalid.
 */
public class InvalidHandle implements UntypedHandle, MessagePipeHandle, ConsumerHandle,
        ProducerHandle, SharedBufferHandle {

    /**
     * Instance singleton.
     */
    public static final InvalidHandle INSTANCE = new InvalidHandle();

    /**
     * Private constructor.
     */
    private InvalidHandle() {
    }

    /**
     * @see Handle#close()
     */
    @Override
    public void close() {
        // Do nothing.
    }

    /**
     * @see Handle#wait(Core.HandleSignals, long)
     */
    @Override
    public WaitResult wait(HandleSignals signals, long deadline) {
        throw new MojoException(MojoResult.INVALID_ARGUMENT);
    }

    /**
     * @see Handle#isValid()
     */
    @Override
    public boolean isValid() {
        return false;
    }

    /**
     * @see Handle#getCore()
     */
    @Override
    public Core getCore() {
        return null;
    }

    /**
     * @see org.chromium.mojo.system.Handle#pass()
     */
    @Override
    public InvalidHandle pass() {
        return this;
    }

    /**
     * @see Handle#toUntypedHandle()
     */
    @Override
    public UntypedHandle toUntypedHandle() {
        return this;
    }

    /**
     * @see Handle#releaseNativeHandle()
     */
    @Override
    public int releaseNativeHandle() {
        return 0;
    }

    /**
     * @see UntypedHandle#toMessagePipeHandle()
     */
    @Override
    public MessagePipeHandle toMessagePipeHandle() {
        return this;
    }

    /**
     * @see UntypedHandle#toDataPipeConsumerHandle()
     */
    @Override
    public ConsumerHandle toDataPipeConsumerHandle() {
        return this;
    }

    /**
     * @see UntypedHandle#toDataPipeProducerHandle()
     */
    @Override
    public ProducerHandle toDataPipeProducerHandle() {
        return this;
    }

    /**
     * @see UntypedHandle#toSharedBufferHandle()
     */
    @Override
    public SharedBufferHandle toSharedBufferHandle() {
        return this;
    }

    /**
     * @see SharedBufferHandle#duplicate(SharedBufferHandle.DuplicateOptions)
     */
    @Override
    public SharedBufferHandle duplicate(DuplicateOptions options) {
        throw new MojoException(MojoResult.INVALID_ARGUMENT);
    }

    /**
     * @see SharedBufferHandle#map(long, long, SharedBufferHandle.MapFlags)
     */
    @Override
    public ByteBuffer map(long offset, long numBytes, MapFlags flags) {
        throw new MojoException(MojoResult.INVALID_ARGUMENT);
    }

    /**
     * @see SharedBufferHandle#unmap(java.nio.ByteBuffer)
     */
    @Override
    public void unmap(ByteBuffer buffer) {
        throw new MojoException(MojoResult.INVALID_ARGUMENT);
    }

    /**
     * @see DataPipe.ProducerHandle#writeData(java.nio.ByteBuffer, DataPipe.WriteFlags)
     */
    @Override
    public ResultAnd<Integer> writeData(ByteBuffer elements, DataPipe.WriteFlags flags) {
        throw new MojoException(MojoResult.INVALID_ARGUMENT);
    }

    /**
     * @see DataPipe.ProducerHandle#beginWriteData(int, DataPipe.WriteFlags)
     */
    @Override
    public ByteBuffer beginWriteData(int numBytes,
            DataPipe.WriteFlags flags) {
        throw new MojoException(MojoResult.INVALID_ARGUMENT);
    }

    /**
     * @see DataPipe.ProducerHandle#endWriteData(int)
     */
    @Override
    public void endWriteData(int numBytesWritten) {
        throw new MojoException(MojoResult.INVALID_ARGUMENT);
    }

    /**
     * @see DataPipe.ConsumerHandle#discardData(int, DataPipe.ReadFlags)
     */
    @Override
    public int discardData(int numBytes, DataPipe.ReadFlags flags) {
        throw new MojoException(MojoResult.INVALID_ARGUMENT);
    }

    /**
     * @see DataPipe.ConsumerHandle#readData(java.nio.ByteBuffer, DataPipe.ReadFlags)
     */
    @Override
    public ResultAnd<Integer> readData(ByteBuffer elements, DataPipe.ReadFlags flags) {
        throw new MojoException(MojoResult.INVALID_ARGUMENT);
    }

    /**
     * @see DataPipe.ConsumerHandle#beginReadData(int, DataPipe.ReadFlags)
     */
    @Override
    public ByteBuffer beginReadData(int numBytes,
            DataPipe.ReadFlags flags) {
        throw new MojoException(MojoResult.INVALID_ARGUMENT);
    }

    /**
     * @see DataPipe.ConsumerHandle#endReadData(int)
     */
    @Override
    public void endReadData(int numBytesRead) {
        throw new MojoException(MojoResult.INVALID_ARGUMENT);
    }

    /**
     * @see MessagePipeHandle#writeMessage(java.nio.ByteBuffer, java.util.List,
     *      MessagePipeHandle.WriteFlags)
     */
    @Override
    public void writeMessage(ByteBuffer bytes, List<? extends Handle> handles, WriteFlags flags) {
        throw new MojoException(MojoResult.INVALID_ARGUMENT);
    }

    /**
     * @see MessagePipeHandle#readMessage(java.nio.ByteBuffer, int, MessagePipeHandle.ReadFlags)
     */
    @Override
    public ResultAnd<ReadMessageResult> readMessage(
            ByteBuffer bytes, int maxNumberOfHandles, ReadFlags flags) {
        throw new MojoException(MojoResult.INVALID_ARGUMENT);
    }

}
