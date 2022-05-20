// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_DARWIN_IOS_IOS_CONTEXT_METAL_SKIA_H_
#define FLUTTER_SHELL_PLATFORM_DARWIN_IOS_IOS_CONTEXT_METAL_SKIA_H_

#include <Metal/Metal.h>

#include "flutter/fml/macros.h"
#include "flutter/fml/platform/darwin/cf_utils.h"
#include "flutter/fml/platform/darwin/scoped_nsobject.h"
#import "flutter/shell/platform/darwin/graphics/FlutterDarwinContextMetal.h"
#import "flutter/shell/platform/darwin/ios/ios_context.h"
#include "third_party/skia/include/gpu/GrDirectContext.h"

namespace flutter {

class IOSContextMetalSkia final : public IOSContext {
 public:
  explicit IOSContextMetalSkia(MsaaSampleCount msaa_samples);

  ~IOSContextMetalSkia();

  fml::scoped_nsobject<FlutterDarwinContextMetal> GetDarwinContext() const;

  // |IOSContext|
  IOSRenderingBackend GetBackend() const override;

  // |IOSContext|
  sk_sp<GrDirectContext> GetMainContext() const override;

  sk_sp<GrDirectContext> GetResourceContext() const;

 private:
  fml::scoped_nsobject<FlutterDarwinContextMetal> darwin_context_metal_;
  fml::scoped_nsprotocol<id<MTLCommandQueue>> main_command_queue_;
  fml::CFRef<CVMetalTextureCacheRef> texture_cache_;

  // |IOSContext|
  sk_sp<GrDirectContext> CreateResourceContext() override;

  // |IOSContext|
  std::unique_ptr<GLContextResult> MakeCurrent() override;

  // |IOSContext|
  std::unique_ptr<Texture> CreateExternalTexture(
      int64_t texture_id,
      fml::scoped_nsobject<NSObject<FlutterTexture>> texture) override;

  FML_DISALLOW_COPY_AND_ASSIGN(IOSContextMetalSkia);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_DARWIN_IOS_IOS_CONTEXT_METAL_SKIA_H_
