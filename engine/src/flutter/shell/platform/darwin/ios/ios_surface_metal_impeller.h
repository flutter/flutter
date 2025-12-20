// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_DARWIN_IOS_IOS_SURFACE_METAL_IMPELLER_H_
#define FLUTTER_SHELL_PLATFORM_DARWIN_IOS_IOS_SURFACE_METAL_IMPELLER_H_

#include "flutter/fml/macros.h"
#include "flutter/shell/gpu/gpu_surface_metal_delegate.h"
#include "flutter/shell/platform/darwin/ios/ios_surface.h"
#include <Metal/Metal.h>

@class CAMetalLayer;

namespace impeller {
class Context;
}  // namespace impeller

namespace flutter {

class SK_API_AVAILABLE_CA_METAL_LAYER IOSSurfaceMetalImpeller final
    : public IOSSurface,
      public GPUSurfaceMetalDelegate {
 public:
  IOSSurfaceMetalImpeller(
    CAMetalLayer* layer,
    const std::shared_ptr<IOSContext>& context,
    bool render_to_surface = true);

  // |IOSSurface|
  ~IOSSurfaceMetalImpeller();

  MTLPixelFormat GetPixelFormat() const;

 private:
  CAMetalLayer* layer_;
  const std::shared_ptr<impeller::Context> impeller_context_;
  std::shared_ptr<impeller::AiksContext> aiks_context_;
  bool is_valid_ = false;
  // TODO(38466): Refactor GPU surface APIs take into account the fact that an
  // external view embedder may want to render to the root surface. This is a
  // hack to make avoid allocating resources for the root surface when an
  // external view embedder is present.
  bool render_to_surface_ = true;

  // |IOSSurface|
  bool IsValid() const override;

  // |IOSSurface|
  void UpdateStorageSizeIfNecessary() override;

  // |IOSSurface|
  std::unique_ptr<Surface> CreateGPUSurface() override;

  // |GPUSurfaceMetalDelegate|
  GPUCAMetalLayerHandle GetCAMetalLayer(const DlISize& frame_info) const override
      __attribute__((cf_audited_transfer));

  // |GPUSurfaceMetalDelegate|
  bool PresentDrawable(GrMTLHandle drawable) const override __attribute__((cf_audited_transfer));

  // |GPUSurfaceMetalDelegate|
  GPUMTLTextureInfo GetMTLTexture(const DlISize& frame_info) const override
      __attribute__((cf_audited_transfer));

  // |GPUSurfaceMetalDelegate|
  bool PresentTexture(GPUMTLTextureInfo texture) const override
      __attribute__((cf_audited_transfer));

  // |GPUSurfaceMetalDelegate|
  bool AllowsDrawingWhenGpuDisabled() const override;

  FML_DISALLOW_COPY_AND_ASSIGN(IOSSurfaceMetalImpeller);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_DARWIN_IOS_IOS_SURFACE_METAL_IMPELLER_H_
