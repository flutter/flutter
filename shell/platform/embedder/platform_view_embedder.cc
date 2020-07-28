// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/embedder/platform_view_embedder.h"

namespace flutter {

PlatformViewEmbedder::PlatformViewEmbedder(
    PlatformView::Delegate& delegate,
    flutter::TaskRunners task_runners,
    EmbedderSurfaceGL::GLDispatchTable gl_dispatch_table,
    bool fbo_reset_after_present,
    PlatformDispatchTable platform_dispatch_table,
    std::unique_ptr<EmbedderExternalViewEmbedder> external_view_embedder)
    : PlatformView(delegate, std::move(task_runners)),
      embedder_surface_(std::make_unique<EmbedderSurfaceGL>(
          gl_dispatch_table,
          fbo_reset_after_present,
          std::move(external_view_embedder))),
      platform_dispatch_table_(platform_dispatch_table) {}

PlatformViewEmbedder::PlatformViewEmbedder(
    PlatformView::Delegate& delegate,
    flutter::TaskRunners task_runners,
    EmbedderSurfaceSoftware::SoftwareDispatchTable software_dispatch_table,
    PlatformDispatchTable platform_dispatch_table,
    std::unique_ptr<EmbedderExternalViewEmbedder> external_view_embedder)
    : PlatformView(delegate, std::move(task_runners)),
      embedder_surface_(std::make_unique<EmbedderSurfaceSoftware>(
          software_dispatch_table,
          std::move(external_view_embedder))),
      platform_dispatch_table_(platform_dispatch_table) {}

PlatformViewEmbedder::~PlatformViewEmbedder() = default;

void PlatformViewEmbedder::UpdateSemantics(
    flutter::SemanticsNodeUpdates update,
    flutter::CustomAccessibilityActionUpdates actions) {
  if (platform_dispatch_table_.update_semantics_nodes_callback != nullptr) {
    platform_dispatch_table_.update_semantics_nodes_callback(std::move(update));
  }
  if (platform_dispatch_table_.update_semantics_custom_actions_callback !=
      nullptr) {
    platform_dispatch_table_.update_semantics_custom_actions_callback(
        std::move(actions));
  }
}

void PlatformViewEmbedder::HandlePlatformMessage(
    fml::RefPtr<flutter::PlatformMessage> message) {
  if (!message) {
    return;
  }

  if (platform_dispatch_table_.platform_message_response_callback == nullptr) {
    if (message->response()) {
      message->response()->CompleteEmpty();
    }
    return;
  }

  platform_dispatch_table_.platform_message_response_callback(
      std::move(message));
}

// |PlatformView|
std::unique_ptr<Surface> PlatformViewEmbedder::CreateRenderingSurface() {
  if (embedder_surface_ == nullptr) {
    FML_LOG(ERROR) << "Embedder surface was null.";
    return nullptr;
  }
  return embedder_surface_->CreateGPUSurface();
}

// |PlatformView|
sk_sp<GrDirectContext> PlatformViewEmbedder::CreateResourceContext() const {
  if (embedder_surface_ == nullptr) {
    FML_LOG(ERROR) << "Embedder surface was null.";
    return nullptr;
  }
  return embedder_surface_->CreateResourceContext();
}

// |PlatformView|
std::unique_ptr<VsyncWaiter> PlatformViewEmbedder::CreateVSyncWaiter() {
  if (!platform_dispatch_table_.vsync_callback) {
    // Superclass implementation creates a timer based fallback.
    return PlatformView::CreateVSyncWaiter();
  }

  return std::make_unique<VsyncWaiterEmbedder>(
      platform_dispatch_table_.vsync_callback, task_runners_);
}

// |PlatformView|
std::unique_ptr<std::vector<std::string>>
PlatformViewEmbedder::ComputePlatformResolvedLocales(
    const std::vector<std::string>& supported_locale_data) {
  if (platform_dispatch_table_.compute_platform_resolved_locale_callback !=
      nullptr) {
    return platform_dispatch_table_.compute_platform_resolved_locale_callback(
        supported_locale_data);
  }
  std::unique_ptr<std::vector<std::string>> out =
      std::make_unique<std::vector<std::string>>();
  return out;
}

}  // namespace flutter
