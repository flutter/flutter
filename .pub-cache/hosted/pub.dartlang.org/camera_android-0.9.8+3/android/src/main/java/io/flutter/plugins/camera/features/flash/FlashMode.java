// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.camera.features.flash;

// Mirrors flash_mode.dart
public enum FlashMode {
  off("off"),
  auto("auto"),
  always("always"),
  torch("torch");

  private final String strValue;

  FlashMode(String strValue) {
    this.strValue = strValue;
  }

  /**
   * Tries to convert the supplied string into a {@see FlashMode} enum value.
   *
   * <p>When the supplied string doesn't match a valid {@see FlashMode} enum value, null is
   * returned.
   *
   * @param modeStr String value to convert into an {@see FlashMode} enum value.
   * @return Matching {@see FlashMode} enum value, or null if no match is found.
   */
  public static FlashMode getValueForString(String modeStr) {
    for (FlashMode value : values()) {
      if (value.strValue.equals(modeStr)) return value;
    }
    return null;
  }

  @Override
  public String toString() {
    return strValue;
  }
}
