// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/embedder/embedder_external_view.h"

#include "flow/embedded_views.h"
#include "flutter/fml/trace_event.h"

namespace flutter {

static SkISize TransformedSurfaceSize(const SkISize& size,
                                      const SkMatrix& transformation) {
  const auto source_rect = SkRect::MakeWH(size.width(), size.height());
  const auto transformed_rect = transformation.mapRect(source_rect);
  return SkISize::Make(transformed_rect.width(), transformed_rect.height());
}

EmbedderExternalView::EmbedderExternalView(
    const SkISize& frame_size,
    const SkMatrix& surface_transformation,
    bool enable_impeller)
    : EmbedderExternalView(frame_size,
                           surface_transformation,
                           {},
                           nullptr,
                           enable_impeller) {}

EmbedderExternalView::EmbedderExternalView(
    const SkISize& frame_size,
    const SkMatrix& surface_transformation,
    ViewIdentifier view_identifier,
    std::unique_ptr<EmbeddedViewParams> params,
    bool enable_impeller)
    : render_surface_size_(
          TransformedSurfaceSize(frame_size, surface_transformation)),
      surface_transformation_(surface_transformation),
      view_identifier_(view_identifier),
      embedded_view_params_(std::move(params)) {
#if IMPELLER_SUPPORTS_RENDERING
  if (enable_impeller) {
    slice_ =
        std::make_unique<ImpellerEmbedderViewSlice>(SkRect::Make(frame_size));
  } else {
#endif  // IMPELLER_SUPPORTS_RENDERING
    slice_ = std::make_unique<DisplayListEmbedderViewSlice>(
        SkRect::Make(frame_size));
#if IMPELLER_SUPPORTS_RENDERING
  }
#endif  // IMPELLER_SUPPORTS_RENDERING
}

EmbedderExternalView::~EmbedderExternalView() = default;

EmbedderExternalView::RenderTargetDescriptor
EmbedderExternalView::CreateRenderTargetDescriptor() const {
  return {view_identifier_, render_surface_size_};
}

DlCanvas* EmbedderExternalView::GetCanvas() {
  return slice_->canvas();
}

SkISize EmbedderExternalView::GetRenderSurfaceSize() const {
  return render_surface_size_;
}

bool EmbedderExternalView::IsRootView() const {
  return !HasPlatformView();
}

bool EmbedderExternalView::HasPlatformView() const {
  return view_identifier_.platform_view_id.has_value();
}

std::list<SkRect> EmbedderExternalView::GetEngineRenderedContentsRegion(
    const SkRect& query) const {
  return slice_->searchNonOverlappingDrawnRects(query);
}

bool EmbedderExternalView::HasEngineRenderedContents() {
  if (has_engine_rendered_contents_.has_value()) {
    return has_engine_rendered_contents_.value();
  }
  TryEndRecording();
  has_engine_rendered_contents_ = slice_->renders_anything();
  return has_engine_rendered_contents_.value();
}

EmbedderExternalView::ViewIdentifier EmbedderExternalView::GetViewIdentifier()
    const {
  return view_identifier_;
}

const EmbeddedViewParams* EmbedderExternalView::GetEmbeddedViewParams() const {
  return embedded_view_params_.get();
}

bool EmbedderExternalView::Render(const EmbedderRenderTarget& render_target) {
  TRACE_EVENT0("flutter", "EmbedderExternalView::Render");
  TryEndRecording();
  FML_DCHECK(HasEngineRenderedContents())
      << "Unnecessarily asked to render into a render target when there was "
         "nothing to render.";

#ifdef IMPELLER_SUPPORTS_RENDERING
  auto* impeller_target = render_target.GetImpellerRenderTarget();
  if (impeller_target) {
    auto aiks_context = render_target.GetAiksContext();

    impeller::DlAiksCanvas dl_canvas(
        SkRect::Make(render_target.GetRenderTargetSize()));
    dl_canvas.SetTransform(&surface_transformation_);
    slice_->render_into(&dl_canvas);

    return aiks_context->Render(dl_canvas.EndRecordingAsPicture(),
                                *impeller_target);
  }
#endif  // IMPELLER_SUPPORTS_RENDERING

  auto skia_surface = render_target.GetSkiaSurface();
  if (!skia_surface) {
    return false;
  }

  FML_DCHECK(render_target.GetRenderTargetSize() == render_surface_size_);

  auto canvas = skia_surface->getCanvas();
  if (!canvas) {
    return false;
  }
  DlSkCanvasAdapter dl_canvas(canvas);
  int restore_count = dl_canvas.GetSaveCount();
  dl_canvas.SetTransform(surface_transformation_);
  dl_canvas.Clear(DlColor::kTransparent());
  slice_->render_into(&dl_canvas);
  dl_canvas.RestoreToCount(restore_count);
  dl_canvas.Flush();

  return true;
}

void EmbedderExternalView::TryEndRecording() const {
  if (slice_->recording_ended()) {
    return;
  }
  slice_->end_recording();
}

}  // namespace flutter
