// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/embedder/platform_view_embedder.h"

#include "flutter/shell/common/io_manager.h"

namespace shell {

PlatformViewEmbedder::PlatformViewEmbedder(PlatformView::Delegate& delegate,
                                           blink::TaskRunners task_runners,
                                           DispatchTable dispatch_table)
    : PlatformView(delegate, std::move(task_runners)),
      dispatch_table_(dispatch_table) {}

PlatformViewEmbedder::~PlatformViewEmbedder() = default;

bool PlatformViewEmbedder::GLContextMakeCurrent() {
  return dispatch_table_.gl_make_current_callback();
}

bool PlatformViewEmbedder::GLContextClearCurrent() {
  return dispatch_table_.gl_clear_current_callback();
}

bool PlatformViewEmbedder::GLContextPresent() {
  return dispatch_table_.gl_present_callback();
}

intptr_t PlatformViewEmbedder::GLContextFBO() const {
  return dispatch_table_.gl_fbo_callback();
}

void PlatformViewEmbedder::HandlePlatformMessage(
    fxl::RefPtr<blink::PlatformMessage> message) {
  if (!message) {
    return;
  }

  if (!message->response()) {
    return;
  }

  if (dispatch_table_.platform_message_response_callback == nullptr) {
    message->response()->CompleteEmpty();
    return;
  }

  dispatch_table_.platform_message_response_callback(std::move(message));
}

std::unique_ptr<Surface> PlatformViewEmbedder::CreateRenderingSurface() {
  return std::make_unique<GPUSurfaceGL>(this);
}

sk_sp<GrContext> PlatformViewEmbedder::CreateResourceContext() const {
  auto callback = dispatch_table_.gl_make_resource_current_callback;
  if (callback && callback()) {
    return IOManager::CreateCompatibleResourceLoadingContext(
        GrBackend::kOpenGL_GrBackend);
  }
  return nullptr;
}

}  // namespace shell
