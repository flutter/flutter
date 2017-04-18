// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugin.common;

import android.util.Log;
import java.nio.ByteBuffer;
import io.flutter.plugin.common.BinaryMessenger.BinaryReply;
import io.flutter.plugin.common.BinaryMessenger.BinaryMessageHandler;

/**
 * A named channel for communicating with the Flutter application using semi-structured messages.
 *
 * Messages are encoded into binary before being sent, and binary messages received are decoded
 * into Java objects. The {@link MessageCodec} used must be compatible with the
 * one used by the Flutter application. This can be achieved by creating a PlatformChannel
 * counterpart of this channel on the Dart side. The static Java type of messages sent and received
 * is Object, but only values supported by the specified {@link MessageCodec} can be used.
 *
 * The channel supports basic message send/receive operations. All communication is asynchronous.
 *
 * Identically named channels may interfere with each other's communication.
 */
public final class BasicMessageChannel<T> {
    private static final String TAG = "FlutterMessageChannel#";

    private final BinaryMessenger messenger;
    private final String name;
    private final MessageCodec<T> codec;

    /**
     * Creates a new channel associated with the specified {@link BinaryMessenger}
     * and with the specified name and {@link MessageCodec}.
     *
     * @param messenger a {@link BinaryMessenger}.
     * @param name a channel name String.
     * @param codec a {@link MessageCodec}.
     */
    public BasicMessageChannel(BinaryMessenger messenger, String name, MessageCodec<T> codec) {
        assert messenger != null;
        assert name != null;
        assert codec != null;
        this.messenger = messenger;
        this.name = name;
        this.codec = codec;
    }

    /**
     * Sends the specified message to the Flutter application on this channel.
     *
     * @param message the message, possibly null.
     */
    public void send(T message) {
        send(message, null);
    }

    /**
     * Sends the specified message to the Flutter application, optionally expecting a reply.
     *
     * @param message the message, possibly null.
     * @param callback a {@link Reply} callback, possibly null.
     */
    public void send(T message, final Reply<T> callback) {
        messenger.send(name, codec.encodeMessage(message),
            callback == null ? null : new IncomingReplyHandler(callback));
    }

    /**
     * Registers a message handler on this channel.
     *
     * Overrides any existing handler registration (for messages, method calls, or streams).
     *
     * @param handler a {@link MessageHandler}, or null to deregister.
     */
    public void setMessageHandler(final MessageHandler<T> handler) {
        messenger.setMessageHandler(name,
            handler == null ? null : new IncomingMessageHandler(handler));
    }

    /**
     * A handler of incoming messages.
     */
    public interface MessageHandler<T> {

        /**
         * Handles the specified message.
         *
         * @param message the message, possibly null.
         * @param reply a {@link Reply} for providing a single message reply.
         */
        void onMessage(T message, Reply<T> reply);
    }

    /**
     * Message reply callback. Used to submit a reply to an incoming
     * message from Flutter. Also used in the dual capacity to handle a reply
     * received from Flutter after sending a message.
     */
    public interface Reply<T> {
        /**
         * Handles the specified message reply.
         *
         * @param reply the reply, possibly null.
         */
        void reply(T reply);
    }

    private final class IncomingReplyHandler implements BinaryReply {
        private final Reply<T> callback;

        private IncomingReplyHandler(Reply<T> callback) {
            this.callback = callback;
        }

        @Override
        public void reply(ByteBuffer reply) {
            try {
                callback.reply(codec.decodeMessage(reply));
            } catch (Exception e) {
                Log.e(TAG + name, "Failed to handle message reply", e);
            }
        }
    }

    private final class IncomingMessageHandler implements BinaryMessageHandler {
        private final MessageHandler<T> handler;

        private IncomingMessageHandler(MessageHandler<T> handler) {
            this.handler = handler;
        }

        @Override
        public void onMessage(ByteBuffer message, final BinaryReply callback) {
            try {
                handler.onMessage(codec.decodeMessage(message), new Reply<T>() {
                    private boolean done = false;

                    @Override
                    public void reply(T reply) {
                        if (done) {
                            throw new IllegalStateException("Call result already provided");
                        }
                        callback.reply(codec.encodeMessage(reply));
                        done = true;
                    }
                });
            } catch (Exception e) {
                Log.e(TAG + name, "Failed to handle message", e);
                callback.reply(null);
            }
        }
    }
}
