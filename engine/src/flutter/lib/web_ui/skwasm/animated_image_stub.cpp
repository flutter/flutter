// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "export.h"
#include "skwasm_support.h"

SKWASM_EXPORT void* animatedImage_create(SkData* data,
                                         int targetWidth,
                                         int targetHeight) {
  emscripten_console_warn(
      "Animated image not implemented in non-heavy skwasm build.");
  return nullptr;
}

SKWASM_EXPORT void animatedImage_dispose(void* image) {
  emscripten_console_warn(
      "Animated image not implemented in non-heavy skwasm build.");
}

SKWASM_EXPORT int animatedImage_getFrameCount(void* image) {
  emscripten_console_warn(
      "Animated image not implemented in non-heavy skwasm build.");
  return 0;
}

SKWASM_EXPORT int animatedImage_getRepetitionCount(void* image) {
  emscripten_console_warn(
      "Animated image not implemented in non-heavy skwasm build.");
  return 0;
}

SKWASM_EXPORT int animatedImage_getCurrentFrameDurationMilliseconds(
    void* image) {
  emscripten_console_warn(
      "Animated image not implemented in non-heavy skwasm build.");
  return 0;
}

SKWASM_EXPORT void animatedImage_decodeNextFrame(void* image) {
  emscripten_console_warn(
      "Animated image not implemented in non-heavy skwasm build.");
}

SKWASM_EXPORT void* animatedImage_getCurrentFrame(void* image) {
  emscripten_console_warn(
      "Animated image not implemented in non-heavy skwasm build.");
  return nullptr;
}
