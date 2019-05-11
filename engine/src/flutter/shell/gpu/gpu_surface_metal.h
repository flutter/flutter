// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_GPU_GPU_SURFACE_METAL_H_
#define FLUTTER_SHELL_GPU_GPU_SURFACE_METAL_H_

#include <Metal/Metal.h>

#include "flutter/fml/macros.h"
#include "flutter/fml/platform/darwin/scoped_nsobject.h"
#include "flutter/shell/common/surface.h"
#include "third_party/skia/include/gpu/GrContext.h"

@class CAMetalLayer;

namespace flutter {

class GPUSurfaceMetal : public Surface {
 public:
  GPUSurfaceMetal(fml::scoped_nsobject<CAMetalLayer> layer);

  ~GPUSurfaceMetal() override;

 private:
  fml::scoped_nsobject<CAMetalLayer> layer_;
  sk_sp<GrContext> context_;
  fml::scoped_nsprotocol<id<MTLCommandQueue>> command_queue_;

  // |Surface|
  bool IsValid() override;

  // |Surface|
  std::unique_ptr<SurfaceFrame> AcquireFrame(const SkISize& size) override;

  // |Surface|
  SkMatrix GetRootTransformation() const override;

  // |Surface|
  GrContext* GetContext() override;

  // |Surface|
  bool MakeRenderContextCurrent() override;

  FML_DISALLOW_COPY_AND_ASSIGN(GPUSurfaceMetal);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_GPU_GPU_SURFACE_METAL_H_
