// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/external_view_embedder/external_view_embedder_wrapper.h"

#include <utility>

#include "flutter/impeller/renderer/backend/vulkan/context_vk.h"
#include "flutter/shell/platform/android/android_rendering_selector.h"
#include "flutter/shell/platform/android/external_view_embedder/external_view_embedder.h"
#include "flutter/shell/platform/android/external_view_embedder/external_view_embedder_2.h"

namespace flutter {

AndroidExternalViewEmbedderWrapper::AndroidExternalViewEmbedderWrapper(
    bool meets_hcpp_criteria,
    const AndroidContext& android_context,
    std::shared_ptr<PlatformViewAndroidJNI> jni_facade,
    std::shared_ptr<AndroidSurfaceFactory> surface_factory,
    const TaskRunners& task_runners)
    : ExternalViewEmbedder(),
      meets_hcpp_criteria_(meets_hcpp_criteria),
      android_context_(android_context),
      task_runners_(task_runners),
      jni_facade_(std::move(jni_facade)),
      surface_factory_(std::move(surface_factory)) {}

void AndroidExternalViewEmbedderWrapper::EnsureInitialized() {
  if (non_hcpp_view_embedder_ || hcpp_view_embedder_) {
    return;
  }
  if (meets_hcpp_criteria_ &&
      android_context_.RenderingApi() == AndroidRenderingAPI::kImpellerVulkan &&
      impeller::ContextVK::Cast(*android_context_.GetImpellerContext())
          .GetShouldEnableSurfaceControlSwapchain()) {
    hcpp_view_embedder_ = std::make_unique<AndroidExternalViewEmbedder2>(
        android_context_, jni_facade_, surface_factory_, task_runners_);
  } else {
    non_hcpp_view_embedder_ = std::make_unique<AndroidExternalViewEmbedder>(
        android_context_, jni_facade_, surface_factory_, task_runners_);
  }
}

// |ExternalViewEmbedder|
void AndroidExternalViewEmbedderWrapper::PrerollCompositeEmbeddedView(
    int64_t view_id,
    std::unique_ptr<EmbeddedViewParams> params) {
  EnsureInitialized();
  if (hcpp_view_embedder_) {
    hcpp_view_embedder_->PrerollCompositeEmbeddedView(view_id,
                                                      std::move(params));
  } else {
    non_hcpp_view_embedder_->PrerollCompositeEmbeddedView(view_id,
                                                          std::move(params));
  }
}

// |ExternalViewEmbedder|
DlCanvas* AndroidExternalViewEmbedderWrapper::CompositeEmbeddedView(
    int64_t view_id) {
  EnsureInitialized();
  if (hcpp_view_embedder_) {
    return hcpp_view_embedder_->CompositeEmbeddedView(view_id);
  } else {
    return non_hcpp_view_embedder_->CompositeEmbeddedView(view_id);
  }
}

// |ExternalViewEmbedder|
void AndroidExternalViewEmbedderWrapper::SubmitFlutterView(
    int64_t flutter_view_id,
    GrDirectContext* context,
    const std::shared_ptr<impeller::AiksContext>& aiks_context,
    std::unique_ptr<SurfaceFrame> frame) {
  EnsureInitialized();
  if (hcpp_view_embedder_) {
    hcpp_view_embedder_->SubmitFlutterView(flutter_view_id, context,
                                           aiks_context, std::move(frame));
  } else {
    non_hcpp_view_embedder_->SubmitFlutterView(flutter_view_id, context,
                                               aiks_context, std::move(frame));
  }
}

// |ExternalViewEmbedder|
PostPrerollResult AndroidExternalViewEmbedderWrapper::PostPrerollAction(
    const fml::RefPtr<fml::RasterThreadMerger>& raster_thread_merger) {
  EnsureInitialized();
  if (hcpp_view_embedder_) {
    return hcpp_view_embedder_->PostPrerollAction(raster_thread_merger);
  } else {
    return non_hcpp_view_embedder_->PostPrerollAction(raster_thread_merger);
  }
}

DlCanvas* AndroidExternalViewEmbedderWrapper::GetRootCanvas() {
  // On Android, the root surface is created from the on-screen render target.
  return nullptr;
}

// |ExternalViewEmbedder|
void AndroidExternalViewEmbedderWrapper::BeginFrame(
    GrDirectContext* context,
    const fml::RefPtr<fml::RasterThreadMerger>& raster_thread_merger) {
  EnsureInitialized();
  if (hcpp_view_embedder_) {
    hcpp_view_embedder_->BeginFrame(context, raster_thread_merger);
  } else {
    non_hcpp_view_embedder_->BeginFrame(context, raster_thread_merger);
  }
}

// |ExternalViewEmbedder|
void AndroidExternalViewEmbedderWrapper::PrepareFlutterView(
    DlISize frame_size,
    double device_pixel_ratio) {
  EnsureInitialized();
  if (hcpp_view_embedder_) {
    hcpp_view_embedder_->PrepareFlutterView(frame_size, device_pixel_ratio);
  } else {
    non_hcpp_view_embedder_->PrepareFlutterView(frame_size, device_pixel_ratio);
  }
}

// |ExternalViewEmbedder|
void AndroidExternalViewEmbedderWrapper::CancelFrame() {
  EnsureInitialized();
  if (hcpp_view_embedder_) {
    hcpp_view_embedder_->CancelFrame();
  } else {
    non_hcpp_view_embedder_->CancelFrame();
  }
}

// |ExternalViewEmbedder|
void AndroidExternalViewEmbedderWrapper::EndFrame(
    bool should_resubmit_frame,
    const fml::RefPtr<fml::RasterThreadMerger>& raster_thread_merger) {
  EnsureInitialized();
  if (hcpp_view_embedder_) {
    hcpp_view_embedder_->EndFrame(should_resubmit_frame, raster_thread_merger);
  } else {
    non_hcpp_view_embedder_->EndFrame(should_resubmit_frame,
                                      raster_thread_merger);
  }
}

// |ExternalViewEmbedder|
bool AndroidExternalViewEmbedderWrapper::SupportsDynamicThreadMerging() {
  EnsureInitialized();
  if (hcpp_view_embedder_) {
    return hcpp_view_embedder_->SupportsDynamicThreadMerging();
  } else {
    return non_hcpp_view_embedder_->SupportsDynamicThreadMerging();
  }
}

// |ExternalViewEmbedder|
void AndroidExternalViewEmbedderWrapper::Teardown() {
  EnsureInitialized();
  if (hcpp_view_embedder_) {
    hcpp_view_embedder_->Teardown();
  } else {
    non_hcpp_view_embedder_->Teardown();
  }
}

}  // namespace flutter
