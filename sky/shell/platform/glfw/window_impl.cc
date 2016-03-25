// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/shell/platform/glfw/window_impl.h"

#include <GLFW/glfw3.h>

#include "sky/shell/platform/glfw/platform_view_glfw.h"
#include "sky/shell/shell.h"

namespace sky {
namespace shell {
namespace {

WindowImpl* ToImpl(GLFWwindow* window) {
  return static_cast<WindowImpl*>(glfwGetWindowUserPointer(window));
}

void OnWindowSizeChanged(GLFWwindow* window, int width, int height) {
  ToImpl(window)->UpdateViewportMetrics(width, height);
}

}  // namespace

WindowImpl::WindowImpl(GLFWwindow* window)
    : window_(window),
      shell_view_(new ShellView(Shell::Shared())) {
  glfwSetWindowUserPointer(window_, this);
  auto platform_view =
      static_cast<sky::shell::PlatformViewGLFW*>(shell_view_->view());
  platform_view->SurfaceCreated(window);
  platform_view->ConnectToEngine(mojo::GetProxy(&engine_));

  int width = 0;
  int height = 0;
  glfwGetWindowSize(window_, &width, &height);
  UpdateViewportMetrics(width, height);

  glfwSetWindowSizeCallback(window_, OnWindowSizeChanged);
}

WindowImpl::~WindowImpl() {
  shell_view_.reset();
  glfwDestroyWindow(window_);
  window_ = nullptr;
}

void WindowImpl::RunFromBundle(const std::string& script_uri,
                               const std::string& bundle_path) {
  engine_->RunFromBundle(script_uri, bundle_path);
}

void WindowImpl::UpdateViewportMetrics(int width, int height) {
  auto metrics = sky::ViewportMetrics::New();
  metrics->physical_width = width;
  metrics->physical_height = height;
  // TODO(abarth): There doesn't appear to be a way to get the device pixel
  // ratio from GLFW.
  metrics->device_pixel_ratio = 1.0;
  engine_->OnViewportMetricsChanged(metrics.Pass());
}

}  // namespace shell
}  // namespace sky
