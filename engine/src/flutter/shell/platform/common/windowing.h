// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_COMMON_WINDOWING_H_
#define FLUTTER_SHELL_PLATFORM_COMMON_WINDOWING_H_

namespace flutter {

// Types of windows.
// The value must match value from WindowType in the Dart code
// in packages/flutter/lib/src/widgets/window.dart
enum class WindowArchetype {
  // Regular top-level window.
  kRegular,
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_COMMON_WINDOWING_H_
