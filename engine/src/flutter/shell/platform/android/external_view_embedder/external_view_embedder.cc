// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/external_view_embedder/external_view_embedder.h"
#include "flutter/fml/synchronization/waitable_event.h"
#include "flutter/fml/trace_event.h"

namespace flutter {

AndroidExternalViewEmbedder::AndroidExternalViewEmbedder(
    const AndroidContext& android_context,
    std::shared_ptr<PlatformViewAndroidJNI> jni_facade,
    std::shared_ptr<AndroidSurfaceFactory> surface_factory,
    const TaskRunners& task_runners,
    bool enable_impeller)
    : ExternalViewEmbedder(),
      android_context_(android_context),
      jni_facade_(std::move(jni_facade)),
      surface_factory_(std::move(surface_factory)),
      surface_pool_(std::make_unique<SurfacePool>()),
      task_runners_(task_runners),
      enable_impeller_(enable_impeller) {}

// |ExternalViewEmbedder|
void AndroidExternalViewEmbedder::PrerollCompositeEmbeddedView(
    int64_t view_id,
    std::unique_ptr<EmbeddedViewParams> params) {
  TRACE_EVENT0("flutter",
               "AndroidExternalViewEmbedder::PrerollCompositeEmbeddedView");

  SkRect view_bounds = SkRect::Make(frame_size_);
  std::unique_ptr<EmbedderViewSlice> view;
  if (enable_impeller_) {
    view = std::make_unique<ImpellerEmbedderViewSlice>(view_bounds);
  } else {
    view = std::make_unique<DisplayListEmbedderViewSlice>(view_bounds);
  }
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

SkRect AndroidExternalViewEmbedder::GetViewRect(int64_t view_id) const {
  const EmbeddedViewParams& params = view_params_.at(view_id);
  // TODO(egarciad): The rect should be computed from the mutator stack.
  // (Clipping is missing)
  // https://github.com/flutter/flutter/issues/59821
  return SkRect::MakeXYWH(params.finalBoundingRect().x(),      //
                          params.finalBoundingRect().y(),      //
                          params.finalBoundingRect().width(),  //
                          params.finalBoundingRect().height()  //
  );
}

// |ExternalViewEmbedder|
void AndroidExternalViewEmbedder::SubmitFrame(
    GrDirectContext* context,
    const std::shared_ptr<impeller::AiksContext>& aiks_context,
    std::unique_ptr<SurfaceFrame> frame) {
  TRACE_EVENT0("flutter", "AndroidExternalViewEmbedder::SubmitFrame");

  if (!FrameHasPlatformLayers()) {
    frame->Submit();
    return;
  }

  std::unordered_map<int64_t, SkRect> overlay_layers;
  DlCanvas* background_canvas = frame->Canvas();
  auto current_frame_view_count = composition_order_.size();

  // Restore the clip context after exiting this method since it's changed
  // below.
  DlAutoCanvasRestore save(background_canvas, /*doSave=*/true);

  for (size_t i = 0; i < current_frame_view_count; i++) {
    int64_t view_id = composition_order_[i];
    EmbedderViewSlice* slice = slices_.at(view_id).get();
    if (slice->canvas() == nullptr) {
      continue;
    }

    slice->end_recording();

    SkRect full_joined_rect = SkRect::MakeEmpty();

    // Determinate if Flutter UI intersects with any of the previous
    // platform views stacked by z position.
    //
    // This is done by querying the r-tree that holds the records for the
    // picture recorder corresponding to the flow layers added after a platform
    // view layer.
    for (ssize_t j = i; j >= 0; j--) {
      int64_t current_view_id = composition_order_[j];
      SkRect current_view_rect = GetViewRect(current_view_id);
      // The rect above the `current_view_rect`
      SkRect partial_joined_rect = SkRect::MakeEmpty();
      // Each rect corresponds to a native view that renders Flutter UI.
      std::list<SkRect> intersection_rects =
          slice->searchNonOverlappingDrawnRects(current_view_rect);

      // Limit the number of native views, so it doesn't grow forever.
      //
      // In this case, the rects are merged into a single one that is the union
      // of all the rects.
      for (const SkRect& rect : intersection_rects) {
        partial_joined_rect.join(rect);
      }
      // Get the intersection rect with the `current_view_rect`,
      partial_joined_rect.intersect(current_view_rect);
      // Join the `partial_joined_rect` into `full_joined_rect` to get the rect
      // above the current `slice`
      full_joined_rect.join(partial_joined_rect);
    }
    if (!full_joined_rect.isEmpty()) {
      // Subpixels in the platform may not align with the canvas subpixels.
      //
      // To workaround it, round the floating point bounds and make the rect
      // slightly larger.
      //
      // For example, {0.3, 0.5, 3.1, 4.7} becomes {0, 0, 4, 5}.
      full_joined_rect.set(full_joined_rect.roundOut());
      overlay_layers.insert({view_id, full_joined_rect});
      // Clip the background canvas, so it doesn't contain any of the pixels
      // drawn on the overlay layer.
      background_canvas->ClipRect(full_joined_rect,
                                  DlCanvas::ClipOp::kDifference);
    }
    slice->render_into(background_canvas);
  }

  // Manually trigger the DlAutoCanvasRestore before we submit the frame
  save.Restore();

  // Submit the background canvas frame before switching the GL context to
  // the overlay surfaces.
  //
  // Skip a frame if the embedding is switching surfaces, and indicate in
  // `PostPrerollAction` that this frame must be resubmitted.
  auto should_submit_current_frame = previous_frame_view_count_ > 0;
  if (should_submit_current_frame) {
    frame->Submit();
  }

  for (int64_t view_id : composition_order_) {
    SkRect view_rect = GetViewRect(view_id);
    const EmbeddedViewParams& params = view_params_.at(view_id);
    // Display the platform view. If it's already displayed, then it's
    // just positioned and sized.
    jni_facade_->FlutterViewOnDisplayPlatformView(
        view_id,             //
        view_rect.x(),       //
        view_rect.y(),       //
        view_rect.width(),   //
        view_rect.height(),  //
        params.sizePoints().width() * device_pixel_ratio_,
        params.sizePoints().height() * device_pixel_ratio_,
        params.mutatorsStack()  //
    );
    std::unordered_map<int64_t, SkRect>::const_iterator overlay =
        overlay_layers.find(view_id);
    if (overlay == overlay_layers.end()) {
      continue;
    }
    std::unique_ptr<SurfaceFrame> frame =
        CreateSurfaceIfNeeded(context,                    //
                              view_id,                    //
                              slices_.at(view_id).get(),  //
                              overlay->second             //
        );
    if (should_submit_current_frame) {
      frame->Submit();
    }
  }
}

// |ExternalViewEmbedder|
std::unique_ptr<SurfaceFrame>
AndroidExternalViewEmbedder::CreateSurfaceIfNeeded(GrDirectContext* context,
                                                   int64_t view_id,
                                                   EmbedderViewSlice* slice,
                                                   const SkRect& rect) {
  std::shared_ptr<OverlayLayer> layer = surface_pool_->GetLayer(
      context, android_context_, jni_facade_, surface_factory_);

  std::unique_ptr<SurfaceFrame> frame =
      layer->surface->AcquireFrame(frame_size_);
  // Display the overlay surface. If it's already displayed, then it's
  // just positioned and sized.
  jni_facade_->FlutterViewDisplayOverlaySurface(layer->id,     //
                                                rect.x(),      //
                                                rect.y(),      //
                                                rect.width(),  //
                                                rect.height()  //
  );
  DlCanvas* overlay_canvas = frame->Canvas();
  overlay_canvas->Clear(DlColor::kTransparent());
  // Offset the picture since its absolute position on the scene is determined
  // by the position of the overlay view.
  overlay_canvas->Translate(-rect.x(), -rect.y());
  slice->render_into(overlay_canvas);
  return frame;
}

// |ExternalViewEmbedder|
PostPrerollResult AndroidExternalViewEmbedder::PostPrerollAction(
    fml::RefPtr<fml::RasterThreadMerger> raster_thread_merger) {
  if (!FrameHasPlatformLayers()) {
    return PostPrerollResult::kSuccess;
  }
  if (!raster_thread_merger->IsMerged()) {
    // The raster thread merger may be disabled if the rasterizer is being
    // created or teared down.
    //
    // In such cases, the current frame is dropped, and a new frame is attempted
    // with the same layer tree.
    //
    // Eventually, the frame is submitted once this method returns `kSuccess`.
    // At that point, the raster tasks are handled on the platform thread.
    CancelFrame();
    raster_thread_merger->MergeWithLease(kDefaultMergedLeaseDuration);
    return PostPrerollResult::kSkipAndRetryFrame;
  }
  raster_thread_merger->ExtendLeaseTo(kDefaultMergedLeaseDuration);
  // Surface switch requires to resubmit the frame.
  // TODO(egarciad): https://github.com/flutter/flutter/issues/65652
  if (previous_frame_view_count_ == 0) {
    return PostPrerollResult::kResubmitFrame;
  }
  return PostPrerollResult::kSuccess;
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
  previous_frame_view_count_ = composition_order_.size();

  composition_order_.clear();
  slices_.clear();
}

// |ExternalViewEmbedder|
void AndroidExternalViewEmbedder::BeginFrame(
    SkISize frame_size,
    GrDirectContext* context,
    double device_pixel_ratio,
    fml::RefPtr<fml::RasterThreadMerger> raster_thread_merger) {
  Reset();

  // The surface size changed. Therefore, destroy existing surfaces as
  // the existing surfaces in the pool can't be recycled.
  if (frame_size_ != frame_size) {
    DestroySurfaces();
  }
  surface_pool_->SetFrameSize(frame_size);
  // JNI method must be called on the platform thread.
  if (raster_thread_merger->IsOnPlatformThread()) {
    jni_facade_->FlutterViewBeginFrame();
  }

  frame_size_ = frame_size;
  device_pixel_ratio_ = device_pixel_ratio;
}

// |ExternalViewEmbedder|
void AndroidExternalViewEmbedder::CancelFrame() {
  Reset();
}

// |ExternalViewEmbedder|
void AndroidExternalViewEmbedder::EndFrame(
    bool should_resubmit_frame,
    fml::RefPtr<fml::RasterThreadMerger> raster_thread_merger) {
  surface_pool_->RecycleLayers();
  // JNI method must be called on the platform thread.
  if (raster_thread_merger->IsOnPlatformThread()) {
    jni_facade_->FlutterViewEndFrame();
  }
}

// |ExternalViewEmbedder|
bool AndroidExternalViewEmbedder::SupportsDynamicThreadMerging() {
  return true;
}

// |ExternalViewEmbedder|
void AndroidExternalViewEmbedder::Teardown() {
  DestroySurfaces();
}

// |ExternalViewEmbedder|
void AndroidExternalViewEmbedder::DestroySurfaces() {
  if (!surface_pool_->HasLayers()) {
    return;
  }
  fml::AutoResetWaitableEvent latch;
  fml::TaskRunner::RunNowOrPostTask(task_runners_.GetPlatformTaskRunner(),
                                    [&]() {
                                      surface_pool_->DestroyLayers(jni_facade_);
                                      latch.Signal();
                                    });
  latch.Wait();
}

}  // namespace flutter
