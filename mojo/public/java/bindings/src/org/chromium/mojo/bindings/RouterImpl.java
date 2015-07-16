// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.mojo.bindings;

import org.chromium.mojo.system.AsyncWaiter;
import org.chromium.mojo.system.Core;
import org.chromium.mojo.system.MessagePipeHandle;

import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.Executor;

/**
 * Implementation of {@link Router}.
 */
public class RouterImpl implements Router {

    /**
     * {@link MessageReceiver} used as the {@link Connector} callback.
     */
    private class HandleIncomingMessageThunk implements MessageReceiver {

        /**
         * @see MessageReceiver#accept(Message)
         */
        @Override
        public boolean accept(Message message) {
            return handleIncomingMessage(message);
        }

        /**
         * @see MessageReceiver#close()
         */
        @Override
        public void close() {
            handleConnectorClose();
        }

    }

    /**
     *
     * {@link MessageReceiver} used to return responses to the caller.
     */
    class ResponderThunk implements MessageReceiver {
        private boolean mAcceptWasInvoked = false;

        /**
         * @see
         * MessageReceiver#accept(Message)
         */
        @Override
        public boolean accept(Message message) {
            mAcceptWasInvoked = true;
            return RouterImpl.this.accept(message);
        }

        /**
         * @see MessageReceiver#close()
         */
        @Override
        public void close() {
            RouterImpl.this.close();
        }

        @Override
        protected void finalize() throws Throwable {
            if (!mAcceptWasInvoked) {
                // We close the pipe here as a way of signaling to the calling application that an
                // error condition occurred. Without this the calling application would have no
                // way of knowing it should stop waiting for a response.
                RouterImpl.this.closeOnHandleThread();
            }
            super.finalize();
        }
    }

    /**
     * The {@link Connector} which is connected to the handle.
     */
    private final Connector mConnector;

    /**
     * The {@link MessageReceiverWithResponder} that will consume the messages received from the
     * pipe.
     */
    private MessageReceiverWithResponder mIncomingMessageReceiver;

    /**
     * The next id to use for a request id which needs a response. It is auto-incremented.
     */
    private long mNextRequestId = 1;

    /**
     * The map from request ids to {@link MessageReceiver} of request currently in flight.
     */
    private Map<Long, MessageReceiver> mResponders = new HashMap<Long, MessageReceiver>();

    /**
     * An Executor that will run on the thread associated with the MessagePipe to which
     * this Router is bound. This may be {@code Null} if the MessagePipeHandle passed
     * in to the constructor is not valid.
     */
    private final Executor mExecutor;

    /**
     * Constructor that will use the default {@link AsyncWaiter}.
     *
     * @param messagePipeHandle The {@link MessagePipeHandle} to route message for.
     */
    public RouterImpl(MessagePipeHandle messagePipeHandle) {
        this(messagePipeHandle, BindingsHelper.getDefaultAsyncWaiterForHandle(messagePipeHandle));
    }

    /**
     * Constructor.
     *
     * @param messagePipeHandle The {@link MessagePipeHandle} to route message for.
     * @param asyncWaiter the {@link AsyncWaiter} to use to get notification of new messages on the
     *            handle.
     */
    public RouterImpl(MessagePipeHandle messagePipeHandle, AsyncWaiter asyncWaiter) {
        mConnector = new Connector(messagePipeHandle, asyncWaiter);
        mConnector.setIncomingMessageReceiver(new HandleIncomingMessageThunk());
        Core core = messagePipeHandle.getCore();
        if (core != null) {
            mExecutor = ExecutorFactory.getExecutorForCurrentThread(core);
        } else {
            mExecutor = null;
        }
    }

    /**
     * @see org.chromium.mojo.bindings.Router#start()
     */
    @Override
    public void start() {
        mConnector.start();
    }

    /**
     * @see Router#setIncomingMessageReceiver(MessageReceiverWithResponder)
     */
    @Override
    public void setIncomingMessageReceiver(MessageReceiverWithResponder incomingMessageReceiver) {
        this.mIncomingMessageReceiver = incomingMessageReceiver;
    }

    /**
     * @see MessageReceiver#accept(Message)
     */
    @Override
    public boolean accept(Message message) {
        // A message without responder is directly forwarded to the connector.
        return mConnector.accept(message);
    }

    /**
     * @see MessageReceiverWithResponder#acceptWithResponder(Message, MessageReceiver)
     */
    @Override
    public boolean acceptWithResponder(Message message, MessageReceiver responder) {
        // The message must have a header.
        ServiceMessage messageWithHeader = message.asServiceMessage();
        // Checking the message expects a response.
        assert messageWithHeader.getHeader().hasFlag(MessageHeader.MESSAGE_EXPECTS_RESPONSE_FLAG);

        // Compute a request id for being able to route the response.
        long requestId = mNextRequestId++;
        // Reserve 0 in case we want it to convey special meaning in the future.
        if (requestId == 0) {
            requestId = mNextRequestId++;
        }
        if (mResponders.containsKey(requestId)) {
            throw new IllegalStateException("Unable to find a new request identifier.");
        }
        messageWithHeader.setRequestId(requestId);
        if (!mConnector.accept(messageWithHeader)) {
            return false;
        }
        // Only keep the responder is the message has been accepted.
        mResponders.put(requestId, responder);
        return true;
    }

    /**
     * @see org.chromium.mojo.bindings.HandleOwner#passHandle()
     */
    @Override
    public MessagePipeHandle passHandle() {
        return mConnector.passHandle();
    }

    /**
     * @see java.io.Closeable#close()
     */
    @Override
    public void close() {
        mConnector.close();
    }

    /**
     * @see Router#setErrorHandler(ConnectionErrorHandler)
     */
    @Override
    public void setErrorHandler(ConnectionErrorHandler errorHandler) {
        mConnector.setErrorHandler(errorHandler);
    }

    /**
     * Receive a message from the connector. Returns |true| if the message has been handled.
     */
    private boolean handleIncomingMessage(Message message) {
        MessageHeader header = message.asServiceMessage().getHeader();
        if (header.hasFlag(MessageHeader.MESSAGE_EXPECTS_RESPONSE_FLAG)) {
            if (mIncomingMessageReceiver != null) {
                return mIncomingMessageReceiver.acceptWithResponder(message, new ResponderThunk());
            }
            // If we receive a request expecting a response when the client is not
            // listening, then we have no choice but to tear down the pipe.
            close();
            return false;
        } else if (header.hasFlag(MessageHeader.MESSAGE_IS_RESPONSE_FLAG)) {
            long requestId = header.getRequestId();
            MessageReceiver responder = mResponders.get(requestId);
            if (responder == null) {
                return false;
            }
            mResponders.remove(requestId);
            return responder.accept(message);
        } else {
            if (mIncomingMessageReceiver != null) {
                return mIncomingMessageReceiver.accept(message);
            }
            // OK to drop the message.
        }
        return false;
    }

    private void handleConnectorClose() {
        if (mIncomingMessageReceiver != null) {
            mIncomingMessageReceiver.close();
        }
    }

    /**
     * Invokes {@link #close()} asynchronously on the thread associated with
     * this Router's Handle. If this Router was constructed with an invalid
     * handle then this method does nothing.
     */
    private void closeOnHandleThread() {
        if (mExecutor != null) {
            mExecutor.execute(new Runnable() {

                @Override
                public void run() {
                    close();
                }
            });
        }
    }
}
