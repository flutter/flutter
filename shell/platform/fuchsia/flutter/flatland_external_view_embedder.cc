// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flatland_external_view_embedder.h"
#include <cstdint>

#include "flutter/fml/trace_event.h"
#include "third_party/skia/include/core/SkPicture.h"
#include "third_party/skia/include/core/SkSurface.h"

namespace flutter_runner {

FlatlandExternalViewEmbedder::FlatlandExternalViewEmbedder(
    fuchsia::ui::views::ViewCreationToken view_creation_token,
    fuchsia::ui::views::ViewIdentityOnCreation view_identity,
    fuchsia::ui::composition::ViewBoundProtocols view_protocols,
    fidl::InterfaceRequest<fuchsia::ui::composition::ParentViewportWatcher>
        parent_viewport_watcher_request,
    std::shared_ptr<FlatlandConnection> flatland,
    std::shared_ptr<SurfaceProducer> surface_producer,
    bool intercept_all_input)
    : flatland_(flatland), surface_producer_(surface_producer) {
  flatland_->flatland()->CreateView2(
      std::move(view_creation_token), std::move(view_identity),
      std::move(view_protocols), std::move(parent_viewport_watcher_request));

  root_transform_id_ = flatland_->NextTransformId();
  flatland_->flatland()->CreateTransform(root_transform_id_);
  flatland_->flatland()->SetRootTransform(root_transform_id_);
}

FlatlandExternalViewEmbedder::~FlatlandExternalViewEmbedder() = default;

SkCanvas* FlatlandExternalViewEmbedder::GetRootCanvas() {
  auto found = frame_layers_.find(kRootLayerId);
  if (found == frame_layers_.end()) {
    FML_LOG(WARNING)
        << "No root canvas could be found. This is extremely unlikely and "
           "indicates that the external view embedder did not receive the "
           "notification to begin the frame.";
    return nullptr;
  }

  return found->second.canvas_spy->GetSpyingCanvas();
}

std::vector<SkCanvas*> FlatlandExternalViewEmbedder::GetCurrentCanvases() {
  std::vector<SkCanvas*> canvases;
  for (const auto& layer : frame_layers_) {
    // This method (for legacy reasons) expects non-root current canvases.
    if (layer.first.has_value()) {
      canvases.push_back(layer.second.canvas_spy->GetSpyingCanvas());
    }
  }
  return canvases;
}

void FlatlandExternalViewEmbedder::PrerollCompositeEmbeddedView(
    int view_id,
    std::unique_ptr<flutter::EmbeddedViewParams> params) {
  zx_handle_t handle = static_cast<zx_handle_t>(view_id);
  FML_CHECK(frame_layers_.count(handle) == 0);

  frame_layers_.emplace(std::make_pair(EmbedderLayerId{handle},
                                       EmbedderLayer(frame_size_, *params)));
  frame_composition_order_.push_back(handle);
}

SkCanvas* FlatlandExternalViewEmbedder::CompositeEmbeddedView(int view_id) {
  zx_handle_t handle = static_cast<zx_handle_t>(view_id);
  auto found = frame_layers_.find(handle);
  FML_CHECK(found != frame_layers_.end());

  return found->second.canvas_spy->GetSpyingCanvas();
}

flutter::PostPrerollResult FlatlandExternalViewEmbedder::PostPrerollAction(
    fml::RefPtr<fml::RasterThreadMerger> raster_thread_merger) {
  return flutter::PostPrerollResult::kSuccess;
}

void FlatlandExternalViewEmbedder::BeginFrame(
    SkISize frame_size,
    GrDirectContext* context,
    double device_pixel_ratio,
    fml::RefPtr<fml::RasterThreadMerger> raster_thread_merger) {
  TRACE_EVENT0("flutter", "FlatlandExternalViewEmbedder::BeginFrame");

  // Reset for new frame.
  Reset();
  frame_size_ = frame_size;

  // TODO(fxbug.dev/94000): Handle device pixel ratio.

  // Create the root layer.
  frame_layers_.emplace(
      std::make_pair(kRootLayerId, EmbedderLayer(frame_size, std::nullopt)));
  frame_composition_order_.push_back(kRootLayerId);
}

void FlatlandExternalViewEmbedder::EndFrame(
    bool should_resubmit_frame,
    fml::RefPtr<fml::RasterThreadMerger> raster_thread_merger) {
  TRACE_EVENT0("flutter", "FlatlandExternalViewEmbedder::EndFrame");
}

void FlatlandExternalViewEmbedder::SubmitFrame(
    GrDirectContext* context,
    std::unique_ptr<flutter::SurfaceFrame> frame) {
  TRACE_EVENT0("flutter", "FlatlandExternalViewEmbedder::SubmitFrame");
  std::vector<std::unique_ptr<SurfaceProducerSurface>> frame_surfaces;
  std::unordered_map<EmbedderLayerId, size_t> frame_surface_indices;

  // Create surfaces for the frame and associate them with layer IDs.
  {
    TRACE_EVENT0("flutter", "CreateSurfaces");

    for (const auto& layer : frame_layers_) {
      if (!layer.second.canvas_spy->DidDrawIntoCanvas()) {
        continue;
      }

      auto surface =
          surface_producer_->ProduceSurface(layer.second.surface_size);
      if (!surface) {
        const std::string layer_id_str =
            layer.first.has_value() ? std::to_string(layer.first.value())
                                    : "Background";
        FML_LOG(ERROR) << "Failed to create surface for layer " << layer_id_str
                       << "; size (" << layer.second.surface_size.width()
                       << ", " << layer.second.surface_size.height() << ")";
        FML_DCHECK(false);
        continue;
      }

      // If we receive an unitialized surface, we need to first create flatland
      // resource.
      if (surface->GetImageId() == 0) {
        auto image_id = flatland_->NextContentId().value;
        const auto& size = surface->GetSize();
        fuchsia::ui::composition::ImageProperties image_properties;
        image_properties.set_size({static_cast<uint32_t>(size.width()),
                                   static_cast<uint32_t>(size.height())});
        flatland_->flatland()->CreateImage(
            {image_id}, surface->GetBufferCollectionImportToken(), 0,
            std::move(image_properties));

        surface->SetImageId(image_id);
        surface->SetReleaseImageCallback([flatland = flatland_, image_id]() {
          flatland->flatland()->ReleaseImage({image_id});
        });
      }

      // Enqueue fences for the next present.
      flatland_->EnqueueAcquireFence(surface->GetAcquireFence());
      flatland_->EnqueueReleaseFence(surface->GetReleaseFence());

      frame_surface_indices.emplace(
          std::make_pair(layer.first, frame_surfaces.size()));
      frame_surfaces.emplace_back(std::move(surface));
    }
  }

  // Submit layers and platform views to Scenic in composition order.
  {
    TRACE_EVENT0("flutter", "SubmitLayers");

    size_t flatland_layer_index = 0;
    for (const auto& layer_id : frame_composition_order_) {
      const auto& layer = frame_layers_.find(layer_id);
      FML_CHECK(layer != frame_layers_.end());

      // Draw the PlatformView associated with each layer first.
      if (layer_id.has_value()) {
        FML_CHECK(layer->second.embedded_view_params.has_value());
        auto& view_params = layer->second.embedded_view_params.value();

        // Get the FlatlandView structure corresponding to the platform view.
        auto found = flatland_views_.find(layer_id.value());
        FML_CHECK(found != flatland_views_.end());
        auto& viewport = found->second;

        // Compute mutators, and size for the platform view.
        const ViewMutators view_mutators =
            ParseMutatorStack(view_params.mutatorsStack());
        const SkSize view_size = view_params.sizePoints();
        FML_CHECK(view_mutators.total_transform ==
                  view_params.transformMatrix());

        if (viewport.pending_create_viewport_callback) {
          if (view_size.fWidth && view_size.fHeight) {
            viewport.pending_create_viewport_callback(view_size);
            viewport.size = view_size;
          } else {
            FML_DLOG(WARNING)
                << "Failed to create viewport because width or height is zero.";
          }
        }

        // TODO(fxbug.dev/64201): Handle clips.

        // Set transform for the viewport.
        // TODO(fxbug.dev/94000): Handle scaling.
        if (view_mutators.transform != viewport.mutators.transform) {
          flatland_->flatland()->SetTranslation(
              viewport.transform_id,
              {static_cast<int32_t>(view_mutators.transform.getTranslateX()),
               static_cast<int32_t>(view_mutators.transform.getTranslateY())});
          viewport.mutators.transform = view_mutators.transform;
        }

        // TODO(fxbug.dev/94000): Set HitTestBehavior.
        // TODO(fxbug.dev/94000): Set opacity.

        // Set size
        // TODO(): Set occlusion hint, and focusable.
        if (view_size != viewport.size) {
          fuchsia::ui::composition::ViewportProperties properties;
          properties.set_logical_size(
              {static_cast<uint32_t>(view_size.fWidth),
               static_cast<uint32_t>(view_size.fHeight)});
          flatland_->flatland()->SetViewportProperties(viewport.viewport_id,
                                                       std::move(properties));
          viewport.size = view_size;
        }

        // Attach the FlatlandView to the main scene graph.
        flatland_->flatland()->AddChild(root_transform_id_,
                                        viewport.transform_id);
        child_transforms_.emplace_back(viewport.transform_id);
      }

      // Acquire the surface associated with the layer.
      SurfaceProducerSurface* surface_for_layer = nullptr;
      if (layer->second.canvas_spy->DidDrawIntoCanvas()) {
        const auto& surface_index = frame_surface_indices.find(layer_id);
        if (surface_index != frame_surface_indices.end()) {
          FML_CHECK(surface_index->second < frame_surfaces.size());
          surface_for_layer = frame_surfaces[surface_index->second].get();
          FML_CHECK(surface_for_layer != nullptr);
        } else {
          const std::string layer_id_str =
              layer_id.has_value() ? std::to_string(layer_id.value())
                                   : "Background";
          FML_LOG(ERROR) << "Missing surface for layer " << layer_id_str
                         << "; skipping scene graph add of layer.";
          FML_DCHECK(false);
        }
      }

      // Draw the layer if we acquired a surface for it successfully.
      if (surface_for_layer != nullptr) {
        // Create a new layer if needed for the surface.
        FML_CHECK(flatland_layer_index <= flatland_layers_.size());
        if (flatland_layer_index == flatland_layers_.size()) {
          FlatlandLayer new_layer{.transform_id = flatland_->NextTransformId()};
          flatland_->flatland()->CreateTransform(new_layer.transform_id);
          flatland_layers_.emplace_back(std::move(new_layer));
        }

        // Update the image content and set size.
        flatland_->flatland()->SetContent(
            flatland_layers_[flatland_layer_index].transform_id,
            {surface_for_layer->GetImageId()});
        flatland_->flatland()->SetImageDestinationSize(
            {surface_for_layer->GetImageId()},
            {static_cast<uint32_t>(surface_for_layer->GetSize().width()),
             static_cast<uint32_t>(surface_for_layer->GetSize().height())});

        // Flutter Embedder lacks an API to detect if a layer has alpha or not.
        // For now, we assume any layer beyond the first has alpha.
        flatland_->flatland()->SetImageBlendingFunction(
            {surface_for_layer->GetImageId()},
            flatland_layer_index == 0
                ? fuchsia::ui::composition::BlendMode::SRC
                : fuchsia::ui::composition::BlendMode::SRC_OVER);

        // Attach the FlatlandLayer to the main scene graph.
        flatland_->flatland()->AddChild(
            root_transform_id_,
            flatland_layers_[flatland_layer_index].transform_id);
        child_transforms_.emplace_back(
            flatland_layers_[flatland_layer_index].transform_id);

        // Attach full-screen hit testing shield.
        flatland_->flatland()->SetHitRegions(
            flatland_layers_[flatland_layer_index].transform_id,
            {{{0, 0, std::numeric_limits<float>::max(),
               std::numeric_limits<float>::max()},
              fuchsia::ui::composition::HitTestInteraction::
                  SEMANTICALLY_INVISIBLE}});
      }

      // Reset for the next pass:
      flatland_layer_index++;
    }
  }

  // Present the session to Scenic, along with surface acquire/release fences.
  {
    TRACE_EVENT0("flutter", "SessionPresent");

    flatland_->Present();
  }

  // Render the recorded SkPictures into the surfaces.
  {
    TRACE_EVENT0("flutter", "RasterizeSurfaces");

    for (const auto& surface_index : frame_surface_indices) {
      TRACE_EVENT0("flutter", "RasterizeSurface");

      FML_CHECK(surface_index.second < frame_surfaces.size());
      SurfaceProducerSurface* surface =
          frame_surfaces[surface_index.second].get();
      FML_CHECK(surface != nullptr);

      sk_sp<SkSurface> sk_surface = surface->GetSkiaSurface();
      FML_CHECK(sk_surface != nullptr);
      FML_CHECK(SkISize::Make(sk_surface->width(), sk_surface->height()) ==
                frame_size_);
      SkCanvas* canvas = sk_surface->getCanvas();
      FML_CHECK(canvas != nullptr);

      const auto& layer = frame_layers_.find(surface_index.first);
      FML_CHECK(layer != frame_layers_.end());
      sk_sp<SkPicture> picture =
          layer->second.recorder->finishRecordingAsPicture();
      FML_CHECK(picture != nullptr);

      canvas->setMatrix(SkMatrix::I());
      canvas->clear(SK_ColorTRANSPARENT);
      canvas->drawPicture(picture);
      canvas->flush();
    }
  }

  // Flush deferred Skia work and inform Scenic that render targets are ready.
  {
    TRACE_EVENT0("flutter", "PresentSurfaces");

    surface_producer_->SubmitSurfaces(std::move(frame_surfaces));
  }

  // Submit the underlying render-backend-specific frame for processing.
  frame->Submit();
}

void FlatlandExternalViewEmbedder::CreateView(
    int64_t view_id,
    ViewCallback on_view_created,
    FlatlandViewCreatedCallback on_view_bound) {
  FML_CHECK(flatland_views_.find(view_id) == flatland_views_.end());

  const auto transform_id = flatland_->NextTransformId();
  const auto viewport_id = flatland_->NextContentId();
  FlatlandView new_view = {.transform_id = transform_id,
                           .viewport_id = viewport_id};
  flatland_->flatland()->CreateTransform(new_view.transform_id);
  fuchsia::ui::composition::ChildViewWatcherPtr child_view_watcher;
  new_view.pending_create_viewport_callback =
      [this, transform_id, viewport_id, view_id,
       child_view_watcher_request =
           child_view_watcher.NewRequest()](const SkSize& size) mutable {
        fuchsia::ui::composition::ViewportProperties properties;
        properties.set_logical_size({static_cast<uint32_t>(size.fWidth),
                                     static_cast<uint32_t>(size.fHeight)});
        flatland_->flatland()->CreateViewport(
            viewport_id, {zx::channel((zx_handle_t)view_id)},
            std::move(properties), std::move(child_view_watcher_request));
        flatland_->flatland()->SetContent(transform_id, viewport_id);
      };

  on_view_created();
  on_view_bound(new_view.viewport_id, std::move(child_view_watcher));
  flatland_views_.emplace(std::make_pair(view_id, std::move(new_view)));
}

void FlatlandExternalViewEmbedder::DestroyView(
    int64_t view_id,
    FlatlandViewIdCallback on_view_unbound) {
  auto flatland_view = flatland_views_.find(view_id);
  FML_CHECK(flatland_view != flatland_views_.end());

  auto viewport_id = flatland_view->second.viewport_id;
  auto transform_id = flatland_view->second.transform_id;
  if (!flatland_view->second.pending_create_viewport_callback) {
    flatland_->flatland()->ReleaseViewport(viewport_id, [](auto) {});
  }
  auto itr =
      std::find_if(child_transforms_.begin(), child_transforms_.end(),
                   [transform_id](fuchsia::ui::composition::TransformId id) {
                     return id.value == transform_id.value;
                   });
  if (itr != child_transforms_.end()) {
    flatland_->flatland()->RemoveChild(root_transform_id_, transform_id);
    child_transforms_.erase(itr);
  }
  flatland_->flatland()->ReleaseTransform(transform_id);

  flatland_views_.erase(flatland_view);
  on_view_unbound(viewport_id);
}

void FlatlandExternalViewEmbedder::SetViewProperties(
    int64_t view_id,
    const SkRect& occlusion_hint,
    bool hit_testable,
    bool focusable) {
  auto found = flatland_views_.find(view_id);
  FML_CHECK(found != flatland_views_.end());

  // TODO(fxbug.dev/94000): Set occlusion_hint, hit_testable and focusable. Note
  // that pending_create_viewport_callback might not have run at this point.
}

void FlatlandExternalViewEmbedder::Reset() {
  frame_layers_.clear();
  frame_composition_order_.clear();
  frame_size_ = SkISize::Make(0, 0);

  // Clear all children from root.
  for (const auto& transform : child_transforms_) {
    flatland_->flatland()->RemoveChild(root_transform_id_, transform);
  }
  child_transforms_.clear();

  // Clear images on all layers so they aren't cached unnecessarily.
  for (const auto& layer : flatland_layers_) {
    flatland_->flatland()->SetContent(layer.transform_id, {0});
  }
}

FlatlandExternalViewEmbedder::ViewMutators
FlatlandExternalViewEmbedder::ParseMutatorStack(
    const flutter::MutatorsStack& mutators_stack) {
  ViewMutators mutators;
  SkMatrix total_transform = SkMatrix::I();
  SkMatrix transform_accumulator = SkMatrix::I();

  for (auto i = mutators_stack.Begin(); i != mutators_stack.End(); ++i) {
    const auto& mutator = *i;
    switch (mutator->GetType()) {
      case flutter::MutatorType::opacity: {
        mutators.opacity *= std::clamp(mutator->GetAlphaFloat(), 0.f, 1.f);
      } break;
      case flutter::MutatorType::transform: {
        total_transform.preConcat(mutator->GetMatrix());
        transform_accumulator.preConcat(mutator->GetMatrix());
      } break;
      case flutter::MutatorType::clip_rect: {
        mutators.clips.emplace_back(TransformedClip{
            .transform = transform_accumulator,
            .rect = mutator->GetRect(),
        });
        transform_accumulator = SkMatrix::I();
      } break;
      case flutter::MutatorType::clip_rrect: {
        mutators.clips.emplace_back(TransformedClip{
            .transform = transform_accumulator,
            .rect = mutator->GetRRect().getBounds(),
        });
        transform_accumulator = SkMatrix::I();
      } break;
      case flutter::MutatorType::clip_path: {
        mutators.clips.emplace_back(TransformedClip{
            .transform = transform_accumulator,
            .rect = mutator->GetPath().getBounds(),
        });
        transform_accumulator = SkMatrix::I();
      } break;
      default: {
        break;
      }
    }
  }
  mutators.total_transform = total_transform;
  mutators.transform = transform_accumulator;
  mutators.opacity = std::clamp(mutators.opacity, 0.f, 1.f);

  return mutators;
}

}  // namespace flutter_runner
