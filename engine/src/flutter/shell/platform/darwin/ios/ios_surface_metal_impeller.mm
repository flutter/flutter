// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/ios/ios_surface_metal_impeller.h"

#include "flutter/impeller/renderer/backend/metal/formats_mtl.h"
#include "flutter/impeller/renderer/context.h"
#include "flutter/shell/gpu/gpu_surface_metal_impeller.h"

namespace impeller {
namespace {

// This appears to be the only safe way to override the
// GetColorAttachmentPixelFormat method.  It is assumed in the Context that
// there will be one pixel format for the whole app which is not true.  So, it
// is unsafe to mutate the Context and you cannot clone the Context at this
// level since the Context does not safely manage the MTLDevice.
class CustomColorAttachmentPixelFormatContext final : public Context {
 public:
  CustomColorAttachmentPixelFormatContext(const std::shared_ptr<Context>& context,
                                          PixelFormat color_attachment_pixel_format)
      : context_(context), color_attachment_pixel_format_(color_attachment_pixel_format) {}

  bool IsValid() const override { return context_->IsValid(); }

  std::shared_ptr<Allocator> GetResourceAllocator() const override {
    return context_->GetResourceAllocator();
  }

  std::shared_ptr<ShaderLibrary> GetShaderLibrary() const override {
    return context_->GetShaderLibrary();
  }

  std::shared_ptr<SamplerLibrary> GetSamplerLibrary() const override {
    return context_->GetSamplerLibrary();
  }

  std::shared_ptr<PipelineLibrary> GetPipelineLibrary() const override {
    return context_->GetPipelineLibrary();
  }

  std::shared_ptr<CommandBuffer> CreateCommandBuffer() const override {
    return context_->CreateCommandBuffer();
  }

  std::shared_ptr<WorkQueue> GetWorkQueue() const override { return context_->GetWorkQueue(); }

  std::shared_ptr<GPUTracer> GetGPUTracer() const override { return context_->GetGPUTracer(); }

  PixelFormat GetColorAttachmentPixelFormat() const override {
    return color_attachment_pixel_format_;
  }

  bool HasThreadingRestrictions() const override { return context_->HasThreadingRestrictions(); }

  bool SupportsOffscreenMSAA() const override { return context_->SupportsOffscreenMSAA(); }

  const BackendFeatures& GetBackendFeatures() const override {
    return context_->GetBackendFeatures();
  }

 private:
  std::shared_ptr<Context> context_;
  PixelFormat color_attachment_pixel_format_;
};
}  // namespace
}  // namespace impeller

namespace flutter {

using impeller::CustomColorAttachmentPixelFormatContext;
using impeller::FromMTLPixelFormat;

IOSSurfaceMetalImpeller::IOSSurfaceMetalImpeller(const fml::scoped_nsobject<CAMetalLayer>& layer,
                                                 const std::shared_ptr<IOSContext>& context)
    : IOSSurface(context),
      GPUSurfaceMetalDelegate(MTLRenderTargetType::kCAMetalLayer),
      layer_(layer),
      impeller_context_(context ? context->GetImpellerContext() : nullptr) {
  if (!impeller_context_) {
    return;
  }
  is_valid_ = true;
}

// |IOSSurface|
IOSSurfaceMetalImpeller::~IOSSurfaceMetalImpeller() = default;

// |IOSSurface|
bool IOSSurfaceMetalImpeller::IsValid() const {
  return is_valid_;
}

// |IOSSurface|
void IOSSurfaceMetalImpeller::UpdateStorageSizeIfNecessary() {
  // Nothing to do.
}

// |IOSSurface|
std::unique_ptr<Surface> IOSSurfaceMetalImpeller::CreateGPUSurface(GrDirectContext*) {
  auto context = std::make_shared<CustomColorAttachmentPixelFormatContext>(
      impeller_context_, FromMTLPixelFormat(layer_.get().pixelFormat));
  return std::make_unique<GPUSurfaceMetalImpeller>(this,    //
                                                   context  //
  );
}

// |GPUSurfaceMetalDelegate|
GPUCAMetalLayerHandle IOSSurfaceMetalImpeller::GetCAMetalLayer(const SkISize& frame_info) const {
  CAMetalLayer* layer = layer_.get();
  const auto drawable_size = CGSizeMake(frame_info.width(), frame_info.height());
  if (!CGSizeEqualToSize(drawable_size, layer.drawableSize)) {
    layer.drawableSize = drawable_size;
  }

  // When there are platform views in the scene, the drawable needs to be presented in the same
  // transaction as the one created for platform views. When the drawable are being presented from
  // the raster thread, there is no such transaction.
  layer.presentsWithTransaction = [[NSThread currentThread] isMainThread];

  return layer;
}

// |GPUSurfaceMetalDelegate|
bool IOSSurfaceMetalImpeller::PresentDrawable(GrMTLHandle drawable) const {
  FML_DCHECK(false);
  return false;
}

// |GPUSurfaceMetalDelegate|
GPUMTLTextureInfo IOSSurfaceMetalImpeller::GetMTLTexture(const SkISize& frame_info) const {
  FML_CHECK(false);
  return GPUMTLTextureInfo{
      .texture_id = -1,   //
      .texture = nullptr  //
  };
}

// |GPUSurfaceMetalDelegate|
bool IOSSurfaceMetalImpeller::PresentTexture(GPUMTLTextureInfo texture) const {
  FML_CHECK(false);
  return false;
}

// |GPUSurfaceMetalDelegate|
bool IOSSurfaceMetalImpeller::AllowsDrawingWhenGpuDisabled() const {
  return false;
}

}  // namespace flutter
