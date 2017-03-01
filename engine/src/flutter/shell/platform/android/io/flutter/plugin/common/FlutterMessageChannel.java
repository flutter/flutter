// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugin.common;

import android.util.Log;
import io.flutter.view.FlutterView;
import io.flutter.view.FlutterView.BinaryMessageReplyCallback;
import io.flutter.view.FlutterView.BinaryMessageResponse;
import io.flutter.view.FlutterView.OnBinaryMessageListenerAsync;
import java.nio.ByteBuffer;
import java.util.Objects;
import java.util.concurrent.atomic.AtomicBoolean;

/**
 * A named channel for communicating with the Flutter application using semi-structured messages.
 *
 * Messages are encoded into binary before being sent, and binary messages received are decoded
 * into Java objects. The {@link MessageCodec} used must be compatible with the
 * one used by the Flutter application. This can be achieved by creating a PlatformChannel
 * counterpart of this channel on the Dart side. The static Java type of messages sent and received
 * is Object, but only values supported by the specified {@link MessageCodec} can be used.
 *
 * The channel supports basic message send/receive operations, handling incoming method
 * invocations, and emitting event streams. All communication is asynchronous.
 *
 * Identically named channels may interfere with each other's communication.
 */
public final class FlutterMessageChannel<T> {
    private static final String TAG = "FlutterMessageChannel#";

    private final FlutterView view;
    private final String name;
    private final MessageCodec<T> codec;

    /**
     * Creates a new channel associated with the specified {@link FlutterView} and with the
     * specified name and {@link MessageCodec}.
     *
     * @param view a {@link FlutterView}.
     * @param name a channel name String.
     * @param codec a {@link MessageCodec}.
     */
    public FlutterMessageChannel(FlutterView view, String name, MessageCodec<T> codec) {
        this.view = Objects.requireNonNull(view);
        this.name = Objects.requireNonNull(name);
        this.codec = Objects.requireNonNull(codec);
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
     * @param handler a {@link ReplyHandler} call-back, possibly null.
     */
    public void send(T message, final ReplyHandler<T> handler) {
        view.sendBinaryMessage(name, codec.encodeMessage(message),
            handler == null ? null : new ReplyCallback(handler));
    }

    /**
     * Registers a message handler on this channel.
     *
     * Overrides any existing handler registration (for messages, method calls, or streams).
     *
     * @param handler a {@link MessageHandler}, or null to deregister.
     */
    public void setMessageHandler(final MessageHandler<T> handler) {
        view.addOnBinaryMessageListenerAsync(name,
            handler == null ? null : new MessageListener(handler));
    }

    /**
     * A call-back interface for handling replies to outgoing messages.
     */
    public interface ReplyHandler<T> {
        /**
         * Handle the specified reply.
         *
         * @param reply the reply, possibly null.
         */
        void onReply(T reply);
    }

    /**
     * A call-back interface for handling incoming messages.
     */
    public interface MessageHandler<T> {

        /**
         * Handles the specified message.
         *
         * @param message The message, possibly null.
         * @param reply A {@link Reply} for providing a single message reply.
         */
        void onMessage(T message, Reply<T> reply);
    }

    /**
     * Response interface for sending results back to Flutter.
     */
    public interface Reply<T> {
        /**
         * Submits a reply.
         *
         * @param reply The result, possibly null.
         */
        void send(T reply);
    }

    private final class ReplyCallback implements BinaryMessageReplyCallback {
        private final ReplyHandler<T> handler;

        private ReplyCallback(ReplyHandler<T> handler) {
            this.handler = handler;
        }

        @Override
        public void onReply(ByteBuffer reply) {
            handler.onReply(codec.decodeMessage(reply));
        }
    }

    private final class MessageListener implements OnBinaryMessageListenerAsync {
        private final MessageHandler<T> handler;

        private MessageListener(MessageHandler<T> handler) {
            this.handler = handler;
        }

        @Override
        public void onMessage(FlutterView view, ByteBuffer message,
            final BinaryMessageResponse response) {
            try {
                handler.onMessage(codec.decodeMessage(message), new Reply<T>() {
                    private boolean done = false;

                    @Override
                    public void send(T reply) {
                        if (done) {
                            throw new IllegalStateException("Call result already provided");
                        }
                        response.send(codec.encodeMessage(reply));
                        done = true;
                    }
                });
            } catch (Exception e) {
                Log.e(TAG + name, "Failed to handle message", e);
                response.send(null);
            }
        }
    }
}
