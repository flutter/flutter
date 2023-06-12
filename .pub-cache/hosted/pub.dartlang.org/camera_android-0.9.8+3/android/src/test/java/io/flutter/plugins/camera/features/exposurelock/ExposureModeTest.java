// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.camera.features.exposurelock;

import static org.junit.Assert.assertEquals;

import org.junit.Test;

public class ExposureModeTest {

  @Test
  public void getValueForString_returnsCorrectValues() {
    assertEquals(
        "Returns ExposureMode.auto for 'auto'",
        ExposureMode.getValueForString("auto"),
        ExposureMode.auto);
    assertEquals(
        "Returns ExposureMode.locked for 'locked'",
        ExposureMode.getValueForString("locked"),
        ExposureMode.locked);
  }

  @Test
  public void getValueForString_returnsNullForNonexistantValue() {
    assertEquals(
        "Returns null for 'nonexistant'", ExposureMode.getValueForString("nonexistant"), null);
  }

  @Test
  public void toString_returnsCorrectValue() {
    assertEquals("Returns 'auto' for ExposureMode.auto", ExposureMode.auto.toString(), "auto");
    assertEquals(
        "Returns 'locked' for ExposureMode.locked", ExposureMode.locked.toString(), "locked");
  }
}
