// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugin.common;

import android.util.Log;
import io.flutter.view.FlutterView;
import io.flutter.view.FlutterView.BinaryMessageResponse;
import io.flutter.view.FlutterView.OnBinaryMessageListenerAsync;
import java.nio.ByteBuffer;
import java.util.concurrent.atomic.AtomicBoolean;

/**
 * A named channel for communicating with the Flutter application using asynchronous
 * method calls and event streams.
 *
 * Incoming method calls are decoded from binary on receipt, and Java results are encoded
 * into binary before being transmitted back to Flutter. The {@link MethodCodec} used must be
 * compatible with the one used by the Flutter application. This can be achieved
 * by creating a PlatformMethodChannel counterpart of this channel on the
 * Flutter side. The Java type of method call arguments and results is Object,
 * but only values supported by the specified {@link MethodCodec} can be used.
 *
 * The identity of the channel is given by its name, so other uses of that name
 * with may interfere with this channel's communication.
 */
public final class FlutterMethodChannel {
    private static final String TAG = "FlutterMethodChannel#";

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
    public FlutterMethodChannel(FlutterView view, String name) {
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
    public FlutterMethodChannel(FlutterView view, String name, MethodCodec codec) {
        assert view != null;
        assert name != null;
        assert codec != null;
        this.view = view;
        this.name = name;
        this.codec = codec;
    }

    /**
     * Registers a method call handler on this channel.
     *
     * Overrides any existing handler registration (for messages, method calls, or streams).
     *
     * @param handler a {@link MethodCallHandler}, or null to deregister.
     */
    public void setMethodCallHandler(final MethodCallHandler handler) {
        view.addOnBinaryMessageListenerAsync(name,
            handler == null ? null : new MethodCallListener(handler));
    }

    /**
     * Registers a stream handler on this channel.
     *
     * Overrides any existing handler registration (for messages, method calls, or streams).
     *
     * @param handler a {@link StreamHandler}, or null to deregister.
     */
    public void setStreamHandler(final StreamHandler handler) {
        view.addOnBinaryMessageListenerAsync(name,
            handler == null ? null : new StreamListener(handler));
    }

    /**
     * A call-back interface for handling incoming method calls.
     */
    public interface MethodCallHandler {

        /**
         * Handles the specified method call.
         *
         * @param call A {@link MethodCall}.
         * @param response A {@link Response} for providing a single method call result.
         */
        void onMethodCall(MethodCall call, Response response);
    }

    /**
     * A call-back interface for handling stream setup and teardown requests.
     */
    public interface StreamHandler {
        /**
         * Handles a stream setup request.
         *
         * @param arguments Stream configuration arguments, possibly null.
         * @param eventSink A {@link EventSink} used to emit events once the stream has been set up.
         */
        void listen(Object arguments, EventSink eventSink);

        /**
         * Handles a stream tear-down request.
         *
         * @param arguments Stream configuration arguments, possibly null.
         */
        void cancel(Object arguments);
    }

    /**
     * Response interface for sending results back to Flutter.
     */
    public interface Response {
        /**
         * Submits a successful result.
         *
         * @param result The result, possibly null.
         */
        void success(Object result);

        /**
         * Submits an error during message handling, an error result of a method call, or an error
         * event.
         *
         * @param errorCode An error code String.
         * @param errorMessage A human-readable error message String, possibly null.
         * @param errorDetails Error details, possibly null
         */
        void error(String errorCode, String errorMessage, Object errorDetails);
    }

    /**
     * A {@link Response} supporting multiple results and which can be terminated.
     */
    public interface EventSink extends Response {
        /**
         * Signals that no more events will be emitted.
         */
        void done();
    }

    private final class MethodCallListener implements OnBinaryMessageListenerAsync {
        private final MethodCallHandler handler;

        MethodCallListener(MethodCallHandler handler) {
            this.handler = handler;
        }

        @Override
        public void onMessage(FlutterView view, ByteBuffer message,
            final BinaryMessageResponse response) {
            final MethodCall call = codec.decodeMethodCall(message);
            try {
                handler.onMethodCall(call, new Response() {
                    private boolean done = false;

                    @Override
                    public void success(Object result) {
                        checkDone();
                        response.send(codec.encodeSuccessEnvelope(result));
                        done = true;
                    }

                    @Override
                    public void error(String errorCode, String errorMessage, Object errorDetails) {
                        checkDone();
                        response.send(codec.encodeErrorEnvelope(
                            errorCode, errorMessage, errorDetails));
                        done = true;
                    }

                    private void checkDone() {
                        if (done) {
                            throw new IllegalStateException("Call result already provided");
                        }
                    }
                });
            } catch (Exception e) {
                Log.e(TAG + name, "Failed to handle method call", e);
                response.send(codec.encodeErrorEnvelope("error", e.getMessage(),null));
            }
        }
    }

    private final class StreamListener implements OnBinaryMessageListenerAsync {
        private final StreamHandler handler;

        StreamListener(StreamHandler handler) {
            this.handler = handler;
        }

        @Override
        public void onMessage(FlutterView view, ByteBuffer message,
            final BinaryMessageResponse response) {
            final MethodCall call = codec.decodeMethodCall(message);
            final AtomicBoolean cancelled = new AtomicBoolean(false);
            if (call.method.equals("listen")) {
                try {
                    handler.listen(call.arguments, new EventSink() {
                        @Override
                        public void success(Object event) {
                            if (cancelled.get()) {
                                return;
                            }
                            FlutterMethodChannel.this.view.sendBinaryMessage(
                                name,
                                codec.encodeSuccessEnvelope(event),
                                null);
                        }

                        @Override
                        public void error(String errorCode, String errorMessage,
                            Object errorDetails) {
                            if (cancelled.get()) {
                                return;
                            }
                            FlutterMethodChannel.this.view.sendBinaryMessage(
                                name,
                                codec.encodeErrorEnvelope(errorCode, errorMessage, errorDetails),
                                null);
                        }

                        @Override
                        public void done() {
                            if (cancelled.get()) {
                                return;
                            }
                            FlutterMethodChannel.this.view.sendToFlutter(name,null);
                        }
                    });
                    response.send(codec.encodeSuccessEnvelope(null));
                } catch (Exception e) {
                    Log.e(TAG + name, "Failed to open event stream", e);
                    response.send(codec.encodeErrorEnvelope("error", e.getMessage(),null));
                }
            } else if (call.method.equals("cancel")) {
                cancelled.set(true);
                try {
                    handler.cancel(call.arguments);
                    response.send(codec.encodeSuccessEnvelope(null));
                } catch (Exception e) {
                    Log.e(TAG + name, "Failed to close event stream", e);
                    response.send(codec.encodeErrorEnvelope("error", e.getMessage(),null));
                }
            }
        }
    }
}
