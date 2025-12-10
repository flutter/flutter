// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/gpu/gpu_surface_multi_view.h"

#include "common/constants.h"
#include "flow/surface_frame.h"
#include "flutter/fml/make_copyable.h"
#include "impeller/display_list/dl_dispatcher.h"
#include "impeller/renderer/backend/gles/surface_gles.h"
#include "impeller/typographer/backends/skia/typographer_context_skia.h"

namespace flutter {

  GPUSurfaceMultiView::GPUSurfaceMultiView(
    std::shared_ptr<impeller::Context> context,
    std::shared_ptr<impeller::AiksContext> aiks_context,
    const MakeRenderContextCurrentCallback& make_render_context_current_callback,
    const ClearRenderContextCallback& clear_render_context_callback,
    const EnableRasterCacheCallback& enable_raster_cache_callback,
    const GetGrContextCallback& get_gr_context_callback):
      make_render_context_current_callback_(make_render_context_current_callback),
      clear_render_context_callback_(clear_render_context_callback),
      enable_raster_cache_callback_(enable_raster_cache_callback),
      get_gr_context_callback_(get_gr_context_callback) {
  if (!context || !context->IsValid()) {
    return;
  }

  if (!aiks_context->IsValid()) {
    return;
  }

  impeller_context_ = std::move(context);
  aiks_context_ = std::move(aiks_context);
  is_valid_ = true;
}

// |Surface|
GPUSurfaceMultiView::~GPUSurfaceMultiView() = default;

// |Surface|
bool GPUSurfaceMultiView::IsValid() {
  return is_valid_;
}

// std::unique_ptr<SurfaceFrame> GPUSurfaceMultiView::AcquireFrame(const DlISize& size, int64_t view_id) {
std::unique_ptr<SurfaceFrame> GPUSurfaceMultiView::AcquireFrame(const DlISize& size) {
  if (!IsValid()) {
    FML_LOG(ERROR) << "GPU surface was invalid.";
    return nullptr;
  }
  return std::make_unique<SurfaceFrame>(
      nullptr, SurfaceFrame::FramebufferInfo{.supports_readback = true},
      [](const SurfaceFrame& surface_frame, DlCanvas* canvas) {
        return true;
      },
      [](const SurfaceFrame& surface_frame) { return true; }, size);
}

// |Surface|
DlMatrix GPUSurfaceMultiView::GetRootTransformation() const {
  // This backend does not currently support root surface transformations. Just
  // return identity.
  return {};
}

// |Surface|
GrDirectContext* GPUSurfaceMultiView::GetContext() {
  // Impeller != Skia.
  return get_gr_context_callback_();
}

// |Surface|
std::unique_ptr<GLContextResult>
GPUSurfaceMultiView::MakeRenderContextCurrent() {
  // TODO(littlegnal): Implement surface less make current
  // if (get_gpu_surface_delegate_) {
  //   auto *delegate = get_gpu_surface_delegate_(kFlutterImplicitViewId);
  //   FML_LOG(ERROR) << "GPUSurfaceMultiView::MakeRenderContextCurrent1111";
  //   return delegate->GLContextMakeCurrent();
  // }
  // return delegate_->GLContextMakeCurrent();
  return make_render_context_current_callback_();
}

// |Surface|
bool GPUSurfaceMultiView::ClearRenderContext() {
    // TODO(littlegnal): Implement surface less clear current
  // if (get_gpu_surface_delegate_) {
  //   auto *delegate = get_gpu_surface_delegate_(kFlutterImplicitViewId);
  //   return delegate->GLContextClearCurrent();
  // }
  // return delegate_->GLContextClearCurrent();
  return clear_render_context_callback_();
}

bool GPUSurfaceMultiView::AllowsDrawingWhenGpuDisabled() const {
  // On Android, all rendering APIs return true for this function
  return true;
}

// |Surface|
bool GPUSurfaceMultiView::EnableRasterCache() const {
  // return false;
  return enable_raster_cache_callback_();
}

// |Surface|
std::shared_ptr<impeller::AiksContext> GPUSurfaceMultiView::GetAiksContext()
    const {
  return aiks_context_;
}

}  // namespace flutter
