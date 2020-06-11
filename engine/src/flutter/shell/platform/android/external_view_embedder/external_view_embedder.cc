// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/external_view_embedder/external_view_embedder.h"

#include "flutter/fml/trace_event.h"

namespace flutter {

AndroidExternalViewEmbedder::AndroidExternalViewEmbedder(
    std::shared_ptr<PlatformViewAndroidJNI> jni_facade)
    : ExternalViewEmbedder(), jni_facade_(jni_facade) {}

// |ExternalViewEmbedder|
void AndroidExternalViewEmbedder::PrerollCompositeEmbeddedView(
    int view_id,
    std::unique_ptr<EmbeddedViewParams> params) {
  // TODO(egarciad): Implement hybrid composition.
  // https://github.com/flutter/flutter/issues/55270
  TRACE_EVENT0("flutter",
               "AndroidExternalViewEmbedder::PrerollCompositeEmbeddedView");
  picture_recorders_[view_id] = std::make_unique<SkPictureRecorder>();
  picture_recorders_[view_id]->beginRecording(SkRect::Make(frame_size_));

  composition_order_.push_back(view_id);
}

// |ExternalViewEmbedder|
SkCanvas* AndroidExternalViewEmbedder::CompositeEmbeddedView(int view_id) {
  return picture_recorders_[view_id]->getRecordingCanvas();
}

// |ExternalViewEmbedder|
std::vector<SkCanvas*> AndroidExternalViewEmbedder::GetCurrentCanvases() {
  // TODO(egarciad): Implement hybrid composition.
  // https://github.com/flutter/flutter/issues/55270
  std::vector<SkCanvas*> canvases;
  for (size_t i = 0; i < composition_order_.size(); i++) {
    int64_t view_id = composition_order_[i];
    canvases.push_back(picture_recorders_[view_id]->getRecordingCanvas());
  }
  return canvases;
}

// |ExternalViewEmbedder|
bool AndroidExternalViewEmbedder::SubmitFrame(
    GrContext* context,
    std::unique_ptr<SurfaceFrame> frame) {
  // TODO(egarciad): Implement hybrid composition.
  // https://github.com/flutter/flutter/issues/55270
  TRACE_EVENT0("flutter", "AndroidExternalViewEmbedder::SubmitFrame");
  if (should_run_rasterizer_on_platform_thread_) {
    // Don't submit the current frame if the frame will be resubmitted.
    return true;
  }
  for (size_t i = 0; i < composition_order_.size(); i++) {
    int64_t view_id = composition_order_[i];
    frame->SkiaCanvas()->drawPicture(
        picture_recorders_[view_id]->finishRecordingAsPicture());
  }
  return frame->Submit();
}

// |ExternalViewEmbedder|
PostPrerollResult AndroidExternalViewEmbedder::PostPrerollAction(
    fml::RefPtr<fml::RasterThreadMerger> raster_thread_merger) {
  // This frame may remove existing platform views that aren't contained
  // in `composition_order_`.
  //
  // If this frame doesn't have platform views, it's still required to keep
  // the rasterizer running on the platform thread for at least one more
  // frame.
  //
  // To keep the rasterizer running on the platform thread one more frame,
  // `kDefaultMergedLeaseDuration` must be at least `1`.
  bool has_platform_views = composition_order_.size() > 0;
  if (has_platform_views) {
    if (raster_thread_merger->IsMerged()) {
      raster_thread_merger->ExtendLeaseTo(kDefaultMergedLeaseDuration);
    } else {
      // Merge the raster and platform threads in `EndFrame`.
      should_run_rasterizer_on_platform_thread_ = true;
      CancelFrame();
      return PostPrerollResult::kResubmitFrame;
    }
  }
  return PostPrerollResult::kSuccess;
}

// |ExternalViewEmbedder|
SkCanvas* AndroidExternalViewEmbedder::GetRootCanvas() {
  // On Android, the root surface is created from the on-screen render target.
  return nullptr;
}

void AndroidExternalViewEmbedder::Reset() {
  composition_order_.clear();
  picture_recorders_.clear();
}

// |ExternalViewEmbedder|
void AndroidExternalViewEmbedder::BeginFrame(SkISize frame_size,
                                             GrContext* context,
                                             double device_pixel_ratio) {
  Reset();
  frame_size_ = frame_size;
}

// |ExternalViewEmbedder|
void AndroidExternalViewEmbedder::CancelFrame() {
  Reset();
}

// |ExternalViewEmbedder|
void AndroidExternalViewEmbedder::EndFrame(
    fml::RefPtr<fml::RasterThreadMerger> raster_thread_merger) {
  if (should_run_rasterizer_on_platform_thread_) {
    raster_thread_merger->MergeWithLease(kDefaultMergedLeaseDuration);
    should_run_rasterizer_on_platform_thread_ = false;
  }
}

}  // namespace flutter
