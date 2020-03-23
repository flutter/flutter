// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/gpu/gpu_surface_metal.h"

#include <QuartzCore/CAMetalLayer.h>

#include "flutter/fml/trace_event.h"
#include "third_party/skia/include/core/SkSurface.h"
#include "third_party/skia/include/gpu/GrBackendSurface.h"
#include "third_party/skia/include/ports/SkCFObject.h"

static_assert(!__has_feature(objc_arc), "ARC must be disabled.");

namespace flutter {

GPUSurfaceMetal::GPUSurfaceMetal(GPUSurfaceDelegate* delegate,
                                 fml::scoped_nsobject<CAMetalLayer> layer,
                                 sk_sp<GrContext> context,
                                 fml::scoped_nsprotocol<id<MTLCommandQueue>> command_queue)
    : delegate_(delegate),
      layer_(std::move(layer)),
      context_(std::move(context)),
      command_queue_(std::move(command_queue)) {
  layer_.get().pixelFormat = MTLPixelFormatBGRA8Unorm;
  // Flutter needs to read from the color attachment in cases where there are effects such as
  // backdrop filters.
  layer_.get().framebufferOnly = NO;
}

GPUSurfaceMetal::~GPUSurfaceMetal() {
  ReleaseUnusedDrawableIfNecessary();
}

// |Surface|
bool GPUSurfaceMetal::IsValid() {
  return layer_ && context_ && command_queue_;
}

// |Surface|
std::unique_ptr<SurfaceFrame> GPUSurfaceMetal::AcquireFrame(const SkISize& frame_size) {
  if (!IsValid()) {
    FML_LOG(ERROR) << "Metal surface was invalid.";
    return nullptr;
  }

  if (frame_size.isEmpty()) {
    FML_LOG(ERROR) << "Metal surface was asked for an empty frame.";
    return nullptr;
  }

  const auto drawable_size = CGSizeMake(frame_size.width(), frame_size.height());

  if (!CGSizeEqualToSize(drawable_size, layer_.get().drawableSize)) {
    layer_.get().drawableSize = drawable_size;
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
    TRACE_EVENT0("flutter", "GPUSurfaceMetal::Submit");
    canvas->flush();

    if (next_drawable_ == nullptr) {
      FML_DLOG(ERROR) << "Could not acquire next Metal drawable from the SkSurface.";
      return false;
    }

    auto command_buffer =
        fml::scoped_nsprotocol<id<MTLCommandBuffer>>([[command_queue_.get() commandBuffer] retain]);

    fml::scoped_nsprotocol<id<CAMetalDrawable>> drawable(
        reinterpret_cast<id<CAMetalDrawable>>(next_drawable_));
    next_drawable_ = nullptr;

    [command_buffer.get() commit];
    [command_buffer.get() waitUntilScheduled];
    [drawable.get() present];

    return true;
  };

  return std::make_unique<SurfaceFrame>(std::move(surface), true, submit_callback);
}

// |Surface|
SkMatrix GPUSurfaceMetal::GetRootTransformation() const {
  // This backend does not currently support root surface transformations. Just
  // return identity.
  return {};
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
bool GPUSurfaceMetal::MakeRenderContextCurrent() {
  // This backend has no such concept.
  return true;
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
