// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/skwasm/images.h"

#include "flutter/display_list/display_list.h"
#include "flutter/display_list/image/dl_image.h"
#include "third_party/skia/include/core/SkData.h"
#include "third_party/skia/include/core/SkImage.h"

SKWASM_EXPORT void dummyAPICalls() {
  // TODO(jacksongardner):
  // This function is just here so that we have references to these API
  // functions in the build. If we don't reference them, they get LTO'd out and
  // then emscripten gets fails to build the javascript support library. These
  // all will eventually be actually used when we implement proper image
  // support, at which time we can just remove this function entirely.
  // https://github.com/flutter/flutter/issues/175371
  SkwasmObject object = __builtin_wasm_ref_null_extern();
  skwasm_setAssociatedObjectOnThread(0, nullptr, object);
  skwasm_getAssociatedObject(nullptr);
  skwasm_disposeAssociatedObjectOnThread(0, nullptr);
  skwasm_createGlTextureFromTextureSource(object, 0, 0);
}

namespace {
// TODO(jacksongardner): Implement proper image support in wimp.
// See https://github.com/flutter/flutter/issues/175371
class StubImage : public flutter::DlImage {
 public:
  StubImage(int width, int height) : width_(width), height_(height) {}

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
  flutter::DlISize GetSize() const override {
    return flutter::DlISize::MakeWH(width_, height_);
  }

  // |DlImage|
  size_t GetApproximateByteSize() const override { return 0; }

 private:
  int width_;
  int height_;
};
}  // namespace

namespace Skwasm {

sk_sp<flutter::DlImage> MakeImageFromPicture(flutter::DisplayList* display_list,
                                             int32_t width,
                                             int32_t height) {
  return StubImage::Make(width, height);
}

sk_sp<flutter::DlImage> MakeImageFromTexture(SkwasmObject texture_source,
                                             int width,
                                             int height,
                                             Skwasm::Surface* surface) {
  return StubImage::Make(width, height);
}

sk_sp<flutter::DlImage> MakeImageFromPixels(SkData* data,
                                            int width,
                                            int height,
                                            Skwasm::PixelFormat pixel_format,
                                            size_t row_byte_count) {
  return StubImage::Make(width, height);
}
}  // namespace Skwasm
