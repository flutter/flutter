// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.embedding.engine.systemchannels;

import android.os.Build;
import android.view.InputDevice;
import android.view.KeyEvent;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import io.flutter.embedding.engine.dart.DartExecutor;
import io.flutter.plugin.common.BasicMessageChannel;
import io.flutter.plugin.common.JSONMessageCodec;
import java.util.HashMap;
import java.util.Map;

/** TODO(mattcarroll): fill in javadoc for KeyEventChannel. */
public class KeyEventChannel {

  @NonNull public final BasicMessageChannel<Object> channel;

  public KeyEventChannel(@NonNull DartExecutor dartExecutor) {
    this.channel =
        new BasicMessageChannel<>(dartExecutor, "flutter/keyevent", JSONMessageCodec.INSTANCE);
  }

  public void keyUp(@NonNull FlutterKeyEvent keyEvent) {
    Map<String, Object> message = new HashMap<>();
    message.put("type", "keyup");
    message.put("keymap", "android");
    encodeKeyEvent(keyEvent, message);

    channel.send(message);
  }

  public void keyDown(@NonNull FlutterKeyEvent keyEvent) {
    Map<String, Object> message = new HashMap<>();
    message.put("type", "keydown");
    message.put("keymap", "android");
    encodeKeyEvent(keyEvent, message);

    channel.send(message);
  }

  private void encodeKeyEvent(
      @NonNull FlutterKeyEvent event, @NonNull Map<String, Object> message) {
    message.put("flags", event.flags);
    message.put("plainCodePoint", event.plainCodePoint);
    message.put("codePoint", event.codePoint);
    message.put("keyCode", event.keyCode);
    message.put("scanCode", event.scanCode);
    message.put("metaState", event.metaState);
    if (event.complexCharacter != null) {
      message.put("character", event.complexCharacter.toString());
    }
    message.put("source", event.source);
    message.put("vendorId", event.vendorId);
    message.put("productId", event.productId);
    message.put("deviceId", event.deviceId);
    message.put("repeatCount", event.repeatCount);
  }

  /** Key event as defined by Flutter. */
  public static class FlutterKeyEvent {
    public final int deviceId;
    public final int flags;
    public final int plainCodePoint;
    public final int codePoint;
    public final int keyCode;
    @Nullable public final Character complexCharacter;
    public final int scanCode;
    public final int metaState;
    public final int source;
    public final int vendorId;
    public final int productId;
    public final int repeatCount;

    public FlutterKeyEvent(@NonNull KeyEvent androidKeyEvent) {
      this(androidKeyEvent, null);
    }

    public FlutterKeyEvent(
        @NonNull KeyEvent androidKeyEvent, @Nullable Character complexCharacter) {
      this(
          androidKeyEvent.getDeviceId(),
          androidKeyEvent.getFlags(),
          androidKeyEvent.getUnicodeChar(0x0),
          androidKeyEvent.getUnicodeChar(),
          androidKeyEvent.getKeyCode(),
          complexCharacter,
          androidKeyEvent.getScanCode(),
          androidKeyEvent.getMetaState(),
          androidKeyEvent.getSource(),
          androidKeyEvent.getRepeatCount());
    }

    public FlutterKeyEvent(
        int deviceId,
        int flags,
        int plainCodePoint,
        int codePoint,
        int keyCode,
        @Nullable Character complexCharacter,
        int scanCode,
        int metaState,
        int source,
        int repeatCount) {
      this.deviceId = deviceId;
      this.flags = flags;
      this.plainCodePoint = plainCodePoint;
      this.codePoint = codePoint;
      this.keyCode = keyCode;
      this.complexCharacter = complexCharacter;
      this.scanCode = scanCode;
      this.metaState = metaState;
      this.source = source;
      this.repeatCount = repeatCount;
      InputDevice device = InputDevice.getDevice(deviceId);
      if (device != null) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
          this.vendorId = device.getVendorId();
          this.productId = device.getProductId();
        } else {
          this.vendorId = 0;
          this.productId = 0;
        }
      } else {
        this.vendorId = 0;
        this.productId = 0;
      }
    }
  }
}
