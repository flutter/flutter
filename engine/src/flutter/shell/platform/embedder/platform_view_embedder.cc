// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/embedder/platform_view_embedder.h"

namespace shell {

PlatformViewEmbedder::PlatformViewEmbedder(
    PlatformView::Delegate& delegate,
    blink::TaskRunners task_runners,
    EmbedderSurfaceGL::GLDispatchTable gl_dispatch_table,
    bool fbo_reset_after_present,
    PlatformDispatchTable platform_dispatch_table)
    : PlatformView(delegate, std::move(task_runners)),
      embedder_surface_(
          std::make_unique<EmbedderSurfaceGL>(gl_dispatch_table,
                                              fbo_reset_after_present)),
      platform_dispatch_table_(platform_dispatch_table) {}

PlatformViewEmbedder::PlatformViewEmbedder(
    PlatformView::Delegate& delegate,
    blink::TaskRunners task_runners,
    EmbedderSurfaceSoftware::SoftwareDispatchTable software_dispatch_table,
    PlatformDispatchTable platform_dispatch_table)
    : PlatformView(delegate, std::move(task_runners)),
      embedder_surface_(
          std::make_unique<EmbedderSurfaceSoftware>(software_dispatch_table)),
      platform_dispatch_table_(platform_dispatch_table) {}

PlatformViewEmbedder::~PlatformViewEmbedder() = default;

void PlatformViewEmbedder::HandlePlatformMessage(
    fml::RefPtr<blink::PlatformMessage> message) {
  if (!message) {
    return;
  }

  if (!message->response()) {
    return;
  }

  if (platform_dispatch_table_.platform_message_response_callback == nullptr) {
    message->response()->CompleteEmpty();
    return;
  }

  platform_dispatch_table_.platform_message_response_callback(
      std::move(message));
}

// |shell::PlatformView|
std::unique_ptr<Surface> PlatformViewEmbedder::CreateRenderingSurface() {
  if (embedder_surface_ == nullptr) {
    FML_LOG(ERROR) << "Embedder surface was null.";
    return nullptr;
  }
  return embedder_surface_->CreateGPUSurface();
}

// |shell::PlatformView|
sk_sp<GrContext> PlatformViewEmbedder::CreateResourceContext() const {
  if (embedder_surface_ == nullptr) {
    FML_LOG(ERROR) << "Embedder surface was null.";
    return nullptr;
  }
  return embedder_surface_->CreateResourceContext();
}

}  // namespace shell
