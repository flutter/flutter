// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.yourcompany.channels;

import java.nio.ByteBuffer;

import android.os.Bundle;

import io.flutter.app.FlutterActivity;
import io.flutter.plugin.common.*;
import io.flutter.plugins.GeneratedPluginRegistrant;

public class MainActivity extends FlutterActivity {
  @Override
  protected void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    GeneratedPluginRegistrant.registerWith(this);
    setupMessageHandshake(new BasicMessageChannel<>(getFlutterView(), "binary-msg", BinaryCodec.INSTANCE));
    setupMessageHandshake(new BasicMessageChannel<>(getFlutterView(), "string-msg", StringCodec.INSTANCE));
    setupMessageHandshake(new BasicMessageChannel<>(getFlutterView(), "json-msg", JSONMessageCodec.INSTANCE));
    setupMessageHandshake(new BasicMessageChannel<>(getFlutterView(), "std-msg", StandardMessageCodec.INSTANCE));
    setupMethodHandshake(new MethodChannel(getFlutterView(), "json-method", JSONMethodCodec.INSTANCE));
    setupMethodHandshake(new MethodChannel(getFlutterView(), "std-method", StandardMethodCodec.INSTANCE));
  }

  private <T> void setupMessageHandshake(final BasicMessageChannel<T> channel) {
    // On message receipt, do a send/reply/send round-trip in the other direction,
    // then reply to the first message.
    channel.setMessageHandler(new BasicMessageChannel.MessageHandler<T>() {
      @Override
      public void onMessage(final T message, final BasicMessageChannel.Reply<T> reply) {
        final T messageEcho = echo(message);
        channel.send(messageEcho, new BasicMessageChannel.Reply<T>() {
          @Override
          public void reply(T replyMessage) {
            channel.send(echo(replyMessage));
            reply.reply(messageEcho);
          }
        });
      }
    });
  }

  // Outgoing ByteBuffer messages must be direct-allocated and payload placed between
  // position 0 and current position.
  @SuppressWarnings("unchecked")
  private <T> T echo(T message) {
    if (message instanceof ByteBuffer) {
      final ByteBuffer buffer = (ByteBuffer) message;
      final ByteBuffer echo = ByteBuffer.allocateDirect(buffer.remaining());
      echo.put(buffer);
      return (T) echo;
    }
    return message;
  }

  private void setupMethodHandshake(final MethodChannel channel) {
    channel.setMethodCallHandler(new MethodChannel.MethodCallHandler() {
      @Override
      public void onMethodCall(final MethodCall methodCall, final MethodChannel.Result result) {
        switch (methodCall.method) {
          case "success":
            doSuccessHandshake(channel, methodCall, result);
            break;
          case "error":
            doErrorHandshake(channel, methodCall, result);
            break;
          default:
            doNotImplementedHandshake(channel, methodCall, result);
            break;
        }
      }
    });
  }

  private void doSuccessHandshake(final MethodChannel channel, final MethodCall methodCall, final MethodChannel.Result result) {
    channel.invokeMethod(methodCall.method, methodCall.arguments, new MethodChannel.Result() {
      @Override
      public void success(Object o) {
        channel.invokeMethod(methodCall.method, o);
        result.success(methodCall.arguments);
      }

      @Override
      public void error(String code, String message, Object details) {
        throw new AssertionError("Should not be called");
      }

      @Override
      public void notImplemented() {
        throw new AssertionError("Should not be called");
      }
    });
  }

  private void doErrorHandshake(final MethodChannel channel, final MethodCall methodCall, final MethodChannel.Result result) {
    channel.invokeMethod(methodCall.method, methodCall.arguments, new MethodChannel.Result() {
      @Override
      public void success(Object o) {
        throw new AssertionError("Should not be called");
      }

      @Override
      public void error(String code, String message, Object details) {
        channel.invokeMethod(methodCall.method, details);
        result.error(code, message, methodCall.arguments);
      }

      @Override
      public void notImplemented() {
        throw new AssertionError("Should not be called");
      }
    });
  }

  private void doNotImplementedHandshake(final MethodChannel channel, final MethodCall methodCall, final MethodChannel.Result result) {
    channel.invokeMethod(methodCall.method, methodCall.arguments, new MethodChannel.Result() {
      @Override
      public void success(Object o) {
        throw new AssertionError("Should not be called");
      }

      @Override
      public void error(String code, String message, Object details) {
        throw new AssertionError("Should not be called");
      }

      @Override
      public void notImplemented() {
        channel.invokeMethod(methodCall.method, null);
        result.notImplemented();
      }
    });
  }
}
