// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_EMBEDDER_PLATFORM_VIEW_EMBEDDER_H_
#define FLUTTER_SHELL_PLATFORM_EMBEDDER_PLATFORM_VIEW_EMBEDDER_H_

#include "flutter/shell/common/platform_view.h"
#include "flutter/shell/gpu/gpu_surface_gl.h"
#include "lib/fxl/macros.h"

namespace shell {

class PlatformViewEmbedder : public PlatformView, public GPUSurfaceGLDelegate {
 public:
  struct DispatchTable {
    std::function<bool(void)> gl_make_current_callback;
    std::function<bool(void)> gl_clear_current_callback;
    std::function<bool(void)> gl_present_callback;
    std::function<intptr_t(void)> gl_fbo_callback;
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

 private:
  DispatchTable dispatch_table_;

  FXL_DISALLOW_COPY_AND_ASSIGN(PlatformViewEmbedder);
};

}  // namespace shell

#endif  // FLUTTER_SHELL_PLATFORM_EMBEDDER_PLATFORM_VIEW_EMBEDDER_H_
