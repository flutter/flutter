// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.mojo.system.impl;

import android.test.suitebuilder.annotation.SmallTest;

import org.chromium.mojo.MojoTestCase;
import org.chromium.mojo.system.AsyncWaiter;
import org.chromium.mojo.system.AsyncWaiter.Callback;
import org.chromium.mojo.system.AsyncWaiter.Cancellable;
import org.chromium.mojo.system.Core;
import org.chromium.mojo.system.Core.HandleSignals;
import org.chromium.mojo.system.Core.HandleSignalsState;
import org.chromium.mojo.system.Core.WaitManyResult;
import org.chromium.mojo.system.Core.WaitResult;
import org.chromium.mojo.system.DataPipe;
import org.chromium.mojo.system.Handle;
import org.chromium.mojo.system.InvalidHandle;
import org.chromium.mojo.system.MessagePipeHandle;
import org.chromium.mojo.system.MojoException;
import org.chromium.mojo.system.MojoResult;
import org.chromium.mojo.system.Pair;
import org.chromium.mojo.system.ResultAnd;
import org.chromium.mojo.system.SharedBufferHandle;

import java.nio.ByteBuffer;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;
import java.util.Random;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.TimeUnit;

/**
 * Testing the core API.
 */
public class CoreImplTest extends MojoTestCase {
    private static final long RUN_LOOP_TIMEOUT_MS = 5;

    private static final ScheduledExecutorService WORKER =
            Executors.newSingleThreadScheduledExecutor();

    private static final HandleSignals ALL_SIGNALS =
            HandleSignals.none().setPeerClosed(true).setReadable(true).setWritable(true);

    private List<Handle> mHandlesToClose = new ArrayList<Handle>();

    /**
     * @see MojoTestCase#tearDown()
     */
    @Override
    protected void tearDown() throws Exception {
        MojoException toThrow = null;
        for (Handle handle : mHandlesToClose) {
            try {
                handle.close();
            } catch (MojoException e) {
                if (toThrow == null) {
                    toThrow = e;
                }
            }
        }
        if (toThrow != null) {
            throw toThrow;
        }
        super.tearDown();
    }

    private void addHandleToClose(Handle handle) {
        mHandlesToClose.add(handle);
    }

    private void addHandlePairToClose(Pair<? extends Handle, ? extends Handle> handles) {
        mHandlesToClose.add(handles.first);
        mHandlesToClose.add(handles.second);
    }

    /**
     * Runnable that will close the given handle.
     */
    private static class CloseHandle implements Runnable {
        private Handle mHandle;

        CloseHandle(Handle handle) {
            mHandle = handle;
        }

        @Override
        public void run() {
            mHandle.close();
        }
    }

    private static void checkSendingMessage(MessagePipeHandle in, MessagePipeHandle out) {
        Random random = new Random();

        // Writing a random 8 bytes message.
        byte[] bytes = new byte[8];
        random.nextBytes(bytes);
        ByteBuffer buffer = ByteBuffer.allocateDirect(bytes.length);
        buffer.put(bytes);
        in.writeMessage(buffer, null, MessagePipeHandle.WriteFlags.NONE);

        // Try to read into a small buffer.
        ByteBuffer receiveBuffer = ByteBuffer.allocateDirect(bytes.length / 2);
        ResultAnd<MessagePipeHandle.ReadMessageResult> result =
                out.readMessage(receiveBuffer, 0, MessagePipeHandle.ReadFlags.NONE);
        assertEquals(MojoResult.RESOURCE_EXHAUSTED, result.getMojoResult());
        assertEquals(bytes.length, result.getValue().getMessageSize());
        assertEquals(0, result.getValue().getHandlesCount());

        // Read into a correct buffer.
        receiveBuffer = ByteBuffer.allocateDirect(bytes.length);
        result = out.readMessage(receiveBuffer, 0, MessagePipeHandle.ReadFlags.NONE);
        assertEquals(MojoResult.OK, result.getMojoResult());
        assertEquals(bytes.length, result.getValue().getMessageSize());
        assertEquals(0, result.getValue().getHandlesCount());
        assertEquals(0, receiveBuffer.position());
        assertEquals(result.getValue().getMessageSize(), receiveBuffer.limit());
        byte[] receivedBytes = new byte[result.getValue().getMessageSize()];
        receiveBuffer.get(receivedBytes);
        assertTrue(Arrays.equals(bytes, receivedBytes));
    }

    private static void checkSendingData(DataPipe.ProducerHandle in, DataPipe.ConsumerHandle out) {
        Random random = new Random();

        // Writing a random 8 bytes message.
        byte[] bytes = new byte[8];
        random.nextBytes(bytes);
        ByteBuffer buffer = ByteBuffer.allocateDirect(bytes.length);
        buffer.put(bytes);
        ResultAnd<Integer> result = in.writeData(buffer, DataPipe.WriteFlags.NONE);
        assertEquals(MojoResult.OK, result.getMojoResult());
        assertEquals(bytes.length, result.getValue().intValue());

        // Query number of bytes available.
        ResultAnd<Integer> readResult = out.readData(null, DataPipe.ReadFlags.none().query(true));
        assertEquals(MojoResult.OK, readResult.getMojoResult());
        assertEquals(bytes.length, readResult.getValue().intValue());

        // Peek data into a buffer.
        ByteBuffer peekBuffer = ByteBuffer.allocateDirect(bytes.length);
        readResult = out.readData(peekBuffer, DataPipe.ReadFlags.none().peek(true));
        assertEquals(MojoResult.OK, readResult.getMojoResult());
        assertEquals(bytes.length, readResult.getValue().intValue());
        assertEquals(bytes.length, peekBuffer.limit());
        byte[] peekBytes = new byte[bytes.length];
        peekBuffer.get(peekBytes);
        assertTrue(Arrays.equals(bytes, peekBytes));

        // Read into a buffer.
        ByteBuffer receiveBuffer = ByteBuffer.allocateDirect(bytes.length);
        readResult = out.readData(receiveBuffer, DataPipe.ReadFlags.NONE);
        assertEquals(MojoResult.OK, readResult.getMojoResult());
        assertEquals(bytes.length, readResult.getValue().intValue());
        assertEquals(0, receiveBuffer.position());
        assertEquals(bytes.length, receiveBuffer.limit());
        byte[] receivedBytes = new byte[bytes.length];
        receiveBuffer.get(receivedBytes);
        assertTrue(Arrays.equals(bytes, receivedBytes));
    }

    private static void checkSharing(SharedBufferHandle in, SharedBufferHandle out) {
        Random random = new Random();

        ByteBuffer buffer1 = in.map(0, 8, SharedBufferHandle.MapFlags.NONE);
        assertEquals(8, buffer1.capacity());
        ByteBuffer buffer2 = out.map(0, 8, SharedBufferHandle.MapFlags.NONE);
        assertEquals(8, buffer2.capacity());

        byte[] bytes = new byte[8];
        random.nextBytes(bytes);
        buffer1.put(bytes);

        byte[] receivedBytes = new byte[bytes.length];
        buffer2.get(receivedBytes);

        assertTrue(Arrays.equals(bytes, receivedBytes));

        in.unmap(buffer1);
        out.unmap(buffer2);
    }

    /**
     * Testing {@link Core#waitMany(List, long)}.
     */
    @SmallTest
    public void testWaitMany() {
        Core core = CoreImpl.getInstance();
        Pair<MessagePipeHandle, MessagePipeHandle> handles = core.createMessagePipe(null);
        addHandlePairToClose(handles);

        // Test waiting on handles of a newly created message pipe - each should be writable, but
        // not readable.
        List<Pair<Handle, Core.HandleSignals>> handlesToWaitOn =
                new ArrayList<Pair<Handle, Core.HandleSignals>>();
        handlesToWaitOn.add(
                new Pair<Handle, Core.HandleSignals>(handles.second, Core.HandleSignals.READABLE));
        handlesToWaitOn.add(
                new Pair<Handle, Core.HandleSignals>(handles.first, Core.HandleSignals.WRITABLE));
        WaitManyResult result = core.waitMany(handlesToWaitOn, 0);
        assertEquals(MojoResult.OK, result.getMojoResult());
        assertEquals(1, result.getHandleIndex());
        for (HandleSignalsState state : result.getSignalStates()) {
            assertEquals(HandleSignals.WRITABLE, state.getSatisfiedSignals());
            assertEquals(ALL_SIGNALS, state.getSatisfiableSignals());
        }

        // Same test, but swap the handles around.
        handlesToWaitOn.clear();
        handlesToWaitOn.add(
                new Pair<Handle, Core.HandleSignals>(handles.first, Core.HandleSignals.WRITABLE));
        handlesToWaitOn.add(
                new Pair<Handle, Core.HandleSignals>(handles.second, Core.HandleSignals.READABLE));
        result = core.waitMany(handlesToWaitOn, 0);
        assertEquals(MojoResult.OK, result.getMojoResult());
        assertEquals(0, result.getHandleIndex());
        for (HandleSignalsState state : result.getSignalStates()) {
            assertEquals(HandleSignals.WRITABLE, state.getSatisfiedSignals());
            assertEquals(ALL_SIGNALS, state.getSatisfiableSignals());
        }
    }

    /**
     * Testing that Core can be retrieved from a handle.
     */
    @SmallTest
    public void testGetCore() {
        Core core = CoreImpl.getInstance();

        Pair<? extends Handle, ? extends Handle> handles = core.createMessagePipe(null);
        addHandlePairToClose(handles);
        assertEquals(core, handles.first.getCore());
        assertEquals(core, handles.second.getCore());

        handles = core.createDataPipe(null);
        addHandlePairToClose(handles);
        assertEquals(core, handles.first.getCore());
        assertEquals(core, handles.second.getCore());

        SharedBufferHandle handle = core.createSharedBuffer(null, 100);
        SharedBufferHandle handle2 = handle.duplicate(null);
        addHandleToClose(handle);
        addHandleToClose(handle2);
        assertEquals(core, handle.getCore());
        assertEquals(core, handle2.getCore());
    }

    private static void createAndCloseMessagePipe(MessagePipeHandle.CreateOptions options) {
        Core core = CoreImpl.getInstance();
        Pair<MessagePipeHandle, MessagePipeHandle> handles = core.createMessagePipe(options);
        handles.first.close();
        handles.second.close();
    }

    /**
     * Testing {@link MessagePipeHandle} creation.
     */
    @SmallTest
    public void testMessagePipeCreation() {
        // Test creation with null options.
        createAndCloseMessagePipe(null);
        // Test creation with default options.
        createAndCloseMessagePipe(new MessagePipeHandle.CreateOptions());
    }

    /**
     * Testing {@link MessagePipeHandle}.
     */
    @SmallTest
    public void testMessagePipeEmpty() {
        Core core = CoreImpl.getInstance();
        Pair<MessagePipeHandle, MessagePipeHandle> handles = core.createMessagePipe(null);
        addHandlePairToClose(handles);
        // Test waiting on handles of a newly created message pipe.
        WaitResult waitResult = handles.first.wait(
                Core.HandleSignals.none().setReadable(true).setWritable(true), 0);
        assertEquals(MojoResult.OK, waitResult.getMojoResult());
        assertEquals(
                HandleSignals.WRITABLE, waitResult.getHandleSignalsState().getSatisfiedSignals());
        assertEquals(ALL_SIGNALS, waitResult.getHandleSignalsState().getSatisfiableSignals());

        waitResult = handles.first.wait(Core.HandleSignals.WRITABLE, 0);
        assertEquals(MojoResult.OK, waitResult.getMojoResult());
        assertEquals(
                HandleSignals.WRITABLE, waitResult.getHandleSignalsState().getSatisfiedSignals());
        assertEquals(ALL_SIGNALS, waitResult.getHandleSignalsState().getSatisfiableSignals());

        waitResult = handles.first.wait(Core.HandleSignals.READABLE, 0);
        assertEquals(MojoResult.DEADLINE_EXCEEDED, waitResult.getMojoResult());
        assertEquals(
                HandleSignals.WRITABLE, waitResult.getHandleSignalsState().getSatisfiedSignals());
        assertEquals(ALL_SIGNALS, waitResult.getHandleSignalsState().getSatisfiableSignals());

        // Testing read on an empty pipe.
        ResultAnd<MessagePipeHandle.ReadMessageResult> readResult =
                handles.first.readMessage(null, 0, MessagePipeHandle.ReadFlags.NONE);
        assertEquals(MojoResult.SHOULD_WAIT, readResult.getMojoResult());

        // Closing a pipe while waiting.
        WORKER.schedule(new CloseHandle(handles.first), 10, TimeUnit.MILLISECONDS);
        waitResult = handles.first.wait(Core.HandleSignals.READABLE, 1000000L);
        assertEquals(MojoResult.CANCELLED, waitResult.getMojoResult());
        assertEquals(
                HandleSignals.none(), waitResult.getHandleSignalsState().getSatisfiedSignals());
        assertEquals(
                HandleSignals.none(), waitResult.getHandleSignalsState().getSatisfiableSignals());

        handles = core.createMessagePipe(null);
        addHandlePairToClose(handles);

        // Closing the other pipe while waiting.
        WORKER.schedule(new CloseHandle(handles.first), 10, TimeUnit.MILLISECONDS);
        waitResult = handles.second.wait(Core.HandleSignals.READABLE, 1000000L);
        assertEquals(MojoResult.FAILED_PRECONDITION, waitResult.getMojoResult());

        // Waiting on a closed pipe.
        waitResult = handles.second.wait(Core.HandleSignals.READABLE, 0);
        assertEquals(MojoResult.FAILED_PRECONDITION, waitResult.getMojoResult());
        waitResult = handles.second.wait(Core.HandleSignals.WRITABLE, 0);
        assertEquals(MojoResult.FAILED_PRECONDITION, waitResult.getMojoResult());
    }

    /**
     * Testing {@link MessagePipeHandle}.
     */
    @SmallTest
    public void testMessagePipeSend() {
        Core core = CoreImpl.getInstance();
        Pair<MessagePipeHandle, MessagePipeHandle> handles = core.createMessagePipe(null);
        addHandlePairToClose(handles);

        checkSendingMessage(handles.first, handles.second);
        checkSendingMessage(handles.second, handles.first);
    }

    /**
     * Testing {@link MessagePipeHandle}.
     */
    @SmallTest
    public void testMessagePipeReceiveOnSmallBuffer() {
        Random random = new Random();
        Core core = CoreImpl.getInstance();
        Pair<MessagePipeHandle, MessagePipeHandle> handles = core.createMessagePipe(null);
        addHandlePairToClose(handles);

        // Writing a random 8 bytes message.
        byte[] bytes = new byte[8];
        random.nextBytes(bytes);
        ByteBuffer buffer = ByteBuffer.allocateDirect(bytes.length);
        buffer.put(bytes);
        handles.first.writeMessage(buffer, null, MessagePipeHandle.WriteFlags.NONE);

        ByteBuffer receiveBuffer = ByteBuffer.allocateDirect(1);
        ResultAnd<MessagePipeHandle.ReadMessageResult> result =
                handles.second.readMessage(receiveBuffer, 0, MessagePipeHandle.ReadFlags.NONE);
        assertEquals(MojoResult.RESOURCE_EXHAUSTED, result.getMojoResult());
        assertEquals(bytes.length, result.getValue().getMessageSize());
        assertEquals(0, result.getValue().getHandlesCount());
    }

    /**
     * Testing {@link MessagePipeHandle}.
     */
    @SmallTest
    public void testMessagePipeSendHandles() {
        Core core = CoreImpl.getInstance();
        Pair<MessagePipeHandle, MessagePipeHandle> handles = core.createMessagePipe(null);
        Pair<MessagePipeHandle, MessagePipeHandle> handlesToShare = core.createMessagePipe(null);
        addHandlePairToClose(handles);
        addHandlePairToClose(handlesToShare);

        handles.first.writeMessage(null, Collections.<Handle>singletonList(handlesToShare.second),
                MessagePipeHandle.WriteFlags.NONE);
        assertFalse(handlesToShare.second.isValid());
        ResultAnd<MessagePipeHandle.ReadMessageResult> readMessageResult =
                handles.second.readMessage(null, 1, MessagePipeHandle.ReadFlags.NONE);
        assertEquals(1, readMessageResult.getValue().getHandlesCount());
        MessagePipeHandle newHandle =
                readMessageResult.getValue().getHandles().get(0).toMessagePipeHandle();
        addHandleToClose(newHandle);
        assertTrue(newHandle.isValid());
        checkSendingMessage(handlesToShare.first, newHandle);
        checkSendingMessage(newHandle, handlesToShare.first);
    }

    private static void createAndCloseDataPipe(DataPipe.CreateOptions options) {
        Core core = CoreImpl.getInstance();
        Pair<DataPipe.ProducerHandle, DataPipe.ConsumerHandle> handles =
                core.createDataPipe(options);
        handles.first.close();
        handles.second.close();
    }

    /**
     * Testing {@link DataPipe}.
     */
    @SmallTest
    public void testDataPipeCreation() {
        // Create datapipe with null options.
        createAndCloseDataPipe(null);
        DataPipe.CreateOptions options = new DataPipe.CreateOptions();
        // Create datapipe with element size set.
        options.setElementNumBytes(24);
        createAndCloseDataPipe(options);
        // Create datapipe with capacity set.
        options.setCapacityNumBytes(1024 * options.getElementNumBytes());
        createAndCloseDataPipe(options);
    }

    /**
     * Testing {@link DataPipe}.
     */
    @SmallTest
    public void testDataPipeSend() {
        Core core = CoreImpl.getInstance();

        Pair<DataPipe.ProducerHandle, DataPipe.ConsumerHandle> handles = core.createDataPipe(null);
        addHandlePairToClose(handles);

        checkSendingData(handles.first, handles.second);
    }

    /**
     * Testing {@link DataPipe}.
     */
    @SmallTest
    public void testDataPipeTwoPhaseSend() {
        Random random = new Random();
        Core core = CoreImpl.getInstance();
        Pair<DataPipe.ProducerHandle, DataPipe.ConsumerHandle> handles = core.createDataPipe(null);
        addHandlePairToClose(handles);

        // Writing a random 8 bytes message.
        byte[] bytes = new byte[8];
        random.nextBytes(bytes);
        ByteBuffer buffer = handles.first.beginWriteData(bytes.length, DataPipe.WriteFlags.NONE);
        assertTrue(buffer.capacity() >= bytes.length);
        buffer.put(bytes);
        handles.first.endWriteData(bytes.length);

        // Read into a buffer.
        ByteBuffer receiveBuffer =
                handles.second.beginReadData(bytes.length, DataPipe.ReadFlags.NONE);
        assertEquals(0, receiveBuffer.position());
        assertEquals(bytes.length, receiveBuffer.limit());
        byte[] receivedBytes = new byte[bytes.length];
        receiveBuffer.get(receivedBytes);
        assertTrue(Arrays.equals(bytes, receivedBytes));
        handles.second.endReadData(bytes.length);
    }

    /**
     * Testing {@link DataPipe}.
     */
    @SmallTest
    public void testDataPipeDiscard() {
        Random random = new Random();
        Core core = CoreImpl.getInstance();
        Pair<DataPipe.ProducerHandle, DataPipe.ConsumerHandle> handles = core.createDataPipe(null);
        addHandlePairToClose(handles);

        // Writing a random 8 bytes message.
        byte[] bytes = new byte[8];
        random.nextBytes(bytes);
        ByteBuffer buffer = ByteBuffer.allocateDirect(bytes.length);
        buffer.put(bytes);
        ResultAnd<Integer> result = handles.first.writeData(buffer, DataPipe.WriteFlags.NONE);
        assertEquals(MojoResult.OK, result.getMojoResult());
        assertEquals(bytes.length, result.getValue().intValue());

        // Discard bytes.
        final int nbBytesToDiscard = 4;
        assertEquals(nbBytesToDiscard,
                handles.second.discardData(nbBytesToDiscard, DataPipe.ReadFlags.NONE));

        // Read into a buffer.
        ByteBuffer receiveBuffer = ByteBuffer.allocateDirect(bytes.length - nbBytesToDiscard);
        ResultAnd<Integer> readResult =
                handles.second.readData(receiveBuffer, DataPipe.ReadFlags.NONE);
        assertEquals(MojoResult.OK, readResult.getMojoResult());
        assertEquals(bytes.length - nbBytesToDiscard, readResult.getValue().intValue());
        assertEquals(0, receiveBuffer.position());
        assertEquals(bytes.length - nbBytesToDiscard, receiveBuffer.limit());
        byte[] receivedBytes = new byte[bytes.length - nbBytesToDiscard];
        receiveBuffer.get(receivedBytes);
        assertTrue(Arrays.equals(
                Arrays.copyOfRange(bytes, nbBytesToDiscard, bytes.length), receivedBytes));
    }

    /**
     * Testing {@link SharedBufferHandle}.
     */
    @SmallTest
    public void testSharedBufferCreation() {
        Core core = CoreImpl.getInstance();
        // Test creation with empty options.
        core.createSharedBuffer(null, 8).close();
        // Test creation with default options.
        core.createSharedBuffer(new SharedBufferHandle.CreateOptions(), 8).close();
    }

    /**
     * Testing {@link SharedBufferHandle}.
     */
    @SmallTest
    public void testSharedBufferDuplication() {
        Core core = CoreImpl.getInstance();
        SharedBufferHandle handle = core.createSharedBuffer(null, 8);
        addHandleToClose(handle);

        // Test duplication with empty options.
        handle.duplicate(null).close();
        // Test creation with default options.
        handle.duplicate(new SharedBufferHandle.DuplicateOptions()).close();
    }

    /**
     * Testing {@link SharedBufferHandle}.
     */
    @SmallTest
    public void testSharedBufferSending() {
        Core core = CoreImpl.getInstance();
        SharedBufferHandle handle = core.createSharedBuffer(null, 8);
        addHandleToClose(handle);
        SharedBufferHandle newHandle = handle.duplicate(null);
        addHandleToClose(newHandle);

        checkSharing(handle, newHandle);
        checkSharing(newHandle, handle);
    }

    /**
     * Testing that invalid handle can be used with this implementation.
     */
    @SmallTest
    public void testInvalidHandle() {
        Core core = CoreImpl.getInstance();
        Handle handle = InvalidHandle.INSTANCE;

        // Checking wait.
        boolean exception = false;
        try {
            core.wait(handle, Core.HandleSignals.WRITABLE, 0);
        } catch (MojoException e) {
            assertEquals(MojoResult.INVALID_ARGUMENT, e.getMojoResult());
            exception = true;
        }
        assertTrue(exception);

        // Checking waitMany.
        exception = false;
        try {
            List<Pair<Handle, Core.HandleSignals>> handles =
                    new ArrayList<Pair<Handle, Core.HandleSignals>>();
            handles.add(Pair.create(handle, Core.HandleSignals.WRITABLE));
            core.waitMany(handles, 0);
        } catch (MojoException e) {
            assertEquals(MojoResult.INVALID_ARGUMENT, e.getMojoResult());
            exception = true;
        }
        assertTrue(exception);

        // Checking sending an invalid handle.
        // Until the behavior is changed on the C++ side, handle gracefully 2 different use case:
        // - Receive a INVALID_ARGUMENT exception
        // - Receive an invalid handle on the other side.
        Pair<MessagePipeHandle, MessagePipeHandle> handles = core.createMessagePipe(null);
        addHandlePairToClose(handles);
        try {
            handles.first.writeMessage(null, Collections.<Handle>singletonList(handle),
                    MessagePipeHandle.WriteFlags.NONE);
            ResultAnd<MessagePipeHandle.ReadMessageResult> readMessageResult =
                    handles.second.readMessage(null, 1, MessagePipeHandle.ReadFlags.NONE);
            assertEquals(1, readMessageResult.getValue().getHandlesCount());
            assertFalse(readMessageResult.getValue().getHandles().get(0).isValid());
        } catch (MojoException e) {
            assertEquals(MojoResult.INVALID_ARGUMENT, e.getMojoResult());
        }
    }

    private static class AsyncWaiterResult implements Callback {
        private int mResult = Integer.MIN_VALUE;
        private MojoException mException = null;

        /**
         * @see Callback#onResult(int)
         */
        @Override
        public void onResult(int result) {
            this.mResult = result;
        }

        /**
         * @see Callback#onError(MojoException)
         */
        @Override
        public void onError(MojoException exception) {
            this.mException = exception;
        }

        /**
         * @return the result
         */
        public int getResult() {
            return mResult;
        }

        /**
         * @return the exception
         */
        public MojoException getException() {
            return mException;
        }
    }

    /**
     * Testing core {@link AsyncWaiter} implementation.
     */
    @SmallTest
    public void testAsyncWaiterCorrectResult() {
        Core core = CoreImpl.getInstance();

        // Checking a correct result.
        Pair<MessagePipeHandle, MessagePipeHandle> handles = core.createMessagePipe(null);
        addHandlePairToClose(handles);
        final AsyncWaiterResult asyncWaiterResult = new AsyncWaiterResult();
        assertEquals(Integer.MIN_VALUE, asyncWaiterResult.getResult());
        assertEquals(null, asyncWaiterResult.getException());

        core.getDefaultAsyncWaiter().asyncWait(handles.first, Core.HandleSignals.READABLE,
                Core.DEADLINE_INFINITE, asyncWaiterResult);
        assertEquals(Integer.MIN_VALUE, asyncWaiterResult.getResult());
        assertEquals(null, asyncWaiterResult.getException());

        handles.second.writeMessage(
                ByteBuffer.allocateDirect(1), null, MessagePipeHandle.WriteFlags.NONE);
        runLoopUntilIdle();
        assertNull(asyncWaiterResult.getException());
        assertEquals(MojoResult.OK, asyncWaiterResult.getResult());
    }

    /**
     * Testing core {@link AsyncWaiter} implementation.
     */
    @SmallTest
    public void testAsyncWaiterClosingPeerHandle() {
        Core core = CoreImpl.getInstance();

        // Closing the peer handle.
        Pair<MessagePipeHandle, MessagePipeHandle> handles = core.createMessagePipe(null);
        addHandlePairToClose(handles);

        final AsyncWaiterResult asyncWaiterResult = new AsyncWaiterResult();
        assertEquals(Integer.MIN_VALUE, asyncWaiterResult.getResult());
        assertEquals(null, asyncWaiterResult.getException());

        core.getDefaultAsyncWaiter().asyncWait(handles.first, Core.HandleSignals.READABLE,
                Core.DEADLINE_INFINITE, asyncWaiterResult);
        assertEquals(Integer.MIN_VALUE, asyncWaiterResult.getResult());
        assertEquals(null, asyncWaiterResult.getException());

        runLoopUntilIdle();
        assertEquals(Integer.MIN_VALUE, asyncWaiterResult.getResult());
        assertEquals(null, asyncWaiterResult.getException());

        handles.second.close();
        runLoopUntilIdle();
        assertNull(asyncWaiterResult.getException());
        assertEquals(MojoResult.FAILED_PRECONDITION, asyncWaiterResult.getResult());
    }

    /**
     * Testing core {@link AsyncWaiter} implementation.
     */
    @SmallTest
    public void testAsyncWaiterClosingWaitingHandle() {
        Core core = CoreImpl.getInstance();

        // Closing the peer handle.
        Pair<MessagePipeHandle, MessagePipeHandle> handles = core.createMessagePipe(null);
        addHandlePairToClose(handles);

        final AsyncWaiterResult asyncWaiterResult = new AsyncWaiterResult();
        assertEquals(Integer.MIN_VALUE, asyncWaiterResult.getResult());
        assertEquals(null, asyncWaiterResult.getException());

        Cancellable cancellable = core.getDefaultAsyncWaiter().asyncWait(handles.first,
                Core.HandleSignals.READABLE, Core.DEADLINE_INFINITE, asyncWaiterResult);
        assertEquals(Integer.MIN_VALUE, asyncWaiterResult.getResult());
        assertEquals(null, asyncWaiterResult.getException());

        runLoopUntilIdle();
        assertEquals(Integer.MIN_VALUE, asyncWaiterResult.getResult());
        assertEquals(null, asyncWaiterResult.getException());

        cancellable.cancel();
        runLoopUntilIdle();
        // TODO(qsr) Re-enable when MojoWaitMany handles it correctly.
        // assertNull(asyncWaiterResult.getException());
        // assertEquals(MojoResult.CANCELLED, asyncWaiterResult.getResult());
    }

    /**
     * Testing core {@link AsyncWaiter} implementation.
     */
    @SmallTest
    public void testAsyncWaiterWaitingWithTimeout() {
        Core core = CoreImpl.getInstance();

        // Closing the peer handle.
        Pair<MessagePipeHandle, MessagePipeHandle> handles = core.createMessagePipe(null);
        addHandlePairToClose(handles);

        final AsyncWaiterResult asyncWaiterResult = new AsyncWaiterResult();
        assertEquals(Integer.MIN_VALUE, asyncWaiterResult.getResult());
        assertEquals(null, asyncWaiterResult.getException());

        core.getDefaultAsyncWaiter().asyncWait(
                handles.first, Core.HandleSignals.READABLE, RUN_LOOP_TIMEOUT_MS, asyncWaiterResult);
        assertEquals(Integer.MIN_VALUE, asyncWaiterResult.getResult());
        assertEquals(null, asyncWaiterResult.getException());

        runLoopUntilIdle();
        assertNull(asyncWaiterResult.getException());
        assertEquals(MojoResult.DEADLINE_EXCEEDED, asyncWaiterResult.getResult());
    }

    /**
     * Testing core {@link AsyncWaiter} implementation.
     */
    @SmallTest
    public void testAsyncWaiterCancelWaiting() {
        Core core = CoreImpl.getInstance();

        // Closing the peer handle.
        Pair<MessagePipeHandle, MessagePipeHandle> handles = core.createMessagePipe(null);
        addHandlePairToClose(handles);

        final AsyncWaiterResult asyncWaiterResult = new AsyncWaiterResult();
        assertEquals(Integer.MIN_VALUE, asyncWaiterResult.getResult());
        assertEquals(null, asyncWaiterResult.getException());

        Cancellable cancellable = core.getDefaultAsyncWaiter().asyncWait(handles.first,
                Core.HandleSignals.READABLE, Core.DEADLINE_INFINITE, asyncWaiterResult);
        assertEquals(Integer.MIN_VALUE, asyncWaiterResult.getResult());
        assertEquals(null, asyncWaiterResult.getException());

        runLoopUntilIdle();
        assertEquals(Integer.MIN_VALUE, asyncWaiterResult.getResult());
        assertEquals(null, asyncWaiterResult.getException());

        cancellable.cancel();
        runLoopUntilIdle();
        assertEquals(Integer.MIN_VALUE, asyncWaiterResult.getResult());
        assertEquals(null, asyncWaiterResult.getException());

        handles.second.writeMessage(
                ByteBuffer.allocateDirect(1), null, MessagePipeHandle.WriteFlags.NONE);
        runLoopUntilIdle();
        assertEquals(Integer.MIN_VALUE, asyncWaiterResult.getResult());
        assertEquals(null, asyncWaiterResult.getException());
    }

    /**
     * Testing core {@link AsyncWaiter} implementation.
     */
    @SmallTest
    public void testAsyncWaiterImmediateCancelOnInvalidHandle() {
        Core core = CoreImpl.getInstance();

        // Closing the peer handle.
        Pair<MessagePipeHandle, MessagePipeHandle> handles = core.createMessagePipe(null);
        addHandlePairToClose(handles);

        final AsyncWaiterResult asyncWaiterResult = new AsyncWaiterResult();
        handles.first.close();
        assertEquals(Integer.MIN_VALUE, asyncWaiterResult.getResult());
        assertEquals(null, asyncWaiterResult.getException());

        Cancellable cancellable = core.getDefaultAsyncWaiter().asyncWait(handles.first,
                Core.HandleSignals.READABLE, Core.DEADLINE_INFINITE, asyncWaiterResult);
        assertEquals(Integer.MIN_VALUE, asyncWaiterResult.getResult());
        assertEquals(null, asyncWaiterResult.getException());
        cancellable.cancel();

        runLoopUntilIdle();
        assertEquals(Integer.MIN_VALUE, asyncWaiterResult.getResult());
        assertEquals(null, asyncWaiterResult.getException());
    }

    /**
     * Testing the pass method on message pipes.
     */
    @SmallTest
    public void testMessagePipeHandlePass() {
        Core core = CoreImpl.getInstance();
        Pair<MessagePipeHandle, MessagePipeHandle> handles = core.createMessagePipe(null);
        addHandlePairToClose(handles);

        assertTrue(handles.first.isValid());
        MessagePipeHandle handleClone = handles.first.pass();

        addHandleToClose(handleClone);

        assertFalse(handles.first.isValid());
        assertTrue(handleClone.isValid());
        checkSendingMessage(handleClone, handles.second);
        checkSendingMessage(handles.second, handleClone);
    }

    /**
     * Testing the pass method on data pipes.
     */
    @SmallTest
    public void testDataPipeHandlePass() {
        Core core = CoreImpl.getInstance();
        Pair<DataPipe.ProducerHandle, DataPipe.ConsumerHandle> handles = core.createDataPipe(null);
        addHandlePairToClose(handles);

        DataPipe.ProducerHandle producerClone = handles.first.pass();
        DataPipe.ConsumerHandle consumerClone = handles.second.pass();

        addHandleToClose(producerClone);
        addHandleToClose(consumerClone);

        assertFalse(handles.first.isValid());
        assertFalse(handles.second.isValid());
        assertTrue(producerClone.isValid());
        assertTrue(consumerClone.isValid());
        checkSendingData(producerClone, consumerClone);
    }

    /**
     * Testing the pass method on shared buffers.
     */
    @SmallTest
    public void testSharedBufferPass() {
        Core core = CoreImpl.getInstance();
        SharedBufferHandle handle = core.createSharedBuffer(null, 8);
        addHandleToClose(handle);
        SharedBufferHandle newHandle = handle.duplicate(null);
        addHandleToClose(newHandle);

        SharedBufferHandle handleClone = handle.pass();
        SharedBufferHandle newHandleClone = newHandle.pass();

        addHandleToClose(handleClone);
        addHandleToClose(newHandleClone);

        assertFalse(handle.isValid());
        assertTrue(handleClone.isValid());
        checkSharing(handleClone, newHandleClone);
        checkSharing(newHandleClone, handleClone);
    }

    /**
     * esting handle conversion to native and back.
     */
    @SmallTest
    public void testHandleConversion() {
        Core core = CoreImpl.getInstance();
        Pair<MessagePipeHandle, MessagePipeHandle> handles = core.createMessagePipe(null);
        addHandlePairToClose(handles);

        MessagePipeHandle converted =
                core.acquireNativeHandle(handles.first.releaseNativeHandle()).toMessagePipeHandle();
        addHandleToClose(converted);

        assertFalse(handles.first.isValid());

        checkSendingMessage(converted, handles.second);
        checkSendingMessage(handles.second, converted);
    }
}
