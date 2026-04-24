// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/display_list/testing/impeller/dl_test_surface_instance_impeller.h"

#include "flutter/impeller/display_list/dl_dispatcher.h"
#include "flutter/impeller/typographer/backends/skia/typographer_context_skia.h"

namespace flutter {
namespace testing {

DlSurfaceInstanceImpeller::DlSurfaceInstanceImpeller(
    std::shared_ptr<impeller::Context> context,
    std::shared_ptr<impeller::Surface> surface)
    : context_(std::move(context)),
      surface_(std::move(surface)),
      aiks_context_(context_, typographer_context_) {}

DlSurfaceInstanceImpeller::DlSurfaceInstanceImpeller(
    std::shared_ptr<impeller::Context> context,
    std::shared_ptr<impeller::RenderTarget> target)
    : context_(std::move(context)),
      target_holder_(std::move(target)),
      aiks_context_(context_, typographer_context_) {}

DlSurfaceInstanceImpeller::~DlSurfaceInstanceImpeller() = default;

inline const impeller::RenderTarget&
DlSurfaceInstanceImpeller::GetRenderTarget() const {
  if (surface_) {
    return surface_->GetRenderTarget();
  }
  if (target_holder_) {
    return *target_holder_;
  }
  FML_UNREACHABLE();
}

void DlSurfaceInstanceImpeller::Clear(const DlColor& color) {
  if (!builder_.IsEmpty()) {
    // Use the Build method to clear whatever is in the builder as it is
    // now irrelevant and ignore the returned DisplayList as it would be
    // useless to try to render it before a surface clear.
    std::ignore = builder_.Build();
  }
  builder_.Clear(color);
  DoRenderDisplayList(builder_.Build());
}

DlCanvas* DlSurfaceInstanceImpeller::GetCanvas() {
  return &builder_;
}

void DlSurfaceInstanceImpeller::RenderDisplayList(
    const sk_sp<DisplayList>& display_list) {
  Flush();
  DoRenderDisplayList(display_list);
}

void DlSurfaceInstanceImpeller::FlushSubmitCpuSync() {
  Flush();
  if (!context_->FinishQueue()) {
    FML_LOG(ERROR) << "Impeller backend did not implement FinishQueue";
    FML_UNREACHABLE();
  }
}

inline void DlSurfaceInstanceImpeller::Flush() {
  if (!builder_.IsEmpty()) {
    // Render anything accumulated previously by making calls on GetCanvas().
    DoRenderDisplayList(builder_.Build());
  }
}

void DlSurfaceInstanceImpeller::DoRenderDisplayList(
    const sk_sp<DisplayList>& display_list) {
  // RenderToTarget requires us to pass in a cull_rect, but we don't want
  // benchmarks to do extra overhead for culling, so we make a large enough
  // cull rect that the dispatcher decides to do a regular sequential dispatch.
  DlRect cull_rect = display_list->GetBounds().Expand(1.0f);
  impeller::RenderToTarget(aiks_context_.GetContentContext(), GetRenderTarget(),
                           display_list, cull_rect, false, false);
}

bool DlSurfaceInstanceImpeller::SnapshotToFile(std::string& filename) const {
  return false;
}

int DlSurfaceInstanceImpeller::width() const {
  return GetRenderTarget().GetRenderTargetSize().width;
}

int DlSurfaceInstanceImpeller::height() const {
  return GetRenderTarget().GetRenderTargetSize().height;
}

std::shared_ptr<impeller::TypographerContext>
    DlSurfaceInstanceImpeller::typographer_context_ =
        impeller::TypographerContextSkia::Make();

}  // namespace testing
}  // namespace flutter
