// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/external_view_embedder/external_view_embedder_2.h"
#include "display_list/dl_color.h"
#include "flow/view_slicer.h"
#include "flutter/fml/synchronization/waitable_event.h"
#include "flutter/fml/trace_event.h"
#include "fml/make_copyable.h"
#include "fml/synchronization/count_down_latch.h"

namespace flutter {

AndroidExternalViewEmbedder2::AndroidExternalViewEmbedder2(
    const AndroidContext& android_context,
    std::shared_ptr<PlatformViewAndroidJNI> jni_facade,
    std::shared_ptr<AndroidSurfaceFactory> surface_factory,
    const TaskRunners& task_runners)
    : ExternalViewEmbedder(),
      android_context_(android_context),
      jni_facade_(std::move(jni_facade)),
      surface_factory_(std::move(surface_factory)),
      surface_pool_(
          std::make_unique<SurfacePool>(/*use_new_surface_methods=*/true)),
      task_runners_(task_runners) {}

// |ExternalViewEmbedder|
void AndroidExternalViewEmbedder2::PrerollCompositeEmbeddedView(
    int64_t view_id,
    std::unique_ptr<EmbeddedViewParams> params) {
  TRACE_EVENT0("flutter",
               "AndroidExternalViewEmbedder2::PrerollCompositeEmbeddedView");

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
DlCanvas* AndroidExternalViewEmbedder2::CompositeEmbeddedView(int64_t view_id) {
  if (slices_.count(view_id) == 1) {
    return slices_.at(view_id)->canvas();
  }
  return nullptr;
}

DlRect AndroidExternalViewEmbedder2::GetViewRect(
    int64_t view_id,
    const std::unordered_map<int64_t, EmbeddedViewParams>& view_params) {
  const EmbeddedViewParams& params = view_params.at(view_id);
  // https://github.com/flutter/flutter/issues/59821
  return params.finalBoundingRect();
}

// |ExternalViewEmbedder|
void AndroidExternalViewEmbedder2::SubmitFlutterView(
    int64_t flutter_view_id,
    GrDirectContext* context,
    const std::shared_ptr<impeller::AiksContext>& aiks_context,
    std::unique_ptr<SurfaceFrame> frame) {
  TRACE_EVENT0("flutter", "AndroidExternalViewEmbedder2::SubmitFlutterView");

  if (!FrameHasPlatformLayers()) {
    frame->Submit();
    task_runners_.GetPlatformTaskRunner()->PostTask(fml::MakeCopyable(
        [this, jni_facade = jni_facade_,
         views_visible_last_frame = views_visible_last_frame_]() {
          // This pointer is guaranteed to not be dangling as long as
          // DestroySurfaces is called before the embedder is deleted. See
          // https://github.com/flutter/flutter/pull/176742#discussion_r2415229396.
          this->HideOverlayLayerIfNeeded();
          for (int64_t view_id : views_visible_last_frame) {
            jni_facade->hidePlatformView2(view_id);
          }

          jni_facade->applyTransaction();
        }));
    views_visible_last_frame_.clear();
    return;
  }

  std::unordered_map<int64_t, DlRect> view_rects;
  for (auto platform_id : composition_order_) {
    view_rects[platform_id] = GetViewRect(platform_id, view_params_);
  }

  std::unordered_map<int64_t, DlRect> overlay_layers =
      SliceViews(frame->Canvas(),     //
                 composition_order_,  //
                 slices_,             //
                 view_rects           //
      );

  // If there is no overlay Surface, initialize one on the platform thread. This
  // will only be done once per application launch, as the singular overlay
  // surface is never released.
  if (!surface_pool_->HasLayers()) {
    std::shared_ptr<fml::CountDownLatch> latch =
        std::make_shared<fml::CountDownLatch>(1u);
    task_runners_.GetPlatformTaskRunner()->PostTask(
        fml::MakeCopyable([&, latch]() {
          surface_pool_->GetLayer(context, android_context_, jni_facade_,
                                  surface_factory_);
          latch->CountDown();
        }));
    latch->Wait();
  }
  surface_pool_->ResetLayers();

  // Create Overlay frame. If overlay surface creation failed,
  // all this work must be skipped.
  std::unique_ptr<SurfaceFrame> overlay_frame;
  if (surface_pool_->HasLayers()) {
    for (size_t i = 0; i < composition_order_.size(); i++) {
      int64_t view_id = composition_order_[i];
      std::unordered_map<int64_t, DlRect>::const_iterator overlay =
          overlay_layers.find(view_id);

      if (overlay == overlay_layers.end()) {
        continue;
      }
      if (overlay_frame == nullptr) {
        std::shared_ptr<OverlayLayer> layer = surface_pool_->GetLayer(
            context, android_context_, jni_facade_, surface_factory_);
        overlay_frame = layer->surface->AcquireFrame(frame_size_);
        overlay_frame->Canvas()->Clear(flutter::DlColor::kTransparent());
      }

      DlCanvas* overlay_canvas = overlay_frame->Canvas();
      int restore_count = overlay_canvas->GetSaveCount();
      overlay_canvas->Save();
      overlay_canvas->ClipRect(overlay->second);

      // For all following platform views that would cover this overlay,
      // emulate the effect by adding a difference clip. This makes the
      // overlays appear as if they are under the platform view, when in
      // reality there is only a single layer.
      for (size_t j = i + 1; j < composition_order_.size(); j++) {
        DlRect view_rect = GetViewRect(composition_order_[j], view_params_);
        overlay_canvas->ClipRect(view_rect, DlClipOp::kDifference);
      }

      slices_[view_id]->render_into(overlay_canvas);
      overlay_canvas->RestoreToCount(restore_count);
    }
  }
  bool overlay_layer_has_content_this_frame_;
  if (overlay_frame != nullptr) {
    overlay_frame->set_submit_info({.frame_boundary = false});
    overlay_frame->Submit();
    overlay_layer_has_content_this_frame_ = true;
  } else {
    overlay_layer_has_content_this_frame_ = false;
  }

  frame->Submit();
  task_runners_.GetPlatformTaskRunner()->PostTask(fml::MakeCopyable(
      [&, composition_order = composition_order_, view_params = view_params_,
       jni_facade = jni_facade_, device_pixel_ratio = device_pixel_ratio_,
       slices = std::move(slices_),
       views_visible_last_frame = views_visible_last_frame_,
       overlay_layer_has_content_this_frame_]() mutable -> void {
        jni_facade->swapTransaction();

        if (overlay_layer_has_content_this_frame_) {
          ShowOverlayLayerIfNeeded();
        } else {
          HideOverlayLayerIfNeeded();
        }

        for (int64_t view_id : composition_order) {
          DlRect view_rect = GetViewRect(view_id, view_params);
          const EmbeddedViewParams& params = view_params.at(view_id);
          jni_facade->onDisplayPlatformView2(
              view_id,                //
              view_rect.GetX(),       //
              view_rect.GetY(),       //
              view_rect.GetWidth(),   //
              view_rect.GetHeight(),  //
              params.sizePoints().width * device_pixel_ratio,
              params.sizePoints().height * device_pixel_ratio,
              params.mutatorsStack()  //
          );
          // Remove from views visible last frame, so we can hide the rest.
          views_visible_last_frame.erase(view_id);
        }
        // Hide views that were visible last frame, but not in this frame.
        for (int64_t view_id : views_visible_last_frame) {
          jni_facade->hidePlatformView2(view_id);
        }

        jni_facade_->onEndFrame2();
      }));

  views_visible_last_frame_.clear();
  views_visible_last_frame_.insert(composition_order_.begin(),
                                   composition_order_.end());
}

// |ExternalViewEmbedder|
PostPrerollResult AndroidExternalViewEmbedder2::PostPrerollAction(
    const fml::RefPtr<fml::RasterThreadMerger>& raster_thread_merger) {
  return PostPrerollResult::kSuccess;
}

bool AndroidExternalViewEmbedder2::FrameHasPlatformLayers() {
  return !composition_order_.empty();
}

// |ExternalViewEmbedder|
DlCanvas* AndroidExternalViewEmbedder2::GetRootCanvas() {
  // On Android, the root surface is created from the on-screen render target.
  return nullptr;
}

void AndroidExternalViewEmbedder2::Reset() {
  composition_order_.clear();
  slices_.clear();
}

// |ExternalViewEmbedder|
void AndroidExternalViewEmbedder2::BeginFrame(
    GrDirectContext* context,
    const fml::RefPtr<fml::RasterThreadMerger>& raster_thread_merger) {}

// |ExternalViewEmbedder|
void AndroidExternalViewEmbedder2::PrepareFlutterView(
    DlISize frame_size,
    double device_pixel_ratio) {
  Reset();

  // The surface size changed. Therefore, destroy existing surfaces as
  // the existing surfaces in the pool can't be recycled.
  if (frame_size_ != frame_size) {
    DestroySurfaces();
  }
  surface_pool_->SetFrameSize(frame_size);
  jni_facade_->MaybeResizeSurfaceView(frame_size.width, frame_size.height);

  frame_size_ = frame_size;
  device_pixel_ratio_ = device_pixel_ratio;
}

// |ExternalViewEmbedder|
void AndroidExternalViewEmbedder2::CancelFrame() {
  Reset();
}

// |ExternalViewEmbedder|
void AndroidExternalViewEmbedder2::EndFrame(
    bool should_resubmit_frame,
    const fml::RefPtr<fml::RasterThreadMerger>& raster_thread_merger) {}

// |ExternalViewEmbedder|
bool AndroidExternalViewEmbedder2::SupportsDynamicThreadMerging() {
  return false;
}

// |ExternalViewEmbedder|
void AndroidExternalViewEmbedder2::Teardown() {
  DestroySurfaces();
}

// |ExternalViewEmbedder|
void AndroidExternalViewEmbedder2::DestroySurfaces() {
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
  overlay_layer_is_shown_.store(false);
}

void AndroidExternalViewEmbedder2::ShowOverlayLayerIfNeeded() {
  if (!overlay_layer_is_shown_.load()) {
    jni_facade_->showOverlaySurface2();
    overlay_layer_is_shown_.store(true);
  }
}

void AndroidExternalViewEmbedder2::HideOverlayLayerIfNeeded() {
  if (overlay_layer_is_shown_.load()) {
    jni_facade_->hideOverlaySurface2();
    overlay_layer_is_shown_.store(false);
  }
}

}  // namespace flutter
