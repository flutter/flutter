// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.embedding.engine.systemchannels;

import android.support.annotation.NonNull;
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

  public void keyUp(@NonNull KeyEvent keyEvent) {
    Map<String, Object> message = new HashMap<>();
    message.put("type", "keyup");
    message.put("keymap", "android");
    encodeKeyEvent(keyEvent, message);

    channel.send(message);
  }

  public void keyDown(@NonNull KeyEvent keyEvent) {
    Map<String, Object> message = new HashMap<>();
    message.put("type", "keydown");
    message.put("keymap", "android");
    encodeKeyEvent(keyEvent, message);

    channel.send(message);
  }

  private void encodeKeyEvent(@NonNull KeyEvent event, @NonNull Map<String, Object> message) {
    message.put("flags", event.getFlags());
    message.put("codePoint", event.getUnicodeChar());
    message.put("keyCode", event.getKeyCode());
    message.put("scanCode", event.getScanCode());
    message.put("metaState", event.getMetaState());
  }
}
