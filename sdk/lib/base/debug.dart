// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

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
