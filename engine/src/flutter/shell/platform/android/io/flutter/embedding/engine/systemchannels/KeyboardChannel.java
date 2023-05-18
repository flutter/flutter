// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.embedding.engine.systemchannels;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import io.flutter.embedding.engine.dart.DartExecutor;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.StandardMethodCodec;
import java.util.HashMap;
import java.util.Map;

/**
 * Event message channel for keyboard events to/from the Flutter framework.
 *
 * <p>Receives asynchronous messages from the framework to query the engine known pressed state.
 */
public class KeyboardChannel {
  private static final String TAG = "KeyboardChannel";

  public final MethodChannel channel;
  private KeyboardMethodHandler keyboardMethodHandler;

  @NonNull
  public final MethodChannel.MethodCallHandler parsingMethodHandler =
      new MethodChannel.MethodCallHandler() {
        @Override
        public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
          if (keyboardMethodHandler == null) {
            return;
          }
          switch (call.method) {
            case "getKeyboardState":
              Map<Long, Long> pressedState = new HashMap<>();
              try {
                pressedState = keyboardMethodHandler.getKeyboardState();
              } catch (IllegalStateException exception) {
                result.error("error", exception.getMessage(), null);
              }
              result.success(pressedState);
              break;
            default:
              result.notImplemented();
              break;
          }
        }
      };

  public KeyboardChannel(@NonNull DartExecutor dartExecutor) {
    channel = new MethodChannel(dartExecutor, "flutter/keyboard", StandardMethodCodec.INSTANCE);
    channel.setMethodCallHandler(parsingMethodHandler);
  }

  /**
   * Sets the {@link KeyboardMethodHandler} which receives all requests to query the keyboard state.
   */
  public void setKeyboardMethodHandler(@Nullable KeyboardMethodHandler keyboardMethodHandler) {
    this.keyboardMethodHandler = keyboardMethodHandler;
  }

  public interface KeyboardMethodHandler {
    /**
     * Returns the keyboard pressed states.
     *
     * @return A map whose keys are physical keyboard key IDs and values are the corresponding
     *     logical keyboard key IDs.
     */
    Map<Long, Long> getKeyboardState();
  }
}
