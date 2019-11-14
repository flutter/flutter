// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/gpu/gpu_surface_metal.h"

#include <QuartzCore/CAMetalLayer.h>

#include "third_party/skia/include/core/SkSurface.h"
#include "third_party/skia/include/gpu/GrBackendSurface.h"
#include "third_party/skia/include/ports/SkCFObject.h"

static_assert(!__has_feature(objc_arc), "ARC must be disabled.");

namespace flutter {

GPUSurfaceMetal::GPUSurfaceMetal(GPUSurfaceDelegate* delegate,
                                 fml::scoped_nsobject<CAMetalLayer> layer)
    : delegate_(delegate), layer_(std::move(layer)) {
  if (!layer_) {
    FML_LOG(ERROR) << "Could not create metal surface because of invalid layer.";
    return;
  }

  layer.get().pixelFormat = MTLPixelFormatBGRA8Unorm;
  // Flutter needs to read from the color attachment in cases where there are effects such as
  // backdrop filters.
  layer.get().framebufferOnly = NO;

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

GPUSurfaceMetal::GPUSurfaceMetal(GPUSurfaceDelegate* delegate,
                                 sk_sp<GrContext> gr_context,
                                 fml::scoped_nsobject<CAMetalLayer> layer)
    : delegate_(delegate), layer_(std::move(layer)), context_(gr_context) {
  if (!layer_) {
    FML_LOG(ERROR) << "Could not create metal surface because of invalid layer.";
    return;
  }
  if (!context_) {
    FML_LOG(ERROR) << "Could not create metal surface because of invalid Skia metal context.";
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
}

GPUSurfaceMetal::~GPUSurfaceMetal() {
  ReleaseUnusedDrawableIfNecessary();
}

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

  ReleaseUnusedDrawableIfNecessary();

  auto surface = SkSurface::MakeFromCAMetalLayer(context_.get(),            // context
                                                 layer_.get(),              // layer
                                                 kTopLeft_GrSurfaceOrigin,  // origin
                                                 1,                         // sample count
                                                 kBGRA_8888_SkColorType,    // color type
                                                 nullptr,                   // colorspace
                                                 nullptr,                   // surface properties
                                                 &next_drawable_  // drawable (transfer out)
  );

  if (!surface) {
    FML_LOG(ERROR) << "Could not create the SkSurface from the metal texture.";
    return nullptr;
  }

  auto submit_callback = [this](const SurfaceFrame& surface_frame, SkCanvas* canvas) -> bool {
    canvas->flush();

    if (next_drawable_ == nullptr) {
      FML_DLOG(ERROR) << "Could not acquire next Metal drawable from the SkSurface.";
      return false;
    }

    const auto has_external_view_embedder = delegate_->GetExternalViewEmbedder() != nullptr;

    auto command_buffer =
        fml::scoped_nsprotocol<id<MTLCommandBuffer>>([[command_queue_.get() commandBuffer] retain]);

    fml::scoped_nsprotocol<id<CAMetalDrawable>> drawable(
        reinterpret_cast<id<CAMetalDrawable>>(next_drawable_));
    next_drawable_ = nullptr;

    // External views need to present with transaction. When presenting with
    // transaction, we have to block, otherwise we risk presenting the drawable
    // after the CATransaction has completed.
    // See:
    // https://developer.apple.com/documentation/quartzcore/cametallayer/1478157-presentswithtransaction
    // TODO(dnfield): only do this if transactions are actually being used.
    // https://github.com/flutter/flutter/issues/24133
    if (!has_external_view_embedder) {
      [command_buffer.get() presentDrawable:drawable.get()];
      [command_buffer.get() commit];
    } else {
      [command_buffer.get() commit];
      [command_buffer.get() waitUntilScheduled];
      [drawable.get() present];
    }
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
flutter::ExternalViewEmbedder* GPUSurfaceMetal::GetExternalViewEmbedder() {
  return delegate_->GetExternalViewEmbedder();
}

// |Surface|
std::unique_ptr<RendererContextSwitchManager::RendererContextSwitch>
GPUSurfaceMetal::MakeRenderContextCurrent() {
  // This backend has no such concept.
  return std::make_unique<RendererContextSwitchManager::RendererContextSwitchPureResult>(true);
}

void GPUSurfaceMetal::ReleaseUnusedDrawableIfNecessary() {
  // If the previous surface frame was not submitted before  a new one is acquired, the old drawable
  // needs to be released. An RAII wrapper may not be used because this needs to interoperate with
  // Skia APIs.
  if (next_drawable_ == nullptr) {
    return;
  }

  CFRelease(next_drawable_);
  next_drawable_ = nullptr;
}

}  // namespace flutter
