// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/external_view_embedder/external_view_embedder.h"

#include <cmath>
#include <utility>

#include "flow/view_slicer.h"
#include "flutter/common/constants.h"
#include "flutter/fml/logging.h"
#include "flutter/fml/make_copyable.h"
#include "flutter/fml/synchronization/waitable_event.h"
#include "flutter/fml/trace_event.h"

namespace flutter {

namespace {

constexpr const char* kPacketTraceCategory = "flutter";
constexpr const char* kPacketTraceFlowName = "HybridCompositionFramePacket";
// Maximum consecutive ScheduleFrame retries after aborted Hybrid Composition
// submits so persistent OOM or GPU loss cannot spin indefinitely every VSync.
constexpr int kMaxConsecutiveAbortRetries = 3;

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

struct PendingViewEntry {
  int64_t view_id = 0;
  DlIRect view_bounds;
  int32_t physical_width = 0;
  int32_t physical_height = 0;
  MutatorsStack mutators_stack;
  ImageLayer* submitted_overlay_layer = nullptr;
  DlIRect overlay_bounds;
};

}  // namespace

AndroidExternalViewEmbedder::AndroidExternalViewEmbedder(
    const AndroidContext& android_context,
    std::shared_ptr<PlatformViewAndroidJNI> jni_facade,
    std::shared_ptr<AndroidSurfaceFactory> surface_factory,
    const TaskRunners& task_runners,
    std::shared_ptr<HybridCompositionState> hc_state,
    std::shared_ptr<DeferredRootSurfaceSlot> deferred_root_surface_slot,
    ScheduleFrameCallback schedule_frame_callback)
    : ExternalViewEmbedder(),
      android_context_(android_context),
      jni_facade_(std::move(jni_facade)),
      surface_factory_(std::move(surface_factory)),
      task_runners_(task_runners),
      hc_state_(hc_state ? std::move(hc_state)
                         : std::make_shared<HybridCompositionState>()),
      deferred_root_surface_slot_(std::move(deferred_root_surface_slot)),
      schedule_frame_callback_(std::move(schedule_frame_callback)),
      mailbox_(std::make_shared<FramePacketMailbox>()) {
  // Unused field silence guard when building without HCPP context inspection.
  (void)android_context_;
}

AndroidExternalViewEmbedder::~AndroidExternalViewEmbedder() {
  std::unique_ptr<FramePacket> pending = mailbox_->CloseAndTake();
  if (pending) {
    TRACE_FLOW_END(kPacketTraceCategory, kPacketTraceFlowName,
                   pending->trace_flow_id);
    pending.reset();
  }
  const bool destroyed = image_layer_pool_.DestroyAllLayers();
  RestoreRootRenderContextIfNeeded(destroyed);
  hc_background_synchronized_ = false;
  if (hc_state_) {
    hc_state_->hc_session_active.store(false, std::memory_order_release);
  }
}

// |ExternalViewEmbedder|
void AndroidExternalViewEmbedder::PrerollCompositeEmbeddedView(
    int64_t view_id,
    std::unique_ptr<EmbeddedViewParams> params) {
  TRACE_EVENT0("flutter",
               "AndroidExternalViewEmbedder::PrerollCompositeEmbeddedView");

  DlRect view_bounds = DlRect::MakeSize(frame_size_);
  std::unique_ptr<EmbedderViewSlice> view =
      std::make_unique<DisplayListEmbedderViewSlice>(view_bounds);
  slices_.insert_or_assign(view_id, std::move(view));

  composition_order_.push_back(view_id);
  if (view_params_.count(view_id) == 1 &&
      view_params_.at(view_id) == *params.get()) {
    return;
  }
  view_params_.insert_or_assign(view_id, EmbeddedViewParams(*params.get()));
}

// |ExternalViewEmbedder|
DlCanvas* AndroidExternalViewEmbedder::CompositeEmbeddedView(int64_t view_id) {
  auto it = slices_.find(view_id);
  if (it != slices_.end() && it->second != nullptr) {
    return it->second->canvas();
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

DeferredRootSurface* AndroidExternalViewEmbedder::GetDeferredRootSurface()
    const {
  if (!deferred_root_surface_slot_ ||
      !deferred_root_surface_slot_->has_value()) {
    return nullptr;
  }
  const fml::WeakPtr<DeferredRootSurface>& weak_surface =
      **deferred_root_surface_slot_;
  return weak_surface ? weak_surface.get() : nullptr;
}

sk_sp<DisplayList> AndroidExternalViewEmbedder::GetRootDisplayList(
    SurfaceFrame& frame) const {
  if (DeferredRootSurface* deferred_root = GetDeferredRootSurface()) {
    return deferred_root->GetOrBuildDisplayList(frame);
  }
  return frame.BuildDisplayList();
}

void AndroidExternalViewEmbedder::RestoreRootRenderContextIfNeeded(
    bool destroyed_any_layer) const {
  if (!destroyed_any_layer) {
    return;
  }
  if (DeferredRootSurface* deferred_root = GetDeferredRootSurface()) {
    deferred_root->MakeRenderContextCurrent();
  }
}

void AndroidExternalViewEmbedder::FlattenSlicesIntoCanvas(
    DlCanvas* canvas,
    std::optional<DlIRect> clip_damage) const {
  if (canvas == nullptr) {
    return;
  }
  DlAutoCanvasRestore save(canvas, clip_damage.has_value());
  if (clip_damage.has_value()) {
    canvas->ClipRect(DlRect::Make(*clip_damage));
  }
  for (int64_t view_id : composition_order_) {
    auto slice_it = slices_.find(view_id);
    if (slice_it == slices_.end() || !slice_it->second) {
      continue;
    }
    if (slice_it->second->canvas() != nullptr) {
      slice_it->second->end_recording();
    }
    slice_it->second->render_into(canvas);
  }
}

void AndroidExternalViewEmbedder::AbortFrameAndScheduleRetry(
    const std::vector<ImageLayer*>& unacquired_submitted_layers,
    bool destroyed_any_layer) {
  TRACE_EVENT0("flutter",
               "AndroidExternalViewEmbedder::AbortFrameAndScheduleRetry");
  if (jni_facade_) {
    for (ImageLayer* layer : unacquired_submitted_layers) {
      if (layer != nullptr && layer->reader_handle != nullptr) {
        HybridJavaGlobalRef stale_image = jni_facade_->AcquireLatestHybridImage(
            layer->reader_handle->reader());
        if (stale_image) {
          layer->reader_handle->ReleaseImage(std::move(stale_image));
        }
      }
    }
  }
  RestoreRootRenderContextIfNeeded(destroyed_any_layer);
  last_submit_succeeded_ = false;
  ScheduleRetryFrameIfAllowed();
}

void AndroidExternalViewEmbedder::PostScheduleFrame() const {
  if (const fml::RefPtr<fml::TaskRunner>& platform_runner =
          task_runners_.GetPlatformTaskRunner()) {
    platform_runner->PostTask([schedule_frame = schedule_frame_callback_]() {
      if (schedule_frame) {
        schedule_frame();
      }
    });
  }
}

void AndroidExternalViewEmbedder::ScheduleRetryFrameIfAllowed() {
  if (consecutive_abort_retries_ >= kMaxConsecutiveAbortRetries) {
    FML_LOG(ERROR) << "Reached Hybrid Composition retry limit ("
                   << kMaxConsecutiveAbortRetries
                   << " consecutive failures); skipping ScheduleFrame retry.";
    return;
  }
  ++consecutive_abort_retries_;
  PostScheduleFrame();
}

void AndroidExternalViewEmbedder::PublishPacket(
    std::unique_ptr<FramePacket> packet) {
  FramePacketMailbox::PublishResult publish_result =
      mailbox_->Publish(std::move(packet));
  if (publish_result.superseded_packet) {
    TRACE_FLOW_STEP(kPacketTraceCategory, kPacketTraceFlowName,
                    publish_result.superseded_packet->trace_flow_id);
    TRACE_FLOW_END(kPacketTraceCategory, kPacketTraceFlowName,
                   publish_result.superseded_packet->trace_flow_id);
    publish_result.superseded_packet.reset();
  }
  if (!publish_result.accepted || !publish_result.schedule_drain) {
    return;
  }
  const fml::RefPtr<fml::TaskRunner>& platform_runner =
      task_runners_.GetPlatformTaskRunner();
  if (!platform_runner) {
    std::unique_ptr<FramePacket> unscheduled = mailbox_->Take();
    if (unscheduled) {
      TRACE_FLOW_END(kPacketTraceCategory, kPacketTraceFlowName,
                     unscheduled->trace_flow_id);
    }
    return;
  }
  platform_runner->PostTask(
      [mailbox = mailbox_, hc_state = hc_state_, jni_facade = jni_facade_]() {
        DrainMailboxOnPlatformThread(mailbox, hc_state, jni_facade);
      });
}

void AndroidExternalViewEmbedder::DrainMailboxOnPlatformThread(
    const std::shared_ptr<FramePacketMailbox>& mailbox,
    const std::shared_ptr<HybridCompositionState>& hc_state,
    const std::shared_ptr<PlatformViewAndroidJNI>& jni_facade) {
  TRACE_EVENT0("flutter", "AndroidExternalViewEmbedder::DrainPacket");
  std::unique_ptr<FramePacket> packet = mailbox->Take();
  if (!packet) {
    return;
  }
  TRACE_FLOW_END(kPacketTraceCategory, kPacketTraceFlowName,
                 packet->trace_flow_id);

  const uint64_t live_epoch =
      hc_state ? hc_state->hc_epoch.load(std::memory_order_acquire) : 0;
  if (packet->hc_epoch != live_epoch || !jni_facade) {
    // Epoch advanced (OnPreEngineRestart, NotifyDestroyed, or Teardown);
    // destroying |packet| releases all acquired images automatically.
    return;
  }

  if (packet->background_image) {
    const HybridJavaGlobalRef& bg_reader = packet->background_image.reader();
    jni_facade->FlutterViewBeginHybridFrame(
        packet->background_image.TakeImage(), bg_reader);
  } else {
    jni_facade->FlutterViewBeginHybridFrame(HybridJavaGlobalRef(),
                                            HybridJavaGlobalRef());
  }

  if (!packet->is_exit_frame) {
    for (PlatformViewPacketEntry& entry : packet->views) {
      jni_facade->FlutterViewOnDisplayHybridPlatformView(
          static_cast<int>(entry.view_id), entry.bounds.GetX(),
          entry.bounds.GetY(), entry.bounds.GetWidth(),
          entry.bounds.GetHeight(), entry.physical_width, entry.physical_height,
          std::move(entry.mutators_stack));
      if (entry.overlay.has_value() && entry.overlay->image) {
        OverlaySlicePacket& overlay = *entry.overlay;
        const HybridJavaGlobalRef& overlay_reader = overlay.image.reader();
        jni_facade->FlutterViewDisplayHybridOverlaySurface(
            overlay.surface_id, overlay.bounds.GetX(), overlay.bounds.GetY(),
            overlay.bounds.GetWidth(), overlay.bounds.GetHeight(),
            overlay.image.TakeImage(), overlay_reader);
      }
    }
  }

  jni_facade->FlutterViewEndHybridFrame(
      packet->is_exit_frame, packet->remove_background_after_traversal);
}

// |ExternalViewEmbedder|
void AndroidExternalViewEmbedder::SubmitFlutterView(
    int64_t flutter_view_id,
    GrDirectContext* context,
    const std::shared_ptr<impeller::AiksContext>& aiks_context,
    std::unique_ptr<SurfaceFrame> frame) {
  TRACE_EVENT0("flutter", "AndroidExternalViewEmbedder::SubmitFlutterView");
  FML_DCHECK(flutter_view_id == kFlutterImplicitViewId);
  (void)aiks_context;

  last_submit_succeeded_ = true;
  if (!frame) {
    last_submit_succeeded_ = false;
    return;
  }

  const bool alive =
      hc_state_ && hc_state_->hc_views_alive.load(std::memory_order_acquire);
  const bool active =
      hc_state_ && hc_state_->hc_session_active.load(std::memory_order_relaxed);
  const bool sync_bg_live =
      !hc_state_ || hc_state_->synchronize_to_native_view_hierarchy.load(
                        std::memory_order_acquire);
  const bool root_transparent =
      hc_state_ &&
      hc_state_->root_surface_transparent.load(std::memory_order_acquire);
  const bool has_pv = FrameHasPlatformLayers();
  const DeferredRootSurface* deferred_root = GetDeferredRootSurface();
  const bool is_direct_non_deferred_frame =
      deferred_root != nullptr && !deferred_root->IsDeferredFrame(*frame);

  // Cases 1 & 2: No active HC session and no PlatformViewLayer in this frame.
  // Case 1 (alive=0, active=0, has_pv=0): direct root frame submit.
  // Case 2 (alive=1, active=0, has_pv=0): deferred DisplayList replays onto
  // inner_ inside frame->Submit().
  if (!active && !has_pv) {
    last_submit_succeeded_ = frame->Submit();
    if (last_submit_succeeded_) {
      consecutive_abort_retries_ = 0;
    }
    return;
  }

  // Case 8 (alive=0, active=0, has_pv=1): PlatformView was created and disposed
  // on main before its first HC frame ever rasterized.
  // Also handles the T1-to-T3 race where `hc_views_alive` flipped false -> true
  // between `DeferredRootSurface::AcquireFrame` (T1, which acquired `inner_`
  // directly) and `SubmitFlutterView` (T3): finish submitting the already-
  // acquired direct `inner_` frame without double-acquiring `inner_` or calling
  // `BuildDisplayList()` on a direct Skia/Software surface, and schedule a
  // follow-up frame when `alive` is now true so HC activates on the next VSync.
  if (!active && has_pv && (!alive || is_direct_non_deferred_frame)) {
    FlattenSlicesIntoCanvas(frame->Canvas(),
                            frame->submit_info().buffer_damage);
    last_submit_succeeded_ = frame->Submit();
    if (last_submit_succeeded_) {
      consecutive_abort_retries_ = 0;
      if (alive) {
        PostScheduleFrame();
      }
    } else if (alive) {
      ScheduleRetryFrameIfAllowed();
    }
    return;
  }

  // Cases 5, 6, & 7: Active HC session exiting because either no
  // PlatformViewLayer remains in the scene (Cases 5 & 6) or all Classic HC
  // views were already disposed in Java (Case 7).
  if (active && (!alive || !has_pv)) {
    if (has_pv) {
      // Case 7: Flatten slices recorded for the already-disposed views onto the
      // deferred root canvas before building the shared DisplayList once.
      FlattenSlicesIntoCanvas(frame->Canvas(), std::nullopt);
    }

    sk_sp<DisplayList> root_dl = GetRootDisplayList(*frame);
    bool destroyed_any_layer = false;
    ImageLayer* submitted_exit_bg_layer = nullptr;

    // 1. Sequentially render and submit to bg_layer first iff the active
    // session had synchronized its background to hcBackgroundImageView.
    if (hc_background_synchronized_ && jni_facade_ && surface_factory_) {
      bool destroyed_existing = false;
      ImageLayer* bg_layer = image_layer_pool_.GetOrCreateBackgroundLayer(
          frame_size_, context, jni_facade_, surface_factory_,
          &destroyed_existing);
      destroyed_any_layer |= destroyed_existing;
      if (bg_layer && bg_layer->surface) {
        if (std::unique_ptr<SurfaceFrame> bg_frame =
                bg_layer->surface->AcquireFrame(frame_size_)) {
          if (DlCanvas* bg_canvas = bg_frame->Canvas()) {
            bg_canvas->Clear(DlColor::kTransparent());
            if (root_dl) {
              bg_canvas->DrawDisplayList(root_dl);
            }
          }
          if (bg_frame->Submit()) {
            submitted_exit_bg_layer = bg_layer;
          }
        }
      }
    }

    // 2. Sequentially replay the cached DisplayList onto inner_ via
    // frame->Submit() so the root surface holds the exact exit scene.
    const bool inner_submitted = frame->Submit();
    last_submit_succeeded_ = inner_submitted;
    if (inner_submitted) {
      consecutive_abort_retries_ = 0;
    } else {
      FML_LOG(WARNING)
          << "Failed submitting root inner surface during Hybrid Composition "
             "exit; scheduling retry.";
      ScheduleRetryFrameIfAllowed();
    }

    // 3. Acquire the exit background Image (if bg_layer was submitted).
    AcquiredHybridImage exit_bg_image;
    if (submitted_exit_bg_layer != nullptr && jni_facade_) {
      HybridJavaGlobalRef raw_image = jni_facade_->AcquireLatestHybridImage(
          submitted_exit_bg_layer->reader_handle->reader());
      if (raw_image) {
        exit_bg_image = AcquiredHybridImage(
            submitted_exit_bg_layer->reader_handle, std::move(raw_image));
      }
    }
    if (hc_background_synchronized_ && !exit_bg_image) {
      FML_LOG(WARNING)
          << "Failed rendering or acquiring Hybrid Composition exit background "
             "image; Java will remove hcBackgroundImageView immediately.";
    }

    // 4. Release all GPU surfaces in ImageLayerPool and restore the root GL
    // context before returning control to Rasterizer.
    destroyed_any_layer |= image_layer_pool_.DestroyAllLayers();
    RestoreRootRenderContextIfNeeded(destroyed_any_layer);

    hc_background_synchronized_ = false;
    if (hc_state_) {
      hc_state_->hc_session_active.store(false, std::memory_order_release);
    }

    auto packet = std::make_unique<FramePacket>();
    packet->hc_epoch = current_frame_hc_epoch_;
    packet->trace_flow_id = fml::tracing::TraceNonce();
    packet->is_exit_frame = true;
    packet->background_image = std::move(exit_bg_image);
    TRACE_FLOW_BEGIN(kPacketTraceCategory, kPacketTraceFlowName,
                     packet->trace_flow_id);
    PublishPacket(std::move(packet));
    return;
  }

  // Cases 3 & 4 (alive=1, has_pv=1): HC entry (active=0 -> 1) or steady-state
  // HC frame (active=1 -> 1).
  std::unordered_map<int64_t, DlRect> view_rects;
  view_rects.reserve(composition_order_.size());
  for (int64_t platform_id : composition_order_) {
    view_rects[platform_id] = GetViewRect(platform_id);
  }

  std::unordered_map<int64_t, DlRect> overlay_layers =
      SliceViews(frame->Canvas(), composition_order_, slices_, view_rects);

  bool destroyed_any_layer = false;
  bool remove_background_after_traversal = false;
  ImageLayer* submitted_bg_layer = nullptr;
  std::vector<ImageLayer*> unacquired_submitted_layers;

  if (sync_bg_live) {
    // When first synchronizing Hybrid Composition onto `hcBackgroundImageView`
    // (either on initial HC entry or when `synchronizeToNativeViewHierarchy`
    // switches `false -> true` mid-session) with a transparent root
    // `FlutterSurfaceView` (`setZOrderOnTop(true)`), clear `inner_` once
    // sequentially to transparent so stale root pixels cannot occlude HC views.
    if (!hc_background_synchronized_ && root_transparent) {
      if (DeferredRootSurface* deferred_root = GetDeferredRootSurface()) {
        if (std::unique_ptr<SurfaceFrame> clear_frame =
                deferred_root->AcquireInnerFrame(frame_size_)) {
          if (DlCanvas* clear_canvas = clear_frame->Canvas()) {
            clear_canvas->Clear(DlColor::kTransparent());
          }
          if (!clear_frame->Submit()) {
            FML_LOG(WARNING) << "Failed submitting transparent root clear "
                                "frame on Hybrid Composition entry.";
          }
        }
      }
    }

    sk_sp<DisplayList> root_dl = GetRootDisplayList(*frame);
    bool destroyed_existing = false;
    ImageLayer* bg_layer = image_layer_pool_.GetOrCreateBackgroundLayer(
        frame_size_, context, jni_facade_, surface_factory_,
        &destroyed_existing);
    destroyed_any_layer |= destroyed_existing;
    if (!bg_layer || !bg_layer->surface) {
      AbortFrameAndScheduleRetry(unacquired_submitted_layers,
                                 destroyed_any_layer);
      return;
    }

    std::unique_ptr<SurfaceFrame> bg_frame =
        bg_layer->surface->AcquireFrame(frame_size_);
    if (!bg_frame) {
      AbortFrameAndScheduleRetry(unacquired_submitted_layers,
                                 destroyed_any_layer);
      return;
    }
    if (DlCanvas* bg_canvas = bg_frame->Canvas()) {
      bg_canvas->Clear(DlColor::kTransparent());
      if (root_dl) {
        bg_canvas->DrawDisplayList(root_dl);
      }
    }
    if (!bg_frame->Submit()) {
      AbortFrameAndScheduleRetry(unacquired_submitted_layers,
                                 destroyed_any_layer);
      return;
    }
    submitted_bg_layer = bg_layer;
    unacquired_submitted_layers.push_back(bg_layer);
  } else {
    // `synchronizeToNativeViewHierarchy` is disabled: submit the background
    // scene directly to `inner_` and request removal of any active
    // `hcBackgroundImageView` on every unsynchronized packet (level-triggered
    // so overwriting a prior packet in `FramePacketMailbox` cannot lose the
    // removal request).
    if (!frame->Submit()) {
      AbortFrameAndScheduleRetry(unacquired_submitted_layers,
                                 destroyed_any_layer);
      return;
    }
    if (hc_background_synchronized_) {
      destroyed_any_layer |= image_layer_pool_.DestroyBackgroundLayer();
    }
    remove_background_after_traversal = true;
  }

  std::vector<PendingViewEntry> pending_entries;
  pending_entries.reserve(composition_order_.size());
  size_t overlay_index = 0;

  for (int64_t view_id : composition_order_) {
    const DlIRect view_bounds = DlIRect::Round(GetViewRect(view_id));
    const EmbeddedViewParams& params = view_params_.at(view_id);

    PendingViewEntry pending;
    pending.view_id = view_id;
    pending.view_bounds = view_bounds;
    pending.physical_width =
        ToPhysicalPixels(params.sizePoints().width, device_pixel_ratio_);
    pending.physical_height =
        ToPhysicalPixels(params.sizePoints().height, device_pixel_ratio_);
    pending.mutators_stack = params.mutatorsStack();

    auto overlay_it = overlay_layers.find(view_id);
    if (overlay_it != overlay_layers.end()) {
      const DlIRect overlay_bounds = DlIRect::RoundOut(overlay_it->second);
      if (!overlay_bounds.IsEmpty()) {
        bool destroyed_existing = false;
        ImageLayer* overlay_layer = image_layer_pool_.GetOrCreateOverlayLayer(
            overlay_index, frame_size_, context, jni_facade_, surface_factory_,
            &destroyed_existing);
        destroyed_any_layer |= destroyed_existing;
        if (!overlay_layer || !overlay_layer->surface) {
          AbortFrameAndScheduleRetry(unacquired_submitted_layers,
                                     destroyed_any_layer);
          return;
        }

        std::unique_ptr<SurfaceFrame> overlay_frame =
            overlay_layer->surface->AcquireFrame(frame_size_);
        if (!overlay_frame) {
          AbortFrameAndScheduleRetry(unacquired_submitted_layers,
                                     destroyed_any_layer);
          return;
        }
        if (DlCanvas* overlay_canvas = overlay_frame->Canvas()) {
          overlay_canvas->Clear(DlColor::kTransparent());
          overlay_canvas->Translate(
              -static_cast<DlScalar>(overlay_bounds.GetX()),
              -static_cast<DlScalar>(overlay_bounds.GetY()));
          slices_.at(view_id)->render_into(overlay_canvas);
        }
        if (!overlay_frame->Submit()) {
          AbortFrameAndScheduleRetry(unacquired_submitted_layers,
                                     destroyed_any_layer);
          return;
        }

        pending.submitted_overlay_layer = overlay_layer;
        pending.overlay_bounds = overlay_bounds;
        unacquired_submitted_layers.push_back(overlay_layer);
        ++overlay_index;
      }
    }

    pending_entries.push_back(std::move(pending));
  }

  // Batch `AcquireLatestHybridImage()` across all submitted layers now that
  // every layer's GPU work is in flight and sequential FBO 0 binds are done.
  auto packet = std::make_unique<FramePacket>();
  packet->hc_epoch = current_frame_hc_epoch_;
  packet->is_exit_frame = false;
  packet->remove_background_after_traversal = remove_background_after_traversal;

  size_t next_unacquired_index = 0;
  if (submitted_bg_layer != nullptr) {
    ++next_unacquired_index;
    HybridJavaGlobalRef raw_bg_image =
        jni_facade_ ? jni_facade_->AcquireLatestHybridImage(
                          submitted_bg_layer->reader_handle->reader())
                    : HybridJavaGlobalRef();
    if (!raw_bg_image) {
      std::vector<ImageLayer*> remaining(
          unacquired_submitted_layers.begin() +
              static_cast<std::ptrdiff_t>(next_unacquired_index),
          unacquired_submitted_layers.end());
      AbortFrameAndScheduleRetry(remaining, destroyed_any_layer);
      return;
    }
    packet->background_image = AcquiredHybridImage(
        submitted_bg_layer->reader_handle, std::move(raw_bg_image));
  }

  packet->views.reserve(pending_entries.size());
  for (PendingViewEntry& pending : pending_entries) {
    std::optional<OverlaySlicePacket> overlay_packet;
    if (pending.submitted_overlay_layer != nullptr) {
      ++next_unacquired_index;
      HybridJavaGlobalRef raw_overlay_image =
          jni_facade_
              ? jni_facade_->AcquireLatestHybridImage(
                    pending.submitted_overlay_layer->reader_handle->reader())
              : HybridJavaGlobalRef();
      if (!raw_overlay_image) {
        std::vector<ImageLayer*> remaining(
            unacquired_submitted_layers.begin() +
                static_cast<std::ptrdiff_t>(next_unacquired_index),
            unacquired_submitted_layers.end());
        // Destroying `packet` on return automatically releases
        // `packet->background_image` and any earlier `overlay_packet`s.
        AbortFrameAndScheduleRetry(remaining, destroyed_any_layer);
        return;
      }
      overlay_packet.emplace(
          pending.submitted_overlay_layer->id, pending.overlay_bounds,
          AcquiredHybridImage(pending.submitted_overlay_layer->reader_handle,
                              std::move(raw_overlay_image)));
    }

    packet->views.emplace_back(pending.view_id, pending.view_bounds,
                               pending.physical_width, pending.physical_height,
                               std::move(pending.mutators_stack),
                               std::move(overlay_packet));
  }

  destroyed_any_layer |=
      image_layer_pool_.RecycleAndTrimUnusedOverlays(overlay_index);
  RestoreRootRenderContextIfNeeded(destroyed_any_layer);

  hc_background_synchronized_ = sync_bg_live;
  consecutive_abort_retries_ = 0;
  if (hc_state_) {
    hc_state_->hc_session_active.store(true, std::memory_order_release);
  }

  packet->trace_flow_id = fml::tracing::TraceNonce();
  TRACE_FLOW_BEGIN(kPacketTraceCategory, kPacketTraceFlowName,
                   packet->trace_flow_id);
  PublishPacket(std::move(packet));
}

// |ExternalViewEmbedder|
PostPrerollResult AndroidExternalViewEmbedder::PostPrerollAction(
    const fml::RefPtr<fml::RasterThreadMerger>& raster_thread_merger) {
  (void)raster_thread_merger;
  return PostPrerollResult::kSuccess;
}

bool AndroidExternalViewEmbedder::FrameHasPlatformLayers() const {
  return !composition_order_.empty();
}

// |ExternalViewEmbedder|
DlCanvas* AndroidExternalViewEmbedder::GetRootCanvas() {
  return nullptr;
}

void AndroidExternalViewEmbedder::Reset() {
  composition_order_.clear();
  slices_.clear();
}

// |ExternalViewEmbedder|
void AndroidExternalViewEmbedder::BeginFrame(
    GrDirectContext* context,
    const fml::RefPtr<fml::RasterThreadMerger>& raster_thread_merger) {
  (void)context;
  (void)raster_thread_merger;
  // Snapshot `hc_epoch` at the start of `BeginFrame` BEFORE reading
  // `hc_views_alive` so any concurrent `OnPreEngineRestart`, `NotifyDestroyed`,
  // or `Teardown` increments `hc_epoch` past `current_frame_hc_epoch_`.
  current_frame_hc_epoch_ =
      hc_state_ ? hc_state_->hc_epoch.load(std::memory_order_acquire) : 0;
  frame_began_ = true;
  last_submit_succeeded_ = true;
}

// |ExternalViewEmbedder|
void AndroidExternalViewEmbedder::PrepareFlutterView(
    DlISize frame_size,
    double device_pixel_ratio) {
  if (!frame_began_) {
    current_frame_hc_epoch_ =
        hc_state_ ? hc_state_->hc_epoch.load(std::memory_order_acquire) : 0;
    last_submit_succeeded_ = true;
  }
  Reset();

  if (frame_size_ != frame_size) {
    // Destroy any stale-sized pooled layers on `1.raster` before `Rasterizer`
    // calls `surface_->AcquireFrame` (which re-binds the root GL context).
    image_layer_pool_.DestroyAllLayers();

    if (const fml::RefPtr<fml::TaskRunner>& platform_runner =
            task_runners_.GetPlatformTaskRunner();
        platform_runner && jni_facade_) {
      platform_runner->PostTask(fml::MakeCopyable([jni_facade = jni_facade_,
                                                   frame_size = frame_size]() {
        jni_facade->MaybeResizeSurfaceView(frame_size.width, frame_size.height);
      }));
    }
  }

  frame_size_ = frame_size;
  device_pixel_ratio_ = device_pixel_ratio;
}

// |ExternalViewEmbedder|
void AndroidExternalViewEmbedder::CancelFrame() {
  Reset();
  frame_began_ = false;
}

// |ExternalViewEmbedder|
void AndroidExternalViewEmbedder::EndFrame(
    bool should_resubmit_frame,
    const fml::RefPtr<fml::RasterThreadMerger>& raster_thread_merger) {
  (void)should_resubmit_frame;
  (void)raster_thread_merger;
  frame_began_ = false;
}

// |ExternalViewEmbedder|
bool AndroidExternalViewEmbedder::SupportsDynamicThreadMerging() {
  return false;
}

// |ExternalViewEmbedder|
bool AndroidExternalViewEmbedder::SupportsPartialRepaint() const {
  return !hc_state_ || !hc_state_->ShouldDeferRootSurface();
}

// |ExternalViewEmbedder|
bool AndroidExternalViewEmbedder::DidLastSubmitSucceed() const {
  return last_submit_succeeded_;
}

// |ExternalViewEmbedder|
void AndroidExternalViewEmbedder::Teardown() {
  if (hc_state_) {
    hc_state_->hc_epoch.fetch_add(1, std::memory_order_acq_rel);
  }

  std::unique_ptr<FramePacket> pending = mailbox_->ResetAndTake();
  if (pending) {
    TRACE_FLOW_END(kPacketTraceCategory, kPacketTraceFlowName,
                   pending->trace_flow_id);
    pending.reset();
  }

  auto raster_cleanup = [this]() {
    const bool destroyed = image_layer_pool_.DestroyAllLayers();
    RestoreRootRenderContextIfNeeded(destroyed);
    hc_background_synchronized_ = false;
    consecutive_abort_retries_ = 0;
    if (hc_state_) {
      hc_state_->hc_session_active.store(false, std::memory_order_release);
    }
  };

  const fml::RefPtr<fml::TaskRunner>& raster_runner =
      task_runners_.GetRasterTaskRunner();
  if (!raster_runner || raster_runner->RunsTasksOnCurrentThread()) {
    raster_cleanup();
  } else {
    fml::AutoResetWaitableEvent latch;
    raster_runner->PostTask([&raster_cleanup, &latch]() {
      raster_cleanup();
      latch.Signal();
    });
    latch.Wait();
  }

  if (jni_facade_) {
    const fml::RefPtr<fml::TaskRunner>& platform_runner =
        task_runners_.GetPlatformTaskRunner();
    if (!platform_runner || platform_runner->RunsTasksOnCurrentThread()) {
      jni_facade_->FlutterViewTeardownHybridComposition();
    } else {
      platform_runner->PostTask([jni_facade = jni_facade_]() {
        jni_facade->FlutterViewTeardownHybridComposition();
      });
    }
  }
}

}  // namespace flutter
