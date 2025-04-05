// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "export.h"
#include "skwasm_support.h"

SKWASM_EXPORT void* animatedImage_create(SkData* data,
                                         int targetWidth,
                                         int targetHeight) {
  return nullptr;
}

SKWASM_EXPORT void animatedImage_dispose(void* image) {}

SKWASM_EXPORT int animatedImage_getFrameCount(void* image) {
  return 0;
}

SKWASM_EXPORT int animatedImage_getRepetitionCount(void* image) {
  return 0;
}

SKWASM_EXPORT int animatedImage_getCurrentFrameDuration(void* image) {
  return 0;
}

SKWASM_EXPORT void animatedImage_decodeNextFrame(void* image) {}

SKWASM_EXPORT void* animatedImage_getCurrentFrame(void* image) {
  return nullptr;
}
