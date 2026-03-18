// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#define GL_GLEXT_PROTOTYPES

#include "flutter/skwasm/images.h"
#include "flutter/skwasm/skwasm_support.h"

#include "flutter/display_list/display_list.h"
#include "flutter/display_list/image/dl_image.h"
#include "third_party/skia/include/core/SkData.h"

#include "impeller/core/texture_descriptor.h"
#include "impeller/display_list/aiks_context.h"
#include "impeller/display_list/dl_dispatcher.h"
#include "impeller/renderer/backend/gles/context_gles.h"
#include "impeller/renderer/backend/gles/texture_gles.h"

extern "C" {
void skwasm_dispatchDisposeDlImage(unsigned long thread_id, void* pointer);
void skwasm_disposeDlImageOnWorker(void* dl_image_ptr);
}

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
  skwasm_dispatchDisposeDlImage(0, nullptr);
  skwasm_disposeDlImageOnWorker(nullptr);
}

namespace Skwasm {

class DlWimpImageBase : public flutter::DlImage {
 public:
  DlWimpImageBase(int width, int height) : width_(width), height_(height) {}

  sk_sp<SkImage> skia_image() const override { return nullptr; }

  std::shared_ptr<impeller::Texture> impeller_texture() const override {
    return nullptr;
  }

  bool isOpaque() const override { return false; }
  bool isTextureBacked() const override { return false; }
  bool isUIThreadSafe() const override { return true; }

  virtual ~DlWimpImageBase();

  flutter::DlISize GetSize() const override {
    return flutter::DlISize::MakeWH(width_, height_);
  }

  size_t GetApproximateByteSize() const override {
    return width_ * height_ * 4;
  }

 protected:
  int width_;
  int height_;
};

DlWimpImageBase::~DlWimpImageBase() {
  skwasm_dispatchDisposeDlImage(GetRasterThread(), this);
}

class DlWimpImageFromTexture : public DlWimpImageBase {
 public:
  DlWimpImageFromTexture(int width,
                         int height,
                         SkwasmObject texture_source,
                         Skwasm::Surface* surface)
      : DlWimpImageBase(width, height),
        texture_source_wrapper_(
            surface->CreateTextureSourceWrapper(texture_source)) {}

  std::shared_ptr<impeller::Texture> GetImpellerTexture(
      const std::shared_ptr<impeller::Context>& context) const override {
    auto* gles_context = impeller::ContextGLES::Cast(context.get());
    GLuint gl_texture_id = skwasm_createGlTextureFromTextureSource(
        texture_source_wrapper_->GetTextureSource(), width_, height_);

    impeller::TextureDescriptor desc;
    desc.size = impeller::ISize(width_, height_);
    desc.format = impeller::PixelFormat::kR8G8B8A8UNormInt;
    desc.mip_count = 1;
    desc.type = impeller::TextureType::kTexture2D;
    desc.usage = static_cast<impeller::TextureUsageMask>(
        impeller::TextureUsage::kShaderRead);

    impeller::HandleGLES external_handle =
        gles_context->GetReactor()->CreateHandle(impeller::HandleType::kTexture,
                                                 gl_texture_id);

    auto texture = impeller::TextureGLES::WrapTexture(
        gles_context->GetReactor(), desc, std::move(external_handle));
    if (texture) {
      texture->SetCoordinateSystem(
          impeller::TextureCoordinateSystem::kUploadFromHost);
    }
    return texture;
  }

 private:
  std::unique_ptr<Skwasm::TextureSourceWrapper> texture_source_wrapper_;
};

class DlWimpImageFromPixels : public DlWimpImageBase {
 public:
  DlWimpImageFromPixels(int width,
                        int height,
                        sk_sp<SkData> data,
                        Skwasm::PixelFormat format,
                        size_t row_byte_count)
      : DlWimpImageBase(width, height),
        data_(std::move(data)),
        format_(format),
        row_byte_count_(row_byte_count) {}

  std::shared_ptr<impeller::Texture> GetImpellerTexture(
      const std::shared_ptr<impeller::Context>& context) const override {
    impeller::TextureDescriptor desc;
    desc.size = impeller::ISize(width_, height_);

    if (format_ == Skwasm::PixelFormat::bgra8888) {
      desc.format = impeller::PixelFormat::kB8G8R8A8UNormInt;
    } else if (format_ == Skwasm::PixelFormat::rgba8888) {
      desc.format = impeller::PixelFormat::kR8G8B8A8UNormInt;
    } else {
      desc.format = impeller::PixelFormat::kR8G8B8A8UNormInt;  // fallback
    }

    desc.mip_count = 1;
    desc.type = impeller::TextureType::kTexture2D;
    desc.usage = static_cast<impeller::TextureUsageMask>(
        impeller::TextureUsage::kShaderRead);

    auto texture = context->GetResourceAllocator()->CreateTexture(desc);
    if (!texture) {
      return nullptr;
    }

    if (!texture->SetContents(static_cast<const uint8_t*>(data_->bytes()),
                              data_->size(), 0)) {
      return nullptr;
    }
    return texture;
  }

 private:
  sk_sp<SkData> data_;
  Skwasm::PixelFormat format_;
  size_t row_byte_count_;
};

class DlWimpImageFromPicture : public DlWimpImageBase {
 public:
  DlWimpImageFromPicture(int width,
                         int height,
                         sk_sp<flutter::DisplayList> display_list)
      : DlWimpImageBase(width, height),
        display_list_(std::move(display_list)) {}

  std::shared_ptr<impeller::Texture> GetImpellerTexture(
      const std::shared_ptr<impeller::Context>& context) const override {
    impeller::AiksContext aiks_context(context, nullptr);
    return impeller::DisplayListToTexture(
        display_list_, impeller::ISize(width_, height_), aiks_context);
  }

 private:
  sk_sp<flutter::DisplayList> display_list_;
};

sk_sp<flutter::DlImage> MakeImageFromPicture(flutter::DisplayList* display_list,
                                             int32_t width,
                                             int32_t height) {
  return sk_make_sp<DlWimpImageFromPicture>(width, height,
                                            sk_ref_sp(display_list));
}

sk_sp<flutter::DlImage> MakeImageFromTexture(SkwasmObject texture_source,
                                             int width,
                                             int height,
                                             Skwasm::Surface* surface) {
  return sk_sp<flutter::DlImage>(
      new DlWimpImageFromTexture(width, height, texture_source, surface));
}

sk_sp<flutter::DlImage> MakeImageFromPixels(SkData* data,
                                            int width,
                                            int height,
                                            Skwasm::PixelFormat pixel_format,
                                            size_t row_byte_count) {
  return sk_make_sp<DlWimpImageFromPixels>(width, height, sk_ref_sp(data),
                                           pixel_format, row_byte_count);
}
}  // namespace Skwasm
