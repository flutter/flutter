// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.mojo;

import org.chromium.mojo.system.Core;
import org.chromium.mojo.system.Core.WaitResult;
import org.chromium.mojo.system.DataPipe;
import org.chromium.mojo.system.DataPipe.ConsumerHandle;
import org.chromium.mojo.system.DataPipe.ProducerHandle;
import org.chromium.mojo.system.Handle;
import org.chromium.mojo.system.MessagePipeHandle;
import org.chromium.mojo.system.MojoResult;
import org.chromium.mojo.system.ResultAnd;
import org.chromium.mojo.system.SharedBufferHandle;
import org.chromium.mojo.system.UntypedHandle;
import org.chromium.mojo.system.impl.CoreImpl;

import java.nio.ByteBuffer;
import java.util.List;

/**
 * A mock handle, that does nothing.
 */
public class HandleMock implements UntypedHandle, MessagePipeHandle,
        ProducerHandle, ConsumerHandle, SharedBufferHandle {

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
    public WaitResult wait(Core.HandleSignals signals, long deadline) {
        // Do nothing.
        WaitResult result = new WaitResult();
        result.setMojoResult(MojoResult.OK);
        return result;
    }

    /**
     * @see Handle#isValid()
     */
    @Override
    public boolean isValid() {
        return true;
    }

    /**
     * @see Handle#toUntypedHandle()
     */
    @Override
    public UntypedHandle toUntypedHandle() {
        return this;
    }

    /**
     * @see org.chromium.mojo.system.Handle#getCore()
     */
    @Override
    public Core getCore() {
        return CoreImpl.getInstance();
    }

    /**
     * @see org.chromium.mojo.system.UntypedHandle#pass()
     */
    @Override
    public HandleMock pass() {
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
     * @see ConsumerHandle#discardData(int, DataPipe.ReadFlags)
     */
    @Override
    public int discardData(int numBytes, DataPipe.ReadFlags flags) {
        // Do nothing.
        return 0;
    }

    /**
     * @see ConsumerHandle#readData(java.nio.ByteBuffer, DataPipe.ReadFlags)
     */
    @Override
    public ResultAnd<Integer> readData(ByteBuffer elements, DataPipe.ReadFlags flags) {
        // Do nothing.
        return new ResultAnd<Integer>(MojoResult.OK, 0);
    }

    /**
     * @see ConsumerHandle#beginReadData(int, DataPipe.ReadFlags)
     */
    @Override
    public ByteBuffer beginReadData(int numBytes,
            DataPipe.ReadFlags flags) {
        // Do nothing.
        return null;
    }

    /**
     * @see ConsumerHandle#endReadData(int)
     */
    @Override
    public void endReadData(int numBytesRead) {
        // Do nothing.
    }

    /**
     * @see ProducerHandle#writeData(java.nio.ByteBuffer, DataPipe.WriteFlags)
     */
    @Override
    public ResultAnd<Integer> writeData(ByteBuffer elements, DataPipe.WriteFlags flags) {
        // Do nothing.
        return new ResultAnd<Integer>(MojoResult.OK, 0);
    }

    /**
     * @see ProducerHandle#beginWriteData(int, DataPipe.WriteFlags)
     */
    @Override
    public ByteBuffer beginWriteData(int numBytes,
            DataPipe.WriteFlags flags) {
        // Do nothing.
        return null;
    }

    /**
     * @see ProducerHandle#endWriteData(int)
     */
    @Override
    public void endWriteData(int numBytesWritten) {
        // Do nothing.
    }

    /**
     * @see MessagePipeHandle#writeMessage(java.nio.ByteBuffer, java.util.List,
     *      MessagePipeHandle.WriteFlags)
     */
    @Override
    public void writeMessage(ByteBuffer bytes, List<? extends Handle> handles,
            WriteFlags flags) {
        // Do nothing.
    }

    /**
     * @see MessagePipeHandle#readMessage(java.nio.ByteBuffer, int, MessagePipeHandle.ReadFlags)
     */
    @Override
    public ResultAnd<ReadMessageResult> readMessage(
            ByteBuffer bytes, int maxNumberOfHandles, ReadFlags flags) {
        // Do nothing.
        return new ResultAnd<ReadMessageResult>(MojoResult.OK, new ReadMessageResult());
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
        // Do nothing.
        return null;
    }

    /**
     * @see SharedBufferHandle#map(long, long, SharedBufferHandle.MapFlags)
     */
    @Override
    public ByteBuffer map(long offset, long numBytes, MapFlags flags) {
        // Do nothing.
        return null;
    }

    /**
     * @see SharedBufferHandle#unmap(java.nio.ByteBuffer)
     */
    @Override
    public void unmap(ByteBuffer buffer) {
        // Do nothing.
    }

}
