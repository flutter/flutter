// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugin.common;

import android.util.Log;
import io.flutter.view.FlutterView;
import io.flutter.view.FlutterView.BinaryMessageResponse;
import io.flutter.view.FlutterView.OnBinaryMessageListenerAsync;

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
public final class FlutterEventChannel {
    private static final String TAG = "FlutterEventChannel#";

    private final FlutterView view;
    private final String name;
    private final MethodCodec codec;

    /**
     * Creates a new channel associated with the specified {@link FlutterView} and with the
     * specified name and the standard {@link MethodCodec}.
     *
     * @param view a {@link FlutterView}.
     * @param name a channel name String.
     */
    public FlutterEventChannel(FlutterView view, String name) {
        this(view, name, StandardMethodCodec.INSTANCE);
    }

    /**
     * Creates a new channel associated with the specified {@link FlutterView} and with the
     * specified name and {@link MethodCodec}.
     *
     * @param view a {@link FlutterView}.
     * @param name a channel name String.
     * @param codec a {@link MessageCodec}.
     */
    public FlutterEventChannel(FlutterView view, String name, MethodCodec codec) {
        assert view != null;
        assert name != null;
        assert codec != null;
        this.view = view;
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
        view.addOnBinaryMessageListenerAsync(name,
            handler == null ? null : new StreamListener(handler));
    }

    /**
     * Strategy for handling event streams. Supports dual use:
     * Producers of events to be sent to Flutter act as clients of this interface
     * for sending events. Consumers of events sent from Flutter implement
     * this interface for handling received events.
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
     * A call-back interface for handling stream setup and tear-down requests.
     */
    public interface StreamHandler {
        /**
         * Handles a request to set up an event stream.
         *
         * @param arguments Stream configuration arguments, possibly null.
         * @param eventSink An {@link EventSink} for sending events to the Flutter receiver.
         */
        void onListen(Object arguments, EventSink eventSink);

        /**
         * Handles a request to tear down an event stream.
         *
         * @param arguments Stream configuration arguments, possibly null.
         */
        void onCancel(Object arguments);
    }

    private final class StreamListener implements OnBinaryMessageListenerAsync {
        private final StreamHandler handler;
        private final AtomicReference<EventSink> activeSink = new AtomicReference<>(null);

        StreamListener(StreamHandler handler) {
            this.handler = handler;
        }

        @Override
        public void onMessage(FlutterView view, ByteBuffer message,
            final BinaryMessageResponse response) {
            final MethodCall call = codec.decodeMethodCall(message);
            if (call.method.equals("listen")) {
                onListen(call.arguments, response);
            } else if (call.method.equals("cancel")) {
                onCancel(call.arguments, response);
            } else {
                response.send(null);
            }
        }

        private void onListen(Object arguments, BinaryMessageResponse response) {
            final EventSink eventSink = new EventSinkImplementation();
            if (activeSink.compareAndSet(null, eventSink)) {
                try {
                    handler.onListen(arguments, eventSink);
                    response.send(codec.encodeSuccessEnvelope(null));
                } catch (Exception e) {
                    activeSink.set(null);
                    Log.e(TAG + name, "Failed to open event stream", e);
                    response.send(codec.encodeErrorEnvelope("error", e.getMessage(), null));
                }
            } else {
                response.send(codec.encodeErrorEnvelope("error", "Stream already active", null));
            }
        }

        private void onCancel(Object arguments, BinaryMessageResponse response) {
            final EventSink oldSink = activeSink.getAndSet(null);
            if (oldSink != null) {
                try {
                    handler.onCancel(arguments);
                    response.send(codec.encodeSuccessEnvelope(null));
                } catch (Exception e) {
                    Log.e(TAG + name, "Failed to close event stream", e);
                    response.send(codec.encodeErrorEnvelope("error", e.getMessage(), null));
                }
            } else {
                response.send(codec.encodeErrorEnvelope("error", "No active stream to cancel", null));
            }
        }

        private final class EventSinkImplementation implements EventSink {
             @Override
             public void success(Object event) {
                 if (activeSink.get() != this) {
                     return;
                 }
                 FlutterEventChannel.this.view.sendBinaryMessage(
                     name,
                     codec.encodeSuccessEnvelope(event),
                     null);
             }

             @Override
             public void error(String errorCode, String errorMessage,
                 Object errorDetails) {
                 if (activeSink.get() != this) {
                     return;
                 }
                 FlutterEventChannel.this.view.sendBinaryMessage(
                     name,
                     codec.encodeErrorEnvelope(errorCode, errorMessage, errorDetails),
                     null);
             }

             @Override
             public void endOfStream() {
                 if (activeSink.get() != this) {
                     return;
                 }
                 FlutterEventChannel.this.view.sendBinaryMessage(name, null, null);
             }
         }
    }
}
