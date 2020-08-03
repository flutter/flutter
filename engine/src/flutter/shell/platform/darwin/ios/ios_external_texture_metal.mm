// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/darwin/ios/ios_external_texture_metal.h"

#include "flutter/fml/logging.h"
#include "third_party/skia/include/core/SkYUVAIndex.h"
#include "third_party/skia/include/gpu/GrBackendSurface.h"
#include "third_party/skia/include/gpu/GrDirectContext.h"
#include "third_party/skia/include/gpu/mtl/GrMtlTypes.h"

namespace flutter {

IOSExternalTextureMetal::IOSExternalTextureMetal(
    int64_t texture_id,
    fml::CFRef<CVMetalTextureCacheRef> texture_cache,
    fml::scoped_nsobject<NSObject<FlutterTexture>> external_texture)
    : Texture(texture_id),
      texture_cache_(std::move(texture_cache)),
      external_texture_(std::move(external_texture)) {
  FML_DCHECK(texture_cache_);
  FML_DCHECK(external_texture_);
}

IOSExternalTextureMetal::~IOSExternalTextureMetal() = default;

void IOSExternalTextureMetal::Paint(SkCanvas& canvas,
                                    const SkRect& bounds,
                                    bool freeze,
                                    GrDirectContext* context,
                                    SkFilterQuality filter_quality) {
  const bool needs_updated_texture = (!freeze && texture_frame_available_) || !external_image_;

  if (needs_updated_texture) {
    auto pixel_buffer = fml::CFRef<CVPixelBufferRef>([external_texture_ copyPixelBuffer]);
    if (!pixel_buffer) {
      pixel_buffer = std::move(last_pixel_buffer_);
    } else {
      pixel_format_ = CVPixelBufferGetPixelFormatType(pixel_buffer);
    }

    // If the application told us there was a texture frame available but did not provide one when
    // asked for it, reuse the previous texture but make sure to ask again the next time around.
    if (auto wrapped_texture = WrapExternalPixelBuffer(pixel_buffer, context)) {
      external_image_ = wrapped_texture;
      texture_frame_available_ = false;
      last_pixel_buffer_ = std::move(pixel_buffer);
    }
  }

  if (external_image_) {
    SkPaint paint;
    paint.setFilterQuality(filter_quality);
    canvas.drawImageRect(external_image_,                                      // image
                         external_image_->bounds(),                            // source rect
                         bounds,                                               // destination rect
                         &paint,                                               // paint
                         SkCanvas::SrcRectConstraint::kFast_SrcRectConstraint  // constraint
    );
  }
}

sk_sp<SkImage> IOSExternalTextureMetal::WrapExternalPixelBuffer(
    fml::CFRef<CVPixelBufferRef> pixel_buffer,
    GrDirectContext* context) const {
  if (!pixel_buffer) {
    return nullptr;
  }

  sk_sp<SkImage> image = nullptr;
  if (pixel_format_ == kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange ||
      pixel_format_ == kCVPixelFormatType_420YpCbCr8BiPlanarFullRange) {
    image = WrapNV12ExternalPixelBuffer(pixel_buffer, context);
  } else {
    image = WrapRGBAExternalPixelBuffer(pixel_buffer, context);
  }

  if (!image) {
    FML_DLOG(ERROR) << "Could not wrap Metal texture as a Skia image.";
  }

  return image;
}

sk_sp<SkImage> IOSExternalTextureMetal::WrapNV12ExternalPixelBuffer(
    fml::CFRef<CVPixelBufferRef> pixel_buffer,
    GrDirectContext* context) const {
  auto texture_size =
      SkISize::Make(CVPixelBufferGetWidth(pixel_buffer), CVPixelBufferGetHeight(pixel_buffer));
  CVMetalTextureRef y_metal_texture_raw = nullptr;
  {
    auto cv_return =
        CVMetalTextureCacheCreateTextureFromImage(/*allocator=*/kCFAllocatorDefault,
                                                  /*textureCache=*/texture_cache_,
                                                  /*sourceImage=*/pixel_buffer,
                                                  /*textureAttributes=*/nullptr,
                                                  /*pixelFormat=*/MTLPixelFormatR8Unorm,
                                                  /*width=*/texture_size.width(),
                                                  /*height=*/texture_size.height(),
                                                  /*planeIndex=*/0u,
                                                  /*texture=*/&y_metal_texture_raw);

    if (cv_return != kCVReturnSuccess) {
      FML_DLOG(ERROR) << "Could not create Metal texture from pixel buffer: CVReturn " << cv_return;
      return nullptr;
    }
  }

  CVMetalTextureRef uv_metal_texture_raw = nullptr;
  {
    auto cv_return =
        CVMetalTextureCacheCreateTextureFromImage(/*allocator=*/kCFAllocatorDefault,
                                                  /*textureCache=*/texture_cache_,
                                                  /*sourceImage=*/pixel_buffer,
                                                  /*textureAttributes=*/nullptr,
                                                  /*pixelFormat=*/MTLPixelFormatRG8Unorm,
                                                  /*width=*/texture_size.width() / 2,
                                                  /*height=*/texture_size.height() / 2,
                                                  /*planeIndex=*/1u,
                                                  /*texture=*/&uv_metal_texture_raw);

    if (cv_return != kCVReturnSuccess) {
      FML_DLOG(ERROR) << "Could not create Metal texture from pixel buffer: CVReturn " << cv_return;
      return nullptr;
    }
  }

  fml::CFRef<CVMetalTextureRef> y_metal_texture(y_metal_texture_raw);

  GrMtlTextureInfo y_skia_texture_info;
  y_skia_texture_info.fTexture = sk_cf_obj<const void*>{
      [reinterpret_cast<NSObject*>(CVMetalTextureGetTexture(y_metal_texture)) retain]};

  GrBackendTexture y_skia_backend_texture(/*width=*/texture_size.width(),
                                          /*height=*/texture_size.height(),
                                          /*mipMapped=*/GrMipMapped ::kNo,
                                          /*textureInfo=*/y_skia_texture_info);

  fml::CFRef<CVMetalTextureRef> uv_metal_texture(uv_metal_texture_raw);

  GrMtlTextureInfo uv_skia_texture_info;
  uv_skia_texture_info.fTexture = sk_cf_obj<const void*>{
      [reinterpret_cast<NSObject*>(CVMetalTextureGetTexture(uv_metal_texture)) retain]};

  GrBackendTexture uv_skia_backend_texture(/*width=*/texture_size.width(),
                                           /*height=*/texture_size.height(),
                                           /*mipMapped=*/GrMipMapped ::kNo,
                                           /*textureInfo=*/uv_skia_texture_info);
  GrBackendTexture nv12TextureHandles[] = {y_skia_backend_texture, uv_skia_backend_texture};
  SkYUVAIndex yuvaIndices[4] = {
      SkYUVAIndex{0, SkColorChannel::kR},  // Read Y data from the red channel of the first texture
      SkYUVAIndex{1, SkColorChannel::kR},  // Read U data from the red channel of the second texture
      SkYUVAIndex{1,
                  SkColorChannel::kG},  // Read V data from the green channel of the second texture
      SkYUVAIndex{-1, SkColorChannel::kA}};  //-1 means to omit the alpha data of YUVA

  struct ImageCaptures {
    fml::CFRef<CVPixelBufferRef> buffer;
    fml::CFRef<CVMetalTextureRef> y_texture;
    fml::CFRef<CVMetalTextureRef> uv_texture;
  };

  auto captures = std::make_unique<ImageCaptures>();
  captures->buffer = std::move(pixel_buffer);
  captures->y_texture = std::move(y_metal_texture);
  captures->uv_texture = std::move(uv_metal_texture);

  SkImage::TextureReleaseProc release_proc = [](SkImage::ReleaseContext release_context) {
    auto captures = reinterpret_cast<ImageCaptures*>(release_context);
    delete captures;
  };
  sk_sp<SkImage> image = SkImage::MakeFromYUVATextures(
      context, kRec601_SkYUVColorSpace, nv12TextureHandles, yuvaIndices, texture_size,
      kTopLeft_GrSurfaceOrigin, /*imageColorSpace=*/nullptr, release_proc, captures.release());
  return image;
}

sk_sp<SkImage> IOSExternalTextureMetal::WrapRGBAExternalPixelBuffer(
    fml::CFRef<CVPixelBufferRef> pixel_buffer,
    GrDirectContext* context) const {
  auto texture_size =
      SkISize::Make(CVPixelBufferGetWidth(pixel_buffer), CVPixelBufferGetHeight(pixel_buffer));
  CVMetalTextureRef metal_texture_raw = nullptr;
  auto cv_return =
      CVMetalTextureCacheCreateTextureFromImage(/*allocator=*/kCFAllocatorDefault,
                                                /*textureCache=*/texture_cache_,
                                                /*sourceImage=*/pixel_buffer,
                                                /*textureAttributes=*/nullptr,
                                                /*pixelFormat=*/MTLPixelFormatBGRA8Unorm,
                                                /*width=*/texture_size.width(),
                                                /*height=*/texture_size.height(),
                                                /*planeIndex=*/0u,
                                                /*texture=*/&metal_texture_raw);

  if (cv_return != kCVReturnSuccess) {
    FML_DLOG(ERROR) << "Could not create Metal texture from pixel buffer: CVReturn " << cv_return;
    return nullptr;
  }

  fml::CFRef<CVMetalTextureRef> metal_texture(metal_texture_raw);

  GrMtlTextureInfo skia_texture_info;
  skia_texture_info.fTexture = sk_cf_obj<const void*>{
      [reinterpret_cast<NSObject*>(CVMetalTextureGetTexture(metal_texture)) retain]};

  GrBackendTexture skia_backend_texture(/*width=*/texture_size.width(),
                                        /*height=*/texture_size.height(),
                                        /*mipMapped=*/GrMipMapped ::kNo,
                                        /*textureInfo=*/skia_texture_info);

  struct ImageCaptures {
    fml::CFRef<CVPixelBufferRef> buffer;
    fml::CFRef<CVMetalTextureRef> texture;
  };

  auto captures = std::make_unique<ImageCaptures>();
  captures->buffer = std::move(pixel_buffer);
  captures->texture = std::move(metal_texture);

  SkImage::TextureReleaseProc release_proc = [](SkImage::ReleaseContext release_context) {
    auto captures = reinterpret_cast<ImageCaptures*>(release_context);
    delete captures;
  };

  auto image =
      SkImage::MakeFromTexture(context, skia_backend_texture, kTopLeft_GrSurfaceOrigin,
                               kBGRA_8888_SkColorType, kPremul_SkAlphaType,
                               /*imageColorSpace=*/nullptr, release_proc, captures.release()

      );
  return image;
}

void IOSExternalTextureMetal::OnGrContextCreated() {
  // External images in this backend have no thread affinity and are not tied to the context in any
  // way. Instead, they are tied to the Metal device which is associated with the cache already and
  // is consistent throughout the shell run.
}

void IOSExternalTextureMetal::OnGrContextDestroyed() {
  // The image must be reset because it is tied to the onscreen context. But the pixel buffer that
  // created the image is still around. In case of context reacquisition, that last pixel
  // buffer will be used to materialize the image in case the application fails to provide a new
  // one.
  external_image_.reset();
  CVMetalTextureCacheFlush(texture_cache_,  // cache
                           0                // options (must be zero)
  );
}

void IOSExternalTextureMetal::MarkNewFrameAvailable() {
  texture_frame_available_ = true;
}

void IOSExternalTextureMetal::OnTextureUnregistered() {
  if ([external_texture_ respondsToSelector:@selector(onTextureUnregistered:)]) {
    [external_texture_ onTextureUnregistered:external_texture_];
  }
}

}  // namespace flutter
