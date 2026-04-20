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
    : context_(std::move(context)), surface_(std::move(surface)) {}

DlSurfaceInstanceImpeller::~DlSurfaceInstanceImpeller() = default;

void DlSurfaceInstanceImpeller::Clear(const DlColor& color) {
  // Clear whatever is in the builder as it is now irrellevant.
  (void)builder_.Build();
  builder_.Clear(color);
  DoRenderDisplayList(builder_.Build());
}

DlCanvas* DlSurfaceInstanceImpeller::GetCanvas() {
  return &builder_;
}

void DlSurfaceInstanceImpeller::RenderDisplayList(
    const sk_sp<DisplayList>& display_list) {
  DoRenderDisplayList(builder_.Build());
  DoRenderDisplayList(display_list);
}

void DlSurfaceInstanceImpeller::FlushSubmitCpuSync() {
  DoRenderDisplayList(builder_.Build());
}

void DlSurfaceInstanceImpeller::DoRenderDisplayList(
    const sk_sp<DisplayList>& display_list) {
  if (display_list->GetRecordCount() > 0) {
    impeller::AiksContext aiks_context(context_, typographer_context_);
    impeller::RenderToTarget(aiks_context.GetContentContext(),
                             surface_->GetRenderTarget(), display_list,
                             display_list->GetBounds(), false, false);
  }
}

bool DlSurfaceInstanceImpeller::Snapshot(std::string& filename) const {
#ifdef BENCHMARKS_NO_SNAPSHOT
  return false;
#else
  return false;
#endif
}

int DlSurfaceInstanceImpeller::width() const {
  return builder_.GetBaseLayerDimensions().width;
}

int DlSurfaceInstanceImpeller::height() const {
  return builder_.GetBaseLayerDimensions().height;
}

std::shared_ptr<impeller::TypographerContext>
    DlSurfaceInstanceImpeller::typographer_context_ =
        impeller::TypographerContextSkia::Make();

}  // namespace testing
}  // namespace flutter
