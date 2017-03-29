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

/**
 * A named channel for communicating with the Flutter application using asynchronous
 * method calls.
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
     * Invokes a method on this channel, expecting no result.
     *
     * @param method the name String of the method.
     * @param arguments the arguments for the invocation, possibly null.
     */
    public void invokeMethod(String method, Object arguments) {
        invokeMethod(method, arguments, null);
    }

    /**
     * Invokes a method on this channel.
     *
     * @param method the name String of the method.
     * @param arguments the arguments for the invocation, possibly null.
     * @param handler a {@link Response} handler for the invocation result.
     */
    public void invokeMethod(String method, Object arguments, Response handler) {
        view.sendBinaryMessage(name, codec.encodeMethodCall(new MethodCall(method, arguments)),
            handler == null ? null : new MethodCallResultCallback(handler));
    }

    /**
     * Registers a method call handler on this channel.
     *
     * Overrides any existing handler registration.
     *
     * @param handler a {@link MethodCallHandler}, or null to deregister.
     */
    public void setMethodCallHandler(final MethodCallHandler handler) {
        view.addOnBinaryMessageListenerAsync(name,
            handler == null ? null : new MethodCallListener(handler));
    }

    /**
     * Strategy for handling the result of a method call. Supports dual use:
     * Implementations of methods to be invoked by Flutter act as clients of this interface
     * for sending results back to Flutter. Invokers of Flutter methods provide
     * implementations of this interface for handling results received from Flutter.
     */
    public interface Response {
        /**
         * Handles a successful result.
         *
         * @param result The result, possibly null.
         */
        void success(Object result);

        /**
         * Handles an error result.
         *
         * @param errorCode An error code String.
         * @param errorMessage A human-readable error message String, possibly null.
         * @param errorDetails Error details, possibly null
         */
        void error(String errorCode, String errorMessage, Object errorDetails);

        /**
         * Handles a call to an unimplemented method.
         */
        void notImplemented();
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

    private final class MethodCallResultCallback implements BinaryMessageReplyCallback {
        private final Response handler;

        MethodCallResultCallback(Response handler) {
            this.handler = handler;
        }

        @Override
        public void onReply(ByteBuffer reply) {
            if (reply == null) {
                handler.notImplemented();
            } else {
                try {
                    final Object result = codec.decodeEnvelope(reply);
                    handler.success(result);
                } catch (FlutterException e) {
                    handler.error(e.code, e.getMessage(), e.details);
                }
            }
        }
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

                    @Override
                    public void notImplemented() {
                        checkDone();
                        response.send(null);
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
                response.send(codec.encodeErrorEnvelope("error", e.getMessage(), null));
            }
        }
    }
}
