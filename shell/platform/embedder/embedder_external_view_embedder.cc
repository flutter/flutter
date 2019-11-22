// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/embedder/embedder_external_view_embedder.h"

#include <algorithm>

#include "flutter/shell/platform/embedder/embedder_layers.h"
#include "flutter/shell/platform/embedder/embedder_render_target.h"

namespace flutter {

EmbedderExternalViewEmbedder::EmbedderExternalViewEmbedder(
    const CreateRenderTargetCallback& create_render_target_callback,
    const PresentCallback& present_callback)
    : create_render_target_callback_(create_render_target_callback),
      present_callback_(present_callback) {
  FML_DCHECK(create_render_target_callback_);
  FML_DCHECK(present_callback_);
}

EmbedderExternalViewEmbedder::~EmbedderExternalViewEmbedder() = default;

void EmbedderExternalViewEmbedder::SetSurfaceTransformationCallback(
    SurfaceTransformationCallback surface_transformation_callback) {
  surface_transformation_callback_ = surface_transformation_callback;
}

SkMatrix EmbedderExternalViewEmbedder::GetSurfaceTransformation() const {
  if (!surface_transformation_callback_) {
    return SkMatrix{};
  }

  return surface_transformation_callback_();
}

void EmbedderExternalViewEmbedder::Reset() {
  pending_recorders_.clear();
  pending_canvas_spies_.clear();
  pending_params_.clear();
  composition_order_.clear();
}

// |ExternalViewEmbedder|
void EmbedderExternalViewEmbedder::CancelFrame() {
  Reset();
}

static FlutterBackingStoreConfig MakeBackingStoreConfig(
    const SkISize& backing_store_size) {
  FlutterBackingStoreConfig config = {};

  config.struct_size = sizeof(config);

  config.size.width = backing_store_size.width();
  config.size.height = backing_store_size.height();

  return config;
}

static SkISize TransformedSurfaceSize(const SkISize& size,
                                      const SkMatrix& transformation) {
  const auto source_rect = SkRect::MakeWH(size.width(), size.height());
  const auto transformed_rect = transformation.mapRect(source_rect);
  return SkISize::Make(transformed_rect.width(), transformed_rect.height());
}

// |ExternalViewEmbedder|
void EmbedderExternalViewEmbedder::BeginFrame(SkISize frame_size,
                                              GrContext* context,
                                              double device_pixel_ratio) {
  Reset();

  pending_frame_size_ = frame_size;
  pending_device_pixel_ratio_ = device_pixel_ratio;
  pending_surface_transformation_ = GetSurfaceTransformation();

  const auto surface_size = TransformedSurfaceSize(
      pending_frame_size_, pending_surface_transformation_);

  // Decide if we want to discard the previous root render target.
  if (root_render_target_) {
    auto surface = root_render_target_->GetRenderSurface();
    // This is unlikely to happen but the embedder could have given the
    // rasterizer a render target the previous frame that Skia could not
    // materialize into a renderable surface. Discard the target and try again.
    if (!surface) {
      root_render_target_ = nullptr;
    } else {
      auto last_surface_size =
          SkISize::Make(surface->width(), surface->height());
      if (surface_size != last_surface_size) {
        root_render_target_ = nullptr;
      }
    }
  }

  // If there is no root render target, create one now.
  // TODO(43778): This should now be moved to be later in the submit call.
  if (!root_render_target_) {
    root_render_target_ = create_render_target_callback_(
        context, MakeBackingStoreConfig(surface_size));
  }

  root_picture_recorder_ = std::make_unique<SkPictureRecorder>();
  root_picture_recorder_->beginRecording(pending_frame_size_.width(),
                                         pending_frame_size_.height());
}

// |ExternalViewEmbedder|
void EmbedderExternalViewEmbedder::PrerollCompositeEmbeddedView(
    int view_id,
    std::unique_ptr<EmbeddedViewParams> params) {
  FML_DCHECK(pending_recorders_.count(view_id) == 0);
  FML_DCHECK(pending_canvas_spies_.count(view_id) == 0);
  FML_DCHECK(pending_params_.count(view_id) == 0);
  FML_DCHECK(std::find(composition_order_.begin(), composition_order_.end(),
                       view_id) == composition_order_.end());

  pending_recorders_[view_id] = std::make_unique<SkPictureRecorder>();
  SkCanvas* recording_canvas = pending_recorders_[view_id]->beginRecording(
      pending_frame_size_.width(), pending_frame_size_.height());
  pending_canvas_spies_[view_id] =
      std::make_unique<CanvasSpy>(recording_canvas);
  pending_params_[view_id] = *params;
  composition_order_.push_back(view_id);
}

// |ExternalViewEmbedder|
std::vector<SkCanvas*> EmbedderExternalViewEmbedder::GetCurrentCanvases() {
  std::vector<SkCanvas*> canvases;
  for (const auto& spy : pending_canvas_spies_) {
    canvases.push_back(spy.second->GetSpyingCanvas());
  }
  return canvases;
}

// |ExternalViewEmbedder|
SkCanvas* EmbedderExternalViewEmbedder::CompositeEmbeddedView(int view_id) {
  auto found = pending_canvas_spies_.find(view_id);
  if (found == pending_canvas_spies_.end()) {
    FML_DCHECK(false) << "Attempted to composite a view that was not "
                         "pre-rolled.";
    return nullptr;
  }
  return found->second->GetSpyingCanvas();
}

bool EmbedderExternalViewEmbedder::RenderPictureToRenderTarget(
    sk_sp<SkPicture> picture,
    const EmbedderRenderTarget* render_target) const {
  if (!picture || render_target == nullptr) {
    return false;
  }

  auto render_surface = render_target->GetRenderSurface();

  if (!render_surface) {
    return false;
  }

  auto render_canvas = render_surface->getCanvas();

  if (render_canvas == nullptr) {
    return false;
  }

  render_canvas->setMatrix(pending_surface_transformation_);
  render_canvas->clear(SK_ColorTRANSPARENT);
  render_canvas->drawPicture(picture);
  render_canvas->flush();

  return true;
}

// |ExternalViewEmbedder|
bool EmbedderExternalViewEmbedder::SubmitFrame(GrContext* context) {
  Registry render_targets_used;
  EmbedderLayers presented_layers(pending_frame_size_,
                                  pending_device_pixel_ratio_,
                                  pending_surface_transformation_);

  if (!root_render_target_) {
    FML_LOG(ERROR)
        << "Could not acquire the root render target from the embedder.";
    return false;
  }

  // Copy the contents of the root picture recorder onto the root surface.
  if (!RenderPictureToRenderTarget(
          root_picture_recorder_->finishRecordingAsPicture(),
          root_render_target_.get())) {
    FML_LOG(ERROR) << "Could not render into the the root render target.";
    return false;
  }
  // The root picture recorder will be reset when a new frame begins.
  root_picture_recorder_.reset();

  {
    // The root surface is expressed as a layer.
    presented_layers.PushBackingStoreLayer(
        root_render_target_->GetBackingStore());
  }

  const auto surface_size = TransformedSurfaceSize(
      pending_frame_size_, pending_surface_transformation_);

  for (const auto& view_id : composition_order_) {
    FML_DCHECK(pending_recorders_.count(view_id) == 1);
    FML_DCHECK(pending_canvas_spies_.count(view_id) == 1);
    FML_DCHECK(pending_params_.count(view_id) == 1);

    const auto& params = pending_params_.at(view_id);
    auto& recorder = pending_recorders_.at(view_id);

    auto picture = recorder->finishRecordingAsPicture();
    if (!picture) {
      FML_LOG(ERROR) << "Could not finish recording into the picture before "
                        "on-screen composition.";
      return false;
    }

    // Tell the embedder that a platform view layer is present at this point.
    presented_layers.PushPlatformViewLayer(view_id, params);

    if (!pending_canvas_spies_.at(view_id)->DidDrawIntoCanvas()) {
      // Nothing was drawn into the overlay canvas, we don't need to tell the
      // embedder to composite it.
      continue;
    }

    const auto backing_store_config = MakeBackingStoreConfig(surface_size);

    RegistryKey registry_key(view_id, backing_store_config);

    auto found_render_target = registry_.find(registry_key);

    // Find a cached render target in the registry. If none exists, ask the
    // embedder for a new one.
    std::shared_ptr<EmbedderRenderTarget> render_target;
    if (found_render_target == registry_.end()) {
      render_target =
          create_render_target_callback_(context, backing_store_config);
    } else {
      render_target = found_render_target->second;
    }

    if (!render_target) {
      FML_LOG(ERROR) << "Could not acquire external render target for "
                        "on-screen composition.";
      return false;
    }

    render_targets_used[registry_key] = render_target;

    if (!RenderPictureToRenderTarget(picture, render_target.get())) {
      FML_LOG(ERROR) << "Could not render into the render target for platform "
                        "view of identifier "
                     << view_id;
      return false;
    }

    // Indicate a layer for the backing store containing contents rendered by
    // Flutter.
    presented_layers.PushBackingStoreLayer(render_target->GetBackingStore());
  }

  // Flush the layer description down to the embedder for presentation.
  presented_layers.InvokePresentCallback(present_callback_);

  // Keep the previously used render target around in case they are required
  // next frame.
  registry_ = std::move(render_targets_used);

  return true;
}

// |ExternalViewEmbedder|
SkCanvas* EmbedderExternalViewEmbedder::GetRootCanvas() {
  if (!root_picture_recorder_) {
    return nullptr;
  }
  return root_picture_recorder_->getRecordingCanvas();
}

}  // namespace flutter
