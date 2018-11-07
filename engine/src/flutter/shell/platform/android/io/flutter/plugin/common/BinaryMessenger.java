// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugin.common;

import java.nio.ByteBuffer;

/**
 * Facility for communicating with Flutter using asynchronous message passing with binary messages.
 * The Flutter Dart code should use
 * <a href="https://docs.flutter.io/flutter/services/BinaryMessages-class.html">BinaryMessages</a>
 * to participate.
 *
 * @see BasicMessageChannel , which supports message passing with Strings and semi-structured messages.
 * @see MethodChannel , which supports communication using asynchronous method invocation.
 * @see EventChannel , which supports communication using event streams.
 */
public interface BinaryMessenger {
    /**
     * Sends a binary message to the Flutter application.
     *
     * @param channel the name {@link String} of the logical channel used for the message.
     * @param message the message payload, a direct-allocated {@link ByteBuffer} with the message bytes
     * between position zero and current position, or null.
     */
    void send(String channel, ByteBuffer message);

    /**
     * Sends a binary message to the Flutter application, optionally expecting a reply.
     *
     * <p>Any uncaught exception thrown by the reply callback will be caught and logged.</p>
     *
     * @param channel the name {@link String} of the logical channel used for the message.
     * @param message the message payload, a direct-allocated {@link ByteBuffer} with the message bytes
     * between position zero and current position, or null.
     * @param callback a {@link BinaryReply} callback invoked when the Flutter application responds to the
     * message, possibly null.
     */
    void send(String channel, ByteBuffer message, BinaryReply callback);

    /**
     * Registers a handler to be invoked when the Flutter application sends a message
     * to its host platform.
     *
     * <p>Registration overwrites any previous registration for the same channel name.
     * Use a null handler to deregister.</p>
     *
     * <p>If no handler has been registered for a particular channel, any incoming message on
     * that channel will be handled silently by sending a null reply.</p>
     *
     * @param channel the name {@link String} of the channel.
     * @param handler a {@link BinaryMessageHandler} to be invoked on incoming messages, or null.
     */
    void setMessageHandler(String channel, BinaryMessageHandler handler);

    /**
     * Handler for incoming binary messages from Flutter.
     */
    interface BinaryMessageHandler {
        /**
         * Handles the specified message.
         *
         * <p>Handler implementations must reply to all incoming messages, by submitting a single reply
         * message to the given {@link BinaryReply}. Failure to do so will result in lingering Flutter reply
         * handlers. The reply may be submitted asynchronously.</p>
         *
         * <p>Any uncaught exception thrown by this method will be caught by the messenger implementation and
         * logged, and a null reply message will be sent back to Flutter.</p>
         *
         * @param message the message {@link ByteBuffer} payload, possibly null.
         * @param reply A {@link BinaryReply} used for submitting a reply back to Flutter.
         */
        void onMessage(ByteBuffer message, BinaryReply reply);
    }

    /**
     * Binary message reply callback. Used to submit a reply to an incoming
     * message from Flutter. Also used in the dual capacity to handle a reply
     * received from Flutter after sending a message.
     */
    interface BinaryReply {
        /**
         * Handles the specified reply.
         *
         * @param reply the reply payload, a direct-allocated {@link ByteBuffer} or null. Senders of
         * outgoing replies must place the reply bytes between position zero and current position.
         * Reply receivers can read from the buffer directly.
         */
        void reply(ByteBuffer reply);
    }
}
