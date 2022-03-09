// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_CHOREOGRAPHER_H_
#define FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_CHOREOGRAPHER_H_

#include "flutter/fml/macros.h"

#include <cstdint>

namespace flutter {

//------------------------------------------------------------------------------
/// The Android Choreographer is used by `VsyncWaiterAndroid` to await vsync
/// signal. It's only available on API 29+ or API 24+ if the architecture is
/// 64-bit.
///
class AndroidChoreographer {
 public:
  typedef void (*OnFrameCallback)(int64_t frame_time_nanos, void* data);
  static bool ShouldUseNDKChoreographer();
  static void PostFrameCallback(OnFrameCallback callback, void* data);

  FML_DISALLOW_COPY_AND_ASSIGN(AndroidChoreographer);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_CHOREOGRAPHER_H_
