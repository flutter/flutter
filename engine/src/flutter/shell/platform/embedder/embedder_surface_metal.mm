// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/embedder/embedder_surface_metal.h"

#include "flutter/fml/logging.h"
#include "flutter/fml/platform/darwin/scoped_nsobject.h"
#include "flutter/shell/gpu/gpu_surface_metal_delegate.h"
#import "flutter/shell/platform/darwin/graphics/FlutterDarwinContextMetal.h"
#include "third_party/skia/include/gpu/GrDirectContext.h"

namespace flutter {

EmbedderSurfaceMetal::EmbedderSurfaceMetal(
    GPUMTLDeviceHandle device,
    GPUMTLCommandQueueHandle command_queue,
    MetalDispatchTable metal_dispatch_table,
    std::shared_ptr<EmbedderExternalViewEmbedder> external_view_embedder)
    : GPUSurfaceMetalDelegate(MTLRenderTargetType::kMTLTexture),
      metal_dispatch_table_(metal_dispatch_table),
      external_view_embedder_(external_view_embedder) {
  auto darwin_metal_context =
      fml::scoped_nsobject<FlutterDarwinContextMetal>{[[[FlutterDarwinContextMetal alloc]
          initWithMTLDevice:(id<MTLDevice>)device
               commandQueue:(id<MTLCommandQueue>)command_queue] retain]};
  main_context_ = darwin_metal_context.get().mainContext;
  resource_context_ = darwin_metal_context.get().resourceContext;
  valid_ = main_context_ && resource_context_;
}

EmbedderSurfaceMetal::~EmbedderSurfaceMetal() = default;

bool EmbedderSurfaceMetal::IsValid() const {
  return valid_;
}

std::unique_ptr<Surface> EmbedderSurfaceMetal::CreateGPUSurface() {
  if (!IsValid()) {
    return nullptr;
  }

  auto surface = std::make_unique<GPUSurfaceMetal>(this, main_context_);

  if (!surface->IsValid()) {
    return nullptr;
  }

  return surface;
}

sk_sp<GrDirectContext> EmbedderSurfaceMetal::CreateResourceContext() const {
  return resource_context_;
}

GPUCAMetalLayerHandle EmbedderSurfaceMetal::GetCAMetalLayer(const SkISize& frame_info) const {
  FML_CHECK(false) << "Only rendering to MTLTexture is supported.";
  return nullptr;
}

bool EmbedderSurfaceMetal::PresentDrawable(GrMTLHandle drawable) const {
  FML_CHECK(false) << "Only rendering to MTLTexture is supported.";
  return false;
}

GPUMTLTextureInfo EmbedderSurfaceMetal::GetMTLTexture(const SkISize& frame_info) const {
  return metal_dispatch_table_.get_texture(frame_info);
}

bool EmbedderSurfaceMetal::PresentTexture(GPUMTLTextureInfo texture) const {
  return metal_dispatch_table_.present(texture);
}

}  // namespace flutter
