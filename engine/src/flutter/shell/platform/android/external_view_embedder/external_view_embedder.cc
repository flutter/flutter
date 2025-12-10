// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/external_view_embedder/external_view_embedder.h"
#include "flow/view_slicer.h"
#include "flutter/common/constants.h"
#include "flutter/fml/synchronization/waitable_event.h"
#include "flutter/fml/trace_event.h"

namespace flutter {
// class AndroidPlatformViewController final : public ExternalViewEmbedder {
//  public:
  AndroidExternalView::AndroidExternalView(
      const AndroidContext& android_context,
      std::shared_ptr<PlatformViewAndroidJNI> jni_facade,
      std::shared_ptr<AndroidSurfaceFactory> surface_factory,
      const TaskRunners& task_runners,
      int64_t flutter_view_id,
      const SurfaceFrameLayer::GetSurfaceFrameLayerCallback& get_surface_frame_layer_callback):
                                android_context_(android_context),
                                jni_facade_(std::move(jni_facade)),
                                surface_factory_(std::move(surface_factory)),
                                surface_pool_(
                                    std::make_unique<SurfacePool>(/*use_new_surface_methods=*/false)),
                                task_runners_(task_runners),
                                flutter_view_id_(flutter_view_id),
                                get_surface_frame_layer_callback_(get_surface_frame_layer_callback) {}

  void AndroidExternalView::CollectView(int64_t view_id) {
    DestroySurfaces(view_id);
  }

  // |ExternalViewEmbedder|
  void AndroidExternalView::PrerollCompositeEmbeddedView(
      int64_t view_id,
      std::unique_ptr<flutter::EmbeddedViewParams> params)  {
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
  DlCanvas* AndroidExternalView::CompositeEmbeddedView(int64_t view_id)  {
    if (slices_.count(view_id) == 1) {
      return slices_.at(view_id)->canvas();
    }
    return nullptr;
  }

  // |ExternalViewEmbedder|
  void AndroidExternalView::SubmitFlutterView(
      int64_t flutter_view_id,
      GrDirectContext* context,
      const std::shared_ptr<impeller::AiksContext>& aiks_context,
      std::unique_ptr<SurfaceFrame> frame)  {
    TRACE_EVENT0("flutter", "AndroidExternalViewEmbedder::SubmitFlutterView");
    // TODO(dkwingsmt): This class only supports rendering into the implicit view.
    // Properly support multi-view in the future.
    FML_DCHECK(flutter_view_id == kFlutterImplicitViewId);

    if (!FrameHasPlatformLayers()) {
      frame->Submit();
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
      DlRect view_rect = GetViewRect(view_id);
      const EmbeddedViewParams& params = view_params_.at(view_id);
      // Display the platform view. If it's already displayed, then it's
      // just positioned and sized.
      jni_facade_->FlutterViewOnDisplayPlatformView(
          flutter_view_id, ///
          view_id,             //
          view_rect.GetX(),       //
          view_rect.GetY(),       //
          view_rect.GetWidth(),   //
          view_rect.GetHeight(),  //
          params.sizePoints().width * device_pixel_ratio_,
          params.sizePoints().height * device_pixel_ratio_,
          params.mutatorsStack()  //
      );
      std::unordered_map<int64_t, DlRect>::const_iterator overlay =
          overlay_layers.find(view_id);
      if (overlay == overlay_layers.end()) {
        continue;
      }
      std::unique_ptr<SurfaceFrame> frame =
          CreateSurfaceIfNeeded(context,                    //
                                flutter_view_id,             //
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
  PostPrerollResult AndroidExternalView::PostPrerollAction(
      const fml::RefPtr<fml::RasterThreadMerger>& raster_thread_merger)
       {
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

  // |ExternalViewEmbedder|
  DlCanvas* AndroidExternalView::GetRootCanvas()  {
    // On Android, the root surface is created from the on-screen render target.
    return nullptr;
  }

  // |ExternalViewEmbedder|
  void AndroidExternalView::BeginFrame(GrDirectContext* context,
                  const fml::RefPtr<fml::RasterThreadMerger>&
                      raster_thread_merger)  {
    // JNI method must be called on the platform thread.
    if (raster_thread_merger->IsOnPlatformThread()) {
      jni_facade_->FlutterViewBeginFrame();
    }
  }

  // |ExternalViewEmbedder|
  void AndroidExternalView::PrepareFlutterView(
                          int64_t flutter_view_id,
                          DlISize frame_size,
                          double device_pixel_ratio) {
    Reset();

    // The surface size changed. Therefore, destroy existing surfaces as
    // the existing surfaces in the pool can't be recycled.
    if (frame_size_ != frame_size) {
      DestroySurfaces(flutter_view_id_);
    }
    surface_pool_->SetFrameSize(frame_size);

    frame_size_ = frame_size;
    device_pixel_ratio_ = device_pixel_ratio;
    // if (!surface_frame_layer_) {
    //   surface_frame_layer_ = get_surface_frame_layer_callback_(flutter_view_id);
    // }
  }

  // |ExternalViewEmbedder|
  void AndroidExternalView::CancelFrame() {
    Reset();
  }

  // |ExternalViewEmbedder|
  void AndroidExternalView::EndFrame(bool should_resubmit_frame,
                const fml::RefPtr<fml::RasterThreadMerger>&
                    raster_thread_merger) {
    surface_pool_->RecycleLayers();
    // JNI method must be called on the platform thread.
    if (raster_thread_merger->IsOnPlatformThread()) {
      jni_facade_->FlutterViewEndFrame();
    }
  }

  // |ExternalViewEmbedder|
  // bool AndroidExternalView::SupportsDynamicThreadMerging() { return true; }

  // // |ExternalViewEmbedder|
  // void AndroidExternalView::Teardown() {
  //   // DestroySurfaces();
  // }

  // Gets the rect based on the device pixel ratio of a platform view displayed
  // on the screen.
  DlRect AndroidExternalView::GetViewRect(int64_t view_id) const {
    const EmbeddedViewParams& params = view_params_.at(view_id);
    // TODO(egarciad): The rect should be computed from the mutator stack.
    // (Clipping is missing)
    // https://github.com/flutter/flutter/issues/59821
    return params.finalBoundingRect();
  }



  // Destroys the surfaces created from the surface factory.
  // This method schedules a task on the platform thread, and waits for
  // the task until it completes.
  void AndroidExternalView::DestroySurfaces(int64_t flutter_view_id) {
    if (!surface_pool_->HasLayers()) {
      return;
    }
    fml::AutoResetWaitableEvent latch;
    fml::TaskRunner::RunNowOrPostTask(task_runners_.GetPlatformTaskRunner(),
                                      [&]() {
                                        surface_pool_->DestroyLayers(jni_facade_, flutter_view_id);
                                        latch.Signal();
                                      });
    latch.Wait();
  }

  // Resets the state.
  void AndroidExternalView::Reset() {
    previous_frame_view_count_ = composition_order_.size();

    composition_order_.clear();
    slices_.clear();
  }

  // Whether the layer tree in the current frame has platform layers.
  bool AndroidExternalView::FrameHasPlatformLayers() {
    return !composition_order_.empty();
  }

  // Creates a Surface when needed or recycles an existing one.
  // Finally, draws the picture on the frame's canvas.
  std::unique_ptr<SurfaceFrame> AndroidExternalView::CreateSurfaceIfNeeded(GrDirectContext* context,
                                                      int64_t flutter_view_id,
                                                      int64_t view_id,
                                                      EmbedderViewSlice* slice,
                                                      const DlRect& rect) {
    std::shared_ptr<OverlayLayer> layer = surface_pool_->GetLayer(
        context, android_context_, jni_facade_, surface_factory_, flutter_view_id);

    std::unique_ptr<SurfaceFrame> frame =
        layer->surface->AcquireFrame(frame_size_);
    // Display the overlay surface. If it's already displayed, then it's
    // just positioned and sized.
    jni_facade_->FlutterViewDisplayOverlaySurface(flutter_view_id, //
                                                  layer->id,     //
                                                  rect.GetX(),      //
                                                  rect.GetY(),      //
                                                  rect.GetWidth(),  //
                                                  rect.GetHeight()  //
    );
    DlCanvas* overlay_canvas = frame->Canvas();
    overlay_canvas->Clear(DlColor::kTransparent());
    // Offset the picture since its absolute position on the scene is determined
    // by the position of the overlay view.
    overlay_canvas->Translate(-rect.GetX(), -rect.GetY());
    slice->render_into(overlay_canvas);
    return frame;
  }

  std::unique_ptr<SurfaceFrame> AndroidExternalView::AcquireRootFrame() {
    auto *frame_layer = get_surface_frame_layer_callback_(flutter_view_id_);
    if (frame_layer) {
      auto surface_frame = frame_layer->MakeSurfaceFrame(frame_size_);
      if (surface_frame) {
        return surface_frame;
      }
    }

    return std::make_unique<SurfaceFrame>(
        nullptr, SurfaceFrame::FramebufferInfo{.supports_readback = true},
        [](const SurfaceFrame& surface_frame, DlCanvas* canvas) {
          return true;
        },
        [](const SurfaceFrame& surface_frame) { return true; }, frame_size_, nullptr, true);
  }

AndroidExternalViewEmbedder::AndroidExternalViewEmbedder(
    const AndroidContext& android_context,
    std::shared_ptr<PlatformViewAndroidJNI> jni_facade,
    std::shared_ptr<AndroidSurfaceFactory> surface_factory,
    const TaskRunners& task_runners,
    const SurfaceFrameLayer::GetSurfaceFrameLayerCallback& get_surface_frame_layer_callback)
    : ExternalViewEmbedder(),
      android_context_(android_context),
      jni_facade_(std::move(jni_facade)),
      surface_factory_(std::move(surface_factory)),
      surface_pool_(
          std::make_unique<SurfacePool>(/*use_new_surface_methods=*/false)),
      task_runners_(task_runners),
      get_surface_frame_layer_callback_(get_surface_frame_layer_callback) {}

// void AndroidExternalViewEmbedder::SetCurrentProcessingView(int64_t flutter_view_id) {
//   pending_flutter_view_id_ = flutter_view_id;
// }

void AndroidExternalViewEmbedder::CollectView(int64_t view_id) {
  FML_LOG(ERROR) << "AndroidExternalViewEmbedder::CollectView, view_id: " << view_id;
  auto iter = pending_views_.find(view_id);
  if (iter != pending_views_.end()) {
    iter->second->CollectView(iter->first);
    pending_views_.erase(view_id);
  }
}

// |ExternalViewEmbedder|
void AndroidExternalViewEmbedder::PrerollCompositeEmbeddedView(
    int64_t view_id,
    std::unique_ptr<EmbeddedViewParams> params) {
  // TRACE_EVENT0("flutter",
  //              "AndroidExternalViewEmbedder::PrerollCompositeEmbeddedView");

  // SkRect view_bounds = SkRect::Make(frame_size_);
  // std::unique_ptr<EmbedderViewSlice> view;
  // view = std::make_unique<DisplayListEmbedderViewSlice>(view_bounds);
  // slices_.insert_or_assign(view_id, std::move(view));

  // composition_order_.push_back(view_id);
  // // Update params only if they changed.
  // if (view_params_.count(view_id) == 1 &&
  //     view_params_.at(view_id) == *params.get()) {
  //   return;
  // }
  // view_params_.insert_or_assign(view_id, EmbeddedViewParams(*params.get()));


  auto iter = pending_views_.find(pending_flutter_view_id_);
  if (iter != pending_views_.end()) {
    iter->second.get()->PrerollCompositeEmbeddedView(view_id, std::move(params));
  }
}

// |ExternalViewEmbedder|
DlCanvas* AndroidExternalViewEmbedder::CompositeEmbeddedView(int64_t view_id) {
  // if (slices_.count(view_id) == 1) {
  //   return slices_.at(view_id)->canvas();
  // }

  auto iter = pending_views_.find(pending_flutter_view_id_);
  if (iter != pending_views_.end()) {
    iter->second.get()->CompositeEmbeddedView(view_id);
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
  // TRACE_EVENT0("flutter", "AndroidExternalViewEmbedder::SubmitFlutterView");
  // // TODO(dkwingsmt): This class only supports rendering into the implicit view.
  // // Properly support multi-view in the future.
  // FML_DCHECK(flutter_view_id == kFlutterImplicitViewId);

  // if (!FrameHasPlatformLayers()) {
  //   frame->Submit();
  //   return;
  // }

  // std::unordered_map<int64_t, SkRect> view_rects;
  // for (auto platform_id : composition_order_) {
  //   view_rects[platform_id] = GetViewRect(platform_id);
  // }

  // std::unordered_map<int64_t, SkRect> overlay_layers =
  //     SliceViews(frame->Canvas(),     //
  //                composition_order_,  //
  //                slices_,             //
  //                view_rects           //
  //     );

  // // Submit the background canvas frame before switching the GL context to
  // // the overlay surfaces.
  // //
  // // Skip a frame if the embedding is switching surfaces, and indicate in
  // // `PostPrerollAction` that this frame must be resubmitted.
  // auto should_submit_current_frame = previous_frame_view_count_ > 0;
  // if (should_submit_current_frame) {
  //   frame->Submit();
  // }

  // for (int64_t view_id : composition_order_) {
  //   SkRect view_rect = GetViewRect(view_id);
  //   const EmbeddedViewParams& params = view_params_.at(view_id);
  //   // Display the platform view. If it's already displayed, then it's
  //   // just positioned and sized.
  //   jni_facade_->FlutterViewOnDisplayPlatformView(
  //       view_id,             //
  //       view_rect.x(),       //
  //       view_rect.y(),       //
  //       view_rect.width(),   //
  //       view_rect.height(),  //
  //       params.sizePoints().width() * device_pixel_ratio_,
  //       params.sizePoints().height() * device_pixel_ratio_,
  //       params.mutatorsStack()  //
  //   );
  //   std::unordered_map<int64_t, SkRect>::const_iterator overlay =
  //       overlay_layers.find(view_id);
  //   if (overlay == overlay_layers.end()) {
  //     continue;
  //   }
  //   std::unique_ptr<SurfaceFrame> frame =
  //       CreateSurfaceIfNeeded(context,                    //
  //                             view_id,                    //
  //                             slices_.at(view_id).get(),  //
  //                             overlay->second             //
  //       );
  //   if (should_submit_current_frame) {
  //     frame->Submit();
  //   }
  // }


  auto iter = pending_views_.find(flutter_view_id);
  if (iter != pending_views_.end()) {
    iter->second.get()->SubmitFlutterView(flutter_view_id, context, aiks_context, std::move(frame));
  }
}

// |ExternalViewEmbedder|
std::unique_ptr<SurfaceFrame>
AndroidExternalViewEmbedder::CreateSurfaceIfNeeded(GrDirectContext* context,
                                                   int64_t view_id,
                                                   EmbedderViewSlice* slice,
                                                   const DlRect& rect) {
  // std::shared_ptr<OverlayLayer> layer = surface_pool_->GetLayer(
  //     context, android_context_, jni_facade_, surface_factory_);

  // std::unique_ptr<SurfaceFrame> frame =
  //     layer->surface->AcquireFrame(frame_size_);
  // // Display the overlay surface. If it's already displayed, then it's
  // // just positioned and sized.
  // jni_facade_->FlutterViewDisplayOverlaySurface(layer->id,     //
  //                                               rect.x(),      //
  //                                               rect.y(),      //
  //                                               rect.width(),  //
  //                                               rect.height()  //
  // );
  // DlCanvas* overlay_canvas = frame->Canvas();
  // overlay_canvas->Clear(DlColor::kTransparent());
  // // Offset the picture since its absolute position on the scene is determined
  // // by the position of the overlay view.
  // overlay_canvas->Translate(-rect.x(), -rect.y());
  // slice->render_into(overlay_canvas);
  // return frame;

  return nullptr;
}

// |ExternalViewEmbedder|
PostPrerollResult AndroidExternalViewEmbedder::PostPrerollAction(
    const fml::RefPtr<fml::RasterThreadMerger>& raster_thread_merger) {
  // if (!FrameHasPlatformLayers()) {
  //   return PostPrerollResult::kSuccess;
  // }
  // if (!raster_thread_merger->IsMerged()) {
  //   // The raster thread merger may be disabled if the rasterizer is being
  //   // created or teared down.
  //   //
  //   // In such cases, the current frame is dropped, and a new frame is attempted
  //   // with the same layer tree.
  //   //
  //   // Eventually, the frame is submitted once this method returns `kSuccess`.
  //   // At that point, the raster tasks are handled on the platform thread.
  //   CancelFrame();
  //   raster_thread_merger->MergeWithLease(kDefaultMergedLeaseDuration);
  //   return PostPrerollResult::kSkipAndRetryFrame;
  // }
  // raster_thread_merger->ExtendLeaseTo(kDefaultMergedLeaseDuration);
  // // Surface switch requires to resubmit the frame.
  // // TODO(egarciad): https://github.com/flutter/flutter/issues/65652
  // if (previous_frame_view_count_ == 0) {
  //   return PostPrerollResult::kResubmitFrame;
  // }
  // return PostPrerollResult::kSuccess;



  auto iter = pending_views_.find(pending_flutter_view_id_);
  if (iter != pending_views_.end()) {
    return iter->second.get()->PostPrerollAction(raster_thread_merger);
  }

  return PostPrerollResult::kSuccess;
}

bool AndroidExternalViewEmbedder::FrameHasPlatformLayers() {
  // return !composition_order_.empty();
  return false;
}

// |ExternalViewEmbedder|
DlCanvas* AndroidExternalViewEmbedder::GetRootCanvas() {
  // On Android, the root surface is created from the on-screen render target.
  return nullptr;
}

void AndroidExternalViewEmbedder::Reset() {
  // previous_frame_view_count_ = composition_order_.size();

  // composition_order_.clear();
  // slices_.clear();
}

// |ExternalViewEmbedder|
void AndroidExternalViewEmbedder::BeginFrame(
    GrDirectContext* context,
    const fml::RefPtr<fml::RasterThreadMerger>& raster_thread_merger) {
  // JNI method must be called on the platform thread.
  if (raster_thread_merger->IsOnPlatformThread()) {
    jni_facade_->FlutterViewBeginFrame();
  }
}

// |ExternalViewEmbedder|
void AndroidExternalViewEmbedder::PrepareFlutterView(
    int64_t flutter_view_id,
    DlISize frame_size,
    double device_pixel_ratio) {
  pending_flutter_view_id_ = flutter_view_id;
  // Reset();

  // // The surface size changed. Therefore, destroy existing surfaces as
  // // the existing surfaces in the pool can't be recycled.
  // if (frame_size_ != frame_size) {
  //   DestroySurfaces();
  // }
  // surface_pool_->SetFrameSize(frame_size);

  // frame_size_ = frame_size;
  // device_pixel_ratio_ = device_pixel_ratio;

  // int64_t flutter_view_id = current_processing_flutter_view_id_;
  AndroidExternalView *android_external_view;
  auto iter = pending_views_.find(flutter_view_id);
  if (iter != pending_views_.end()) {
    android_external_view = iter->second.get();
  } else {
    auto ev = std::make_unique<AndroidExternalView>(
      android_context_,
      jni_facade_,
      surface_factory_,
      task_runners_,
      flutter_view_id,
      get_surface_frame_layer_callback_
    );
    // auto controller = std::make_unique<AndroidPlatformViewController>(
    //   android_context_, jni_facade_, surface_factory_, task_runners_);
    android_external_view = ev.get();
  // pending_views_.emplace(flutter_view_id, std::move(controller));
    pending_views_.emplace(flutter_view_id, std::move(ev));
    // platform_view_controller = pending_views_.at(flutter_view_id).get();
  }

  android_external_view->PrepareFlutterView(flutter_view_id, frame_size, device_pixel_ratio);
}

// |ExternalViewEmbedder|
void AndroidExternalViewEmbedder::CancelFrame() {
  // Reset();
}

// |ExternalViewEmbedder|
void AndroidExternalViewEmbedder::EndFrame(
    bool should_resubmit_frame,
    const fml::RefPtr<fml::RasterThreadMerger>& raster_thread_merger) {
  // surface_pool_->RecycleLayers();
  // JNI method must be called on the platform thread.
  // if (raster_thread_merger->IsOnPlatformThread()) {
  //   jni_facade_->FlutterViewEndFrame();
  // }
}

bool AndroidExternalViewEmbedder::SkipFrame(int64_t flutter_view_id) {
  auto *frame_layer = get_surface_frame_layer_callback_(flutter_view_id);
  return frame_layer == nullptr;
}

// |ExternalViewEmbedder|
bool AndroidExternalViewEmbedder::SupportsDynamicThreadMerging() {
  return true;
}

// |ExternalViewEmbedder|
void AndroidExternalViewEmbedder::Teardown() {
  // DestroySurfaces();

  // for (auto &iter : pending_views_) {
  //   iter.second->CollectView(iter.first);
  // }
  // pending_views_.clear();
}

// |ExternalViewEmbedder|
void AndroidExternalViewEmbedder::DestroySurfaces() {
  // if (!surface_pool_->HasLayers()) {
  //   return;
  // }
  // fml::AutoResetWaitableEvent latch;
  // fml::TaskRunner::RunNowOrPostTask(task_runners_.GetPlatformTaskRunner(),
  //                                   [&]() {
  //                                     surface_pool_->DestroyLayers(jni_facade_);
  //                                     latch.Signal();
  //                                   });
  // latch.Wait();
}

std::unique_ptr<SurfaceFrame> AndroidExternalViewEmbedder::AcquireRootFrame(int64_t flutter_view_id) {
  auto found = pending_views_.find(flutter_view_id);
  if (found == pending_views_.end()) {
    FML_DLOG(WARNING)
        << "No root surface frame could be found. This is extremely unlikely and "
           "indicates that the external view embedder did not receive the "
           "notification to begin the frame.";
    return nullptr;
  }
  FML_LOG(ERROR) << "AndroidExternalViewEmbedder::AcquireRootFrame view_id: " << flutter_view_id;
  return found->second->AcquireRootFrame();
}

}  // namespace flutter
