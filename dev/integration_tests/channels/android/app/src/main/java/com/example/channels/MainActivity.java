// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.example.channels;

import java.io.ByteArrayOutputStream;
import java.nio.ByteBuffer;
import java.util.Date;

import android.os.Bundle;
import androidx.annotation.NonNull;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.dart.DartExecutor;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.*;
import io.flutter.plugins.GeneratedPluginRegistrant;

public class MainActivity extends FlutterActivity {
  @Override
  public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
    super.configureFlutterEngine(flutterEngine);

    DartExecutor dartExecutor = flutterEngine.getDartExecutor();
    setupMessageHandshake(new BasicMessageChannel<>(dartExecutor, "binary-msg", BinaryCodec.INSTANCE));
    setupMessageHandshake(new BasicMessageChannel<>(dartExecutor, "string-msg", StringCodec.INSTANCE));
    setupMessageHandshake(new BasicMessageChannel<>(dartExecutor, "json-msg", JSONMessageCodec.INSTANCE));
    setupMessageHandshake(new BasicMessageChannel<>(dartExecutor, "std-msg", ExtendedStandardMessageCodec.INSTANCE));
    setupMethodHandshake(new MethodChannel(dartExecutor, "json-method", JSONMethodCodec.INSTANCE));
    setupMethodHandshake(new MethodChannel(dartExecutor, "std-method", new StandardMethodCodec(ExtendedStandardMessageCodec.INSTANCE)));

    BasicMessageChannel echoChannel =
        new BasicMessageChannel(dartExecutor, "std-echo", ExtendedStandardMessageCodec.INSTANCE);
    echoChannel.setMessageHandler(new BasicMessageChannel.MessageHandler(){
      @Override
      public void onMessage(final Object message, final BasicMessageChannel.Reply reply) {
        reply.reply(message);
      }
    });
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

final class ExtendedStandardMessageCodec extends StandardMessageCodec {
  public static final ExtendedStandardMessageCodec INSTANCE = new ExtendedStandardMessageCodec();
  private static final byte DATE = (byte) 128;
  private static final byte PAIR = (byte) 129;

  @Override
  protected void writeValue(ByteArrayOutputStream stream, Object value) {
    if (value instanceof Date) {
      stream.write(DATE);
      writeLong(stream, ((Date) value).getTime());
    } else if (value instanceof Pair) {
      stream.write(PAIR);
      writeValue(stream, ((Pair) value).left);
      writeValue(stream, ((Pair) value).right);
    } else {
      super.writeValue(stream, value);
    }
  }

  @Override
  protected Object readValueOfType(byte type, ByteBuffer buffer) {
    switch (type) {
      case DATE:
        return new Date(buffer.getLong());
      case PAIR:
        return new Pair(readValue(buffer), readValue(buffer));
      default: return super.readValueOfType(type, buffer);
    }
  }
}

final class Pair {
  public final Object left;
  public final Object right;

  public Pair(Object left, Object right) {
    this.left = left;
    this.right = right;
  }

  @Override
  public String toString() {
    return "Pair[" + left + ", " + right + "]";
  }
}
