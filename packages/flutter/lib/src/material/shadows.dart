// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show Color, Offset;

import 'package:flutter/painting.dart';

// Based on http://material.google.com/what-is-material/elevation-shadows.html
// Currently, only the elevation values that are bound to one or more widgets are
// defined here.

/// Map of elevation offsets used by material design to [BoxShadow] definitions.
///
/// The following elevations have defined shadows: 1, 2, 3, 4, 6, 8, 9, 12, 16, 24
///
/// Each entry has three shadows which must be combined to obtain the defined
/// effect for that elevation.
///
/// See also:
///
///  * [Material]
///  * <https://material.google.com/what-is-material/elevation-shadows.html>
const Map<int, List<BoxShadow>> kElevationToShadow = _elevationToShadow; // to hide the literal from the docs

const Color _kKeyUmbraOpacity = Color(0x33000000); // alpha = 0.2
const Color _kKeyPenumbraOpacity = Color(0x24000000); // alpha = 0.14
const Color _kAmbientShadowOpacity = Color(0x1F000000); // alpha = 0.12
const Map<int, List<BoxShadow>> _elevationToShadow = <int, List<BoxShadow>>{
  1: <BoxShadow>[
    BoxShadow(offset: Offset(0.0, 2.0), blurRadius: 1.0, spreadRadius: -1.0, color: _kKeyUmbraOpacity),
    BoxShadow(offset: Offset(0.0, 1.0), blurRadius: 1.0, spreadRadius: 0.0, color: _kKeyPenumbraOpacity),
    BoxShadow(offset: Offset(0.0, 1.0), blurRadius: 3.0, spreadRadius: 0.0, color: _kAmbientShadowOpacity),
  ],

  2: <BoxShadow>[
    BoxShadow(offset: Offset(0.0, 3.0), blurRadius: 1.0, spreadRadius: -2.0, color: _kKeyUmbraOpacity),
    BoxShadow(offset: Offset(0.0, 2.0), blurRadius: 2.0, spreadRadius: 0.0, color: _kKeyPenumbraOpacity),
    BoxShadow(offset: Offset(0.0, 1.0), blurRadius: 5.0, spreadRadius: 0.0, color: _kAmbientShadowOpacity),
  ],

  3: <BoxShadow>[
    BoxShadow(offset: Offset(0.0, 3.0), blurRadius: 3.0, spreadRadius: -2.0, color: _kKeyUmbraOpacity),
    BoxShadow(offset: Offset(0.0, 3.0), blurRadius: 4.0, spreadRadius: 0.0, color: _kKeyPenumbraOpacity),
    BoxShadow(offset: Offset(0.0, 1.0), blurRadius: 8.0, spreadRadius: 0.0, color: _kAmbientShadowOpacity),
  ],

  4: <BoxShadow>[
    BoxShadow(offset: Offset(0.0, 2.0), blurRadius: 4.0, spreadRadius: -1.0, color: _kKeyUmbraOpacity),
    BoxShadow(offset: Offset(0.0, 4.0), blurRadius: 5.0, spreadRadius: 0.0, color: _kKeyPenumbraOpacity),
    BoxShadow(offset: Offset(0.0, 1.0), blurRadius: 10.0, spreadRadius: 0.0, color: _kAmbientShadowOpacity),
  ],

  6: <BoxShadow>[
    BoxShadow(offset: Offset(0.0, 3.0), blurRadius: 5.0, spreadRadius: -1.0, color: _kKeyUmbraOpacity),
    BoxShadow(offset: Offset(0.0, 6.0), blurRadius: 10.0, spreadRadius: 0.0, color: _kKeyPenumbraOpacity),
    BoxShadow(offset: Offset(0.0, 1.0), blurRadius: 18.0, spreadRadius: 0.0, color: _kAmbientShadowOpacity),
  ],

  8: <BoxShadow>[
    BoxShadow(offset: Offset(0.0, 5.0), blurRadius: 5.0, spreadRadius: -3.0, color: _kKeyUmbraOpacity),
    BoxShadow(offset: Offset(0.0, 8.0), blurRadius: 10.0, spreadRadius: 1.0, color: _kKeyPenumbraOpacity),
    BoxShadow(offset: Offset(0.0, 3.0), blurRadius: 14.0, spreadRadius: 2.0, color: _kAmbientShadowOpacity),
  ],

  9: <BoxShadow>[
    BoxShadow(offset: Offset(0.0, 5.0), blurRadius: 6.0, spreadRadius: -3.0, color: _kKeyUmbraOpacity),
    BoxShadow(offset: Offset(0.0, 9.0), blurRadius: 12.0, spreadRadius: 1.0, color: _kKeyPenumbraOpacity),
    BoxShadow(offset: Offset(0.0, 3.0), blurRadius: 16.0, spreadRadius: 2.0, color: _kAmbientShadowOpacity),
  ],

  12: <BoxShadow>[
    BoxShadow(offset: Offset(0.0, 7.0), blurRadius: 8.0, spreadRadius: -4.0, color: _kKeyUmbraOpacity),
    BoxShadow(offset: Offset(0.0, 12.0), blurRadius: 17.0, spreadRadius: 2.0, color: _kKeyPenumbraOpacity),
    BoxShadow(offset: Offset(0.0, 5.0), blurRadius: 22.0, spreadRadius: 4.0, color: _kAmbientShadowOpacity),
  ],

  16: <BoxShadow>[
    BoxShadow(offset: Offset(0.0, 8.0), blurRadius: 10.0, spreadRadius: -5.0, color: _kKeyUmbraOpacity),
    BoxShadow(offset: Offset(0.0, 16.0), blurRadius: 24.0, spreadRadius: 2.0, color: _kKeyPenumbraOpacity),
    BoxShadow(offset: Offset(0.0, 6.0), blurRadius: 30.0, spreadRadius: 5.0, color: _kAmbientShadowOpacity),
  ],

  24: <BoxShadow>[
    BoxShadow(offset: Offset(0.0, 11.0), blurRadius: 15.0, spreadRadius: -7.0, color: _kKeyUmbraOpacity),
    BoxShadow(offset: Offset(0.0, 24.0), blurRadius: 38.0, spreadRadius: 3.0, color: _kKeyPenumbraOpacity),
    BoxShadow(offset: Offset(0.0, 9.0), blurRadius: 46.0, spreadRadius: 8.0, color: _kAmbientShadowOpacity),
  ],
};
