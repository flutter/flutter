// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.mojo.bindings;

import org.chromium.mojo.bindings.Callbacks.Callback1;
import org.chromium.mojo.bindings.Interface.Manager;
import org.chromium.mojo.bindings.Interface.Proxy;
import org.chromium.mojo.system.Core;

/**
 * Helper class to handle interface control messages. See
 * mojo/public/interfaces/bindings/interface_control_messages.mojom.
 */
public class InterfaceControlMessagesHelper {
    /**
     * MessageReceiver that forwards a message containing a {@link RunResponseMessageParams} to a
     * callback.
     */
    private static class RunResponseForwardToCallback
            extends SideEffectFreeCloseable implements MessageReceiver {
        private final Callback1<RunResponseMessageParams> mCallback;

        RunResponseForwardToCallback(Callback1<RunResponseMessageParams> callback) {
            mCallback = callback;
        }

        /**
         * @see MessageReceiver#accept(Message)
         */
        @Override
        public boolean accept(Message message) {
            RunResponseMessageParams response =
                    RunResponseMessageParams.deserialize(message.asServiceMessage().getPayload());
            mCallback.call(response);
            return true;
        }
    }

    /**
     * Sends the given run message through the receiver, registering the callback.
     */
    public static void sendRunMessage(Core core, MessageReceiverWithResponder receiver,
            RunMessageParams params, Callback1<RunResponseMessageParams> callback) {
        Message message = params.serializeWithHeader(
                core, new MessageHeader(InterfaceControlMessagesConstants.RUN_MESSAGE_ID,
                        MessageHeader.MESSAGE_EXPECTS_RESPONSE_FLAG, 0));
        receiver.acceptWithResponder(message, new RunResponseForwardToCallback(callback));
    }

    /**
     * Sends the given run or close pipe message through the receiver.
     */
    public static void sendRunOrClosePipeMessage(
            Core core, MessageReceiverWithResponder receiver, RunOrClosePipeMessageParams params) {
        Message message = params.serializeWithHeader(core,
                new MessageHeader(InterfaceControlMessagesConstants.RUN_OR_CLOSE_PIPE_MESSAGE_ID));
        receiver.accept(message);
    }

    /**
     * Handles a received run message.
     */
    public static <I extends Interface, P extends Proxy> boolean handleRun(
            Core core, Manager<I, P> manager, ServiceMessage message, MessageReceiver responder) {
        RunResponseMessageParams response = new RunResponseMessageParams();
        response.reserved0 = 16;
        response.reserved1 = 0;
        response.queryVersionResult = new QueryVersionResult();
        response.queryVersionResult.version = manager.getVersion();

        return responder.accept(response.serializeWithHeader(
                core, new MessageHeader(InterfaceControlMessagesConstants.RUN_MESSAGE_ID,
                        MessageHeader.MESSAGE_IS_RESPONSE_FLAG,
                        message.getHeader().getRequestId())));
    }

    /**
     * Handles a received run or close pipe message. Closing the pipe is handled by returning
     * |false|.
     */
    public static <I extends Interface, P extends Proxy> boolean handleRunOrClosePipe(
            Manager<I, P> manager, ServiceMessage message) {
        Message payload = message.getPayload();
        RunOrClosePipeMessageParams query = RunOrClosePipeMessageParams.deserialize(payload);
        return query.requireVersion.version <= manager.getVersion();
    }
}
