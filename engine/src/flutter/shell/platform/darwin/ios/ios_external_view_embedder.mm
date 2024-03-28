// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/ios/ios_external_view_embedder.h"

#include "flutter/common/constants.h"

namespace flutter {

IOSExternalViewEmbedder::IOSExternalViewEmbedder(
    const std::shared_ptr<FlutterPlatformViewsController>& platform_views_controller,
    std::shared_ptr<IOSContext> context)
    : platform_views_controller_(platform_views_controller), ios_context_(std::move(context)) {
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
  FML_CHECK(platform_views_controller_);
  platform_views_controller_->CancelFrame();
}

// |ExternalViewEmbedder|
void IOSExternalViewEmbedder::BeginFrame(
    GrDirectContext* context,
    const fml::RefPtr<fml::RasterThreadMerger>& raster_thread_merger) {}

// |ExternalViewEmbedder|
void IOSExternalViewEmbedder::PrepareFlutterView(SkISize frame_size, double device_pixel_ratio) {
  FML_CHECK(platform_views_controller_);
  platform_views_controller_->BeginFrame(frame_size);
}

// |ExternalViewEmbedder|
void IOSExternalViewEmbedder::PrerollCompositeEmbeddedView(
    int64_t view_id,
    std::unique_ptr<EmbeddedViewParams> params) {
  TRACE_EVENT0("flutter", "IOSExternalViewEmbedder::PrerollCompositeEmbeddedView");
  FML_CHECK(platform_views_controller_);
  platform_views_controller_->PrerollCompositeEmbeddedView(view_id, std::move(params));
}

// |ExternalViewEmbedder|
PostPrerollResult IOSExternalViewEmbedder::PostPrerollAction(
    const fml::RefPtr<fml::RasterThreadMerger>& raster_thread_merger) {
  TRACE_EVENT0("flutter", "IOSExternalViewEmbedder::PostPrerollAction");
  FML_CHECK(platform_views_controller_);
  PostPrerollResult result = platform_views_controller_->PostPrerollAction(raster_thread_merger);
  return result;
}

// |ExternalViewEmbedder|
DlCanvas* IOSExternalViewEmbedder::CompositeEmbeddedView(int64_t view_id) {
  TRACE_EVENT0("flutter", "IOSExternalViewEmbedder::CompositeEmbeddedView");
  FML_CHECK(platform_views_controller_);
  return platform_views_controller_->CompositeEmbeddedView(view_id);
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
  platform_views_controller_->SubmitFrame(context, ios_context_, std::move(frame));
  TRACE_EVENT0("flutter", "IOSExternalViewEmbedder::DidSubmitFrame");
}

// |ExternalViewEmbedder|
void IOSExternalViewEmbedder::EndFrame(
    bool should_resubmit_frame,
    const fml::RefPtr<fml::RasterThreadMerger>& raster_thread_merger) {
  TRACE_EVENT0("flutter", "IOSExternalViewEmbedder::EndFrame");
  platform_views_controller_->EndFrame(should_resubmit_frame, raster_thread_merger);
}

// |ExternalViewEmbedder|
bool IOSExternalViewEmbedder::SupportsDynamicThreadMerging() {
  return true;
}

// |ExternalViewEmbedder|
void IOSExternalViewEmbedder::PushFilterToVisitedPlatformViews(
    const std::shared_ptr<const DlImageFilter>& filter,
    const SkRect& filter_rect) {
  platform_views_controller_->PushFilterToVisitedPlatformViews(filter, filter_rect);
}

// |ExternalViewEmbedder|
void IOSExternalViewEmbedder::PushVisitedPlatformView(int64_t view_id) {
  platform_views_controller_->PushVisitedPlatformView(view_id);
}

}  // namespace flutter
