// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of dart.sky;

/// List of predefined color transfer modes. This list comes from Skia's
/// SkXfermode.h and the values (order) should be kept in sync.
enum TransferMode {
  clearMode,
  srcMode,
  dstMode,
  srcOverMode,
  dstOverMode,
  srcInMode,
  dstInMode,
  srcOutMode,
  dstOutMode,
  srcATopMode,
  dstATopMode,
  xorMode,
  plusMode,
  modulateMode,

  // Following blend modes are defined in the CSS Compositing standard.
  screenMode,  /// The last coeff mode.

  overlayMode,
  darkenMode,
  lightenMode,
  colorDodgeMode,
  colorBurnMode,
  hardLightMode,
  softLightMode,
  differenceMode,
  exclusionMode,
  multiplyMode,  /// The last separable mode.

  hueMode,
  saturationMode,
  colorMode,
  luminosityMode,
}
