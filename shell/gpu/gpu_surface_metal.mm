// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/gpu/gpu_surface_metal.h"

#include <QuartzCore/CAMetalLayer.h>

#include "third_party/skia/include/core/SkSurface.h"
#include "third_party/skia/include/gpu/GrBackendSurface.h"
#include "third_party/skia/include/ports/SkCFObject.h"

namespace flutter {

GPUSurfaceMetal::GPUSurfaceMetal(fml::scoped_nsobject<CAMetalLayer> layer)
    : layer_(std::move(layer)) {
  if (!layer_) {
    FML_LOG(ERROR) << "Could not create metal surface because of invalid layer.";
    return;
  }

  layer.get().pixelFormat = MTLPixelFormatBGRA8Unorm;

  auto metal_device = fml::scoped_nsprotocol<id<MTLDevice>>([layer_.get().device retain]);
  auto metal_queue = fml::scoped_nsprotocol<id<MTLCommandQueue>>([metal_device newCommandQueue]);

  if (!metal_device || !metal_queue) {
    FML_LOG(ERROR) << "Could not create metal device or queue.";
    return;
  }

  command_queue_ = metal_queue;

  // The context creation routine accepts arguments using transfer semantics.
  auto context = GrContext::MakeMetal(metal_device.release(), metal_queue.release());
  if (!context) {
    FML_LOG(ERROR) << "Could not create Skia metal context.";
    return;
  }

  context_ = context;
}

GPUSurfaceMetal::~GPUSurfaceMetal() = default;

// |Surface|
bool GPUSurfaceMetal::IsValid() {
  return layer_ && context_ && command_queue_;
}

// |Surface|
std::unique_ptr<SurfaceFrame> GPUSurfaceMetal::AcquireFrame(const SkISize& size) {
  if (!IsValid()) {
    FML_LOG(ERROR) << "Metal surface was invalid.";
    return nullptr;
  }

  if (size.isEmpty()) {
    FML_LOG(ERROR) << "Metal surface was asked for an empty frame.";
    return nullptr;
  }

  const auto bounds = layer_.get().bounds.size;
  if (bounds.width <= 0.0 || bounds.height <= 0.0) {
    FML_LOG(ERROR) << "Metal layer bounds were invalid.";
    return nullptr;
  }

  const auto scale = layer_.get().contentsScale;

  auto next_drawable = fml::scoped_nsprotocol<id<CAMetalDrawable>>([[layer_ nextDrawable] retain]);
  if (!next_drawable) {
    FML_LOG(ERROR) << "Could not acquire next metal drawable.";
    return nullptr;
  }

  auto metal_texture = fml::scoped_nsprotocol<id<MTLTexture>>([next_drawable.get().texture retain]);
  if (!metal_texture) {
    FML_LOG(ERROR) << "Could not acquire metal texture from drawable.";
    return nullptr;
  }

  GrMtlTextureInfo metal_texture_info;
  metal_texture_info.fTexture.reset(SkCFSafeRetain(metal_texture.get()));

  GrBackendRenderTarget metal_render_target(bounds.width * scale,   // width
                                            bounds.height * scale,  // height
                                            1,                      // sample count
                                            metal_texture_info      // metal texture info
  );

  auto command_buffer =
      fml::scoped_nsprotocol<id<MTLCommandBuffer>>([[command_queue_.get() commandBuffer] retain]);

  SkSurface::RenderTargetReleaseProc release_proc = [](SkSurface::ReleaseContext context) {
    [reinterpret_cast<id>(context) release];
  };

  auto surface =
      SkSurface::MakeFromBackendRenderTarget(context_.get(),            // context
                                             metal_render_target,       // backend render target
                                             kTopLeft_GrSurfaceOrigin,  // origin
                                             kBGRA_8888_SkColorType,    // color type
                                             nullptr,                   // colorspace
                                             nullptr,                   // surface properties
                                             release_proc,              // release proc
                                             metal_texture.release()    // release context (texture)
      );

  if (!surface) {
    FML_LOG(ERROR) << "Could not create the SkSurface from the metal texture.";
    return nullptr;
  }

  auto submit_callback = [drawable = next_drawable, command_buffer](
                             const SurfaceFrame& surface_frame, SkCanvas* canvas) -> bool {
    canvas->flush();
    [command_buffer.get() presentDrawable:drawable.get()];
    [command_buffer.get() commit];
    return true;
  };

  return std::make_unique<SurfaceFrame>(std::move(surface), submit_callback);
}

// |Surface|
SkMatrix GPUSurfaceMetal::GetRootTransformation() const {
  // This backend does not currently support root surface transformations. Just
  // return identity.
  SkMatrix matrix;
  matrix.reset();
  return matrix;
}

// |Surface|
GrContext* GPUSurfaceMetal::GetContext() {
  return context_.get();
}

// |Surface|
bool GPUSurfaceMetal::MakeRenderContextCurrent() {
  // This backend has no such concept.
  return true;
}

}  // namespace flutter
