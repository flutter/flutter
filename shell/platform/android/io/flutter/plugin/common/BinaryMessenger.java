package io.flutter.plugin.common;

import java.nio.ByteBuffer;

/**
 * Facility for communicating with Flutter using asynchronous message passing with binary messages.
 * The Flutter Dart code can use {@code BinaryMessages} to participate.
 *
 * @see BasicMessageChannel , which supports message passing with Strings and semi-structured messages.
 * @see MethodChannel , which supports communication using asynchronous method invocation.
 * @see EventChannel , which supports communication using event streams.
 */
public interface BinaryMessenger {
    /**
     * Sends a binary message to the Flutter application. The Flutter Dart code can register a
     * platform message handler with {@code BinaryMessages} that will receive these messages.
     *
     * @param channel the name {@link String} of the channel that will receive this message.
     * @param message the message payload, a {@link ByteBuffer} with the message bytes between position
     * zero and current position, or null.
     */
    void send(String channel, ByteBuffer message);

    /**
     * Sends a binary message to the Flutter application,
     *
     * @param channel the name {@link String} of the channel that will receive this message.
     * @param message the message payload, a {@link ByteBuffer} with the message bytes between position
     * zero and current position, or null.
     * @param callback a {@link BinaryReply} callback invoked when the Flutter application responds to the
     * message, possibly null.
     */
    void send(String channel, ByteBuffer message, BinaryReply callback);

    /**
     * Registers a handler to be invoked when the Flutter application sends a message
     * to its host platform.
     *
     * Registration overwrites any previous registration for the same channel name.
     * Use a {@code null} handler to unregister.
     *
     * @param channel the name {@link String} of the channel.
     * @param handler a {@link BinaryMessageHandler} to be invoked on incoming messages.
     */
    void setMessageHandler(String channel, BinaryMessageHandler handler);

    /**
     * Handler for incoming binary messages from Flutter.
     */
    interface BinaryMessageHandler {
        /**
         * Handles the specified message.
         *
         * @param message the message {@link ByteBuffer} payload.
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
         * @param reply the reply payload, a {@link ByteBuffer} or null. Senders of outgoing
         * replies must place the reply bytes between position zero and current position.
         * Reply receivers can read from the buffer directly.
         */
        void reply(ByteBuffer reply);
    }
}
