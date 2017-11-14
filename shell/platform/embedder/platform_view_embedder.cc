// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/embedder/platform_view_embedder.h"
#include "flutter/shell/gpu/gpu_rasterizer.h"

namespace shell {

PlatformViewEmbedder::PlatformViewEmbedder(DispatchTable dispatch_table)
    : PlatformView(std::make_unique<GPURasterizer>(nullptr)),
      dispatch_table_(dispatch_table) {}

PlatformViewEmbedder::~PlatformViewEmbedder() {
  NotifyDestroyed();
}

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

void PlatformViewEmbedder::Attach() {
  CreateEngine();
  NotifyCreated(std::make_unique<shell::GPUSurfaceGL>(this));
}

bool PlatformViewEmbedder::ResourceContextMakeCurrent() {
  // Unsupported.
  return false;
}

void PlatformViewEmbedder::RunFromSource(const std::string& assets_directory,
                                         const std::string& main,
                                         const std::string& packages) {
  FXL_LOG(INFO) << "Hot reloading is unsupported on this platform.";
}

}  // namespace shell
