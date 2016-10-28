// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SHELL_PLATFORM_GLFW_PLATFORM_VIEW_GLFW_H_
#define SHELL_PLATFORM_GLFW_PLATFORM_VIEW_GLFW_H_

#include <string>
#include "flutter/shell/common/platform_view.h"
#include "flutter/shell/gpu/gpu_surface_gl.h"
#include "lib/ftl/memory/weak_ptr.h"

struct GLFWwindow;

namespace shell {

class PlatformViewGLFW : public PlatformView, public GPUSurfaceGLDelegate {
 public:
  PlatformViewGLFW();

  ~PlatformViewGLFW() override;

  bool IsValid() const;

  bool ResourceContextMakeCurrent() override;

  bool GLContextMakeCurrent() override;

  bool GLContextClearCurrent() override;

  bool GLContextPresent() override;

  intptr_t GLContextFBO() const override;

  void RunFromSource(const std::string& assets_directory,
                     const std::string& main,
                     const std::string& packages) override;

 private:
  bool valid_;
  GLFWwindow* glfw_window_;
  int buttons_;

  void OnWindowSizeChanged(int width, int height);

  void OnMouseButtonChanged(int button, int action, int mods);

  void OnCursorPosChanged(double x, double y);

  void OnKeyEvent(int key, int scancode, int action, int mods);

  FTL_DISALLOW_COPY_AND_ASSIGN(PlatformViewGLFW);
};

}  // namespace shell

#endif  // SHELL_PLATFORM_GLFW_PLATFORM_VIEW_GLFW_H_
