// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/ios/ios_external_view_embedder.h"
#include <cstddef>
#include "fml/task_runner.h"
#include "flutter/shell/platform/darwin/ios/platform_view_ios.h"
#include "impeller/renderer/backend/metal/surface_mtl.h"
#include "impeller/renderer/backend/metal/swapchain_transients_mtl.h"
#include "impeller/display_list/dl_dispatcher.h"
#include "flutter/fml/make_copyable.h"
#import "flutter/shell/platform/darwin/ios/ios_surface_metal_impeller.h"
#import "flutter/shell/gpu/gpu_surface_metal_impeller.h"

#include "flutter/common/constants.h"

FLUTTER_ASSERT_ARC

namespace flutter {

IOSExternalViewEmbedder::IOSExternalViewEmbedder(
    __weak FlutterPlatformViewsController* platform_views_controller,
    const std::shared_ptr<IOSContext>& context,
    const CreateSurfaceFrameCallback& create_surface_frame_callback
  ) : platform_views_controller_(platform_views_controller),
      ios_context_(context),
      create_surface_frame_callback_(create_surface_frame_callback) {
  FML_CHECK(ios_context_);
}

IOSExternalViewEmbedder::~IOSExternalViewEmbedder() = default;

// |ExternalViewEmbedder|
DlCanvas* IOSExternalViewEmbedder::GetRootCanvas() {
  return pending_frame_->Canvas();
}

// |ExternalViewEmbedder|
void IOSExternalViewEmbedder::CancelFrame() {
  TRACE_EVENT0("flutter", "IOSExternalViewEmbedder::CancelFrame");
  FML_CHECK(platform_views_controller_);
  [platform_views_controller_ cancelFrame];
}

// |ExternalViewEmbedder|
void IOSExternalViewEmbedder::BeginFrame(
    GrDirectContext* context,
    const fml::RefPtr<fml::RasterThreadMerger>& raster_thread_merger) {}

// |ExternalViewEmbedder|
void IOSExternalViewEmbedder::PrepareFlutterView(int64_t flutter_view_id, DlISize frame_size, double device_pixel_ratio) {
  FML_CHECK(platform_views_controller_);

  pending_frame_ = create_surface_frame_callback_(flutter_view_id, frame_size);

  [platform_views_controller_ beginFrameWithSize:frame_size];
}

// |ExternalViewEmbedder|
void IOSExternalViewEmbedder::PrerollCompositeEmbeddedView(
    int64_t view_id,
    std::unique_ptr<EmbeddedViewParams> params) {
  TRACE_EVENT0("flutter", "IOSExternalViewEmbedder::PrerollCompositeEmbeddedView");
  FML_CHECK(platform_views_controller_);
  [platform_views_controller_ prerollCompositeEmbeddedView:view_id withParams:std::move(params)];
}

// |ExternalViewEmbedder|
PostPrerollResult IOSExternalViewEmbedder::PostPrerollAction(
    const fml::RefPtr<fml::RasterThreadMerger>& raster_thread_merger) {
  TRACE_EVENT0("flutter", "IOSExternalViewEmbedder::PostPrerollAction");
  FML_CHECK(platform_views_controller_);
  PostPrerollResult result =
      [platform_views_controller_ postPrerollActionWithThreadMerger:raster_thread_merger];
  return result;
}

// |ExternalViewEmbedder|
DlCanvas* IOSExternalViewEmbedder::CompositeEmbeddedView(int64_t view_id) {
  TRACE_EVENT0("flutter", "IOSExternalViewEmbedder::CompositeEmbeddedView");
  FML_CHECK(platform_views_controller_);
  return [platform_views_controller_ compositeEmbeddedViewWithId:view_id];
}

// |ExternalViewEmbedder|
void IOSExternalViewEmbedder::SubmitFlutterView(
    int64_t flutter_view_id,
    GrDirectContext* context,
    const std::shared_ptr<impeller::AiksContext>& aiks_context,
    std::unique_ptr<SurfaceFrame> frame) {
  TRACE_EVENT0("flutter", "IOSExternalViewEmbedder::SubmitFlutterView");
  FML_CHECK(platform_views_controller_);

  [platform_views_controller_ submitFrame:std::move(pending_frame_)
                           withIosContext:ios_context_
                        withFlutterViewId:flutter_view_id];
  frame->Submit();
  TRACE_EVENT0("flutter", "IOSExternalViewEmbedder::DidSubmitFrame");
}

// |ExternalViewEmbedder|
void IOSExternalViewEmbedder::EndFrame(
    bool should_resubmit_frame,
    const fml::RefPtr<fml::RasterThreadMerger>& raster_thread_merger) {
  TRACE_EVENT0("flutter", "IOSExternalViewEmbedder::EndFrame");
  [platform_views_controller_ endFrameWithResubmit:should_resubmit_frame
                                      threadMerger:raster_thread_merger];
}

// |ExternalViewEmbedder|
bool IOSExternalViewEmbedder::SupportsDynamicThreadMerging() {
  return false;
}

// |ExternalViewEmbedder|
void IOSExternalViewEmbedder::PushFilterToVisitedPlatformViews(
    const std::shared_ptr<DlImageFilter>& filter,
    const DlRect& filter_rect) {
  [platform_views_controller_ pushFilterToVisitedPlatformViews:filter withRect:filter_rect];
}

// |ExternalViewEmbedder|
void IOSExternalViewEmbedder::PushVisitedPlatformView(int64_t view_id) {
  [platform_views_controller_ pushVisitedPlatformViewId:view_id];
}

// |ExternalViewEmbedder|
void IOSExternalViewEmbedder::PushClipRectToVisitedPlatformViews(const DlRect& clip_rect) {
  [platform_views_controller_ pushClipRectToVisitedPlatformViews:clip_rect];
}

// |ExternalViewEmbedder|
void IOSExternalViewEmbedder::PushClipRRectToVisitedPlatformViews(const DlRoundRect& clip_rrect) {
  [platform_views_controller_ pushClipRRectToVisitedPlatformViews:clip_rrect];
}

// |ExternalViewEmbedder|
void IOSExternalViewEmbedder::PushClipRSuperellipseToVisitedPlatformViews(
    const DlRoundSuperellipse& clip_rse) {
  [platform_views_controller_ pushClipRSuperellipseToVisitedPlatformViews:clip_rse];
}

// |ExternalViewEmbedder|
void IOSExternalViewEmbedder::PushClipPathToVisitedPlatformViews(const DlPath& clip_path) {
  [platform_views_controller_ pushClipPathToVisitedPlatformViews:clip_path];
}

void IOSExternalViewEmbedder::CollectView(int64_t view_id) {
  [platform_views_controller_ collectView:view_id];
}

}  // namespace flutter
