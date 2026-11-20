// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/surface/deferred_root_surface.h"

#include <algorithm>
#include <utility>

#include "flutter/fml/logging.h"
#include "flutter/fml/trace_event.h"

#if IMPELLER_SUPPORTS_RENDERING
#include "impeller/display_list/aiks_context.h"
#include "impeller/renderer/context.h"
#endif  // IMPELLER_SUPPORTS_RENDERING

namespace flutter {

struct DeferredRootSurface::DeferredFrameState {
  const SurfaceFrame* frame = nullptr;
  sk_sp<DisplayList> cached_display_list;
  std::unique_ptr<SurfaceFrame> inner_frame;
  bool inner_encoded = false;
};

DeferredRootSurface::DeferredRootSurface(std::unique_ptr<Surface> inner,
                                         ShouldDeferFn should_defer)
    : should_defer_(std::move(should_defer)),
      inner_(std::move(inner)),
      weak_factory_(this) {}

DeferredRootSurface::~DeferredRootSurface() {
  for (const std::weak_ptr<DeferredFrameState>& weak_state :
       live_deferred_frames_) {
    if (std::shared_ptr<DeferredFrameState> state = weak_state.lock()) {
      state->inner_frame.reset();
      state->inner_encoded = false;
    }
  }
  live_deferred_frames_.clear();
  active_deferred_frame_state_.reset();
}

fml::WeakPtr<DeferredRootSurface> DeferredRootSurface::GetWeakPtr() const {
  return weak_factory_.GetWeakPtr();
}

std::unique_ptr<SurfaceFrame> DeferredRootSurface::AcquireInnerFrame(
    const DlISize& size) {
  if (!IsValid() || size.width <= 0 || size.height <= 0) {
    return nullptr;
  }
  std::unique_ptr<SurfaceFrame> frame = inner_->AcquireFrame(size);
  if (frame && had_deferred_frame_) {
    frame->ClearExistingDamage();
  }
  return frame;
}

bool DeferredRootSurface::IsDeferredFrame(const SurfaceFrame& frame) const {
  if (std::shared_ptr<DeferredFrameState> state =
          active_deferred_frame_state_.lock()) {
    return state->frame == &frame;
  }
  return false;
}

sk_sp<DisplayList> DeferredRootSurface::GetOrBuildDisplayList(
    SurfaceFrame& frame) {
  if (std::shared_ptr<DeferredFrameState> state =
          active_deferred_frame_state_.lock();
      state && state->frame == &frame) {
    if (!state->cached_display_list) {
      state->cached_display_list = frame.BuildDisplayList();
    }
    return state->cached_display_list;
  }
  return frame.BuildDisplayList();
}

// |Surface|
bool DeferredRootSurface::IsValid() {
  return inner_ != nullptr && inner_->IsValid();
}

// |Surface|
std::unique_ptr<SurfaceFrame> DeferredRootSurface::AcquireFrame(
    const DlISize& size) {
  if (!IsValid() || size.width <= 0 || size.height <= 0) {
    return nullptr;
  }

  if (!should_defer_ || !should_defer_()) {
    active_deferred_frame_state_.reset();
    std::unique_ptr<SurfaceFrame> frame = inner_->AcquireFrame(size);
    if (frame && had_deferred_frame_) {
      frame->ClearExistingDamage();
      had_deferred_frame_ = false;
    }
    return frame;
  }

  TRACE_EVENT0("flutter", "DeferredRootSurface::AcquireDeferredFrame");

#if IMPELLER_SUPPORTS_RENDERING
  // Release thread-local Impeller command and descriptor pools on every
  // deferred frame even when |inner_->AcquireFrame| is skipped.
  if (std::shared_ptr<impeller::AiksContext> aiks_context =
          inner_->GetAiksContext()) {
    if (std::shared_ptr<impeller::Context> impeller_context =
            aiks_context->GetContext()) {
      impeller_context->DisposeThreadLocalCachedResources();
    }
  }
#endif  // IMPELLER_SUPPORTS_RENDERING

  std::unique_ptr<GLContextResult> context_result =
      inner_->MakeRenderContextCurrent();
  if (!context_result || !context_result->GetResult()) {
    FML_LOG(ERROR)
        << "DeferredRootSurface could not make render context current.";
    return nullptr;
  }

  had_deferred_frame_ = true;
  auto state = std::make_shared<DeferredFrameState>();
  active_deferred_frame_state_ = state;
  std::erase_if(live_deferred_frames_,
                [](const std::weak_ptr<DeferredFrameState>& weak_state) {
                  return weak_state.expired();
                });
  live_deferred_frames_.push_back(state);

  fml::WeakPtr<DeferredRootSurface> weak_self = weak_factory_.GetWeakPtr();
  SurfaceFrame::EncodeCallback encode_callback =
      [weak_self, state, size](SurfaceFrame& deferred_frame,
                               DlCanvas*) -> bool {
    TRACE_EVENT0("flutter", "DeferredRootSurface::EncodeDeferredFrame");
    if (!weak_self || !weak_self->IsValid()) {
      return false;
    }
    if (!state->cached_display_list) {
      state->cached_display_list = deferred_frame.BuildDisplayList();
    }
    if (!state->cached_display_list) {
      return false;
    }

    std::unique_ptr<SurfaceFrame> inner_frame =
        weak_self->inner_->AcquireFrame(size);
    if (!inner_frame) {
      return false;
    }
    inner_frame->ClearExistingDamage();
    inner_frame->set_submit_info(deferred_frame.submit_info());
    state->inner_frame = std::move(inner_frame);

    DlCanvas* inner_canvas = state->inner_frame->Canvas();
    if (!inner_canvas) {
      return false;
    }
    inner_canvas->DrawDisplayList(state->cached_display_list);
    if (!state->inner_frame->Encode()) {
      return false;
    }
    state->inner_encoded = true;
    return true;
  };

  SurfaceFrame::SubmitCallback submit_callback =
      [weak_self, state](SurfaceFrame& deferred_frame) -> bool {
    TRACE_EVENT0("flutter", "DeferredRootSurface::SubmitDeferredFrame");
    if (!weak_self || !weak_self->IsValid() || !state->inner_frame ||
        !state->inner_encoded) {
      return false;
    }
    state->inner_frame->set_submit_info(deferred_frame.submit_info());
    return state->inner_frame->Submit();
  };

  SurfaceFrame::FramebufferInfo framebuffer_info;
  framebuffer_info.supports_readback = true;

  auto deferred_frame = std::make_unique<SurfaceFrame>(
      /*surface=*/nullptr, framebuffer_info, encode_callback, submit_callback,
      size, std::move(context_result), /*display_list_fallback=*/true);
  state->frame = deferred_frame.get();
  return deferred_frame;
}

// |Surface|
DlMatrix DeferredRootSurface::GetRootTransformation() const {
  return inner_ ? inner_->GetRootTransformation() : DlMatrix();
}

// |Surface|
GrDirectContext* DeferredRootSurface::GetContext() {
  return inner_ ? inner_->GetContext() : nullptr;
}

// |Surface|
std::unique_ptr<GLContextResult>
DeferredRootSurface::MakeRenderContextCurrent() {
  return inner_ ? inner_->MakeRenderContextCurrent()
                : std::make_unique<GLContextDefaultResult>(false);
}

// |Surface|
bool DeferredRootSurface::ClearRenderContext() {
  return inner_ ? inner_->ClearRenderContext() : false;
}

// |Surface|
bool DeferredRootSurface::AllowsDrawingWhenGpuDisabled() const {
  return inner_ ? inner_->AllowsDrawingWhenGpuDisabled() : false;
}

// |Surface|
bool DeferredRootSurface::EnableRasterCache() const {
  return inner_ ? inner_->EnableRasterCache() : true;
}

// |Surface|
std::shared_ptr<impeller::AiksContext> DeferredRootSurface::GetAiksContext()
    const {
  return inner_ ? inner_->GetAiksContext() : nullptr;
}

// |Surface|
Surface::SurfaceData DeferredRootSurface::GetSurfaceData() const {
  return inner_ ? inner_->GetSurfaceData() : SurfaceData{};
}

}  // namespace flutter
