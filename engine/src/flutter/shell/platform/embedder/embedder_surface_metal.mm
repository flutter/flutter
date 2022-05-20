// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/embedder/embedder_surface_metal.h"

#include "flutter/fml/logging.h"
#include "flutter/shell/gpu/gpu_surface_metal_delegate.h"
#import "flutter/shell/platform/darwin/graphics/FlutterDarwinContextMetal.h"
#include "third_party/skia/include/gpu/GrDirectContext.h"

FLUTTER_ASSERT_NOT_ARC
namespace flutter {

EmbedderSurfaceMetal::EmbedderSurfaceMetal(
    GPUMTLDeviceHandle device,
    GPUMTLCommandQueueHandle command_queue,
    MetalDispatchTable metal_dispatch_table,
    std::shared_ptr<EmbedderExternalViewEmbedder> external_view_embedder)
    : GPUSurfaceMetalDelegate(MTLRenderTargetType::kMTLTexture),
      metal_dispatch_table_(metal_dispatch_table),
      external_view_embedder_(external_view_embedder) {
  main_context_ = [FlutterDarwinContextMetal createGrContext:(id<MTLDevice>)device
                                                commandQueue:(id<MTLCommandQueue>)command_queue];
  resource_context_ =
      [FlutterDarwinContextMetal createGrContext:(id<MTLDevice>)device
                                    commandQueue:(id<MTLCommandQueue>)command_queue];
  valid_ = main_context_ && resource_context_;
}

EmbedderSurfaceMetal::~EmbedderSurfaceMetal() = default;

bool EmbedderSurfaceMetal::IsValid() const {
  return valid_;
}

std::unique_ptr<Surface> EmbedderSurfaceMetal::CreateGPUSurface() API_AVAILABLE(ios(13.0)) {
  if (@available(iOS 13.0, *)) {
  } else {
    return nullptr;
  }
  if (!IsValid()) {
    return nullptr;
  }

  const bool render_to_surface = !external_view_embedder_;
  auto surface = std::make_unique<GPUSurfaceMetalSkia>(this, main_context_, MsaaSampleCount::kNone,
                                                       render_to_surface);

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
