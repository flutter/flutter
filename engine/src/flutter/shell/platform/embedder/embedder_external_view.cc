// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/embedder/embedder_external_view.h"
#include "flutter/fml/trace_event.h"
#include "flutter/shell/common/canvas_spy.h"

namespace flutter {

static SkISize TransformedSurfaceSize(const SkISize& size,
                                      const SkMatrix& transformation) {
  const auto source_rect = SkRect::MakeWH(size.width(), size.height());
  const auto transformed_rect = transformation.mapRect(source_rect);
  return SkISize::Make(transformed_rect.width(), transformed_rect.height());
}

EmbedderExternalView::EmbedderExternalView(
    const SkISize& frame_size,
    const SkMatrix& surface_transformation)
    : EmbedderExternalView(frame_size, surface_transformation, {}, nullptr) {}

EmbedderExternalView::EmbedderExternalView(
    const SkISize& frame_size,
    const SkMatrix& surface_transformation,
    ViewIdentifier view_identifier,
    std::unique_ptr<EmbeddedViewParams> params)
    : render_surface_size_(
          TransformedSurfaceSize(frame_size, surface_transformation)),
      surface_transformation_(surface_transformation),
      view_identifier_(view_identifier),
      embedded_view_params_(std::move(params)),
      recorder_(std::make_unique<SkPictureRecorder>()),
      canvas_spy_(std::make_unique<CanvasSpy>(
          recorder_->beginRecording(frame_size.width(), frame_size.height()))) {
}

EmbedderExternalView::~EmbedderExternalView() = default;

EmbedderExternalView::RenderTargetDescriptor
EmbedderExternalView::CreateRenderTargetDescriptor() const {
  return {view_identifier_, render_surface_size_};
}

DlCanvas* EmbedderExternalView::GetCanvas() {
  return canvas_spy_->GetSpyingCanvas();
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

bool EmbedderExternalView::HasEngineRenderedContents() const {
  return canvas_spy_->DidDrawIntoCanvas();
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

  FML_DCHECK(HasEngineRenderedContents())
      << "Unnecessarily asked to render into a render target when there was "
         "nothing to render.";

  auto picture = recorder_->finishRecordingAsPicture();
  if (!picture) {
    return false;
  }

  auto surface = render_target.GetRenderSurface();
  if (!surface) {
    return false;
  }

  FML_DCHECK(SkISize::Make(surface->width(), surface->height()) ==
             render_surface_size_);

  auto canvas = surface->getCanvas();
  if (!canvas) {
    return false;
  }

  canvas->setMatrix(surface_transformation_);
  canvas->clear(SK_ColorTRANSPARENT);
  canvas->drawPicture(picture);
  canvas->flush();

  return true;
}

}  // namespace flutter
