// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/skwasm/images.h"

#include <GLES2/gl2.h>
#include <GLES2/gl2ext.h>
#include <emscripten/html5_webgl.h>

#include "flutter/display_list/geometry/dl_geometry_conversions.h"
#include "flutter/display_list/skia/dl_sk_conversions.h"
#include "flutter/display_list/skia/dl_sk_dispatcher.h"
#include "third_party/skia/include/core/SkColorSpace.h"
#include "third_party/skia/include/core/SkData.h"
#include "third_party/skia/include/core/SkImage.h"
#include "third_party/skia/include/core/SkImageInfo.h"
#include "third_party/skia/include/core/SkPicture.h"
#include "third_party/skia/include/core/SkPictureRecorder.h"
#include "third_party/skia/include/gpu/GpuTypes.h"
#include "third_party/skia/include/gpu/ganesh/GrBackendSurface.h"
#include "third_party/skia/include/gpu/ganesh/GrDirectContext.h"
#include "third_party/skia/include/gpu/ganesh/GrExternalTextureGenerator.h"
#include "third_party/skia/include/gpu/ganesh/SkImageGanesh.h"
#include "third_party/skia/include/gpu/ganesh/SkSurfaceGanesh.h"
#include "third_party/skia/include/gpu/ganesh/gl/GrGLBackendSurface.h"
#include "third_party/skia/include/gpu/ganesh/gl/GrGLInterface.h"
#include "third_party/skia/include/gpu/ganesh/gl/GrGLTypes.h"

namespace {

SkColorType ColorTypeForPixelFormat(Skwasm::PixelFormat format) {
  switch (format) {
    case Skwasm::PixelFormat::rgba8888:
      return SkColorType::kRGBA_8888_SkColorType;
    case Skwasm::PixelFormat::bgra8888:
      return SkColorType::kBGRA_8888_SkColorType;
    case Skwasm::PixelFormat::rgbaFloat32:
      return SkColorType::kRGBA_F32_SkColorType;
  }
}

SkAlphaType AlphaTypeForPixelFormat(Skwasm::PixelFormat format) {
  switch (format) {
    case Skwasm::PixelFormat::rgba8888:
    case Skwasm::PixelFormat::bgra8888:
      return SkAlphaType::kPremul_SkAlphaType;
    case Skwasm::PixelFormat::rgbaFloat32:
      return SkAlphaType::kUnpremul_SkAlphaType;
  }
}

class ExternalWebGLTexture : public GrExternalTexture {
 public:
  ExternalWebGLTexture(GrBackendTexture backend_texture,
                       GLuint texture_id,
                       EMSCRIPTEN_WEBGL_CONTEXT_HANDLE context)
      : backend_texture_(backend_texture),
        texture_id_(texture_id),
        web_gl_context_(context) {}

  GrBackendTexture getBackendTexture() override { return backend_texture_; }

  void dispose() override {
    Skwasm::makeCurrent(web_gl_context_);
    glDeleteTextures(1, &texture_id_);
  }

 private:
  GrBackendTexture backend_texture_;
  GLuint texture_id_;
  EMSCRIPTEN_WEBGL_CONTEXT_HANDLE web_gl_context_;
};

class TextureSourceImageGenerator : public GrExternalTextureGenerator {
 public:
  TextureSourceImageGenerator(SkImageInfo ii,
                              Skwasm::SkwasmObject texture_source,
                              Skwasm::Surface* surface)
      : GrExternalTextureGenerator(ii),
        texture_source_wrapper_(
            surface->CreateTextureSourceWrapper(texture_source)) {}

  std::unique_ptr<GrExternalTexture> generateExternalTexture(
      GrRecordingContext* context,
      skgpu::Mipmapped mipmapped) override {
    GrGLTextureInfo gl_info;
    gl_info.fID = skwasm_createGlTextureFromTextureSource(
        texture_source_wrapper_->GetTextureSource(), fInfo.width(),
        fInfo.height());
    gl_info.fFormat = GL_RGBA8_OES;
    gl_info.fTarget = GL_TEXTURE_2D;

    auto backend_texture = GrBackendTextures::MakeGL(
        fInfo.width(), fInfo.height(), skgpu::Mipmapped::kNo, gl_info);

    // In order to bind the image source to the texture, makeTexture has changed
    // which texture is "in focus" for the WebGL context.
    GrAsDirectContext(context)->resetContext(kTextureBinding_GrGLBackendState);
    return std::make_unique<ExternalWebGLTexture>(
        backend_texture, gl_info.fID, emscripten_webgl_get_current_context());
  }

 private:
  std::unique_ptr<Skwasm::TextureSourceWrapper> texture_source_wrapper_;
};

}  // namespace

namespace Skwasm {

sk_sp<flutter::DlImage> MakeImageFromPicture(flutter::DisplayList* display_list,
                                             int32_t width,
                                             int32_t height) {
  SkPictureRecorder recorder;
  SkCanvas* canvas =
      recorder.beginRecording(flutter::ToSkRect(display_list->GetBounds()));
  flutter::DlSkCanvasDispatcher dispatcher(canvas);
  dispatcher.drawDisplayList(sk_ref_sp(display_list), 1.0f);

  return flutter::DlImage::Make(SkImages::DeferredFromPicture(
      recorder.finishRecordingAsPicture(), {width, height}, nullptr, nullptr,
      SkImages::BitDepth::kU8, SkColorSpace::MakeSRGB()));
}

sk_sp<flutter::DlImage> MakeImageFromTexture(SkwasmObject texture_source,
                                             int width,
                                             int height,
                                             Skwasm::Surface* surface) {
  return flutter::DlImage::Make(SkImages::DeferredFromTextureGenerator(
      std::unique_ptr<TextureSourceImageGenerator>(
          new TextureSourceImageGenerator(
              SkImageInfo::Make(width, height,
                                SkColorType::kRGBA_8888_SkColorType,
                                SkAlphaType::kPremul_SkAlphaType),
              texture_source, surface))));
}

sk_sp<flutter::DlImage> MakeImageFromPixels(SkData* data,
                                            int width,
                                            int height,
                                            Skwasm::PixelFormat pixel_format,
                                            size_t row_byte_count) {
  return flutter::DlImage::Make(SkImages::RasterFromData(
      SkImageInfo::Make(width, height, ColorTypeForPixelFormat(pixel_format),
                        AlphaTypeForPixelFormat(pixel_format),
                        SkColorSpace::MakeSRGB()),
      sk_ref_sp(data), row_byte_count));
}
}  // namespace Skwasm
