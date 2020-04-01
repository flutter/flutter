// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/darwin/ios/ios_external_texture_metal.h"

#include "flutter/fml/logging.h"
#include "third_party/skia/include/gpu/GrBackendSurface.h"
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
                                    GrContext* context) {
  const bool needs_updated_texture = (!freeze && texture_frame_available_) || !external_image_;

  if (needs_updated_texture) {
    // If the application told us there was a texture frame available but did not provide one when
    // asked for it, reuse the previous texture but make sure to ask again the next time around.
    if (auto wrapped_texture = WrapExternalPixelBuffer(context)) {
      external_image_ = wrapped_texture;
      texture_frame_available_ = false;
    }
  }

  if (external_image_) {
    canvas.drawImageRect(external_image_,                                      // image
                         external_image_->bounds(),                            // source rect
                         bounds,                                               // destination rect
                         nullptr,                                              // paint
                         SkCanvas::SrcRectConstraint::kFast_SrcRectConstraint  // constraint
    );
  }
}

sk_sp<SkImage> IOSExternalTextureMetal::WrapExternalPixelBuffer(GrContext* context) const {
  auto pixel_buffer = fml::CFRef<CVPixelBufferRef>([external_texture_ copyPixelBuffer]);
  if (!pixel_buffer) {
    return nullptr;
  }

  auto texture_size =
      SkISize::Make(CVPixelBufferGetWidth(pixel_buffer), CVPixelBufferGetHeight(pixel_buffer));

  CVMetalTextureRef metal_texture_raw = NULL;
  auto cv_return =
      CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault,       // allocator
                                                texture_cache_,            // texture cache
                                                pixel_buffer,              // source image
                                                NULL,                      // texture attributes
                                                MTLPixelFormatBGRA8Unorm,  // pixel format
                                                texture_size.width(),      // width
                                                texture_size.height(),     // height
                                                0u,                        // plane index
                                                &metal_texture_raw         // [out] texture
      );

  if (cv_return != kCVReturnSuccess) {
    FML_DLOG(ERROR) << "Could not create Metal texture from pixel buffer: CVReturn " << cv_return;
    return nullptr;
  }

  fml::CFRef<CVMetalTextureRef> metal_texture(metal_texture_raw);

  GrMtlTextureInfo skia_texture_info;
  skia_texture_info.fTexture = sk_cf_obj<const void*>{
      [reinterpret_cast<NSObject*>(CVMetalTextureGetTexture(metal_texture)) retain]};

  GrBackendTexture skia_backend_texture(texture_size.width(),   // width
                                        texture_size.height(),  // height
                                        GrMipMapped ::kNo,      // mip-mapped
                                        skia_texture_info       // texture info
  );

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

  auto image = SkImage::MakeFromTexture(context,                   // context
                                        skia_backend_texture,      // backend texture
                                        kTopLeft_GrSurfaceOrigin,  // origin
                                        kBGRA_8888_SkColorType,    // color type
                                        kPremul_SkAlphaType,       // alpha type
                                        nullptr,                   // color space
                                        release_proc,              // release proc
                                        captures.release()         // release context

  );

  if (!image) {
    FML_DLOG(ERROR) << "Could not wrap Metal texture as a Skia image.";
  }

  return image;
}

void IOSExternalTextureMetal::OnGrContextCreated() {
  // External images in this backend have no thread affinity and are not tied to the context in any
  // way. Instead, they are tied to the Metal device which is associated with the cache already and
  // is consistent throughout the shell run.
}

void IOSExternalTextureMetal::OnGrContextDestroyed() {
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
