// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/embedder/embedder_external_view_embedder.h"

#include <algorithm>

#include "flutter/shell/platform/embedder/embedder_render_target.h"

namespace flutter {

EmbedderExternalViewEmbedder::EmbedderExternalViewEmbedder(
    CreateRenderTargetCallback create_render_target_callback,
    PresentCallback present_callback)
    : create_render_target_callback_(create_render_target_callback),
      present_callback_(present_callback) {
  FML_DCHECK(create_render_target_callback_);
  FML_DCHECK(present_callback_);
}

EmbedderExternalViewEmbedder::~EmbedderExternalViewEmbedder() = default;

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

static FlutterBackingStoreConfig MakeBackingStoreConfig(const SkISize& size) {
  FlutterBackingStoreConfig config = {};

  config.struct_size = sizeof(config);

  config.size.width = size.width();
  config.size.height = size.height();

  return config;
}

// |ExternalViewEmbedder|
void EmbedderExternalViewEmbedder::BeginFrame(SkISize frame_size,
                                              GrContext* context) {
  Reset();
  pending_frame_size_ = frame_size;

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
      if (pending_frame_size_ != last_surface_size) {
        root_render_target_ = nullptr;
      }
    }
  }

  // If there is no root render target, create one now. This will be accessed by
  // the rasterizer before the submit call layer to access the surface surface
  // canvas.
  if (!root_render_target_) {
    root_render_target_ = create_render_target_callback_(
        context, MakeBackingStoreConfig(pending_frame_size_));
  }
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

static FlutterLayer MakeLayer(const SkISize& frame_size,
                              const FlutterBackingStore* store) {
  FlutterLayer layer = {};

  layer.struct_size = sizeof(layer);
  layer.type = kFlutterLayerContentTypeBackingStore;
  layer.backing_store = store;

  layer.offset.x = 0.0;
  layer.offset.y = 0.0;

  layer.size.width = frame_size.width();
  layer.size.height = frame_size.height();

  return layer;
}

static FlutterPlatformView MakePlatformView(
    FlutterPlatformViewIdentifier identifier) {
  FlutterPlatformView view = {};

  view.struct_size = sizeof(view);

  view.identifier = identifier;

  return view;
}

static FlutterLayer MakeLayer(const EmbeddedViewParams& params,
                              const FlutterPlatformView& platform_view) {
  FlutterLayer layer = {};

  layer.struct_size = sizeof(layer);
  layer.type = kFlutterLayerContentTypePlatformView;
  layer.platform_view = &platform_view;

  layer.offset.x = params.offsetPixels.x();
  layer.offset.y = params.offsetPixels.y();

  layer.size.width = params.sizePoints.width();
  layer.size.height = params.sizePoints.height();

  return layer;
}

// |ExternalViewEmbedder|
bool EmbedderExternalViewEmbedder::SubmitFrame(GrContext* context) {
  std::map<FlutterPlatformViewIdentifier, FlutterPlatformView>
      presented_platform_views;
  // Layers may contain pointers to platform views in the collection above.
  std::vector<FlutterLayer> presented_layers;
  Registry render_targets_used;

  if (!root_render_target_) {
    FML_LOG(ERROR)
        << "Could not acquire the root render target from the embedder.";
    return false;
  }

  if (auto root_canvas = root_render_target_->GetRenderSurface()->getCanvas()) {
    root_canvas->flush();
  }

  {
    // The root surface is expressed as a layer.
    EmbeddedViewParams params;
    params.offsetPixels = SkPoint::Make(0, 0);
    params.sizePoints = pending_frame_size_;
    presented_layers.push_back(
        MakeLayer(pending_frame_size_, root_render_target_->GetBackingStore()));
  }

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

    // Indicate a layer for the platform view. Add to `presented_platform_views`
    // in order to keep at allocated just for the scope of the current method.
    // The layers presented to the embedder will contain a back pointer to this
    // struct. It is safe to deallocate when the embedder callback is done.
    presented_platform_views[view_id] = MakePlatformView(view_id);
    presented_layers.push_back(
        MakeLayer(params, presented_platform_views.at(view_id)));

    if (!pending_canvas_spies_.at(view_id)->DidDrawIntoCanvas()) {
      // Nothing was drawn into the overlay canvas, we don't need to composite
      // it.
      continue;
    }
    const auto backing_store_config =
        MakeBackingStoreConfig(pending_frame_size_);

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

    auto render_surface = render_target->GetRenderSurface();
    auto render_canvas = render_surface ? render_surface->getCanvas() : nullptr;

    if (!render_canvas) {
      FML_LOG(ERROR)
          << "Could not acquire render canvas for on-screen rendering.";
      return false;
    }

    render_canvas->clear(SK_ColorTRANSPARENT);
    render_canvas->drawPicture(picture);
    render_canvas->flush();
    // Indicate a layer for the backing store containing contents rendered by
    // Flutter.
    presented_layers.push_back(
        MakeLayer(pending_frame_size_, render_target->GetBackingStore()));
  }

  {
    std::vector<const FlutterLayer*> presented_layers_pointers;
    presented_layers_pointers.reserve(presented_layers.size());
    for (const auto& layer : presented_layers) {
      presented_layers_pointers.push_back(&layer);
    }
    present_callback_(std::move(presented_layers_pointers));
  }

  registry_ = std::move(render_targets_used);

  return true;
}

// |ExternalViewEmbedder|
sk_sp<SkSurface> EmbedderExternalViewEmbedder::GetRootSurface() {
  return root_render_target_ ? root_render_target_->GetRenderSurface()
                             : nullptr;
}

}  // namespace flutter
