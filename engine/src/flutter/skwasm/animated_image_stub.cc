// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <emscripten/console.h>

#include "flutter/skwasm/export.h"
#include "flutter/skwasm/skwasm_support.h"
#include "third_party/skia/include/core/SkData.h"

namespace {
// Callers are expected to check `skwasm_supportsAnimatedImages` and route to
// the browser's decoder instead of calling into these stubs.
void WarnUnsupported() {
  emscripten_console_warn(
      "Animated image decoding is not supported in this skwasm build.");
}
}  // namespace

SKWASM_EXPORT bool skwasm_supportsAnimatedImages() {
  return false;
}

SKWASM_EXPORT void* animatedImage_create(SkData* data,
                                         int target_width,
                                         int target_height) {
  WarnUnsupported();
  return nullptr;
}

SKWASM_EXPORT void animatedImage_dispose(void* image) {
  WarnUnsupported();
}

SKWASM_EXPORT int animatedImage_getFrameCount(void* image) {
  WarnUnsupported();
  return 0;
}

SKWASM_EXPORT int animatedImage_getRepetitionCount(void* image) {
  WarnUnsupported();
  return 0;
}

SKWASM_EXPORT int animatedImage_getCurrentFrameDurationMilliseconds(
    void* image) {
  WarnUnsupported();
  return 0;
}

SKWASM_EXPORT void animatedImage_decodeNextFrame(void* image) {
  WarnUnsupported();
}

SKWASM_EXPORT void* animatedImage_getCurrentFrame(void* image) {
  WarnUnsupported();
  return nullptr;
}
