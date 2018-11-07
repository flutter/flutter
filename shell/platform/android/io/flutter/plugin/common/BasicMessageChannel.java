// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugin.common;

import android.util.Log;
import java.nio.ByteBuffer;

import io.flutter.plugin.common.BinaryMessenger.BinaryReply;
import io.flutter.plugin.common.BinaryMessenger.BinaryMessageHandler;

/**
 * A named channel for communicating with the Flutter application using basic, asynchronous message passing.
 *
 * <p>Messages are encoded into binary before being sent, and binary messages received are decoded
 * into Java objects. The {@link MessageCodec} used must be compatible with the
 * one used by the Flutter application. This can be achieved by creating a
 * <a href="https://docs.flutter.io/flutter/services/BasicMessageChannel-class.html">BasicMessageChannel</a>
 * counterpart of this channel on the Dart side. The static Java type of messages sent and received
 * is {@code Object}, but only values supported by the specified {@link MessageCodec} can be used.</p>
 *
 * <p>The logical identity of the channel is given by its name. Identically named channels will interfere
 * with each other's communication.</p>
 */
public final class BasicMessageChannel<T> {
    private static final String TAG = "BasicMessageChannel#";

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
     * <p>Any uncaught exception thrown by the reply callback will be caught and logged.</p>
     *
     * @param message the message, possibly null.
     * @param callback a {@link Reply} callback, possibly null.
     */
    public void send(T message, final Reply<T> callback) {
        messenger.send(name, codec.encodeMessage(message),
            callback == null ? null : new IncomingReplyHandler(callback));
    }

    /**
     * Registers a message handler on this channel for receiving messages sent from the Flutter
     * application.
     *
     * <p>Overrides any existing handler registration for (the name of) this channel.</p>
     *
     * <p>If no handler has been registered, any incoming message on this channel will be handled silently
     * by sending a null reply.</p>
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
         * Handles the specified message received from Flutter.
         *
         * <p>Handler implementations must reply to all incoming messages, by submitting a single reply
         * message to the given {@link Reply}. Failure to do so will result in lingering Flutter reply
         * handlers. The reply may be submitted asynchronously.</p>
         *
         * <p>Any uncaught exception thrown by this method, or the preceding message decoding, will be
         * caught by the channel implementation and logged, and a null reply message will be sent back
         * to Flutter.</p>
         *
         * <p>Any uncaught exception thrown during encoding a reply message submitted to the {@link Reply}
         * is treated similarly: the exception is logged, and a null reply is sent to Flutter.</p>
         *
         * @param message the message, possibly null.
         * @param reply a {@link Reply} for sending a single message reply back to Flutter.
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
            } catch (RuntimeException e) {
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
                    @Override
                    public void reply(T reply) {
                        callback.reply(codec.encodeMessage(reply));
                    }
                });
            } catch (RuntimeException e) {
                Log.e(TAG + name, "Failed to handle message", e);
                callback.reply(null);
            }
        }
    }
}
