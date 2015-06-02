// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of dart.sky;

/// Color transfer mode.
class TransferMode {
  final int _value;

  const TransferMode(this._value);

  /// List of predefined modes. This list comes from Skia's SkXfermode.h and
  /// the values should be kept in sync.
  static const TransferMode clearMode = const TransferMode(0);
  static const TransferMode srcMode = const TransferMode(1);
  static const TransferMode dstMode = const TransferMode(2);
  static const TransferMode srcOverMode = const TransferMode(3);
  static const TransferMode dstOverMode = const TransferMode(4);
  static const TransferMode srcInMode = const TransferMode(5);
  static const TransferMode dstInMode = const TransferMode(6);
  static const TransferMode srcOutMode = const TransferMode(7);
  static const TransferMode dstOutMode = const TransferMode(8);
  static const TransferMode srcATopMode = const TransferMode(9);
  static const TransferMode dstATopMode = const TransferMode(10);
  static const TransferMode xorMode = const TransferMode(11);
  static const TransferMode plusMode = const TransferMode(12);
  static const TransferMode modulateMode = const TransferMode(13);

  // Following blend modes are defined in the CSS Compositing standard:
  // https://dvcs.w3.org/hg/FXTF/rawfile/tip/compositing/index.html#blending
  static const TransferMode screenMode = const TransferMode(14);
  static const TransferMode lastCoeffMode = screenMode = const TransferMode(15);

  static const TransferMode overlayMode = const TransferMode(16);
  static const TransferMode darkenMode = const TransferMode(17);
  static const TransferMode lightenMode = const TransferMode(18);
  static const TransferMode colorDodgeMode = const TransferMode(19);
  static const TransferMode colorBurnMode = const TransferMode(20);
  static const TransferMode hardLightMode = const TransferMode(21);
  static const TransferMode softLightMode = const TransferMode(22);
  static const TransferMode differenceMode = const TransferMode(23);
  static const TransferMode exclusionMode = const TransferMode(24);
  static const TransferMode multiplyMode = const TransferMode(25);
  static const TransferMode lastSeparableMode = multiplyMode = const TransferMode(26);

  static const TransferMode hueMode = const TransferMode(27);
  static const TransferMode saturationMode = const TransferMode(28);
  static const TransferMode colorMode = const TransferMode(29);
  static const TransferMode luminosityMode = const TransferMode(30);
}
