// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.mojo.bindings;

import org.chromium.mojo.system.AsyncWaiter;
import org.chromium.mojo.system.Core;
import org.chromium.mojo.system.MessagePipeHandle;
import org.chromium.mojo.system.MessagePipeHandle.ReadMessageResult;
import org.chromium.mojo.system.MojoException;
import org.chromium.mojo.system.MojoResult;
import org.chromium.mojo.system.ResultAnd;

import java.nio.ByteBuffer;

/**
 * A {@link Connector} owns a {@link MessagePipeHandle} and will send any received messages to the
 * registered {@link MessageReceiver}. It also acts as a {@link MessageReceiver} and will send any
 * message through the handle.
 * <p>
 * The method |start| must be called before the {@link Connector} will start listening to incoming
 * messages.
 */
public class Connector implements MessageReceiver, HandleOwner<MessagePipeHandle> {

    /**
     * The callback that is notified when the state of the owned handle changes.
     */
    private final AsyncWaiterCallback mAsyncWaiterCallback = new AsyncWaiterCallback();

    /**
     * The owned message pipe.
     */
    private final MessagePipeHandle mMessagePipeHandle;

    /**
     * A waiter which is notified when a new message is available on the owned message pipe.
     */
    private final AsyncWaiter mAsyncWaiter;

    /**
     * The {@link MessageReceiver} to which received messages are sent.
     */
    private MessageReceiver mIncomingMessageReceiver;

    /**
     * The Cancellable for the current wait. Is |null| when not currently waiting for new messages.
     */
    private AsyncWaiter.Cancellable mCancellable;

    /**
     * The error handler to notify of errors.
     */
    private ConnectionErrorHandler mErrorHandler;

    /**
     * Create a new connector over a |messagePipeHandle|. The created connector will use the default
     * {@link AsyncWaiter} from the {@link Core} implementation of |messagePipeHandle|.
     */
    public Connector(MessagePipeHandle messagePipeHandle) {
        this(messagePipeHandle, BindingsHelper.getDefaultAsyncWaiterForHandle(messagePipeHandle));
    }

    /**
     * Create a new connector over a |messagePipeHandle| using the given {@link AsyncWaiter} to get
     * notified of changes on the handle.
     */
    public Connector(MessagePipeHandle messagePipeHandle, AsyncWaiter asyncWaiter) {
        mCancellable = null;
        mMessagePipeHandle = messagePipeHandle;
        mAsyncWaiter = asyncWaiter;
    }

    /**
     * Set the {@link MessageReceiver} that will receive message from the owned message pipe.
     */
    public void setIncomingMessageReceiver(MessageReceiver incomingMessageReceiver) {
        mIncomingMessageReceiver = incomingMessageReceiver;
    }

    /**
     * Set the {@link ConnectionErrorHandler} that will be notified of errors on the owned message
     * pipe.
     */
    public void setErrorHandler(ConnectionErrorHandler errorHandler) {
        mErrorHandler = errorHandler;
    }

    /**
     * Start listening for incoming messages.
     */
    public void start() {
        assert mCancellable == null;
        registerAsyncWaiterForRead();
    }

    /**
     * @see MessageReceiver#accept(Message)
     */
    @Override
    public boolean accept(Message message) {
        try {
            mMessagePipeHandle.writeMessage(message.getData(),
                    message.getHandles(), MessagePipeHandle.WriteFlags.NONE);
            return true;
        } catch (MojoException e) {
            onError(e);
            return false;
        }
    }

    /**
     * Pass the owned handle of the connector. After this, the connector is disconnected. It cannot
     * accept new message and it isn't listening to the handle anymore.
     *
     * @see org.chromium.mojo.bindings.HandleOwner#passHandle()
     */
    @Override
    public MessagePipeHandle passHandle() {
        cancelIfActive();
        MessagePipeHandle handle = mMessagePipeHandle.pass();
        if (mIncomingMessageReceiver != null) {
            mIncomingMessageReceiver.close();
        }
        return handle;
    }

    /**
     * @see java.io.Closeable#close()
     */
    @Override
    public void close() {
        cancelIfActive();
        mMessagePipeHandle.close();
        if (mIncomingMessageReceiver != null) {
            MessageReceiver incomingMessageReceiver = mIncomingMessageReceiver;
            mIncomingMessageReceiver = null;
            incomingMessageReceiver.close();
        }
    }

    private class AsyncWaiterCallback implements AsyncWaiter.Callback {

        /**
         * @see org.chromium.mojo.system.AsyncWaiter.Callback#onResult(int)
         */
        @Override
        public void onResult(int result) {
            Connector.this.onAsyncWaiterResult(result);
        }

        /**
         * @see org.chromium.mojo.system.AsyncWaiter.Callback#onError(MojoException)
         */
        @Override
        public void onError(MojoException exception) {
            mCancellable = null;
            Connector.this.onError(exception);
        }

    }

    /**
     * @see org.chromium.mojo.system.AsyncWaiter.Callback#onResult(int)
     */
    private void onAsyncWaiterResult(int result) {
        mCancellable = null;
        if (result == MojoResult.OK) {
            readOutstandingMessages();
        } else {
            onError(new MojoException(result));
        }
    }

    private void onError(MojoException exception) {
        close();
        assert mCancellable == null;
        if (mErrorHandler != null) {
            mErrorHandler.onConnectionError(exception);
        }
    }

    /**
     * Register to be called back when a new message is available on the owned message pipe.
     */
    private void registerAsyncWaiterForRead() {
        assert mCancellable == null;
        if (mAsyncWaiter != null) {
            mCancellable = mAsyncWaiter.asyncWait(mMessagePipeHandle, Core.HandleSignals.READABLE,
                    Core.DEADLINE_INFINITE, mAsyncWaiterCallback);
        } else {
            onError(new MojoException(MojoResult.INVALID_ARGUMENT));
        }
    }

    /**
     * Read all available messages on the owned message pipe.
     */
    private void readOutstandingMessages() {
        ResultAnd<Boolean> result;
        do {
            try {
                result = readAndDispatchMessage(mMessagePipeHandle, mIncomingMessageReceiver);
            } catch (MojoException e) {
                onError(e);
                return;
            }
        } while (result.getValue());
        if (result.getMojoResult() == MojoResult.SHOULD_WAIT) {
            registerAsyncWaiterForRead();
        } else {
            onError(new MojoException(result.getMojoResult()));
        }
    }

    private void cancelIfActive() {
        if (mCancellable != null) {
            mCancellable.cancel();
            mCancellable = null;
        }
    }

    /**
     * Read a message, and pass it to the given |MessageReceiver| if not null. If the
     * |MessageReceiver| is null, the message is lost.
     *
     * @param receiver The {@link MessageReceiver} that will receive the read {@link Message}. Can
     *            be <code>null</code>, in which case the message is discarded.
     */
    static ResultAnd<Boolean> readAndDispatchMessage(
            MessagePipeHandle handle, MessageReceiver receiver) {
        // TODO(qsr) Allow usage of a pool of pre-allocated buffer for performance.
        ResultAnd<ReadMessageResult> result =
                handle.readMessage(null, 0, MessagePipeHandle.ReadFlags.NONE);
        if (result.getMojoResult() != MojoResult.RESOURCE_EXHAUSTED) {
            return new ResultAnd<Boolean>(result.getMojoResult(), false);
        }
        ReadMessageResult readResult = result.getValue();
        assert readResult != null;
        ByteBuffer buffer = ByteBuffer.allocateDirect(readResult.getMessageSize());
        result = handle.readMessage(
                buffer, readResult.getHandlesCount(), MessagePipeHandle.ReadFlags.NONE);
        if (receiver != null && result.getMojoResult() == MojoResult.OK) {
            boolean accepted = receiver.accept(new Message(buffer, result.getValue().getHandles()));
            return new ResultAnd<Boolean>(result.getMojoResult(), accepted);
        }
        return new ResultAnd<Boolean>(result.getMojoResult(), false);
    }
}
