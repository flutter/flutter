// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_DARWIN_IOS_IOS_CONTEXT_METAL_H_
#define FLUTTER_SHELL_PLATFORM_DARWIN_IOS_IOS_CONTEXT_METAL_H_

#include <Metal/Metal.h>

#include "flutter/fml/macros.h"
#include "flutter/fml/platform/darwin/cf_utils.h"
#include "flutter/fml/platform/darwin/scoped_nsobject.h"
#include "flutter/shell/platform/darwin/ios/ios_context.h"
#include "third_party/skia/include/gpu/GrDirectContext.h"

namespace flutter {

class IOSContextMetal final : public IOSContext {
 public:
  IOSContextMetal();

  ~IOSContextMetal();

  fml::scoped_nsprotocol<id<MTLDevice>> GetDevice() const;

  fml::scoped_nsprotocol<id<MTLCommandQueue>> GetMainCommandQueue() const;

  fml::scoped_nsprotocol<id<MTLCommandQueue>> GetResourceCommandQueue() const;

  sk_sp<GrDirectContext> GetMainContext() const;

  sk_sp<GrDirectContext> GetResourceContext() const;

 private:
  fml::scoped_nsprotocol<id<MTLDevice>> device_;
  fml::scoped_nsprotocol<id<MTLCommandQueue>> main_queue_;
  sk_sp<GrDirectContext> main_context_;
  sk_sp<GrDirectContext> resource_context_;
  fml::CFRef<CVMetalTextureCacheRef> texture_cache_;
  bool is_valid_ = false;

  // |IOSContext|
  sk_sp<GrDirectContext> CreateResourceContext() override;

  // |IOSContext|
  std::unique_ptr<GLContextResult> MakeCurrent() override;

  // |IOSContext|
  std::unique_ptr<Texture> CreateExternalTexture(
      int64_t texture_id,
      fml::scoped_nsobject<NSObject<FlutterTexture>> texture) override;

  FML_DISALLOW_COPY_AND_ASSIGN(IOSContextMetal);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_DARWIN_IOS_IOS_CONTEXT_METAL_H_
