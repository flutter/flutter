// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.embedding.engine.dart;

import android.support.annotation.NonNull;
import android.util.Log;

import java.nio.ByteBuffer;
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.atomic.AtomicBoolean;

import io.flutter.embedding.engine.FlutterJNI;
import io.flutter.plugin.common.BinaryMessenger;

/**
 * Message conduit for 2-way communication between Android and Dart.
 * <p>
 * WARNING: THIS CLASS IS EXPERIMENTAL. DO NOT SHIP A DEPENDENCY ON THIS CODE.
 * IF YOU USE IT, WE WILL BREAK YOU.
 * <p>
 * See {@link BinaryMessenger}, which sends messages from Android to Dart
 * See {@link PlatformMessageHandler}, which handles messages to Android from Dart
 */
class DartMessenger implements BinaryMessenger, PlatformMessageHandler {
  private static final String TAG = "DartMessenger";
  
  private final FlutterJNI flutterJNI;
  private final Map<String, BinaryMessenger.BinaryMessageHandler> messageHandlers;
  private final Map<Integer, BinaryMessenger.BinaryReply> mPendingReplies = new HashMap<>();
  private int mNextReplyId = 1;
  
  DartMessenger(@NonNull FlutterJNI flutterJNI) {
    this.flutterJNI = flutterJNI;
    this.messageHandlers = new HashMap<>();
  }
  
  @Override
  public void setMessageHandler(String channel, BinaryMessenger.BinaryMessageHandler handler) {
    if (handler == null) {
      messageHandlers.remove(channel);
    } else {
      messageHandlers.put(channel, handler);
    }
  }
  
  @Override
  public void send(String channel, ByteBuffer message) {
    send(channel, message, null);
  }
  
  @Override
  public void send(String channel, ByteBuffer message, BinaryMessenger.BinaryReply callback) {
    int replyId = 0;
    if (callback != null) {
      replyId = mNextReplyId++;
      mPendingReplies.put(replyId, callback);
    }
    if (message == null) {
      flutterJNI.dispatchEmptyPlatformMessage(channel, replyId);
    } else {
      flutterJNI.dispatchPlatformMessage(channel, message, message.position(), replyId);
    }
  }
  
  @Override
  public void handlePlatformMessage(final String channel, byte[] message, final int replyId) {
    BinaryMessenger.BinaryMessageHandler handler = messageHandlers.get(channel);
    if (handler != null) {
      try {
        final ByteBuffer buffer = (message == null ? null : ByteBuffer.wrap(message));
        handler.onMessage(buffer, new BinaryMessenger.BinaryReply() {
          private final AtomicBoolean done = new AtomicBoolean(false);
          
          @Override
          public void reply(ByteBuffer reply) {
            if (done.getAndSet(true)) {
              throw new IllegalStateException("Reply already submitted");
            }
            if (reply == null) {
              flutterJNI.invokePlatformMessageEmptyResponseCallback(replyId);
            } else {
              flutterJNI.invokePlatformMessageResponseCallback(replyId, reply, reply.position());
            }
          }
        });
      } catch (Exception ex) {
        Log.e(TAG, "Uncaught exception in binary message listener", ex);
        flutterJNI.invokePlatformMessageEmptyResponseCallback(replyId);
      }
      return;
    }
    flutterJNI.invokePlatformMessageEmptyResponseCallback(replyId);
  }
  
  @Override
  public void handlePlatformMessageResponse(int replyId, byte[] reply) {
    BinaryMessenger.BinaryReply callback = mPendingReplies.remove(replyId);
    if (callback != null) {
      try {
        callback.reply(reply == null ? null : ByteBuffer.wrap(reply));
      } catch (Exception ex) {
        Log.e(TAG, "Uncaught exception in binary message reply handler", ex);
      }
    }
  }
}