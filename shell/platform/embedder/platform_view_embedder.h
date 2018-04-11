// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_EMBEDDER_PLATFORM_VIEW_EMBEDDER_H_
#define FLUTTER_SHELL_PLATFORM_EMBEDDER_PLATFORM_VIEW_EMBEDDER_H_

#include "flutter/shell/common/platform_view.h"
#include "flutter/shell/gpu/gpu_surface_gl.h"
#include "flutter/shell/platform/embedder/embedder.h"
#include "lib/fxl/macros.h"

namespace shell {

class PlatformViewEmbedder final : public PlatformView,
                                   public GPUSurfaceGLDelegate {
 public:
  using PlatformMessageResponseCallback =
      std::function<void(fxl::RefPtr<blink::PlatformMessage>)>;
  struct DispatchTable {
    std::function<bool(void)> gl_make_current_callback;   // required
    std::function<bool(void)> gl_clear_current_callback;  // required
    std::function<bool(void)> gl_present_callback;        // required
    std::function<intptr_t(void)> gl_fbo_callback;        // required
    PlatformMessageResponseCallback
        platform_message_response_callback;                       // optional
    std::function<bool(void)> gl_make_resource_current_callback;  // optional
  };

  PlatformViewEmbedder(PlatformView::Delegate& delegate,
                       blink::TaskRunners task_runners,
                       DispatchTable dispatch_table);

  ~PlatformViewEmbedder() override;

  // |shell::GPUSurfaceGLDelegate|
  bool GLContextMakeCurrent() override;

  // |shell::GPUSurfaceGLDelegate|
  bool GLContextClearCurrent() override;

  // |shell::GPUSurfaceGLDelegate|
  bool GLContextPresent() override;

  // |shell::GPUSurfaceGLDelegate|
  intptr_t GLContextFBO() const override;

  // |shell::PlatformView|
  void HandlePlatformMessage(
      fxl::RefPtr<blink::PlatformMessage> message) override;

 private:
  DispatchTable dispatch_table_;

  // |shell::PlatformView|
  std::unique_ptr<Surface> CreateRenderingSurface() override;

  // |shell::PlatformView|
  sk_sp<GrContext> CreateResourceContext() const override;

  FXL_DISALLOW_COPY_AND_ASSIGN(PlatformViewEmbedder);
};

}  // namespace shell

#endif  // FLUTTER_SHELL_PLATFORM_EMBEDDER_PLATFORM_VIEW_EMBEDDER_H_
