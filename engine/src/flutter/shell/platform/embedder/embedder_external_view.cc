// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/embedder/embedder_external_view.h"

#include "flutter/display_list/dl_builder.h"
#include "flutter/fml/trace_event.h"
#include "flutter/shell/common/dl_op_spy.h"
#include "third_party/skia/include/gpu/ganesh/GrDirectContext.h"
#include "third_party/skia/include/gpu/ganesh/GrRecordingContext.h"

namespace flutter {

static DlISize TransformedSurfaceSize(const DlISize& size,
                                      const DlMatrix& transformation) {
  const auto source_rect = DlRect::MakeSize(size);
  const auto transformed_rect =
      source_rect.TransformAndClipBounds(transformation);
  return DlIRect::RoundOut(transformed_rect).GetSize();
}

EmbedderExternalView::EmbedderExternalView(
    const DlISize& frame_size,
    const DlMatrix& surface_transformation)
    : EmbedderExternalView(frame_size, surface_transformation, {}, nullptr) {}

EmbedderExternalView::EmbedderExternalView(
    const DlISize& frame_size,
    const DlMatrix& surface_transformation,
    ViewIdentifier view_identifier,
    std::unique_ptr<EmbeddedViewParams> params)
    : render_surface_size_(
          TransformedSurfaceSize(frame_size, surface_transformation)),
      surface_transformation_(surface_transformation),
      view_identifier_(view_identifier),
      embedded_view_params_(std::move(params)),
      slice_(std::make_unique<DisplayListEmbedderViewSlice>(
          DlRect::MakeSize(frame_size))) {}

EmbedderExternalView::~EmbedderExternalView() = default;

EmbedderExternalView::RenderTargetDescriptor
EmbedderExternalView::CreateRenderTargetDescriptor() const {
  return RenderTargetDescriptor(render_surface_size_);
}

DlCanvas* EmbedderExternalView::GetCanvas() {
  return slice_->canvas();
}

DlISize EmbedderExternalView::GetRenderSurfaceSize() const {
  return render_surface_size_;
}

bool EmbedderExternalView::IsRootView() const {
  return !HasPlatformView();
}

bool EmbedderExternalView::HasPlatformView() const {
  return view_identifier_.platform_view_id.has_value();
}

const DlRegion& EmbedderExternalView::GetDlRegion() const {
  return slice_->getRegion();
}

bool EmbedderExternalView::HasEngineRenderedContents() {
  if (has_engine_rendered_contents_.has_value()) {
    return has_engine_rendered_contents_.value();
  }
  TryEndRecording();
  DlOpSpy dl_op_spy;
  slice_->dispatch(dl_op_spy);
  has_engine_rendered_contents_ = dl_op_spy.did_draw() && !slice_->is_empty();
  // NOLINTNEXTLINE(bugprone-unchecked-optional-access)
  return has_engine_rendered_contents_.value();
}

EmbedderExternalView::ViewIdentifier EmbedderExternalView::GetViewIdentifier()
    const {
  return view_identifier_;
}

const EmbeddedViewParams* EmbedderExternalView::GetEmbeddedViewParams() const {
  return embedded_view_params_.get();
}

void EmbedderExternalView::Render(DlCanvas& dl_canvas, bool clear_surface) {
  TRACE_EVENT0("flutter", "EmbedderExternalView::Render");
  TryEndRecording();
  FML_DCHECK(HasEngineRenderedContents())
      << "Unnecessarily asked to render into a render target when there was "
         "nothing to render.";

  int restore_count = dl_canvas.GetSaveCount();
  dl_canvas.SetTransform(surface_transformation_);
  if (clear_surface) {
    dl_canvas.Clear(DlColor::kTransparent());
  }
  slice_->render_into(&dl_canvas);
  dl_canvas.RestoreToCount(restore_count);
  dl_canvas.Flush();
}

void EmbedderExternalView::TryEndRecording() const {
  if (slice_->recording_ended()) {
    return;
  }
  slice_->end_recording();
}

}  // namespace flutter
