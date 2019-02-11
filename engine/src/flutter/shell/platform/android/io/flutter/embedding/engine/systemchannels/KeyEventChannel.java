// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.embedding.engine.systemchannels;

import android.support.annotation.NonNull;
import android.support.annotation.Nullable;
import android.view.KeyEvent;

import java.util.HashMap;
import java.util.Map;

import io.flutter.embedding.engine.dart.DartExecutor;
import io.flutter.plugin.common.BasicMessageChannel;
import io.flutter.plugin.common.JSONMessageCodec;

/**
 * TODO(mattcarroll): fill in javadoc for KeyEventChannel.
 */
public class KeyEventChannel {

  @NonNull
  public final BasicMessageChannel<Object> channel;

  public KeyEventChannel(@NonNull DartExecutor dartExecutor) {
    this.channel = new BasicMessageChannel<>(dartExecutor, "flutter/keyevent", JSONMessageCodec.INSTANCE);
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

  private void encodeKeyEvent(@NonNull FlutterKeyEvent event, @NonNull Map<String, Object> message) {
    message.put("flags", event.flags);
    message.put("plainCodePoint", event.plainCodePoint);
    message.put("codePoint", event.codePoint);
    message.put("keyCode", event.keyCode);
    message.put("scanCode", event.scanCode);
    message.put("metaState", event.metaState);
    if (event.complexCharacter != null) {
      message.put("character", event.complexCharacter.toString());
    }
  }

  /**
   * Key event as defined by Flutter.
   */
  public static class FlutterKeyEvent {
    public final int flags;
    public final int plainCodePoint;
    public final int codePoint;
    public final int keyCode;
    @Nullable
    public final Character complexCharacter;
    public final int scanCode;
    public final int metaState;

    public FlutterKeyEvent(
        @NonNull KeyEvent androidKeyEvent
    ) {
      this(androidKeyEvent, null);
    }

    public FlutterKeyEvent(
        @NonNull KeyEvent androidKeyEvent,
        @Nullable Character complexCharacter
    ) {
      this(
          androidKeyEvent.getFlags(),
          androidKeyEvent.getUnicodeChar(0x0),
          androidKeyEvent.getUnicodeChar(),
          androidKeyEvent.getKeyCode(),
          complexCharacter,
          androidKeyEvent.getScanCode(),
          androidKeyEvent.getMetaState()
      );
    }

    public FlutterKeyEvent(
        int flags,
        int plainCodePoint,
        int codePoint,
        int keyCode,
        @Nullable Character complexCharacter,
        int scanCode,
        int metaState
    ) {
      this.flags = flags;
      this.plainCodePoint = plainCodePoint;
      this.codePoint = codePoint;
      this.keyCode = keyCode;
      this.complexCharacter = complexCharacter;
      this.scanCode = scanCode;
      this.metaState = metaState;
    }
  }
}
