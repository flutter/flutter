// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/gpu/gpu_surface_metal.h"

#import <Metal/Metal.h>

#include "flutter/common/graphics/persistent_cache.h"
#include "flutter/fml/make_copyable.h"
#include "flutter/fml/platform/darwin/cf_utils.h"
#include "flutter/fml/trace_event.h"
#include "flutter/shell/gpu/gpu_surface_metal_delegate.h"
#include "third_party/skia/include/core/SkSurface.h"
#include "third_party/skia/include/gpu/GrBackendSurface.h"
#include "third_party/skia/include/ports/SkCFObject.h"

static_assert(!__has_feature(objc_arc), "ARC must be disabled.");

namespace flutter {

GPUSurfaceMetal::GPUSurfaceMetal(GPUSurfaceMetalDelegate* delegate,
                                 sk_sp<GrDirectContext> context,
                                 bool render_to_surface)
    : delegate_(delegate),
      render_target_type_(delegate->GetRenderTargetType()),
      context_(std::move(context)),
      render_to_surface_(render_to_surface) {}

GPUSurfaceMetal::~GPUSurfaceMetal() {
  ReleaseUnusedDrawableIfNecessary();
}

// |Surface|
bool GPUSurfaceMetal::IsValid() {
  return context_ != nullptr;
}

void GPUSurfaceMetal::PrecompileKnownSkSLsIfNecessary() {
  auto* current_context = GetContext();
  if (current_context == precompiled_sksl_context_) {
    // Known SkSLs have already been prepared in this context.
    return;
  }
  precompiled_sksl_context_ = current_context;
  flutter::PersistentCache::GetCacheForProcess()->PrecompileKnownSkSLs(precompiled_sksl_context_);
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

  if (!render_to_surface_) {
    return std::make_unique<SurfaceFrame>(
        nullptr, true, [](const SurfaceFrame& surface_frame, SkCanvas* canvas) { return true; });
  }

  PrecompileKnownSkSLsIfNecessary();

  switch (render_target_type_) {
    case MTLRenderTargetType::kCAMetalLayer:
      return AcquireFrameFromCAMetalLayer(frame_size);
    case MTLRenderTargetType::kMTLTexture:
      return AcquireFrameFromMTLTexture(frame_size);
    default:
      FML_CHECK(false) << "Unknown MTLRenderTargetType type.";
  }

  return nullptr;
}

std::unique_ptr<SurfaceFrame> GPUSurfaceMetal::AcquireFrameFromCAMetalLayer(
    const SkISize& frame_info) {
  auto layer = delegate_->GetCAMetalLayer(frame_info);
  if (!layer) {
    FML_LOG(ERROR) << "Invalid CAMetalLayer given by the embedder.";
    return nullptr;
  }

  ReleaseUnusedDrawableIfNecessary();
  sk_sp<SkSurface> surface =
      SkSurface::MakeFromCAMetalLayer(context_.get(),            // context
                                      layer,                     // layer
                                      kTopLeft_GrSurfaceOrigin,  // origin
                                      1,                         // sample count
                                      kBGRA_8888_SkColorType,    // color type
                                      nullptr,                   // colorspace
                                      nullptr,                   // surface properties
                                      &next_drawable_            // drawable (transfer out)
      );

  if (!surface) {
    FML_LOG(ERROR) << "Could not create the SkSurface from the CAMetalLayer.";
    return nullptr;
  }

  auto submit_callback = [this](const SurfaceFrame& surface_frame, SkCanvas* canvas) -> bool {
    TRACE_EVENT0("flutter", "GPUSurfaceMetal::Submit");
    if (canvas == nullptr) {
      FML_DLOG(ERROR) << "Canvas not available.";
      return false;
    }

    canvas->flush();

    GrMTLHandle drawable = next_drawable_;
    if (!drawable) {
      FML_DLOG(ERROR) << "Unable to obtain a metal drawable.";
      return false;
    }

    return delegate_->PresentDrawable(drawable);
  };

  return std::make_unique<SurfaceFrame>(std::move(surface), true, submit_callback);
}

std::unique_ptr<SurfaceFrame> GPUSurfaceMetal::AcquireFrameFromMTLTexture(
    const SkISize& frame_info) {
  GPUMTLTextureInfo texture = delegate_->GetMTLTexture(frame_info);
  id<MTLTexture> mtl_texture = (id<MTLTexture>)(texture.texture);

  if (!mtl_texture) {
    FML_LOG(ERROR) << "Invalid MTLTexture given by the embedder.";
    return nullptr;
  }

  GrMtlTextureInfo info;
  info.fTexture.reset([mtl_texture retain]);
  GrBackendTexture backend_texture(frame_info.width(), frame_info.height(), GrMipmapped::kNo, info);

  sk_sp<SkSurface> surface =
      SkSurface::MakeFromBackendTexture(context_.get(), backend_texture, kTopLeft_GrSurfaceOrigin,
                                        1, kBGRA_8888_SkColorType, nullptr, nullptr);

  if (!surface) {
    FML_LOG(ERROR) << "Could not create the SkSurface from the metal texture.";
    return nullptr;
  }

  auto submit_callback = [texture = texture, delegate = delegate_](
                             const SurfaceFrame& surface_frame, SkCanvas* canvas) -> bool {
    TRACE_EVENT0("flutter", "GPUSurfaceMetal::PresentTexture");
    if (canvas == nullptr) {
      FML_DLOG(ERROR) << "Canvas not available.";
      return false;
    }

    canvas->flush();

    return delegate->PresentTexture(texture);
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
GrDirectContext* GPUSurfaceMetal::GetContext() {
  return context_.get();
}

// |Surface|
std::unique_ptr<GLContextResult> GPUSurfaceMetal::MakeRenderContextCurrent() {
  // A context may either be necessary to render to the surface or to snapshot an offscreen
  // surface. Either way, SkSL precompilation must be attempted.
  PrecompileKnownSkSLsIfNecessary();

  // This backend has no such concept.
  return std::make_unique<GLContextDefaultResult>(true);
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
