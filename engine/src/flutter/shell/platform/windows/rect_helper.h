// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "Windows.h"

#ifndef FLUTTER_SHELL_PLATFORM_WINDOWS_RECT_HELPER_H_
#define FLUTTER_SHELL_PLATFORM_WINDOWS_RECT_HELPER_H_

namespace flutter {
LONG RectWidth(const RECT& r) {
  return r.right - r.left;
}

LONG RectHeight(const RECT& r) {
  return r.bottom - r.top;
}

bool AreRectsEqual(const RECT& a, const RECT& b) {
  return a.left == b.left && a.top == b.top && a.right == b.right &&
         a.bottom == b.bottom;
}
}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_WINDOWS_RECT_HELPER_H_
