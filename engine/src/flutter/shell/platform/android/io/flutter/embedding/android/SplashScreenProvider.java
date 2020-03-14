// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.embedding.android;

import androidx.annotation.Nullable;

/**
 * Provides a {@link SplashScreen} to display while Flutter initializes and renders its first frame.
 */
public interface SplashScreenProvider {
  /**
   * Provides a {@link SplashScreen} to display while Flutter initializes and renders its first
   * frame.
   */
  @Nullable
  SplashScreen provideSplashScreen();
}
