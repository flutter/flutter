// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.mojo.bindings;

import org.chromium.mojo.TestUtils;
import org.chromium.mojo.system.Handle;
import org.chromium.mojo.system.MessagePipeHandle;
import org.chromium.mojo.system.MojoException;
import org.chromium.mojo.system.Pair;
import org.chromium.mojo.system.impl.CoreImpl;

import java.io.Closeable;
import java.nio.ByteBuffer;
import java.util.ArrayList;
import java.util.List;

/**
 * Utility class for bindings tests.
 */
public class BindingsTestUtils {

    /**
     * {@link MessageReceiver} that records any message it receives.
     */
    public static class RecordingMessageReceiver extends SideEffectFreeCloseable
            implements MessageReceiver {

        public final List<Message> messages = new ArrayList<Message>();

        /**
         * @see MessageReceiver#accept(Message)
         */
        @Override
        public boolean accept(Message message) {
            messages.add(message);
            return true;
        }
    }

    /**
     * {@link MessageReceiverWithResponder} that records any message it receives.
     */
    public static class RecordingMessageReceiverWithResponder extends RecordingMessageReceiver
            implements MessageReceiverWithResponder {

        public final List<Pair<Message, MessageReceiver>> messagesWithReceivers =
                new ArrayList<Pair<Message, MessageReceiver>>();

        /**
         * @see MessageReceiverWithResponder#acceptWithResponder(Message, MessageReceiver)
         */
        @Override
        public boolean acceptWithResponder(Message message, MessageReceiver responder) {
            messagesWithReceivers.add(Pair.create(message, responder));
            return true;
        }
    }

    /**
     * {@link ConnectionErrorHandler} that records any error it received.
     */
    public static class CapturingErrorHandler implements ConnectionErrorHandler {

        private MojoException mLastMojoException = null;

        /**
         * @see ConnectionErrorHandler#onConnectionError(MojoException)
         */
        @Override
        public void onConnectionError(MojoException e) {
            mLastMojoException = e;
        }

        /**
         * Returns the last recorded exception.
         */
        public MojoException getLastMojoException() {
            return mLastMojoException;
        }

    }

    /**
     * Creates a new valid {@link Message}. The message will have a valid header.
     */
    public static Message newRandomMessage(int size) {
        assert size > 16;
        ByteBuffer message = TestUtils.newRandomBuffer(size);
        int[] headerAsInts = {16, 2, 0, 0};
        for (int i = 0; i < 4; ++i) {
            message.putInt(4 * i, headerAsInts[i]);
        }
        message.position(0);
        return new Message(message, new ArrayList<Handle>());
    }

    public static <I extends Interface, P extends Interface.Proxy> P newProxyOverPipe(
            Interface.Manager<I, P> manager, I impl, List<Closeable> toClose) {
        Pair<MessagePipeHandle, MessagePipeHandle> handles =
                CoreImpl.getInstance().createMessagePipe(null);
        P proxy = manager.attachProxy(handles.first, 0);
        toClose.add(proxy);
        manager.bind(impl, handles.second);
        return proxy;
    }
}
