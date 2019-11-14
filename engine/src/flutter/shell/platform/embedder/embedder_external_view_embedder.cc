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

static FlutterLayer MakeBackingStoreLayer(
    const SkISize& frame_size,
    const FlutterBackingStore* store,
    const SkMatrix& surface_transformation) {
  FlutterLayer layer = {};

  layer.struct_size = sizeof(layer);
  layer.type = kFlutterLayerContentTypeBackingStore;
  layer.backing_store = store;

  const auto layer_bounds =
      SkRect::MakeWH(frame_size.width(), frame_size.height());

  const auto transformed_layer_bounds =
      surface_transformation.mapRect(layer_bounds);

  layer.offset.x = transformed_layer_bounds.x();
  layer.offset.y = transformed_layer_bounds.y();
  layer.size.width = transformed_layer_bounds.width();
  layer.size.height = transformed_layer_bounds.height();

  return layer;
}

static FlutterPlatformView MakePlatformView(
    FlutterPlatformViewIdentifier identifier) {
  FlutterPlatformView view = {};

  view.struct_size = sizeof(view);

  view.identifier = identifier;

  return view;
}

static FlutterLayer MakePlatformViewLayer(
    const EmbeddedViewParams& params,
    const FlutterPlatformView& platform_view,
    const SkMatrix& surface_transformation,
    double device_pixel_ratio) {
  FlutterLayer layer = {};

  layer.struct_size = sizeof(layer);
  layer.type = kFlutterLayerContentTypePlatformView;
  layer.platform_view = &platform_view;

  const auto layer_bounds = SkRect::MakeXYWH(params.offsetPixels.x(),    //
                                             params.offsetPixels.y(),    //
                                             params.sizePoints.width(),  //
                                             params.sizePoints.height()  //
  );

  const auto transformed_layer_bounds =
      SkMatrix::Concat(surface_transformation,
                       SkMatrix::MakeScale(device_pixel_ratio))
          .mapRect(layer_bounds);

  layer.offset.x = transformed_layer_bounds.x();
  layer.offset.y = transformed_layer_bounds.y();
  layer.size.width = transformed_layer_bounds.width();
  layer.size.height = transformed_layer_bounds.height();

  return layer;
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
    presented_layers.push_back(MakeBackingStoreLayer(
        pending_frame_size_,                     // frame size
        root_render_target_->GetBackingStore(),  // backing store
        pending_surface_transformation_          // surface transformation
        ));
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

    // Indicate a layer for the platform view. Add to `presented_platform_views`
    // in order to keep at allocated just for the scope of the current method.
    // The layers presented to the embedder will contain a back pointer to this
    // struct. It is safe to deallocate when the embedder callback is done.
    presented_platform_views[view_id] = MakePlatformView(view_id);
    presented_layers.push_back(MakePlatformViewLayer(
        params,                                // embedded view params
        presented_platform_views.at(view_id),  // platform view
        pending_surface_transformation_,       // surface transformation
        pending_device_pixel_ratio_            // device pixel ratio
        ));

    if (!pending_canvas_spies_.at(view_id)->DidDrawIntoCanvas()) {
      // Nothing was drawn into the overlay canvas, we don't need to composite
      // it.
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
    presented_layers.push_back(MakeBackingStoreLayer(
        pending_frame_size_,               // frame size
        render_target->GetBackingStore(),  // backing store
        pending_surface_transformation_    // surface transformation
        ));
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
SkCanvas* EmbedderExternalViewEmbedder::GetRootCanvas() {
  if (!root_picture_recorder_) {
    return nullptr;
  }
  return root_picture_recorder_->getRecordingCanvas();
}

}  // namespace flutter
