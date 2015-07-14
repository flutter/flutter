// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:sky' as sky;

final bool inDebugBuild = _initInDebugBuild();

bool _initInDebugBuild() {
  bool _inDebug = false;
  bool setAssert() {
    _inDebug = true;
    return true;
  }
  assert(setAssert());
  return _inDebug;
}

bool debugPaintSizeEnabled = false;
const sky.Color debugPaintSizeColor = const sky.Color(0xFF00FFFF);

bool debugPaintBaselinesEnabled = false;
const sky.Color debugPaintAlphabeticBaselineColor = const sky.Color(0xFF00FF00);
const sky.Color debugPaintIdeographicBaselineColor = const sky.Color(0xFFFFD000);

bool debugPaintBoundsEnabled = false;
