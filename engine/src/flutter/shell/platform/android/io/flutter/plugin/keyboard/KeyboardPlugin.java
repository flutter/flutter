// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugin.keyboard;

import androidx.annotation.NonNull;
import androidx.annotation.VisibleForTesting;
import io.flutter.embedding.android.KeyboardManager;
import io.flutter.embedding.engine.systemchannels.KeyboardChannel;
import io.flutter.plugin.common.MethodChannel;
import java.util.Map;

/**
 * {@link KeyboardPlugin} is the implementation of all functionalities needed for querying keyboard
 * pressed state.
 *
 * <p>The plugin handles requests for querying keyboard pressed states by the {@link
 * io.flutter.embedding.engine.systemchannels.KeyboardChannel} via returning the {@link
 * io.flutter.embedding.android.KeyEmbedderResponder} pressed keys.
 */
public class KeyboardPlugin implements KeyboardChannel.KeyboardMethodHandler {

  private final KeyboardChannel mKeyboardChannel;
  private final KeyboardManager mKeyboardManager;

  @VisibleForTesting MethodChannel.Result pendingResult;

  public KeyboardPlugin(
      @NonNull KeyboardManager keyboardManager, @NonNull KeyboardChannel keyboardChannel) {
    mKeyboardManager = keyboardManager;
    mKeyboardChannel = keyboardChannel;

    mKeyboardChannel.setKeyboardMethodHandler(this);
  }

  /**
   * Unregisters this {@code KeyboardPlugin} as the {@code KeyboardChannel.KeyboardMethodHandler},
   * for the {@link io.flutter.embedding.engine.systemchannels.KeyboardChannel}.
   *
   * <p>Do not invoke any methods on a {@code KeyboardPlugin} after invoking this method.
   */
  public void destroy() {
    mKeyboardChannel.setKeyboardMethodHandler(null);
  }

  /**
   * Returns the keyboard pressed state.
   *
   * @return A map whose keys are physical keyboard key IDs and values are the corresponding logical
   *     keyboard key IDs.
   */
  @Override
  public Map<Long, Long> getKeyboardState() {
    return mKeyboardManager.getPressedState();
  }
}
