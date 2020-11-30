// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_GPU_GPU_SURFACE_METAL_H_
#define FLUTTER_SHELL_GPU_GPU_SURFACE_METAL_H_

#include <Metal/Metal.h>

#include "flutter/flow/surface.h"
#include "flutter/fml/macros.h"
#include "flutter/fml/platform/darwin/scoped_nsobject.h"
#include "third_party/skia/include/gpu/GrDirectContext.h"
#include "third_party/skia/include/gpu/mtl/GrMtlTypes.h"

@class CAMetalLayer;

namespace flutter {

class SK_API_AVAILABLE_CA_METAL_LAYER GPUSurfaceMetal : public Surface {
 public:
  GPUSurfaceMetal(fml::scoped_nsobject<CAMetalLayer> layer,
                  sk_sp<GrDirectContext> context,
                  fml::scoped_nsprotocol<id<MTLCommandQueue>> command_queue);

  // |Surface|
  ~GPUSurfaceMetal();

 private:
  fml::scoped_nsobject<CAMetalLayer> layer_;
  sk_sp<GrDirectContext> context_;
  fml::scoped_nsprotocol<id<MTLCommandQueue>> command_queue_;
  GrMTLHandle next_drawable_ = nullptr;

  // |Surface|
  bool IsValid() override;

  // |Surface|
  std::unique_ptr<SurfaceFrame> AcquireFrame(const SkISize& size) override;

  // |Surface|
  SkMatrix GetRootTransformation() const override;

  // |Surface|
  GrDirectContext* GetContext() override;

  // |Surface|
  std::unique_ptr<GLContextResult> MakeRenderContextCurrent() override;

  void ReleaseUnusedDrawableIfNecessary();

  FML_DISALLOW_COPY_AND_ASSIGN(GPUSurfaceMetal);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_GPU_GPU_SURFACE_METAL_H_
