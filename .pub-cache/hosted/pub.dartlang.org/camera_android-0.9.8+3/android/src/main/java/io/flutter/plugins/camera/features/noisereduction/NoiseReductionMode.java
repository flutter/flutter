// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.camera.features.noisereduction;

/** Only supports fast mode for now. */
public enum NoiseReductionMode {
  off("off"),
  fast("fast"),
  highQuality("highQuality"),
  minimal("minimal"),
  zeroShutterLag("zeroShutterLag");

  private final String strValue;

  NoiseReductionMode(String strValue) {
    this.strValue = strValue;
  }

  /**
   * Tries to convert the supplied string into a {@see NoiseReductionMode} enum value.
   *
   * <p>When the supplied string doesn't match a valid {@see NoiseReductionMode} enum value, null is
   * returned.
   *
   * @param modeStr String value to convert into an {@see NoiseReductionMode} enum value.
   * @return Matching {@see NoiseReductionMode} enum value, or null if no match is found.
   */
  public static NoiseReductionMode getValueForString(String modeStr) {
    for (NoiseReductionMode value : values()) {
      if (value.strValue.equals(modeStr)) return value;
    }
    return null;
  }

  @Override
  public String toString() {
    return strValue;
  }
}
