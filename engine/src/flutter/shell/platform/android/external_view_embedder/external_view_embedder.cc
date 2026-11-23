// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/external_view_embedder/external_view_embedder.h"

#include <cmath>
#include <utility>

#include "flow/view_slicer.h"
#include "flutter/common/constants.h"
#include "flutter/fml/logging.h"
#include "flutter/fml/synchronization/waitable_event.h"
#include "flutter/fml/trace_event.h"
#include "fml/make_copyable.h"

namespace flutter {

namespace {

// Converts a size in logical pixels to the whole number of physical pixels the
// platform view should be laid out at.
//
// Android view geometry is integral, so this conversion is lossy no matter
// what, but it must *round* rather than truncate. `size_points * dpr` is
// computed in double precision from a float `size_points`, so a platform view
// that exactly covers the screen lands a hair under the physical size (e.g.
// 1079.99996 for a 1080px wide screen at a device pixel ratio of 2.625).
// Truncating that drops a pixel off the right and bottom edges, and the Flutter
// content behind the platform view shows through as a thin line.
//
// See https://github.com/flutter/flutter/issues/189834.
int32_t ToPhysicalPixels(DlScalar size_points, double device_pixel_ratio) {
  return static_cast<int32_t>(std::round(size_points * device_pixel_ratio));
}

}  // namespace

AndroidExternalViewEmbedder::AndroidExternalViewEmbedder(
    const AndroidContext& android_context,
    std::shared_ptr<PlatformViewAndroidJNI> jni_facade,
    std::shared_ptr<AndroidSurfaceFactory> surface_factory,
    const TaskRunners& task_runners,
    fml::closure schedule_frame)
    : ExternalViewEmbedder(),
      android_context_(android_context),
      jni_facade_(std::move(jni_facade)),
      surface_factory_(std::move(surface_factory)),
      surface_pool_(
          std::make_shared<SurfacePool>(/*use_new_surface_methods=*/false)),
      task_runners_(task_runners),
      schedule_frame_(std::move(schedule_frame)),
      state_(std::make_shared<State>()) {}

AndroidExternalViewEmbedder::~AndroidExternalViewEmbedder() {
  state_->destroyed.store(true);
  state_->generation.fetch_add(1);
  std::lock_guard lock(state_->mutex);
  state_->in_flight = false;
  state_->pending_resume = nullptr;
}

bool AndroidExternalViewEmbedder::ReadyForNextFrame(
    const fml::closure& resume) {
  std::lock_guard lock(state_->mutex);
  if (!state_->in_flight) {
    return true;
  }
  TRACE_EVENT0("flutter", "AndroidExternalViewEmbedder::DeferredFrame");
  if (resume) {
    state_->pending_resume = resume;
  }
  return false;
}

// |ExternalViewEmbedder|
void AndroidExternalViewEmbedder::PrerollCompositeEmbeddedView(
    int64_t view_id,
    std::unique_ptr<EmbeddedViewParams> params) {
  TRACE_EVENT0("flutter",
               "AndroidExternalViewEmbedder::PrerollCompositeEmbeddedView");

  DlRect view_bounds = DlRect::MakeSize(frame_size_);
  std::unique_ptr<EmbedderViewSlice> view;
  view = std::make_unique<DisplayListEmbedderViewSlice>(view_bounds);
  slices_.insert_or_assign(view_id, std::move(view));

  composition_order_.push_back(view_id);
  // Update params only if they changed.
  if (view_params_.count(view_id) == 1 &&
      view_params_.at(view_id) == *params.get()) {
    return;
  }
  view_params_.insert_or_assign(view_id, EmbeddedViewParams(*params.get()));
}

// |ExternalViewEmbedder|
DlCanvas* AndroidExternalViewEmbedder::CompositeEmbeddedView(int64_t view_id) {
  if (slices_.count(view_id) == 1) {
    return slices_.at(view_id)->canvas();
  }
  return nullptr;
}

DlRect AndroidExternalViewEmbedder::GetViewRect(int64_t view_id) const {
  const EmbeddedViewParams& params = view_params_.at(view_id);
  // TODO(egarciad): The rect should be computed from the mutator stack.
  // (Clipping is missing)
  // https://github.com/flutter/flutter/issues/59821
  return params.finalBoundingRect();
}

// |ExternalViewEmbedder|
void AndroidExternalViewEmbedder::SubmitFlutterView(
    int64_t flutter_view_id,
    GrDirectContext* context,
    const std::shared_ptr<impeller::AiksContext>& aiks_context,
    std::unique_ptr<SurfaceFrame> frame) {
  TRACE_EVENT0("flutter", "AndroidExternalViewEmbedder::SubmitFlutterView");
  // TODO(dkwingsmt): This class only supports rendering into the implicit view.
  // Properly support multi-view in the future.
  FML_DCHECK(flutter_view_id == kFlutterImplicitViewId);

  std::vector<int32_t> newly_retired = surface_pool_->TakeRetiredLayerIds();
  pending_retired_overlay_ids_.insert(pending_retired_overlay_ids_.end(),
                                      newly_retired.begin(),
                                      newly_retired.end());

  if (!FrameHasPlatformLayers()) {
    frame->Submit();
    std::vector<int32_t> retired_ids;
    retired_ids.swap(pending_retired_overlay_ids_);
    if (presented_platform_views_) {
      TRACE_EVENT0("flutter",
                   "AndroidExternalViewEmbedder::TransitionOutOfPlatformViews");
      presented_platform_views_ = false;
      PostPlatformWork(PlatformWorkMode::kPresent, /*ops=*/{},
                       std::move(retired_ids));
    } else if (!retired_ids.empty()) {
      PostPlatformWork(PlatformWorkMode::kRetiredIdsOnly, /*ops=*/{},
                       std::move(retired_ids));
    }
    return;
  }

  if (!presented_platform_views_) {
    // Frame 0: FlutterView may still be rendering into FlutterSurfaceView until
    // the platform thread converts to FlutterImageView in the queued present
    // below. Skip SliceViews and replay every slice directly in composition
    // order onto the root canvas so Frame 0 renders complete z-ordered UI
    // without clipped overhangs, then explicitly schedule Frame 1 on the
    // platform thread so overlays render even when convertToImageView() does
    // not swap surfaces.
    for (int64_t view_id : composition_order_) {
      EmbedderViewSlice* slice = slices_.at(view_id).get();
      if (slice->canvas() != nullptr) {
        slice->end_recording();
        slice->render_into(frame->Canvas());
      }
    }
    frame->Submit();
    presented_platform_views_ = true;

    std::vector<PlatformOp> ops;
    ops.reserve(composition_order_.size());
    for (int64_t view_id : composition_order_) {
      const DlIRect view_rect = DlIRect::Round(GetViewRect(view_id));
      const EmbeddedViewParams& params = view_params_.at(view_id);
      ops.push_back(PlatformOp{
          .type = PlatformOp::Type::kDisplayPlatformView,
          .view_id = view_id,
          .x = view_rect.GetX(),
          .y = view_rect.GetY(),
          .width = view_rect.GetWidth(),
          .height = view_rect.GetHeight(),
          .view_width =
              ToPhysicalPixels(params.sizePoints().width, device_pixel_ratio_),
          .view_height =
              ToPhysicalPixels(params.sizePoints().height, device_pixel_ratio_),
          .mutators_stack = params.mutatorsStack(),
      });
    }

    std::vector<int32_t> retired_ids;
    retired_ids.swap(pending_retired_overlay_ids_);
    PostPlatformWork(PlatformWorkMode::kPresent, std::move(ops),
                     std::move(retired_ids), /*aborted_overlay_ids=*/{},
                     /*schedule_frame_after_present=*/true);
    return;
  }

  std::unordered_map<int64_t, DlRect> view_rects;
  for (auto platform_id : composition_order_) {
    view_rects[platform_id] = GetViewRect(platform_id);
  }

  std::unordered_map<int64_t, DlRect> overlay_layers =
      SliceViews(frame->Canvas(),     //
                 composition_order_,  //
                 slices_,             //
                 view_rects           //
      );

  // Submit the background canvas frame before switching the GPU context to
  // the overlay surfaces.
  frame->Submit();

  std::vector<PlatformOp> ops;
  ops.reserve(composition_order_.size() * 2);
  std::vector<int32_t> submitted_overlay_ids;
  bool aborted = false;

  for (int64_t view_id : composition_order_) {
    // Round, rather than truncate, the bounds onto the pixel grid. See
    // `ToPhysicalPixels` for why.
    const DlIRect view_rect = DlIRect::Round(GetViewRect(view_id));
    const EmbeddedViewParams& params = view_params_.at(view_id);
    ops.push_back(PlatformOp{
        .type = PlatformOp::Type::kDisplayPlatformView,
        .view_id = view_id,
        .x = view_rect.GetX(),
        .y = view_rect.GetY(),
        .width = view_rect.GetWidth(),
        .height = view_rect.GetHeight(),
        .view_width =
            ToPhysicalPixels(params.sizePoints().width, device_pixel_ratio_),
        .view_height =
            ToPhysicalPixels(params.sizePoints().height, device_pixel_ratio_),
        .mutators_stack = params.mutatorsStack(),
    });
    std::unordered_map<int64_t, DlRect>::const_iterator overlay =
        overlay_layers.find(view_id);
    if (overlay == overlay_layers.end()) {
      continue;
    }
    int32_t overlay_surface_id = 0;
    std::unique_ptr<SurfaceFrame> overlay_frame =
        CreateSurfaceIfNeeded(context,                    //
                              view_id,                    //
                              slices_.at(view_id).get(),  //
                              overlay->second,            //
                              &overlay_surface_id         //
        );
    if (overlay_frame || surface_pool_->HasPendingDestroy()) {
      overlays_may_exist_ = true;
    }
    if (!overlay_frame) {
      FML_LOG(ERROR) << "Aborting partial Hybrid Composition present after "
                        "overlay creation/acquire failed for view "
                     << view_id << ".";
      aborted = true;
      break;
    }
    overlay_frame->Submit();
    submitted_overlay_ids.push_back(overlay_surface_id);
    ops.push_back(PlatformOp{
        .type = PlatformOp::Type::kDisplayOverlaySurface,
        .surface_id = overlay_surface_id,
        .x = static_cast<int32_t>(overlay->second.GetX()),
        .y = static_cast<int32_t>(overlay->second.GetY()),
        .width = static_cast<int32_t>(overlay->second.GetWidth()),
        .height = static_cast<int32_t>(overlay->second.GetHeight()),
    });
  }

  newly_retired = surface_pool_->TakeRetiredLayerIds();
  pending_retired_overlay_ids_.insert(pending_retired_overlay_ids_.end(),
                                      newly_retired.begin(),
                                      newly_retired.end());
  std::vector<int32_t> retired_ids;
  retired_ids.swap(pending_retired_overlay_ids_);

  if (aborted) {
    ops.clear();
    // Root frame->Submit() (and any earlier overlay_frame->Submit()) already
    // enqueued buffers into ImageReaders (maxImages = 3). Drain them on the
    // platform thread without mutating view visibility so repeated aborts
    // cannot exhaust ImageReader buffers and deadlock vkAcquireNextImageKHR.
    PostPlatformWork(PlatformWorkMode::kDrainAborted, /*ops=*/{},
                     std::move(retired_ids), std::move(submitted_overlay_ids));
    return;
  }

  PostPlatformWork(PlatformWorkMode::kPresent, std::move(ops),
                   std::move(retired_ids));
}

// |ExternalViewEmbedder|
std::unique_ptr<SurfaceFrame>
AndroidExternalViewEmbedder::CreateSurfaceIfNeeded(GrDirectContext* context,
                                                   int64_t view_id,
                                                   EmbedderViewSlice* slice,
                                                   const DlRect& rect,
                                                   int32_t* out_surface_id) {
  std::shared_ptr<OverlayLayer> layer = surface_pool_->GetLayer(
      context, android_context_, jni_facade_, surface_factory_);
  if (!layer || !layer->surface) {
    return nullptr;
  }

  std::unique_ptr<SurfaceFrame> frame =
      layer->surface->AcquireFrame(frame_size_);
  if (!frame) {
    return nullptr;
  }
  *out_surface_id = layer->id;
  DlCanvas* overlay_canvas = frame->Canvas();
  overlay_canvas->Clear(DlColor::kTransparent());
  // Offset the picture since its absolute position on the scene is determined
  // by the position of the overlay view.
  overlay_canvas->Translate(-rect.GetX(), -rect.GetY());
  slice->render_into(overlay_canvas);
  return frame;
}

bool AndroidExternalViewEmbedder::FrameHasPlatformLayers() {
  return !composition_order_.empty();
}

// |ExternalViewEmbedder|
DlCanvas* AndroidExternalViewEmbedder::GetRootCanvas() {
  // On Android, the root surface is created from the on-screen render target.
  return nullptr;
}

void AndroidExternalViewEmbedder::Reset() {
  composition_order_.clear();
  slices_.clear();
}

// |ExternalViewEmbedder|
void AndroidExternalViewEmbedder::BeginFrame(GrDirectContext* context) {}

// |ExternalViewEmbedder|
void AndroidExternalViewEmbedder::PrepareFlutterView(
    DlISize frame_size,
    double device_pixel_ratio) {
  Reset();

  // Overlay layers are allocated for the current frame size, so the layers in
  // the pool can't be recycled after the size changes. Release them on the
  // raster thread and record their IDs so Java destroys them on the platform
  // thread ahead of the next present.
  if (frame_size_ != frame_size) {
    ReleaseOverlayLayers();

    // This should not block to prevent deadlocks with
    // setViewportMetrics.
    task_runners_.GetPlatformTaskRunner()->PostTask(fml::MakeCopyable(
        [jni_facade = jni_facade_, frame_size = frame_size]() {
          jni_facade->MaybeResizeSurfaceView(frame_size.width,
                                             frame_size.height);
        }));
  }
  surface_pool_->SetFrameSize(frame_size);

  frame_size_ = frame_size;
  device_pixel_ratio_ = device_pixel_ratio;
}

// |ExternalViewEmbedder|
void AndroidExternalViewEmbedder::CancelFrame() {
  Reset();
  FlushRetiredOverlayIds();
}

// |ExternalViewEmbedder|
void AndroidExternalViewEmbedder::EndFrame() {
  surface_pool_->RecycleLayers();
  FlushRetiredOverlayIds();
}

// |ExternalViewEmbedder|
void AndroidExternalViewEmbedder::Teardown() {
  FML_DCHECK(task_runners_.GetPlatformTaskRunner()->RunsTasksOnCurrentThread());

  uint64_t new_generation = state_->generation.fetch_add(1) + 1;
  bool should_destroy_java_overlays = false;
  fml::closure deferred_resume;
  fml::AutoResetWaitableEvent raster_latch;
  fml::TaskRunner::RunNowOrPostTask(
      task_runners_.GetRasterTaskRunner(),
      [this, new_generation, &should_destroy_java_overlays, &deferred_resume,
       &raster_latch]() {
        presented_platform_views_ = false;
        Reset();
        std::vector<std::shared_ptr<OverlayLayer>> layers =
            surface_pool_->TakeLayers();
        std::vector<int32_t> retired_pool_ids =
            surface_pool_->TakeRetiredLayerIds();
        should_destroy_java_overlays = overlays_may_exist_ || !layers.empty() ||
                                       !retired_pool_ids.empty() ||
                                       !pending_retired_overlay_ids_.empty();
        overlays_may_exist_ = false;
        pending_retired_overlay_ids_.clear();
        layers.clear();
        {
          std::lock_guard lock(state_->mutex);
          if (state_->generation.load() == new_generation) {
            state_->in_flight = false;
            deferred_resume = std::move(state_->pending_resume);
          }
        }
        raster_latch.Signal();
      });
  raster_latch.Wait();

  if (should_destroy_java_overlays && jni_facade_) {
    jni_facade_->FlutterViewDestroyOverlaySurfaces();
  }

  if (deferred_resume) {
    task_runners_.GetRasterTaskRunner()->PostTask(
        fml::MakeCopyable([state = state_, new_generation,
                           deferred_resume = std::move(deferred_resume)]() {
          if (state->destroyed.load() ||
              state->generation.load() != new_generation) {
            return;
          }
          deferred_resume();
        }));
  }
}

void AndroidExternalViewEmbedder::ReleaseOverlayLayers() {
  std::vector<std::shared_ptr<OverlayLayer>> layers =
      surface_pool_->TakeLayers();
  // Release the rendering surfaces on the raster thread, which renders into
  // them.
  layers.clear();
  std::vector<int32_t> newly_retired = surface_pool_->TakeRetiredLayerIds();
  pending_retired_overlay_ids_.insert(pending_retired_overlay_ids_.end(),
                                      newly_retired.begin(),
                                      newly_retired.end());
}

void AndroidExternalViewEmbedder::FlushRetiredOverlayIds() {
  std::vector<int32_t> newly_retired = surface_pool_->TakeRetiredLayerIds();
  pending_retired_overlay_ids_.insert(pending_retired_overlay_ids_.end(),
                                      newly_retired.begin(),
                                      newly_retired.end());
  if (pending_retired_overlay_ids_.empty()) {
    return;
  }
  std::vector<int32_t> retired_ids;
  retired_ids.swap(pending_retired_overlay_ids_);
  PostPlatformWork(PlatformWorkMode::kRetiredIdsOnly, /*ops=*/{},
                   std::move(retired_ids));
}

void AndroidExternalViewEmbedder::PostPlatformWork(
    PlatformWorkMode mode,
    std::vector<PlatformOp> ops,
    std::vector<int32_t> retired_ids,
    std::vector<int32_t> aborted_overlay_ids,
    bool schedule_frame_after_present) {
  if (mode == PlatformWorkMode::kRetiredIdsOnly && retired_ids.empty()) {
    return;
  }

  const bool track_in_flight = mode != PlatformWorkMode::kRetiredIdsOnly;
  uint64_t expected_generation = 0;
  {
    std::lock_guard lock(state_->mutex);
    expected_generation = state_->generation.load();
    if (track_in_flight) {
      state_->in_flight = true;
    }
  }

  const uint64_t flow_id =
      state_->next_trace_flow_id.fetch_add(1, std::memory_order_relaxed);
  TRACE_FLOW_BEGIN("flutter", "HybridCompositionPresent", flow_id);

  task_runners_.GetPlatformTaskRunner()->PostTask(fml::MakeCopyable(
      [state = state_, jni_facade = jni_facade_,
       raster_task_runner = task_runners_.GetRasterTaskRunner(),
       schedule_frame = schedule_frame_, expected_generation, flow_id, mode,
       ops = std::move(ops), retired_ids = std::move(retired_ids),
       aborted_overlay_ids = std::move(aborted_overlay_ids),
       schedule_frame_after_present]() {
        TRACE_EVENT0("flutter", "AndroidExternalViewEmbedder::Present");
        if (state->destroyed.load() ||
            state->generation.load() != expected_generation) {
          TRACE_FLOW_END("flutter", "HybridCompositionPresent", flow_id);
          return;
        }

        if (mode == PlatformWorkMode::kRetiredIdsOnly) {
          if (!retired_ids.empty()) {
            jni_facade->FlutterViewDestroyOverlaySurfacesByIds(retired_ids);
          }
          TRACE_FLOW_END("flutter", "HybridCompositionPresent", flow_id);
          return;
        }

        if (mode == PlatformWorkMode::kDrainAborted) {
          jni_facade->FlutterViewDrainAbortedFrame(aborted_overlay_ids);
          if (!retired_ids.empty()) {
            jni_facade->FlutterViewDestroyOverlaySurfacesByIds(retired_ids);
          }
        } else {
          jni_facade->FlutterViewBeginFrame();
          for (const PlatformOp& op : ops) {
            switch (op.type) {
              case PlatformOp::Type::kDisplayPlatformView:
                jni_facade->FlutterViewOnDisplayPlatformView(
                    op.view_id, op.x, op.y, op.width, op.height, op.view_width,
                    op.view_height, op.mutators_stack);
                break;
              case PlatformOp::Type::kDisplayOverlaySurface:
                jni_facade->FlutterViewDisplayOverlaySurface(
                    op.surface_id, op.x, op.y, op.width, op.height);
                break;
            }
          }
          jni_facade->FlutterViewEndFrame();
          if (!retired_ids.empty()) {
            jni_facade->FlutterViewDestroyOverlaySurfacesByIds(retired_ids);
          }
          if (schedule_frame_after_present && schedule_frame) {
            schedule_frame();
          }
        }

        TRACE_FLOW_STEP("flutter", "HybridCompositionPresent", flow_id);
        raster_task_runner->PostTask([state, expected_generation, flow_id]() {
          TRACE_EVENT0("flutter", "AndroidExternalViewEmbedder::PresentDone");
          TRACE_FLOW_END("flutter", "HybridCompositionPresent", flow_id);
          if (state->destroyed.load() ||
              state->generation.load() != expected_generation) {
            return;
          }
          fml::closure resume;
          {
            std::lock_guard lock(state->mutex);
            if (state->generation.load() != expected_generation) {
              return;
            }
            state->in_flight = false;
            resume = std::move(state->pending_resume);
          }
          if (resume) {
            resume();
          }
        });
      }));
}

}  // namespace flutter
