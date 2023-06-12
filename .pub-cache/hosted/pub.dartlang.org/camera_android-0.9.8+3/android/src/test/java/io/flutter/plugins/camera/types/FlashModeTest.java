// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.camera.types;

import static org.junit.Assert.assertEquals;

import org.junit.Test;

public class FlashModeTest {

  @Test
  public void getValueForString_returnsCorrectValues() {
    assertEquals(
        "Returns FlashMode.off for 'off'", FlashMode.getValueForString("off"), FlashMode.off);
    assertEquals(
        "Returns FlashMode.auto for 'auto'", FlashMode.getValueForString("auto"), FlashMode.auto);
    assertEquals(
        "Returns FlashMode.always for 'always'",
        FlashMode.getValueForString("always"),
        FlashMode.always);
    assertEquals(
        "Returns FlashMode.torch for 'torch'",
        FlashMode.getValueForString("torch"),
        FlashMode.torch);
  }

  @Test
  public void getValueForString_returnsNullForNonexistantValue() {
    assertEquals(
        "Returns null for 'nonexistant'", FlashMode.getValueForString("nonexistant"), null);
  }

  @Test
  public void toString_returnsCorrectValue() {
    assertEquals("Returns 'off' for FlashMode.off", FlashMode.off.toString(), "off");
    assertEquals("Returns 'auto' for FlashMode.auto", FlashMode.auto.toString(), "auto");
    assertEquals("Returns 'always' for FlashMode.always", FlashMode.always.toString(), "always");
    assertEquals("Returns 'torch' for FlashMode.torch", FlashMode.torch.toString(), "torch");
  }
}
