// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "images.h"

using namespace flutter;
using namespace Skwasm;

SKWASM_EXPORT void dummyAPICalls() {
  // TODO(jacksongardner):
  // This function is just here so that we have references to these API
  // functions in the build. If we don't reference them, they get LTO'd out and
  // then emscripten gets fails to build the javascript support library. These
  // all will eventually be actually used when we implement proper image
  // support, at which time we can just remove this function entirely.
  // https://github.com/flutter/flutter/issues/175371
  auto object = __builtin_wasm_ref_null_extern();
  skwasm_setAssociatedObjectOnThread(0, nullptr, object);
  skwasm_getAssociatedObject(nullptr);
  skwasm_disposeAssociatedObjectOnThread(0, nullptr);
  skwasm_createGlTextureFromTextureSource(object, 0, 0);
}

namespace {
// TODO(jacksongardner): Implement proper image support in wimp.
// See https://github.com/flutter/flutter/issues/175371
class StubImage : public DlImage {
 public:
  StubImage(int width, int height) : _width(width), _height(height) {}

  static sk_sp<StubImage> Make(int width, int height) {
    return sk_make_sp<StubImage>(width, height);
  }

  // |DlImage|
  sk_sp<SkImage> skia_image() const override { return nullptr; }

  // |DlImage|
  std::shared_ptr<impeller::Texture> impeller_texture() const override {
    return nullptr;
  }

  // |DlImage|
  bool isOpaque() const override { return false; }

  // |DlImage|
  bool isTextureBacked() const override { return false; }

  // |DlImage|
  bool isUIThreadSafe() const override { return true; }

  // |DlImage|
  DlISize GetSize() const override { return DlISize::MakeWH(_width, _height); }

  // |DlImage|
  size_t GetApproximateByteSize() const override { return 0; }

 private:
  int _width;
  int _height;
};
}  // namespace

namespace Skwasm {

sk_sp<DlImage> MakeImageFromPicture(flutter::DisplayList* displayList,
                                    int32_t width,
                                    int32_t height) {
  return StubImage::Make(width, height);
}

sk_sp<DlImage> MakeImageFromTexture(SkwasmObject textureSource,
                                    int width,
                                    int height,
                                    Skwasm::Surface* surface) {
  return StubImage::Make(width, height);
}

sk_sp<DlImage> MakeImageFromPixels(SkData* data,
                                   int width,
                                   int height,
                                   PixelFormat pixelFormat,
                                   size_t rowByteCount) {
  return StubImage::Make(width, height);
}
}  // namespace Skwasm
