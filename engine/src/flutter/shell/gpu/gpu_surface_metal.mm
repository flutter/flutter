// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/gpu/gpu_surface_metal.h"

#import <Metal/Metal.h>
#import <QuartzCore/QuartzCore.h>

#include "flutter/common/graphics/persistent_cache.h"
#include "flutter/fml/make_copyable.h"
#include "flutter/fml/platform/darwin/cf_utils.h"
#include "flutter/fml/platform/darwin/scoped_nsobject.h"
#include "flutter/fml/trace_event.h"
#include "flutter/shell/gpu/gpu_surface_metal_delegate.h"
#include "third_party/skia/include/core/SkSurface.h"
#include "third_party/skia/include/gpu/GrBackendSurface.h"
#include "third_party/skia/include/ports/SkCFObject.h"

static_assert(!__has_feature(objc_arc), "ARC must be disabled.");

namespace flutter {

namespace {
sk_sp<SkSurface> CreateSurfaceFromMetalTexture(GrDirectContext* context,
                                               id<MTLTexture> texture,
                                               GrSurfaceOrigin origin,
                                               int sample_cnt,
                                               SkColorType color_type,
                                               sk_sp<SkColorSpace> color_space,
                                               const SkSurfaceProps* props) {
  GrMtlTextureInfo info;
  info.fTexture.reset([texture retain]);
  GrBackendTexture backend_texture(texture.width, texture.height, GrMipmapped::kNo, info);
  return SkSurface::MakeFromBackendTexture(context, backend_texture, origin, sample_cnt, color_type,
                                           color_space, props);
}
}  // namespace

GPUSurfaceMetal::GPUSurfaceMetal(GPUSurfaceMetalDelegate* delegate,
                                 sk_sp<GrDirectContext> context,
                                 bool render_to_surface)
    : delegate_(delegate),
      render_target_type_(delegate->GetRenderTargetType()),
      context_(std::move(context)),
      render_to_surface_(render_to_surface) {}

GPUSurfaceMetal::~GPUSurfaceMetal() = default;

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
        nullptr, SurfaceFrame::FramebufferInfo(),
        [](const SurfaceFrame& surface_frame, SkCanvas* canvas) { return true; });
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

  auto* mtl_layer = (CAMetalLayer*)layer;
  // Get the drawable eagerly, we will need texture object to identify target framebuffer
  fml::scoped_nsprotocol<id<CAMetalDrawable>> drawable(
      reinterpret_cast<id<CAMetalDrawable>>([[mtl_layer nextDrawable] retain]));

  if (!drawable.get()) {
    FML_LOG(ERROR) << "Could not obtain drawable from the metal layer.";
    return nullptr;
  }

  auto surface = CreateSurfaceFromMetalTexture(context_.get(), drawable.get().texture,
                                               kTopLeft_GrSurfaceOrigin,  // origin
                                               1,                         // sample count
                                               kBGRA_8888_SkColorType,    // color type
                                               nullptr,                   // colorspace
                                               nullptr                    // surface properties
  );

  if (!surface) {
    FML_LOG(ERROR) << "Could not create the SkSurface from the CAMetalLayer.";
    return nullptr;
  }

  auto submit_callback = [this, drawable](const SurfaceFrame& surface_frame,
                                          SkCanvas* canvas) -> bool {
    TRACE_EVENT0("flutter", "GPUSurfaceMetal::Submit");
    if (canvas == nullptr) {
      FML_DLOG(ERROR) << "Canvas not available.";
      return false;
    }

    {
      TRACE_EVENT0("flutter", "SkCanvas::Flush");
      canvas->flush();
    }

    uintptr_t texture = reinterpret_cast<uintptr_t>(drawable.get().texture);
    for (auto& entry : damage_) {
      if (entry.first != texture) {
        // Accumulate damage for other framebuffers
        if (surface_frame.submit_info().frame_damage) {
          entry.second.join(*surface_frame.submit_info().frame_damage);
        }
      }
    }
    // Reset accumulated damage for current framebuffer
    damage_[texture] = SkIRect::MakeEmpty();

    return delegate_->PresentDrawable(drawable);
  };

  SurfaceFrame::FramebufferInfo framebuffer_info;
  framebuffer_info.supports_readback = true;

  // Provide accumulated damage to rasterizer (area in current framebuffer that lags behind
  // front buffer)
  uintptr_t texture = reinterpret_cast<uintptr_t>(drawable.get().texture);
  auto i = damage_.find(texture);
  if (i != damage_.end()) {
    framebuffer_info.existing_damage = i->second;
  }
  framebuffer_info.supports_partial_repaint = true;
  return std::make_unique<SurfaceFrame>(std::move(surface), framebuffer_info, submit_callback);
}

std::unique_ptr<SurfaceFrame> GPUSurfaceMetal::AcquireFrameFromMTLTexture(
    const SkISize& frame_info) {
  GPUMTLTextureInfo texture = delegate_->GetMTLTexture(frame_info);
  id<MTLTexture> mtl_texture = (id<MTLTexture>)(texture.texture);

  if (!mtl_texture) {
    FML_LOG(ERROR) << "Invalid MTLTexture given by the embedder.";
    return nullptr;
  }

  sk_sp<SkSurface> surface =
      CreateSurfaceFromMetalTexture(context_.get(), mtl_texture, kTopLeft_GrSurfaceOrigin, 1,
                                    kBGRA_8888_SkColorType, nullptr, nullptr);

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

    {
      TRACE_EVENT0("flutter", "SkCanvas::Flush");
      canvas->flush();
    }

    return delegate->PresentTexture(texture);
  };

  SurfaceFrame::FramebufferInfo framebuffer_info;
  framebuffer_info.supports_readback = true;

  return std::make_unique<SurfaceFrame>(std::move(surface), std::move(framebuffer_info),
                                        submit_callback);
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

bool GPUSurfaceMetal::AllowsDrawingWhenGpuDisabled() const {
  return delegate_->AllowsDrawingWhenGpuDisabled();
}

}  // namespace flutter
