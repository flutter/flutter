// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugin.common;

import android.util.Log;
import io.flutter.plugin.common.BinaryMessenger.BinaryMessageHandler;
import io.flutter.plugin.common.BinaryMessenger.BinaryReply;
import java.nio.ByteBuffer;

/**
 * A named channel for communicating with the Flutter application using asynchronous
 * method calls.
 *
 * <p>Incoming method calls are decoded from binary on receipt, and Java results are encoded
 * into binary before being transmitted back to Flutter. The {@link MethodCodec} used must be
 * compatible with the one used by the Flutter application. This can be achieved
 * by creating a
 * <a href="https://docs.flutter.io/flutter/services/MethodChannel-class.html">MethodChannel</a>
 * counterpart of this channel on the Dart side. The Java type of method call arguments and results is
 * {@code Object}, but only values supported by the specified {@link MethodCodec} can be used.</p>
 *
 * <p>The logical identity of the channel is given by its name. Identically named channels will interfere
 * with each other's communication.</p>
 */
public final class MethodChannel {
    private static final String TAG = "MethodChannel#";

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
    public MethodChannel(BinaryMessenger messenger, String name) {
        this(messenger, name, StandardMethodCodec.INSTANCE);
    }

    /**
     * Creates a new channel associated with the specified {@link BinaryMessenger} and with the
     * specified name and {@link MethodCodec}.
     *
     * @param messenger a {@link BinaryMessenger}.
     * @param name a channel name String.
     * @param codec a {@link MessageCodec}.
     */
    public MethodChannel(BinaryMessenger messenger, String name, MethodCodec codec) {
        assert messenger != null;
        assert name != null;
        assert codec != null;
        this.messenger = messenger;
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
     * Invokes a method on this channel, optionally expecting a result.
     *
     * <p>Any uncaught exception thrown by the result callback will be caught and logged.</p>
     *
     * @param method the name String of the method.
     * @param arguments the arguments for the invocation, possibly null.
     * @param callback a {@link Result} callback for the invocation result, or null.
     */
    public void invokeMethod(String method, Object arguments, Result callback) {
        messenger.send(name, codec.encodeMethodCall(new MethodCall(method, arguments)),
            callback == null ? null : new IncomingResultHandler(callback));
    }

    /**
     * Registers a method call handler on this channel.
     *
     * <p>Overrides any existing handler registration for (the name of) this channel.</p>
     *
     * <p>If no handler has been registered, any incoming method call on this channel will be handled
     * silently by sending a null reply. This results in a
     * <a href="https://docs.flutter.io/flutter/services/MissingPluginException-class.html">MissingPluginException</a>
     * on the Dart side, unless an
     * <a href="https://docs.flutter.io/flutter/services/OptionalMethodChannel-class.html">OptionalMethodChannel</a>
     * is used.</p>
     *
     * @param handler a {@link MethodCallHandler}, or null to deregister.
     */
    public void setMethodCallHandler(final MethodCallHandler handler) {
        messenger.setMessageHandler(name,
            handler == null ? null : new IncomingMethodCallHandler(handler));
    }

    /**
     * A handler of incoming method calls.
     */
    public interface MethodCallHandler {
        /**
         * Handles the specified method call received from Flutter.
         *
         * <p>Handler implementations must submit a result for all incoming calls, by making a single call
         * on the given {@link Result} callback. Failure to do so will result in lingering Flutter result
         * handlers. The result may be submitted asynchronously. Calls to unknown or unimplemented methods
         * should be handled using {@link Result#notImplemented()}.</p>
         *
         * <p>Any uncaught exception thrown by this method, or the preceding method call decoding, will be
         * caught by the channel implementation and logged, and an error result will be sent back to Flutter.</p>
         *
         * <p>Any uncaught exception thrown during encoding a result submitted to the {@link Result}
         * is treated similarly: the exception is logged, and an error result is sent to Flutter.</p>
         *
         * @param call A {@link MethodCall}.
         * @param result A {@link Result} used for submitting the result of the call.
         */
        void onMethodCall(MethodCall call, Result result);
    }

    /**
     * Method call result callback. Supports dual use: Implementations of methods
     * to be invoked by Flutter act as clients of this interface for sending results
     * back to Flutter. Invokers of Flutter methods provide implementations of this
     * interface for handling results received from Flutter.
     */
    public interface Result {
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

    private final class IncomingResultHandler implements BinaryReply {
        private final Result callback;

        IncomingResultHandler(Result callback) {
            this.callback = callback;
        }

        @Override
        public void reply(ByteBuffer reply) {
            try {
                if (reply == null) {
                    callback.notImplemented();
                } else {
                    try {
                        final Object result = codec.decodeEnvelope(reply);
                        callback.success(result);
                    } catch (FlutterException e) {
                        callback.error(e.code, e.getMessage(), e.details);
                    }
                }
            } catch (RuntimeException e) {
                Log.e(TAG + name, "Failed to handle method call result", e);
            }
        }
    }

    private final class IncomingMethodCallHandler implements BinaryMessageHandler {
        private final MethodCallHandler handler;

        IncomingMethodCallHandler(MethodCallHandler handler) {
            this.handler = handler;
        }

        @Override
        public void onMessage(ByteBuffer message, final BinaryReply reply) {
            MethodCall call;
            try {
                call = codec.decodeMethodCall(message);
            } catch (RuntimeException e) {
                Log.e(TAG + name, "Failed to decode method call", e);
                reply.reply(codec.encodeErrorEnvelope("decode", e.getMessage(), null));
                return;
            }
            try {
                handler.onMethodCall(call, new Result() {
                    @Override
                    public void success(Object result) {
                        try {
                            reply.reply(codec.encodeSuccessEnvelope(result));
                        } catch (RuntimeException e) {
                            Log.e(TAG + name, "Failed to encode success result", e);
                            reply.reply(codec.encodeErrorEnvelope("encode", e.getMessage(), null));
                        }
                    }

                    @Override
                    public void error(String errorCode, String errorMessage, Object errorDetails) {
                        try {
                            reply.reply(codec.encodeErrorEnvelope(
                                    errorCode, errorMessage, errorDetails));
                        } catch (RuntimeException e) {
                            Log.e(TAG + name, "Failed to encode error result", e);
                            reply.reply(codec.encodeErrorEnvelope("encode", e.getMessage(), null));
                        }
                    }

                    @Override
                    public void notImplemented() {
                        reply.reply(null);
                    }
                });
            } catch (RuntimeException e) {
                Log.e(TAG + name, "Failed to handle method call", e);
                reply.reply(codec.encodeErrorEnvelope("uncaught", e.getMessage(), null));
            }
        }
    }
}
