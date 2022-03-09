// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/android_choreographer.h"

#include "flutter/fml/native_library.h"

// Only avialalbe on API 24+
typedef void AChoreographer;
// Only available on API 29+ or API 24+ if the architecture is 64-bit.
typedef void (*AChoreographer_frameCallback)(int64_t frameTimeNanos,
                                             void* data);
// Only avialalbe on API 24+
typedef AChoreographer* (*AChoreographer_getInstance_FPN)();
typedef void (*AChoreographer_postFrameCallback_FPN)(
    AChoreographer* choreographer,
    AChoreographer_frameCallback callback,
    void* data);
static AChoreographer_getInstance_FPN AChoreographer_getInstance;
static AChoreographer_postFrameCallback_FPN AChoreographer_postFrameCallback;

namespace flutter {

bool AndroidChoreographer::ShouldUseNDKChoreographer() {
  static std::optional<bool> use_ndk_choreographer;
  if (use_ndk_choreographer) {
    return use_ndk_choreographer.value();
  }
  auto libandroid = fml::NativeLibrary::Create("libandroid.so");
  FML_DCHECK(libandroid);
  auto get_instance_fn =
      libandroid->ResolveFunction<AChoreographer_getInstance_FPN>(
          "AChoreographer_getInstance");
  auto post_frame_callback_fn =
      libandroid->ResolveFunction<AChoreographer_postFrameCallback_FPN>(
          "AChoreographer_postFrameCallback64");
#if FML_ARCH_CPU_64_BITS
  if (!post_frame_callback_fn) {
    post_frame_callback_fn =
        libandroid->ResolveFunction<AChoreographer_postFrameCallback_FPN>(
            "AChoreographer_postFrameCallback");
  }
#endif
  if (get_instance_fn && post_frame_callback_fn) {
    AChoreographer_getInstance = get_instance_fn.value();
    AChoreographer_postFrameCallback = post_frame_callback_fn.value();
    use_ndk_choreographer = true;
  } else {
    use_ndk_choreographer = false;
  }
  return use_ndk_choreographer.value();
}

void AndroidChoreographer::PostFrameCallback(OnFrameCallback callback,
                                             void* data) {
  AChoreographer* choreographer = AChoreographer_getInstance();
  AChoreographer_postFrameCallback(choreographer, callback, data);
}

}  // namespace flutter
