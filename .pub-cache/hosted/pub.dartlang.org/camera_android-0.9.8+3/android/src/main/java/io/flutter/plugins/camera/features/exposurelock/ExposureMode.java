// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.camera.features.exposurelock;

// Mirrors exposure_mode.dart
public enum ExposureMode {
  auto("auto"),
  locked("locked");

  private final String strValue;

  ExposureMode(String strValue) {
    this.strValue = strValue;
  }

  /**
   * Tries to convert the supplied string into an {@see ExposureMode} enum value.
   *
   * <p>When the supplied string doesn't match a valid {@see ExposureMode} enum value, null is
   * returned.
   *
   * @param modeStr String value to convert into an {@see ExposureMode} enum value.
   * @return Matching {@see ExposureMode} enum value, or null if no match is found.
   */
  public static ExposureMode getValueForString(String modeStr) {
    for (ExposureMode value : values()) {
      if (value.strValue.equals(modeStr)) {
        return value;
      }
    }
    return null;
  }

  @Override
  public String toString() {
    return strValue;
  }
}
