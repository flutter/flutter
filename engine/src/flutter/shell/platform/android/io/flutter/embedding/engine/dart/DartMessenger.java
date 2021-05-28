// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.embedding.engine.dart;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.annotation.UiThread;
import io.flutter.Log;
import io.flutter.embedding.engine.FlutterJNI;
import io.flutter.plugin.common.BinaryMessenger;
import java.nio.ByteBuffer;
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.atomic.AtomicBoolean;

/**
 * Message conduit for 2-way communication between Android and Dart.
 *
 * <p>See {@link BinaryMessenger}, which sends messages from Android to Dart
 *
 * <p>See {@link PlatformMessageHandler}, which handles messages to Android from Dart
 */
class DartMessenger implements BinaryMessenger, PlatformMessageHandler {
  private static final String TAG = "DartMessenger";

  @NonNull private final FlutterJNI flutterJNI;
  @NonNull private final Map<String, BinaryMessenger.BinaryMessageHandler> messageHandlers;
  @NonNull private final Map<Integer, BinaryMessenger.BinaryReply> pendingReplies;
  private int nextReplyId = 1;

  DartMessenger(@NonNull FlutterJNI flutterJNI) {
    this.flutterJNI = flutterJNI;
    this.messageHandlers = new HashMap<>();
    this.pendingReplies = new HashMap<>();
  }

  @Override
  public void setMessageHandler(
      @NonNull String channel, @Nullable BinaryMessenger.BinaryMessageHandler handler) {
    if (handler == null) {
      Log.v(TAG, "Removing handler for channel '" + channel + "'");
      messageHandlers.remove(channel);
    } else {
      Log.v(TAG, "Setting handler for channel '" + channel + "'");
      messageHandlers.put(channel, handler);
    }
  }

  @Override
  @UiThread
  public void send(@NonNull String channel, @NonNull ByteBuffer message) {
    Log.v(TAG, "Sending message over channel '" + channel + "'");
    send(channel, message, null);
  }

  @Override
  public void send(
      @NonNull String channel,
      @Nullable ByteBuffer message,
      @Nullable BinaryMessenger.BinaryReply callback) {
    Log.v(TAG, "Sending message with callback over channel '" + channel + "'");
    int replyId = 0;
    if (callback != null) {
      replyId = nextReplyId++;
      pendingReplies.put(replyId, callback);
    }
    if (message == null) {
      flutterJNI.dispatchEmptyPlatformMessage(channel, replyId);
    } else {
      flutterJNI.dispatchPlatformMessage(channel, message, message.position(), replyId);
    }
  }

  @Override
  public void handleMessageFromDart(
      @NonNull final String channel, @Nullable byte[] message, final int replyId) {
    Log.v(TAG, "Received message from Dart over channel '" + channel + "'");
    BinaryMessenger.BinaryMessageHandler handler = messageHandlers.get(channel);
    if (handler != null) {
      try {
        Log.v(TAG, "Deferring to registered handler to process message.");
        final ByteBuffer buffer = (message == null ? null : ByteBuffer.wrap(message));
        handler.onMessage(buffer, new Reply(flutterJNI, replyId));
      } catch (Exception ex) {
        Log.e(TAG, "Uncaught exception in binary message listener", ex);
        flutterJNI.invokePlatformMessageEmptyResponseCallback(replyId);
      } catch (Error err) {
        handleError(err);
      }
    } else {
      Log.v(TAG, "No registered handler for message. Responding to Dart with empty reply message.");
      flutterJNI.invokePlatformMessageEmptyResponseCallback(replyId);
    }
  }

  @Override
  public void handlePlatformMessageResponse(int replyId, @Nullable byte[] reply) {
    Log.v(TAG, "Received message reply from Dart.");
    BinaryMessenger.BinaryReply callback = pendingReplies.remove(replyId);
    if (callback != null) {
      try {
        Log.v(TAG, "Invoking registered callback for reply from Dart.");
        callback.reply(reply == null ? null : ByteBuffer.wrap(reply));
      } catch (Exception ex) {
        Log.e(TAG, "Uncaught exception in binary message reply handler", ex);
      } catch (Error err) {
        handleError(err);
      }
    }
  }

  /**
   * Returns the number of pending channel callback replies.
   *
   * <p>When sending messages to the Flutter application using {@link BinaryMessenger#send(String,
   * ByteBuffer, io.flutter.plugin.common.BinaryMessenger.BinaryReply)}, developers can optionally
   * specify a reply callback if they expect a reply from the Flutter application.
   *
   * <p>This method tracks all the pending callbacks that are waiting for response, and is supposed
   * to be called from the main thread (as other methods). Calling from a different thread could
   * possibly capture an indeterministic internal state, so don't do it.
   */
  @UiThread
  public int getPendingChannelResponseCount() {
    return pendingReplies.size();
  }

  // Handles `Error` objects which are not supposed to be caught.
  //
  // We forward them to the thread's uncaught exception handler if there is one. If not, they
  // are rethrown.
  private static void handleError(Error err) {
    Thread currentThread = Thread.currentThread();
    if (currentThread.getUncaughtExceptionHandler() == null) {
      throw err;
    }
    currentThread.getUncaughtExceptionHandler().uncaughtException(currentThread, err);
  }

  static class Reply implements BinaryMessenger.BinaryReply {
    @NonNull private final FlutterJNI flutterJNI;
    private final int replyId;
    private final AtomicBoolean done = new AtomicBoolean(false);

    Reply(@NonNull FlutterJNI flutterJNI, int replyId) {
      this.flutterJNI = flutterJNI;
      this.replyId = replyId;
    }

    @Override
    public void reply(@Nullable ByteBuffer reply) {
      if (done.getAndSet(true)) {
        throw new IllegalStateException("Reply already submitted");
      }
      if (reply == null) {
        flutterJNI.invokePlatformMessageEmptyResponseCallback(replyId);
      } else {
        flutterJNI.invokePlatformMessageResponseCallback(replyId, reply, reply.position());
      }
    }
  }
}
