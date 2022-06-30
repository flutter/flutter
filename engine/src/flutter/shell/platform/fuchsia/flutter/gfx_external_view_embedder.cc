// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gfx_external_view_embedder.h"

#include <lib/ui/scenic/cpp/commands.h>
#include <lib/ui/scenic/cpp/view_token_pair.h>
#include <zircon/types.h>

#include <algorithm>  // For std::clamp

#include "flutter/fml/logging.h"
#include "flutter/fml/trace_event.h"
#include "third_party/skia/include/core/SkPicture.h"
#include "third_party/skia/include/core/SkSurface.h"

namespace flutter_runner {
namespace {

ViewMutators ParseMutatorStack(const flutter::MutatorsStack& mutators_stack) {
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

std::vector<fuchsia::ui::gfx::Plane3> ClipPlanesFromRect(SkRect rect) {
  // We will generate 4 oriented planes, one for each edge of the bounding rect.
  std::vector<fuchsia::ui::gfx::Plane3> clip_planes;
  clip_planes.resize(4);

  // Top plane.
  clip_planes[0].dist = rect.top();
  clip_planes[0].dir.x = 0.f;
  clip_planes[0].dir.y = 1.f;
  clip_planes[0].dir.z = 0.f;

  // Bottom plane.
  clip_planes[1].dist = -rect.bottom();
  clip_planes[1].dir.x = 0.f;
  clip_planes[1].dir.y = -1.f;
  clip_planes[1].dir.z = 0.f;

  // Left plane.
  clip_planes[2].dist = rect.left();
  clip_planes[2].dir.x = 1.f;
  clip_planes[2].dir.y = 0.f;
  clip_planes[2].dir.z = 0.f;

  // Right plane.
  clip_planes[3].dist = -rect.right();
  clip_planes[3].dir.x = -1.f;
  clip_planes[3].dir.y = 0.f;
  clip_planes[3].dir.z = 0.f;

  return clip_planes;
}

}  // namespace

GfxExternalViewEmbedder::GfxExternalViewEmbedder(
    std::string debug_label,
    fuchsia::ui::views::ViewToken view_token,
    scenic::ViewRefPair view_ref_pair,
    std::shared_ptr<GfxSessionConnection> session,
    std::shared_ptr<SurfaceProducer> surface_producer,
    bool intercept_all_input)
    : session_(session),
      surface_producer_(surface_producer),
      root_view_(session_->get(),
                 std::move(view_token),
                 std::move(view_ref_pair.control_ref),
                 std::move(view_ref_pair.view_ref),
                 debug_label),
      metrics_node_(session_->get()),
      layer_tree_node_(session_->get()) {
  layer_tree_node_.SetLabel("Flutter::LayerTree");
  metrics_node_.SetLabel("Flutter::MetricsWatcher");
  metrics_node_.SetEventMask(fuchsia::ui::gfx::kMetricsEventMask);
  metrics_node_.AddChild(layer_tree_node_);
  root_view_.AddChild(metrics_node_);

  // Set up the input interceptor at the top of the scene, if applicable.  It
  // will capture all input, and any unwanted input will be reinjected into
  // embedded views.
  if (intercept_all_input) {
    input_interceptor_node_.emplace(session_->get());
    input_interceptor_node_->SetLabel("Flutter::InputInterceptor");
    input_interceptor_node_->SetHitTestBehavior(
        fuchsia::ui::gfx::HitTestBehavior::kDefault);
    input_interceptor_node_->SetSemanticVisibility(false);

    metrics_node_.AddChild(input_interceptor_node_.value());
  }

  session_->Present();
}

GfxExternalViewEmbedder::~GfxExternalViewEmbedder() = default;

SkCanvas* GfxExternalViewEmbedder::GetRootCanvas() {
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

std::vector<SkCanvas*> GfxExternalViewEmbedder::GetCurrentCanvases() {
  std::vector<SkCanvas*> canvases;
  for (const auto& layer : frame_layers_) {
    // This method (for legacy reasons) expects non-root current canvases.
    if (layer.first.has_value()) {
      canvases.push_back(layer.second.canvas_spy->GetSpyingCanvas());
    }
  }
  return canvases;
}

void GfxExternalViewEmbedder::PrerollCompositeEmbeddedView(
    int view_id,
    std::unique_ptr<flutter::EmbeddedViewParams> params) {
  zx_handle_t handle = static_cast<zx_handle_t>(view_id);
  FML_CHECK(frame_layers_.count(handle) == 0);

  frame_layers_.emplace(std::make_pair(
      EmbedderLayerId{handle},
      EmbedderLayer(frame_size_, *params, flutter::RTreeFactory())));
  frame_composition_order_.push_back(handle);
}

SkCanvas* GfxExternalViewEmbedder::CompositeEmbeddedView(int view_id) {
  zx_handle_t handle = static_cast<zx_handle_t>(view_id);
  auto found = frame_layers_.find(handle);
  FML_CHECK(found != frame_layers_.end());

  return found->second.canvas_spy->GetSpyingCanvas();
}

flutter::PostPrerollResult GfxExternalViewEmbedder::PostPrerollAction(
    fml::RefPtr<fml::RasterThreadMerger> raster_thread_merger) {
  return flutter::PostPrerollResult::kSuccess;
}

void GfxExternalViewEmbedder::BeginFrame(
    SkISize frame_size,
    GrDirectContext* context,
    double device_pixel_ratio,
    fml::RefPtr<fml::RasterThreadMerger> raster_thread_merger) {
  TRACE_EVENT0("flutter", "GfxExternalViewEmbedder::BeginFrame");

  // Reset for new frame.
  Reset();
  frame_size_ = frame_size;
  frame_dpr_ = device_pixel_ratio;

  // Create the root layer.
  frame_layers_.emplace(std::make_pair(
      kRootLayerId,
      EmbedderLayer(frame_size, std::nullopt, flutter::RTreeFactory())));
  frame_composition_order_.push_back(kRootLayerId);

  // Set up the input interceptor at the top of the scene, if applicable.
  if (input_interceptor_node_.has_value()) {
    const uint64_t rect_hash =
        (static_cast<uint64_t>(frame_size_.width()) << 32) +
        frame_size_.height();

    // Create a new rect if needed for the interceptor.
    auto found_rect = scenic_interceptor_rects_.find(rect_hash);
    if (found_rect == scenic_interceptor_rects_.end()) {
      auto [emplaced_rect, success] =
          scenic_interceptor_rects_.emplace(std::make_pair(
              rect_hash, scenic::Rectangle(session_->get(), frame_size_.width(),
                                           frame_size_.height())));
      FML_CHECK(success);

      found_rect = std::move(emplaced_rect);
    }

    // TODO(fxb/): Don't hardcode elevation.
    input_interceptor_node_->SetTranslation(
        frame_size.width() * 0.5f, frame_size.height() * 0.5f,
        -kScenicElevationForInputInterceptor);
    input_interceptor_node_->SetShape(found_rect->second);
  }
}

void GfxExternalViewEmbedder::EndFrame(
    bool should_resubmit_frame,
    fml::RefPtr<fml::RasterThreadMerger> raster_thread_merger) {
  TRACE_EVENT0("flutter", "GfxExternalViewEmbedder::EndFrame");
}

void GfxExternalViewEmbedder::SubmitFrame(
    GrDirectContext* context,
    std::unique_ptr<flutter::SurfaceFrame> frame) {
  TRACE_EVENT0("flutter", "GfxExternalViewEmbedder::SubmitFrame");
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

      frame_surface_indices.emplace(
          std::make_pair(layer.first, frame_surfaces.size()));
      frame_surfaces.emplace_back(std::move(surface));
    }
  }

  // Finish recording SkPictures.
  {
    TRACE_EVENT0("flutter", "FinishRecordingPictures");

    for (const auto& surface_index : frame_surface_indices) {
      const auto& layer = frame_layers_.find(surface_index.first);
      FML_CHECK(layer != frame_layers_.end());
      layer->second.picture =
          layer->second.recorder->finishRecordingAsPicture();
      FML_CHECK(layer->second.picture != nullptr);
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
    layer_tree_node_.SetScale(inv_dpr, inv_dpr, 1.0f);

    bool first_layer = true;
    for (const auto& layer_id : frame_composition_order_) {
      const auto& layer = frame_layers_.find(layer_id);
      FML_CHECK(layer != frame_layers_.end());

      // Draw the PlatformView associated with each layer first.
      if (layer_id.has_value()) {
        FML_CHECK(layer->second.embedded_view_params.has_value());
        auto& view_params = layer->second.embedded_view_params.value();

        // Get the ScenicView structure corresponding to the platform view.
        auto found = scenic_views_.find(layer_id.value());
        FML_CHECK(found != scenic_views_.end());
        auto& view_holder = found->second;

        // Compute mutators, size, and elevation for the platform view.
        const ViewMutators view_mutators =
            ParseMutatorStack(view_params.mutatorsStack());
        const SkSize view_size = view_params.sizePoints();
        const float view_elevation =
            kScenicZElevationBetweenLayers * scenic_layer_index +
            embedded_views_height;
        FML_CHECK(view_mutators.total_transform ==
                  view_params.transformMatrix());

        // Set clips for the platform view.
        if (view_mutators.clips != view_holder.mutators.clips) {
          // Expand the clip_nodes array to fit any new nodes.
          while (view_holder.clip_nodes.size() < view_mutators.clips.size()) {
            view_holder.clip_nodes.emplace_back(
                scenic::EntityNode(session_->get()));
          }
          FML_CHECK(view_holder.clip_nodes.size() >=
                    view_mutators.clips.size());

          // Adjust and re-parent all clip rects.
          for (auto& clip_node : view_holder.clip_nodes) {
            clip_node.DetachChildren();
          }
          for (size_t c = 0; c < view_mutators.clips.size(); c++) {
            const SkMatrix& clip_transform = view_mutators.clips[c].transform;
            const SkRect& clip_rect = view_mutators.clips[c].rect;

            view_holder.clip_nodes[c].SetTranslation(
                clip_transform.getTranslateX(), clip_transform.getTranslateY(),
                0.f);
            view_holder.clip_nodes[c].SetScale(clip_transform.getScaleX(),
                                               clip_transform.getScaleY(), 1.f);
            view_holder.clip_nodes[c].SetClipPlanes(
                ClipPlanesFromRect(clip_rect));

            if (c != (view_mutators.clips.size() - 1)) {
              view_holder.clip_nodes[c].AddChild(view_holder.clip_nodes[c + 1]);
            } else {
              view_holder.clip_nodes[c].AddChild(view_holder.opacity_node);
            }
          }

          view_holder.mutators.clips = view_mutators.clips;
        }

        // Set transform and elevation for the platform view.
        if (view_mutators.transform != view_holder.mutators.transform ||
            view_elevation != view_holder.elevation) {
          view_holder.transform_node.SetTranslation(
              view_mutators.transform.getTranslateX(),
              view_mutators.transform.getTranslateY(), -view_elevation);
          view_holder.transform_node.SetScale(
              view_mutators.transform.getScaleX(),
              view_mutators.transform.getScaleY(), 1.f);

          view_holder.mutators.transform = view_mutators.transform;
          view_holder.elevation = view_elevation;
        }

        // Set HitTestBehavior for the platform view.
        if (view_holder.pending_hit_testable != view_holder.hit_testable) {
          view_holder.transform_node.SetHitTestBehavior(
              view_holder.pending_hit_testable
                  ? fuchsia::ui::gfx::HitTestBehavior::kDefault
                  : fuchsia::ui::gfx::HitTestBehavior::kSuppress);

          view_holder.hit_testable = view_holder.pending_hit_testable;
        }

        // Set opacity for the platform view.
        if (view_mutators.opacity != view_holder.mutators.opacity) {
          view_holder.opacity_node.SetOpacity(view_mutators.opacity);

          view_holder.mutators.opacity = view_mutators.opacity;
        }

        // Set size, occlusion hint, and focusable.
        if (view_size != view_holder.size ||
            view_holder.pending_occlusion_hint != view_holder.occlusion_hint ||
            view_holder.pending_focusable != view_holder.focusable) {
          view_holder.view_holder.SetViewProperties({
              .bounding_box =
                  {
                      .min = {.x = 0.f, .y = 0.f, .z = -1000.f},
                      .max = {.x = view_size.fWidth,
                              .y = view_size.fHeight,
                              .z = 0.f},
                  },
              .inset_from_min = {.x = view_holder.pending_occlusion_hint.fLeft,
                                 .y = view_holder.pending_occlusion_hint.fTop,
                                 .z = 0.f},
              .inset_from_max = {.x = view_holder.pending_occlusion_hint.fRight,
                                 .y =
                                     view_holder.pending_occlusion_hint.fBottom,
                                 .z = 0.f},
              .focus_change = view_holder.pending_focusable,
          });

          view_holder.size = view_size;
          view_holder.occlusion_hint = view_holder.pending_occlusion_hint;
          view_holder.focusable = view_holder.pending_focusable;
        }

        // Attach the ScenicView to the main scene graph.
        if (view_holder.mutators.clips.empty()) {
          layer_tree_node_.AddChild(view_holder.opacity_node);
        } else {
          layer_tree_node_.AddChild(view_holder.clip_nodes[0]);
        }

        // Account for the ScenicView's height when positioning the next layer.
        embedded_views_height += kScenicZElevationForPlatformView;
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
        FML_CHECK(scenic_layer_index <= scenic_layers_.size());
        if (scenic_layer_index == scenic_layers_.size()) {
          ScenicLayer new_layer{
              .layer_node = scenic::EntityNode(session_->get()),
              .image =
                  ScenicImage{
                      .shape_node = scenic::ShapeNode(session_->get()),
                      .material = scenic::Material(session_->get()),
                  },
              // We'll set hit regions later.
              .hit_regions = {},
          };
          new_layer.layer_node.SetLabel("Flutter::Layer");
          new_layer.layer_node.AddChild(new_layer.image.shape_node);
          new_layer.image.shape_node.SetMaterial(new_layer.image.material);
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
          FML_CHECK(success);

          found_rects = std::move(emplaced_rects);
        }
        FML_CHECK(rect_index <= found_rects->second.size());
        if (rect_index == found_rects->second.size()) {
          found_rects->second.emplace_back(scenic::Rectangle(
              session_->get(), layer->second.surface_size.width(),
              layer->second.surface_size.height()));
        }

        // Set layer shape and texture.
        // Scenic currently lacks an API to enable rendering of alpha channel;
        // Flutter Embedder also lacks an API to detect if a layer has alpha or
        // not. Alpha channels are only rendered if there is a OpacityNode
        // higher in the tree with opacity != 1. For now, assume any layer
        // beyond the first has alpha and clamp to a infinitesimally smaller
        // value than 1.  The first layer retains an opacity of 1 to avoid
        // blending with anything underneath.
        //
        // This does not cause visual problems in practice, but probably has
        // performance implications.
        const SkAlpha layer_opacity =
            first_layer ? kBackgroundLayerOpacity : kOverlayLayerOpacity;
        const float layer_elevation =
            kScenicZElevationBetweenLayers * scenic_layer_index +
            embedded_views_height;
        auto& scenic_layer = scenic_layers_[scenic_layer_index];
        auto& scenic_rect = found_rects->second[rect_index];
        auto& image = scenic_layer.image;
        image.shape_node.SetLabel("Flutter::Layer::Image");
        image.shape_node.SetShape(scenic_rect);
        image.shape_node.SetTranslation(
            layer->second.surface_size.width() * 0.5f,
            layer->second.surface_size.height() * 0.5f, -layer_elevation);
        image.material.SetColor(SK_AlphaOPAQUE, SK_AlphaOPAQUE, SK_AlphaOPAQUE,
                                layer_opacity);
        image.material.SetTexture(surface_for_layer->GetImageId());

        // We'll set hit regions expliclty on a separate ShapeNode, so the image
        // itself should be unhittable and semantically invisible.
        image.shape_node.SetHitTestBehavior(
            fuchsia::ui::gfx::HitTestBehavior::kSuppress);
        image.shape_node.SetSemanticVisibility(false);

        // Attach the ScenicLayer to the main scene graph.
        layer_tree_node_.AddChild(scenic_layer.layer_node);

        // Compute the set of non-overlapping set of bounding boxes for the
        // painted content in this layer.
        {
          FML_CHECK(layer->second.rtree);
          std::list<SkRect> intersection_rects =
              layer->second.rtree->searchNonOverlappingDrawnRects(
                  SkRect::Make(layer->second.surface_size));

          // SkRect joined_rect = SkRect::MakeEmpty();
          for (const SkRect& rect : intersection_rects) {
            auto paint_bounds =
                scenic::Rectangle(session_->get(), rect.width(), rect.height());
            auto hit_region = scenic::ShapeNode(session_->get());
            hit_region.SetLabel("Flutter::Layer::HitRegion");
            hit_region.SetShape(paint_bounds);
            hit_region.SetTranslation(rect.centerX(), rect.centerY(),
                                      -layer_elevation);
            hit_region.SetHitTestBehavior(
                fuchsia::ui::gfx::HitTestBehavior::kDefault);
            hit_region.SetSemanticVisibility(true);

            scenic_layer.layer_node.AddChild(hit_region);
            scenic_layer.hit_regions.push_back(std::move(hit_region));
          }
        }
      }

      // Reset for the next pass:
      //  +The next layer will not be the first layer.
      //  +Account for the current layer's height when positioning the next.
      first_layer = false;
      scenic_layer_index++;
    }
  }

  // Present the session to Scenic, along with surface acquire/release fencess.
  {
    TRACE_EVENT0("flutter", "SessionPresent");

    session_->Present();
  }

  // Flush pending skia operations.
  // NOTE: This operation MUST occur AFTER the `Present() ` call above. We
  // pipeline the Skia rendering work with scenic IPC, and scenic will delay
  // internally until Skia is finished. So, doing this work before calling
  // `Present()` would adversely affect performance.
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

      canvas->setMatrix(SkMatrix::I());
      canvas->clear(SK_ColorTRANSPARENT);
      canvas->drawPicture(layer->second.picture);
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

void GfxExternalViewEmbedder::EnableWireframe(bool enable) {
  session_->get()->Enqueue(
      scenic::NewSetEnableDebugViewBoundsCmd(root_view_.id(), enable));
  session_->Present();
}

void GfxExternalViewEmbedder::CreateView(int64_t view_id,
                                         ViewCallback on_view_created,
                                         GfxViewIdCallback on_view_bound) {
  FML_CHECK(scenic_views_.find(view_id) == scenic_views_.end());

  ScenicView new_view = {
      .opacity_node = scenic::OpacityNodeHACK(session_->get()),
      .transform_node = scenic::EntityNode(session_->get()),
      .view_holder = scenic::ViewHolder(
          session_->get(),
          scenic::ToViewHolderToken(zx::eventpair((zx_handle_t)view_id)),
          "Flutter::PlatformView"),
  };
  on_view_created();
  on_view_bound(new_view.view_holder.id());

  new_view.opacity_node.SetLabel("Flutter::PlatformView::OpacityMutator");
  new_view.opacity_node.AddChild(new_view.transform_node);
  new_view.transform_node.SetLabel("Flutter::PlatformView::TransformMutator");
  new_view.transform_node.SetTranslation(0.f, 0.f,
                                         -kScenicZElevationBetweenLayers);
  new_view.transform_node.Attach(new_view.view_holder);

  scenic_views_.emplace(std::make_pair(view_id, std::move(new_view)));
}

void GfxExternalViewEmbedder::DestroyView(int64_t view_id,
                                          GfxViewIdCallback on_view_unbound) {
  auto scenic_view = scenic_views_.find(view_id);
  FML_CHECK(scenic_view != scenic_views_.end());
  scenic::ResourceId resource_id = scenic_view->second.view_holder.id();

  scenic_views_.erase(scenic_view);
  on_view_unbound(resource_id);
}

void GfxExternalViewEmbedder::SetViewProperties(int64_t view_id,
                                                const SkRect& occlusion_hint,
                                                bool hit_testable,
                                                bool focusable) {
  auto found = scenic_views_.find(view_id);
  FML_CHECK(found != scenic_views_.end());
  auto& view_holder = found->second;

  view_holder.pending_occlusion_hint = occlusion_hint;
  view_holder.pending_hit_testable = hit_testable;
  view_holder.pending_focusable = focusable;
}

void GfxExternalViewEmbedder::Reset() {
  frame_layers_.clear();
  frame_composition_order_.clear();
  frame_size_ = SkISize::Make(0, 0);
  frame_dpr_ = 1.f;

  // Detach the root node to prepare for the next frame.
  layer_tree_node_.DetachChildren();

  // Clear images on all layers so they aren't cached unnecessarily.
  for (auto& layer : scenic_layers_) {
    layer.image.material.SetTexture(0);

    // Detach hit regions; otherwise, they may persist across frames
    // incorrectly.
    for (auto& hit_region : layer.hit_regions) {
      hit_region.Detach();
    }

    // Remove cached hit regions so that we don't recreate stale ones.
    layer.hit_regions.clear();
  }
}

}  // namespace flutter_runner
