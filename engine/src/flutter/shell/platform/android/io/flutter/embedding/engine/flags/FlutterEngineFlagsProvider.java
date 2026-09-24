// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.embedding.engine.flags;

import android.content.Intent;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import io.flutter.embedding.engine.FlutterEngine;
import java.util.List;

public interface FlutterEngineFlagsProvider {
  /**
   * Get the engine flags set via Intent to pass to a new {@link FlutterEngine}. Implementations
   * should return an empty list in release builds for security purposes.
   *
   * @param intent The Intent that was used to launch the Flutter component.
   * @return The engine flags to pass to a new {@link FlutterEngine}.
   */
  @NonNull
  List<String> getFlags(@Nullable Intent intent);

  /**
   * Get whether software rendering is enabled. Implementations should return false in release
   * builds for security purposes.
   *
   * @param intent The Intent that was used to launch the Flutter component.
   * @return Whether software rendering is enabled.
   */
  boolean isSoftwareRenderingEnabled(@Nullable Intent intent);
}
