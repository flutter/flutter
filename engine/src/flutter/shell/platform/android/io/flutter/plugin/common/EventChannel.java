// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugin.common;

import android.util.Log;
import io.flutter.plugin.common.BinaryMessenger.BinaryMessageHandler;
import io.flutter.plugin.common.BinaryMessenger.BinaryReply;

import java.nio.ByteBuffer;
import java.util.concurrent.atomic.AtomicReference;

/**
 * A named channel for communicating with the Flutter application using asynchronous
 * event streams.
 *
 * Incoming requests for event stream setup are decoded from binary on receipt, and
 * Java responses and events are encoded into binary before being transmitted back
 * to Flutter. The {@link MethodCodec} used must be compatible with the one used by
 * the Flutter application. This can be achieved by creating a PlatformEventChannel
 * counterpart of this channel on the Flutter side. The Java type of responses and
 * events is Object, but only values supported by the specified {@link MethodCodec}
 * can be used.
 *
 * The identity of the channel is given by its name, so other uses of that name
 * with may interfere with this channel's communication.
 */
public final class EventChannel {
    private static final String TAG = "EventChannel#";

    private final BinaryMessenger messenger;
    private final String name;
    private final MethodCodec codec;

    /**
     * Creates a new channel associated with the specified {@link BinaryMessenger}
     * and with the specified name and the standard {@link MethodCodec}.
     *
     * @param messenger a {@link BinaryMessenger}.
     * @param name a channel name String.
     */
    public EventChannel(BinaryMessenger messenger, String name) {
        this(messenger, name, StandardMethodCodec.INSTANCE);
    }

    /**
     * Creates a new channel associated with the specified {@link BinaryMessenger}
     * and with the specified name and {@link MethodCodec}.
     *
     * @param messenger a {@link BinaryMessenger}.
     * @param name a channel name String.
     * @param codec a {@link MessageCodec}.
     */
    public EventChannel(BinaryMessenger messenger, String name, MethodCodec codec) {
        assert messenger != null;
        assert name != null;
        assert codec != null;
        this.messenger = messenger;
        this.name = name;
        this.codec = codec;
    }

    /**
     * Registers a stream handler on this channel.
     *
     * Overrides any existing handler registration.
     *
     * @param handler a {@link StreamHandler}, or null to deregister.
     */
    public void setStreamHandler(final StreamHandler handler) {
        messenger.setMessageHandler(name, handler == null ? null : new IncomingStreamRequestHandler(handler));
    }

    /**
     * Event callback. Supports dual use: Producers of events to be sent to Flutter
     * act as clients of this interface for sending events. Consumers of events sent
     * from Flutter implement this interface for handling received events.
     */
    public interface EventSink {
        /**
         * Consumes a successful event.
         *
         * @param event The event, possibly null.
         */
        void success(Object event);

        /**
         * Consumes an error event.
         *
         * @param errorCode An error code String.
         * @param errorMessage A human-readable error message String, possibly null.
         * @param errorDetails Error details, possibly null
         */
        void error(String errorCode, String errorMessage, Object errorDetails);

        /**
         * Consumes end of stream. No calls to {@link #success(Object)} or
         * {@link #error(String, String, Object)} will be made following a call
         * to this method.
         */
        void endOfStream();
    }

    /**
     * Handler of stream setup and tear-down requests.
     */
    public interface StreamHandler {
        /**
         * Handles a request to set up an event stream.
         *
         * @param arguments Stream configuration arguments, possibly null.
         * @param events An {@link EventSink} for emitting events to the Flutter receiver.
         */
        void onListen(Object arguments, EventSink events);

        /**
         * Handles a request to tear down an event stream.
         *
         * @param arguments Stream configuration arguments, possibly null.
         */
        void onCancel(Object arguments);
    }

    private final class IncomingStreamRequestHandler implements BinaryMessageHandler {
        private final StreamHandler handler;
        private final AtomicReference<EventSink> activeSink = new AtomicReference<>(null);

        IncomingStreamRequestHandler(StreamHandler handler) {
            this.handler = handler;
        }

        @Override
        public void onMessage(ByteBuffer message, final BinaryReply reply) {
            final MethodCall call = codec.decodeMethodCall(message);
            if (call.method.equals("listen")) {
                onListen(call.arguments, reply);
            } else if (call.method.equals("cancel")) {
                onCancel(call.arguments, reply);
            } else {
                reply.reply(null);
            }
        }

        private void onListen(Object arguments, BinaryReply callback) {
            final EventSink eventSink = new EventSinkImplementation();
            if (activeSink.compareAndSet(null, eventSink)) {
                try {
                    handler.onListen(arguments, eventSink);
                    callback.reply(codec.encodeSuccessEnvelope(null));
                } catch (Exception e) {
                    activeSink.set(null);
                    Log.e(TAG + name, "Failed to open event stream", e);
                    callback.reply(codec.encodeErrorEnvelope("error", e.getMessage(), null));
                }
            } else {
                callback.reply(codec.encodeErrorEnvelope("error", "Stream already active", null));
            }
        }

        private void onCancel(Object arguments, BinaryReply callback) {
            final EventSink oldSink = activeSink.getAndSet(null);
            if (oldSink != null) {
                try {
                    handler.onCancel(arguments);
                    callback.reply(codec.encodeSuccessEnvelope(null));
                } catch (Exception e) {
                    Log.e(TAG + name, "Failed to close event stream", e);
                    callback.reply(codec.encodeErrorEnvelope("error", e.getMessage(), null));
                }
            } else {
                callback.reply(codec.encodeErrorEnvelope("error", "No active stream to cancel", null));
            }
        }

        private final class EventSinkImplementation implements EventSink {
             @Override
             public void success(Object event) {
                 if (activeSink.get() != this) {
                     return;
                 }
                 EventChannel.this.messenger.send(
                     name,
                     codec.encodeSuccessEnvelope(event));
             }

             @Override
             public void error(String errorCode, String errorMessage,
                 Object errorDetails) {
                 if (activeSink.get() != this) {
                     return;
                 }
                 EventChannel.this.messenger.send(
                     name,
                     codec.encodeErrorEnvelope(errorCode, errorMessage, errorDetails));
             }

             @Override
             public void endOfStream() {
                 if (activeSink.get() != this) {
                     return;
                 }
                 EventChannel.this.messenger.send(name, null);
             }
         }
    }
}
