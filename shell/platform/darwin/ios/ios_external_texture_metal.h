// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_DARWIN_IOS_IOS_EXTERNAL_TEXTURE_METAL_H_
#define FLUTTER_SHELL_PLATFORM_DARWIN_IOS_IOS_EXTERNAL_TEXTURE_METAL_H_

#include <atomic>

#import <CoreVideo/CoreVideo.h>

#include "flutter/flow/texture.h"
#include "flutter/fml/macros.h"
#include "flutter/fml/platform/darwin/cf_utils.h"
#include "flutter/fml/platform/darwin/scoped_nsobject.h"
#include "flutter/shell/platform/darwin/common/framework/Headers/FlutterTexture.h"
#include "third_party/skia/include/core/SkImage.h"

namespace flutter {

class IOSExternalTextureMetal final : public Texture {
 public:
  IOSExternalTextureMetal(int64_t texture_id,
                          fml::CFRef<CVMetalTextureCacheRef> texture_cache,
                          fml::scoped_nsobject<NSObject<FlutterTexture>> external_texture);

  // |Texture|
  ~IOSExternalTextureMetal();

 private:
  fml::CFRef<CVMetalTextureCacheRef> texture_cache_;
  fml::scoped_nsobject<NSObject<FlutterTexture>> external_texture_;
  std::atomic_bool texture_frame_available_;
  fml::CFRef<CVPixelBufferRef> last_pixel_buffer_;
  sk_sp<SkImage> external_image_;
  OSType pixel_format_ = 0;

  // |Texture|
  void Paint(SkCanvas& canvas,
             const SkRect& bounds,
             bool freeze,
             GrDirectContext* context,
             SkFilterQuality filter_quality) override;

  // |Texture|
  void OnGrContextCreated() override;

  // |Texture|
  void OnGrContextDestroyed() override;

  // |Texture|
  void MarkNewFrameAvailable() override;

  // |Texture|
  void OnTextureUnregistered() override;

  sk_sp<SkImage> WrapExternalPixelBuffer(fml::CFRef<CVPixelBufferRef> pixel_buffer,
                                         GrDirectContext* context) const;
  sk_sp<SkImage> WrapRGBAExternalPixelBuffer(fml::CFRef<CVPixelBufferRef> pixel_buffer,
                                             GrDirectContext* context) const;
  sk_sp<SkImage> WrapNV12ExternalPixelBuffer(fml::CFRef<CVPixelBufferRef> pixel_buffer,
                                             GrDirectContext* context) const;

  FML_DISALLOW_COPY_AND_ASSIGN(IOSExternalTextureMetal);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_DARWIN_IOS_IOS_EXTERNAL_TEXTURE_METAL_H_
