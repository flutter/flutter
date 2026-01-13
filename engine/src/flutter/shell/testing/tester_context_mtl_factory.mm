// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#define FML_USED_ON_EMBEDDER

#include "flutter/shell/testing/tester_context_mtl_factory.h"

#include <Foundation/Foundation.h>
#include <QuartzCore/QuartzCore.h>
#include <deque>
#include <optional>
#include <type_traits>
#include <vector>

#include "flutter/fml/mapping.h"
#include "flutter/fml/synchronization/sync_switch.h"
#include "flutter/shell/gpu/gpu_surface_metal_impeller.h"
#include "impeller/base/validation.h"
#include "impeller/display_list/aiks_context.h"
#include "impeller/entity/mtl/entity_shaders.h"
#include "impeller/entity/mtl/framebuffer_blend_shaders.h"
#include "impeller/entity/mtl/modern_shaders.h"
#include "impeller/renderer/backend/metal/context_mtl.h"
#include "impeller/typographer/backends/skia/typographer_context_skia.h"
#include "impeller/typographer/typographer_context.h"

namespace flutter {

namespace {

class TesterGPUSurfaceMetalDelegate : public GPUSurfaceMetalDelegate {
 public:
  explicit TesterGPUSurfaceMetalDelegate(id<MTLDevice> device)
      : GPUSurfaceMetalDelegate(MTLRenderTargetType::kCAMetalLayer) {
    layer_ = [[CAMetalLayer alloc] init];
    layer_.device = device;
    layer_.pixelFormat = MTLPixelFormatBGRA8Unorm;
  }

  ~TesterGPUSurfaceMetalDelegate() = default;

  GPUCAMetalLayerHandle GetCAMetalLayer(const DlISize& frame_info) const override {
    layer_.drawableSize = CGSizeMake(frame_info.width, frame_info.height);
    return (__bridge GPUCAMetalLayerHandle)(layer_);
  }

  bool PresentDrawable(GrMTLHandle drawable) const override { return true; }

  GPUMTLTextureInfo GetMTLTexture(const DlISize& frame_info) const override { return {}; }

  bool PresentTexture(GPUMTLTextureInfo texture) const override { return true; }

  bool AllowsDrawingWhenGpuDisabled() const override { return true; }

 private:
  CAMetalLayer* layer_ = nil;
};

std::vector<std::shared_ptr<fml::Mapping>> ShaderLibraryMappings() {
  return {
      std::make_shared<fml::NonOwnedMapping>(impeller_entity_shaders_data,
                                             impeller_entity_shaders_length),
      std::make_shared<fml::NonOwnedMapping>(impeller_modern_shaders_data,
                                             impeller_modern_shaders_length),
      std::make_shared<fml::NonOwnedMapping>(impeller_framebuffer_blend_shaders_data,
                                             impeller_framebuffer_blend_shaders_length),
  };
}

}  // namespace

class TesterContextMTL : public TesterContext {
 public:
  TesterContextMTL() = default;

  ~TesterContextMTL() override {
    if (context_) {
      context_->Shutdown();
    }
  }

  bool Initialize() {
    std::vector<std::shared_ptr<fml::Mapping>> shader_mappings = ShaderLibraryMappings();
    auto sync_switch = std::make_shared<fml::SyncSwitch>(false);
    context_ = impeller::ContextMTL::Create(impeller::Flags{}, shader_mappings, sync_switch,
                                            "Impeller Library");

    if (!context_ || !context_->IsValid()) {
      VALIDATION_LOG << "Could not create Metal context.";
      return false;
    }

    auto device = context_->GetMTLDevice();
    if (!device) {
      VALIDATION_LOG << "Could not get Metal device.";
      return false;
    }

    delegate_ = std::make_unique<TesterGPUSurfaceMetalDelegate>(device);
    aiks_context_ = std::make_shared<impeller::AiksContext>(
        context_, /*typographer_context=*/impeller::TypographerContextSkia::Make());

    return true;
  }

  // |TesterContext|
  std::shared_ptr<impeller::Context> GetImpellerContext() const override { return context_; }

  // |TesterContext|
  std::unique_ptr<Surface> CreateRenderingSurface() override {
    auto surface = std::make_unique<GPUSurfaceMetalImpeller>(delegate_.get(), aiks_context_);
    if (!surface->IsValid()) {
      return nullptr;
    }
    return surface;
  }

 private:
  std::shared_ptr<impeller::ContextMTL> context_;
  std::unique_ptr<TesterGPUSurfaceMetalDelegate> delegate_;
  std::shared_ptr<impeller::AiksContext> aiks_context_;
};

std::unique_ptr<TesterContext> TesterContextMTLFactory::Create() {
  auto context = std::make_unique<TesterContextMTL>();
  if (!context->Initialize()) {
    return nullptr;
  }
  return context;
}

}  // namespace flutter
