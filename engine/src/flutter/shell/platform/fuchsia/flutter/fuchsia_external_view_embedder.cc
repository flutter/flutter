// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "fuchsia_external_view_embedder.h"

#include <lib/ui/scenic/cpp/commands.h>
#include <lib/ui/scenic/cpp/view_token_pair.h>
#include <zircon/types.h>

#include <algorithm>  // For std::clamp

#include "flutter/fml/trace_event.h"
#include "third_party/skia/include/core/SkPicture.h"
#include "third_party/skia/include/core/SkSurface.h"

namespace flutter_runner {
namespace {

// Layer separation is as infinitesimal as possible without introducing
// Z-fighting.
constexpr float kScenicZElevationBetweenLayers = 0.0001f;
constexpr float kScenicZElevationForPlatformView = 100.f;

}  // namespace

FuchsiaExternalViewEmbedder::FuchsiaExternalViewEmbedder(
    std::string debug_label,
    fuchsia::ui::views::ViewToken view_token,
    scenic::ViewRefPair view_ref_pair,
    SessionConnection& session,
    VulkanSurfaceProducer& surface_producer,
    bool intercept_all_input)
    : session_(session),
      surface_producer_(surface_producer),
      root_view_(session_.get(),
                 std::move(view_token),
                 std::move(view_ref_pair.control_ref),
                 std::move(view_ref_pair.view_ref),
                 debug_label),
      metrics_node_(session_.get()),
      root_node_(session_.get()),
      intercept_all_input_(intercept_all_input) {
  root_view_.AddChild(metrics_node_);
  metrics_node_.SetEventMask(fuchsia::ui::gfx::kMetricsEventMask);
  metrics_node_.SetLabel("Flutter::MetricsWatcher");
  metrics_node_.AddChild(root_node_);
  root_node_.SetLabel("Flutter::LayerTree");

  // Set up the input interceptor at the top of the scene, if applicable.
  if (intercept_all_input_) {
    input_interceptor_.emplace(session_.get());
    metrics_node_.AddChild(input_interceptor_->node());
  }

  session_.Present();
}

FuchsiaExternalViewEmbedder::~FuchsiaExternalViewEmbedder() = default;

SkCanvas* FuchsiaExternalViewEmbedder::GetRootCanvas() {
  auto found = frame_layers_.find(kRootLayerId);
  if (found == frame_layers_.end()) {
    FML_DLOG(WARNING)
        << "No root canvas could be found. This is extremely unlikely and "
           "indicates that the external view embedder did not receive the "
           "notification to begin the frame.";
    return nullptr;
  }

  return found->second.canvas_spy->GetSpyingCanvas();
}

std::vector<SkCanvas*> FuchsiaExternalViewEmbedder::GetCurrentCanvases() {
  std::vector<SkCanvas*> canvases;
  for (const auto& layer : frame_layers_) {
    // This method (for legacy reasons) expects non-root current canvases.
    if (layer.first.has_value()) {
      canvases.push_back(layer.second.canvas_spy->GetSpyingCanvas());
    }
  }
  return canvases;
}

void FuchsiaExternalViewEmbedder::PrerollCompositeEmbeddedView(
    int view_id,
    std::unique_ptr<flutter::EmbeddedViewParams> params) {
  zx_handle_t handle = static_cast<zx_handle_t>(view_id);
  FML_DCHECK(frame_layers_.count(handle) == 0);

  frame_layers_.emplace(std::make_pair(EmbedderLayerId{handle},
                                       EmbedderLayer(frame_size_, *params)));
  frame_composition_order_.push_back(handle);
}

SkCanvas* FuchsiaExternalViewEmbedder::CompositeEmbeddedView(int view_id) {
  zx_handle_t handle = static_cast<zx_handle_t>(view_id);
  auto found = frame_layers_.find(handle);
  FML_DCHECK(found != frame_layers_.end());

  return found->second.canvas_spy->GetSpyingCanvas();
}

flutter::PostPrerollResult FuchsiaExternalViewEmbedder::PostPrerollAction(
    fml::RefPtr<fml::RasterThreadMerger> raster_thread_merger) {
  return flutter::PostPrerollResult::kSuccess;
}

void FuchsiaExternalViewEmbedder::BeginFrame(
    SkISize frame_size,
    GrDirectContext* context,
    double device_pixel_ratio,
    fml::RefPtr<fml::RasterThreadMerger> raster_thread_merger) {
  TRACE_EVENT0("flutter", "FuchsiaExternalViewEmbedder::BeginFrame");

  // Reset for new frame.
  Reset();
  frame_size_ = frame_size;
  frame_dpr_ = device_pixel_ratio;

  // Create the root layer.
  frame_layers_.emplace(
      std::make_pair(kRootLayerId, EmbedderLayer(frame_size, std::nullopt)));
  frame_composition_order_.push_back(kRootLayerId);

  // Set up the input interceptor at the top of the scene, if applicable.
  if (input_interceptor_.has_value()) {
    // TODO: Don't hardcode elevation.
    const float kMaximumElevation = -100.f;
    input_interceptor_->UpdateDimensions(session_.get(), frame_size.width(),
                                         frame_size.height(),
                                         kMaximumElevation);
  }
}

void FuchsiaExternalViewEmbedder::EndFrame(
    bool should_resubmit_frame,
    fml::RefPtr<fml::RasterThreadMerger> raster_thread_merger) {
  TRACE_EVENT0("flutter", "FuchsiaExternalViewEmbedder::EndFrame");
}

void FuchsiaExternalViewEmbedder::SubmitFrame(
    GrDirectContext* context,
    std::unique_ptr<flutter::SurfaceFrame> frame,
    const std::shared_ptr<fml::SyncSwitch>& gpu_disable_sync_switch) {
  TRACE_EVENT0("flutter", "FuchsiaExternalViewEmbedder::SubmitFrame");
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
          surface_producer_.ProduceSurface(layer.second.surface_size);
      FML_DCHECK(surface)
          << "Embedder did not return a valid render target of size ("
          << layer.second.surface_size.width() << ", "
          << layer.second.surface_size.height() << ")";

      frame_surface_indices.emplace(
          std::make_pair(layer.first, frame_surfaces.size()));
      frame_surfaces.emplace_back(std::move(surface));
    }
  }

  // Submit layers and platform views to Scenic in composition order.
  {
    TRACE_EVENT0("flutter", "SubmitLayers");

    std::unordered_map<uint64_t, size_t> scenic_rect_indices;
    size_t scenic_layer_index = 0;
    float embedded_views_height = 0.0f;

    // First re-scale everything according to the DPR.
    const float inv_dpr = 1.0f / frame_dpr_;
    root_node_.SetScale(inv_dpr, inv_dpr, 1.0f);

    bool first_layer = true;
    for (const auto& layer_id : frame_composition_order_) {
      const auto& layer = frame_layers_.find(layer_id);
      FML_DCHECK(layer != frame_layers_.end());

      // Draw the PlatformView associated with each layer first.
      if (layer_id.has_value()) {
        FML_DCHECK(layer->second.embedded_view_params.has_value());
        auto& view_params = layer->second.embedded_view_params.value();

        // Compute offset and size for the platform view.
        SkPoint view_offset =
            SkPoint::Make(view_params.finalBoundingRect().left(),
                          view_params.finalBoundingRect().top());
        SkSize view_size =
            SkSize::Make(view_params.finalBoundingRect().width(),
                         view_params.finalBoundingRect().height());

        // Compute opacity for the platform view.
        float view_opacity = 1.0f;
        for (auto i = view_params.mutatorsStack().Bottom();
             i != view_params.mutatorsStack().Top(); ++i) {
          const auto& mutator = *i;
          switch (mutator->GetType()) {
            case flutter::MutatorType::opacity: {
              view_opacity *= std::clamp(mutator->GetAlphaFloat(), 0.0f, 1.0f);
            } break;
            default: {
              break;
            }
          }
        }

        auto found = scenic_views_.find(layer_id.value());
        FML_DCHECK(found != scenic_views_.end());
        auto& view_holder = found->second;

        // Set opacity.
        if (view_opacity != view_holder.opacity) {
          view_holder.opacity_node.SetOpacity(view_opacity);
          view_holder.opacity = view_opacity;
        }

        // Set offset and elevation.
        const float view_elevation =
            kScenicZElevationBetweenLayers * scenic_layer_index +
            embedded_views_height;
        if (view_offset != view_holder.offset ||
            view_elevation != view_holder.elevation) {
          view_holder.entity_node.SetTranslation(view_offset.fX, view_offset.fY,
                                                 -view_elevation);
          view_holder.elevation = view_elevation;
        }

        // Set HitTestBehavior.
        if (view_holder.pending_hit_testable != view_holder.hit_testable) {
          view_holder.entity_node.SetHitTestBehavior(
              view_holder.pending_hit_testable
                  ? fuchsia::ui::gfx::HitTestBehavior::kDefault
                  : fuchsia::ui::gfx::HitTestBehavior::kSuppress);
          view_holder.hit_testable = view_holder.pending_hit_testable;
        }

        // Set size and focusable.
        //
        // Scenic rejects `SetViewProperties` calls with a zero size.
        if (!view_size.isEmpty() &&
            (view_size != view_holder.size ||
             view_holder.pending_focusable != view_holder.focusable)) {
          view_holder.view_holder.SetViewProperties({
              .bounding_box =
                  {
                      .min = {.x = 0.f, .y = 0.f, .z = -1000.f},
                      .max = {.x = view_size.width(),
                              .y = view_size.height(),
                              .z = 0.f},
                  },
              .inset_from_min = {.x = 0.f, .y = 0.f, .z = 0.f},
              .inset_from_max = {.x = 0.f, .y = 0.f, .z = 0.f},
              .focus_change = view_holder.pending_focusable,
          });
          view_holder.size = view_size;
          view_holder.focusable = view_holder.pending_focusable;
        }

        // Attach the ScenicView to the main scene graph.
        root_node_.AddChild(view_holder.opacity_node);

        // Account for the ScenicView's height when positioning the next layer.
        embedded_views_height += kScenicZElevationForPlatformView;
      }

      if (layer->second.canvas_spy->DidDrawIntoCanvas()) {
        const auto& surface_index = frame_surface_indices.find(layer_id);
        FML_DCHECK(surface_index != frame_surface_indices.end());
        scenic::Image* surface_image =
            frame_surfaces[surface_index->second]->GetImage();

        // Create a new layer if needed for the surface.
        FML_DCHECK(scenic_layer_index <= scenic_layers_.size());
        if (scenic_layer_index == scenic_layers_.size()) {
          ScenicLayer new_layer{
              .shape_node = scenic::ShapeNode(session_.get()),
              .material = scenic::Material(session_.get()),
          };
          new_layer.shape_node.SetMaterial(new_layer.material);
          scenic_layers_.emplace_back(std::move(new_layer));
        }

        // Compute a hash and index for the rect.
        const uint64_t rect_hash =
            (static_cast<uint64_t>(layer->second.surface_size.width()) << 32) +
            layer->second.surface_size.height();
        size_t rect_index = 0;
        auto found_index = scenic_rect_indices.find(rect_hash);
        if (found_index == scenic_rect_indices.end()) {
          scenic_rect_indices.emplace(std::make_pair(rect_hash, 0));
        } else {
          rect_index = found_index->second + 1;
          scenic_rect_indices[rect_hash] = rect_index;
        }

        // Create a new rect if needed for the surface.
        auto found_rects = scenic_rects_.find(rect_hash);
        if (found_rects == scenic_rects_.end()) {
          auto [emplaced_rects, success] = scenic_rects_.emplace(
              std::make_pair(rect_hash, std::vector<scenic::Rectangle>()));
          FML_DCHECK(success);

          found_rects = std::move(emplaced_rects);
        }
        FML_DCHECK(rect_index <= found_rects->second.size());
        if (rect_index == found_rects->second.size()) {
          found_rects->second.emplace_back(scenic::Rectangle(
              session_.get(), layer->second.surface_size.width(),
              layer->second.surface_size.height()));
        }

        // Set layer shape and texture.
        // Scenic currently lacks an API to enable rendering of alpha channel;
        // Flutter Embedder also lacks an API to detect if a layer has alpha or
        // not. Alpha channels are only rendered if there is a OpacityNode
        // higher in the tree with opacity != 1. For now, always assume t he
        // layer has alpha and clamp to a infinitesimally smaller value than 1.
        //
        // This does not cause visual problems in practice, but probably has
        // performance implications.
        auto& scenic_layer = scenic_layers_[scenic_layer_index];
        auto& scenic_rect = found_rects->second[rect_index];
        const float layer_elevation =
            kScenicZElevationBetweenLayers * scenic_layer_index +
            embedded_views_height;
        scenic_layer.shape_node.SetLabel("Flutter::Layer");
        scenic_layer.shape_node.SetShape(scenic_rect);
        scenic_layer.shape_node.SetTranslation(
            layer->second.surface_size.width() * 0.5f,
            layer->second.surface_size.height() * 0.5f, -layer_elevation);
        scenic_layer.material.SetColor(SK_AlphaOPAQUE, SK_AlphaOPAQUE,
                                       SK_AlphaOPAQUE, SK_AlphaOPAQUE - 1);
        scenic_layer.material.SetTexture(*surface_image);

        // Only the first (i.e. the bottom-most) layer should receive input.
        // TODO: Workaround for invisible overlays stealing input. Remove when
        // the underlying bug is fixed.
        if (first_layer) {
          scenic_layer.shape_node.SetHitTestBehavior(
              fuchsia::ui::gfx::HitTestBehavior::kDefault);
        } else {
          scenic_layer.shape_node.SetHitTestBehavior(
              fuchsia::ui::gfx::HitTestBehavior::kSuppress);
        }
        first_layer = false;

        // Attach the ScenicLayer to the main scene graph.
        root_node_.AddChild(scenic_layer.shape_node);

        // Account for the ScenicLayer's height when positioning the next layer.
        scenic_layer_index++;
      }
    }
  }

  // Present the session to Scenic, along with surface acquire/release fencess.
  {
    TRACE_EVENT0("flutter", "SessionPresent");

    session_.Present();
  }

  // Render the recorded SkPictures into the surfaces.
  {
    TRACE_EVENT0("flutter", "RasterizeSurfaces");

    for (const auto& surface_index : frame_surface_indices) {
      TRACE_EVENT0("flutter", "RasterizeSurface");

      const auto& layer = frame_layers_.find(surface_index.first);
      FML_DCHECK(layer != frame_layers_.end());
      sk_sp<SkPicture> picture =
          layer->second.recorder->finishRecordingAsPicture();
      FML_DCHECK(picture);

      sk_sp<SkSurface> sk_surface =
          frame_surfaces[surface_index.second]->GetSkiaSurface();
      FML_DCHECK(sk_surface);
      FML_DCHECK(SkISize::Make(sk_surface->width(), sk_surface->height()) ==
                 frame_size_);

      SkCanvas* canvas = sk_surface->getCanvas();
      FML_DCHECK(canvas);

      canvas->setMatrix(SkMatrix::I());
      canvas->clear(SK_ColorTRANSPARENT);
      canvas->drawPicture(picture);
      canvas->flush();
    }
  }

  // Flush deferred Skia work and inform Scenic that render targets are ready.
  {
    TRACE_EVENT0("flutter", "PresentSurfaces");

    surface_producer_.OnSurfacesPresented(std::move(frame_surfaces));
  }

  // Submit the underlying render-backend-specific frame for processing.
  frame->Submit();
}

void FuchsiaExternalViewEmbedder::EnableWireframe(bool enable) {
  session_.get()->Enqueue(
      scenic::NewSetEnableDebugViewBoundsCmd(root_view_.id(), enable));
  session_.Present();
}

void FuchsiaExternalViewEmbedder::CreateView(int64_t view_id) {
  FML_DCHECK(scenic_views_.find(view_id) == scenic_views_.end());

  ScenicView new_view = {
      .opacity_node = scenic::OpacityNodeHACK(session_.get()),
      .entity_node = scenic::EntityNode(session_.get()),
      .view_holder = scenic::ViewHolder(
          session_.get(),
          scenic::ToViewHolderToken(zx::eventpair((zx_handle_t)view_id)),
          "Flutter::PlatformView"),
  };

  new_view.opacity_node.SetLabel("flutter::PlatformView::OpacityMutator");
  new_view.entity_node.SetLabel("flutter::PlatformView::TransformMutator");
  new_view.opacity_node.AddChild(new_view.entity_node);
  new_view.entity_node.Attach(new_view.view_holder);
  new_view.entity_node.SetTranslation(0.f, 0.f,
                                      -kScenicZElevationBetweenLayers);

  scenic_views_.emplace(std::make_pair(view_id, std::move(new_view)));
}

void FuchsiaExternalViewEmbedder::DestroyView(int64_t view_id) {
  size_t erased = scenic_views_.erase(view_id);
  FML_DCHECK(erased == 1);
}

void FuchsiaExternalViewEmbedder::SetViewProperties(int64_t view_id,
                                                    bool hit_testable,
                                                    bool focusable) {
  auto found = scenic_views_.find(view_id);
  FML_DCHECK(found != scenic_views_.end());
  auto& view_holder = found->second;

  view_holder.pending_hit_testable = hit_testable;
  view_holder.pending_focusable = focusable;
}

void FuchsiaExternalViewEmbedder::Reset() {
  frame_layers_.clear();
  frame_composition_order_.clear();
  frame_size_ = SkISize::Make(0, 0);
  frame_dpr_ = 1.f;

  // Detach the root node to prepare for the next frame.
  session_.get()->Enqueue(scenic::NewDetachChildrenCmd(root_node_.id()));

  // Clear images on all layers so they aren't cached unnecesarily.
  for (auto& layer : scenic_layers_) {
    layer.material.SetTexture(0);
  }

  input_interceptor_.reset();
}

}  // namespace flutter_runner
