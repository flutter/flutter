// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "images.h"

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

#include <GLES2/gl2.h>
#include <GLES2/gl2ext.h>
#include <emscripten/html5_webgl.h>

using namespace flutter;
using namespace SkImages;
using namespace Skwasm;

namespace {

SkColorType colorTypeForPixelFormat(PixelFormat format) {
  switch (format) {
    case PixelFormat::rgba8888:
      return SkColorType::kRGBA_8888_SkColorType;
    case PixelFormat::bgra8888:
      return SkColorType::kBGRA_8888_SkColorType;
    case PixelFormat::rgbaFloat32:
      return SkColorType::kRGBA_F32_SkColorType;
  }
}

SkAlphaType alphaTypeForPixelFormat(PixelFormat format) {
  switch (format) {
    case PixelFormat::rgba8888:
    case PixelFormat::bgra8888:
      return SkAlphaType::kPremul_SkAlphaType;
    case PixelFormat::rgbaFloat32:
      return SkAlphaType::kUnpremul_SkAlphaType;
  }
}

class ExternalWebGLTexture : public GrExternalTexture {
 public:
  ExternalWebGLTexture(GrBackendTexture backendTexture,
                       GLuint textureId,
                       EMSCRIPTEN_WEBGL_CONTEXT_HANDLE context)
      : _backendTexture(backendTexture),
        _textureId(textureId),
        _webGLContext(context) {}

  GrBackendTexture getBackendTexture() override { return _backendTexture; }

  void dispose() override {
    Skwasm::makeCurrent(_webGLContext);
    glDeleteTextures(1, &_textureId);
  }

 private:
  GrBackendTexture _backendTexture;
  GLuint _textureId;
  EMSCRIPTEN_WEBGL_CONTEXT_HANDLE _webGLContext;
};

class TextureSourceImageGenerator : public GrExternalTextureGenerator {
 public:
  TextureSourceImageGenerator(SkImageInfo ii,
                              SkwasmObject textureSource,
                              Skwasm::Surface* surface)
      : GrExternalTextureGenerator(ii),
        _textureSourceWrapper(
            surface->createTextureSourceWrapper(textureSource)) {}

  std::unique_ptr<GrExternalTexture> generateExternalTexture(
      GrRecordingContext* context,
      skgpu::Mipmapped mipmapped) override {
    GrGLTextureInfo glInfo;
    glInfo.fID = skwasm_createGlTextureFromTextureSource(
        _textureSourceWrapper->getTextureSource(), fInfo.width(),
        fInfo.height());
    glInfo.fFormat = GL_RGBA8_OES;
    glInfo.fTarget = GL_TEXTURE_2D;

    auto backendTexture = GrBackendTextures::MakeGL(
        fInfo.width(), fInfo.height(), skgpu::Mipmapped::kNo, glInfo);

    // In order to bind the image source to the texture, makeTexture has changed
    // which texture is "in focus" for the WebGL context.
    GrAsDirectContext(context)->resetContext(kTextureBinding_GrGLBackendState);
    return std::make_unique<ExternalWebGLTexture>(
        backendTexture, glInfo.fID, emscripten_webgl_get_current_context());
  }

 private:
  std::unique_ptr<Skwasm::TextureSourceWrapper> _textureSourceWrapper;
};

}  // namespace

namespace Skwasm {

sk_sp<DlImage> MakeImageFromPicture(flutter::DisplayList* displayList,
                                    int32_t width,
                                    int32_t height) {
  SkPictureRecorder recorder;
  SkCanvas* canvas =
      recorder.beginRecording(ToSkRect(displayList->GetBounds()));
  DlSkCanvasDispatcher dispatcher(canvas);
  dispatcher.drawDisplayList(sk_ref_sp(displayList), 1.0f);

  return DlImage::Make(DeferredFromPicture(
      recorder.finishRecordingAsPicture(), {width, height}, nullptr, nullptr,
      BitDepth::kU8, SkColorSpace::MakeSRGB()));
}

sk_sp<DlImage> MakeImageFromTexture(SkwasmObject textureSource,
                                    int width,
                                    int height,
                                    Skwasm::Surface* surface) {
  return DlImage::Make(SkImages::DeferredFromTextureGenerator(
      std::unique_ptr<TextureSourceImageGenerator>(
          new TextureSourceImageGenerator(
              SkImageInfo::Make(width, height,
                                SkColorType::kRGBA_8888_SkColorType,
                                SkAlphaType::kPremul_SkAlphaType),
              textureSource, surface))));
}

sk_sp<DlImage> MakeImageFromPixels(SkData* data,
                                   int width,
                                   int height,
                                   PixelFormat pixelFormat,
                                   size_t rowByteCount) {
  return DlImage::Make(SkImages::RasterFromData(
      SkImageInfo::Make(width, height, colorTypeForPixelFormat(pixelFormat),
                        alphaTypeForPixelFormat(pixelFormat),
                        SkColorSpace::MakeSRGB()),
      sk_ref_sp(data), rowByteCount));
}
}  // namespace Skwasm
