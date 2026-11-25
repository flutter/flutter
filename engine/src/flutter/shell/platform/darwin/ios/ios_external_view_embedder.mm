// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/ios/ios_external_view_embedder.h"
#include "fml/task_runner.h"

#include "flutter/common/constants.h"

FLUTTER_ASSERT_ARC

namespace flutter {

IOSExternalViewEmbedder::IOSExternalViewEmbedder(
    __weak FlutterPlatformViewsController* platform_views_controller,
    const std::shared_ptr<IOSContext>& context)
    : platform_views_controller_(platform_views_controller), ios_context_(context) {
  FML_CHECK(ios_context_);
}

IOSExternalViewEmbedder::~IOSExternalViewEmbedder() = default;

// |ExternalViewEmbedder|
DlCanvas* IOSExternalViewEmbedder::GetRootCanvas() {
  // On iOS, the root surface is created from the on-screen render target. Only the surfaces for the
  // various overlays are controlled by this class.
  return nullptr;
}

// |ExternalViewEmbedder|
void IOSExternalViewEmbedder::CancelFrame() {
  TRACE_EVENT0("flutter", "IOSExternalViewEmbedder::CancelFrame");
  ResetFrameState();
}

// |ExternalViewEmbedder|
void IOSExternalViewEmbedder::BeginFrame(
    GrDirectContext* context,
    const fml::RefPtr<fml::RasterThreadMerger>& raster_thread_merger) {}

// |ExternalViewEmbedder|
void IOSExternalViewEmbedder::PrepareFlutterView(DlISize frame_size, double device_pixel_ratio) {
  FML_DCHECK(device_pixel_ratio > 0);
  ResetFrameState();
  frame_size_ = frame_size;
  device_pixel_ratio_ = device_pixel_ratio;
}

// |ExternalViewEmbedder|
void IOSExternalViewEmbedder::PrerollCompositeEmbeddedView(
    int64_t view_id,
    std::unique_ptr<EmbeddedViewParams> params) {
  TRACE_EVENT0("flutter", "IOSExternalViewEmbedder::PrerollCompositeEmbeddedView");
  DlRect view_bounds = DlRect::MakeSize(frame_size_);
  slices_.insert_or_assign(view_id, std::make_unique<DisplayListEmbedderViewSlice>(view_bounds));

  composition_order_.push_back(view_id);
  composition_params_[view_id] = std::move(*params);
}

// |ExternalViewEmbedder|
DlCanvas* IOSExternalViewEmbedder::CompositeEmbeddedView(int64_t view_id) {
  TRACE_EVENT0("flutter", "IOSExternalViewEmbedder::CompositeEmbeddedView");
  FML_DCHECK(slices_.find(view_id) != slices_.end());
  return slices_[view_id]->canvas();
}

// |ExternalViewEmbedder|
void IOSExternalViewEmbedder::SubmitFlutterView(
    int64_t flutter_view_id,
    GrDirectContext* context,
    const std::shared_ptr<impeller::AiksContext>& aiks_context,
    std::unique_ptr<SurfaceFrame> frame) {
  TRACE_EVENT0("flutter", "IOSExternalViewEmbedder::SubmitFlutterView");

  // TODO(dkwingsmt): This class only supports rendering into the implicit view.
  // Properly support multi-view in the future.
  FML_DCHECK(flutter_view_id == kFlutterImplicitViewId);
  FML_CHECK(platform_views_controller_);
  [platform_views_controller_ submitFrame:std::move(frame)
                           withIosContext:ios_context_
                                frameSize:frame_size_
                         devicePixelRatio:device_pixel_ratio_
                         compositionOrder:composition_order_
                        compositionParams:composition_params_
                                   slices:slices_];
  TRACE_EVENT0("flutter", "IOSExternalViewEmbedder::DidSubmitFrame");
}

// |ExternalViewEmbedder|
bool IOSExternalViewEmbedder::SupportsDynamicThreadMerging() {
  return false;
}

// |ExternalViewEmbedder|
void IOSExternalViewEmbedder::PushFilterToVisitedPlatformViews(
    const std::shared_ptr<DlImageFilter>& filter,
    const DlRect& filter_rect) {
  for (int64_t id : visited_platform_views_) {
    composition_params_[id].PushImageFilter(filter, filter_rect);
  }
}

// |ExternalViewEmbedder|
void IOSExternalViewEmbedder::PushVisitedPlatformView(int64_t view_id) {
  visited_platform_views_.push_back(view_id);
}

// |ExternalViewEmbedder|
void IOSExternalViewEmbedder::PushClipRectToVisitedPlatformViews(const DlRect& clip_rect) {
  for (int64_t id : visited_platform_views_) {
    composition_params_[id].PushPlatformViewClipRect(clip_rect);
  }
}

// |ExternalViewEmbedder|
void IOSExternalViewEmbedder::PushClipRRectToVisitedPlatformViews(const DlRoundRect& clip_rrect) {
  for (int64_t id : visited_platform_views_) {
    composition_params_[id].PushPlatformViewClipRRect(clip_rrect);
  }
}

// |ExternalViewEmbedder|
void IOSExternalViewEmbedder::PushClipRSuperellipseToVisitedPlatformViews(
    const DlRoundSuperellipse& clip_rse) {
  for (int64_t id : visited_platform_views_) {
    composition_params_[id].PushPlatformViewClipRSuperellipse(clip_rse);
  }
}

// |ExternalViewEmbedder|
void IOSExternalViewEmbedder::PushClipPathToVisitedPlatformViews(const DlPath& clip_path) {
  for (int64_t id : visited_platform_views_) {
    composition_params_[id].PushPlatformViewClipPath(clip_path);
  }
}

void IOSExternalViewEmbedder::ResetFrameState() {
  slices_.clear();
  composition_order_.clear();
  composition_params_.clear();
  visited_platform_views_.clear();
}

}  // namespace flutter
