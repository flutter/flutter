// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "images.h"

using namespace flutter;

namespace {
// TODO(jacksongardner): Remove this. This just hacks around weird LTO problems
// with emscripten.
void blurp() {
  auto object = __builtin_wasm_ref_null_extern();
  skwasm_setAssociatedObjectOnThread(0, nullptr, object);
  skwasm_getAssociatedObject(nullptr);
  skwasm_disposeAssociatedObjectOnThread(0, nullptr);
  skwasm_createGlTextureFromTextureSource(object, 0, 0);
}
}  // namespace

namespace Skwasm {

sk_sp<DlImage> MakeImageFromPicture(flutter::DisplayList* displayList,
                                    int32_t width,
                                    int32_t height) {
  return nullptr;
}

sk_sp<DlImage> MakeImageFromTexture(SkwasmObject textureSource,
                                    int width,
                                    int height,
                                    Skwasm::Surface* surface) {
  return nullptr;
}

sk_sp<DlImage> MakeImageFromPixels(SkData* data,
                                   int width,
                                   int height,
                                   PixelFormat pixelFormat,
                                   size_t rowByteCount) {
  if (rowByteCount < -1) {
    blurp();
  }
  return nullptr;
}
}  // namespace Skwasm
