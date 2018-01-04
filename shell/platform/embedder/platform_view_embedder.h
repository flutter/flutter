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

class PlatformViewEmbedder : public PlatformView, public GPUSurfaceGLDelegate {
 public:
  using PlatformMessageResponseCallback =
      std::function<void(fxl::RefPtr<blink::PlatformMessage>)>;
  struct DispatchTable {
    std::function<bool(void)> gl_make_current_callback;   // required
    std::function<bool(void)> gl_clear_current_callback;  // required
    std::function<bool(void)> gl_present_callback;        // required
    std::function<intptr_t(void)> gl_fbo_callback;        // required
    PlatformMessageResponseCallback
        platform_message_response_callback;  // optional
  };

  PlatformViewEmbedder(DispatchTable dispatch_table);

  ~PlatformViewEmbedder();

  // |shell::GPUSurfaceGLDelegate|
  bool GLContextMakeCurrent() override;

  // |shell::GPUSurfaceGLDelegate|
  bool GLContextClearCurrent() override;

  // |shell::GPUSurfaceGLDelegate|
  bool GLContextPresent() override;

  // |shell::GPUSurfaceGLDelegate|
  intptr_t GLContextFBO() const override;

  // |shell::PlatformView|
  void Attach() override;

  // |shell::PlatformView|
  bool ResourceContextMakeCurrent() override;

  // |shell::PlatformView|
  void RunFromSource(const std::string& assets_directory,
                     const std::string& main,
                     const std::string& packages) override;

  // |shell::PlatformView|
  void SetAssetBundlePath(const std::string& assets_directory) override;

  // |shell::PlatformView|
  void HandlePlatformMessage(
      fxl::RefPtr<blink::PlatformMessage> message) override;

 private:
  DispatchTable dispatch_table_;

  FXL_DISALLOW_COPY_AND_ASSIGN(PlatformViewEmbedder);
};

}  // namespace shell

#endif  // FLUTTER_SHELL_PLATFORM_EMBEDDER_PLATFORM_VIEW_EMBEDDER_H_
