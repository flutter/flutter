// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_SHELL_PLATFORM_GLFW_WINDOW_IMPL_H_
#define SKY_SHELL_PLATFORM_GLFW_WINDOW_IMPL_H_

#include <memory>
#include <string>

#include "sky/services/engine/sky_engine.mojom.h"
#include "sky/shell/platform_view.h"
#include "sky/shell/shell_view.h"

namespace sky {
namespace shell {

class WindowImpl {
 public:
  explicit WindowImpl(GLFWwindow* window);
  ~WindowImpl();

  void RunFromBundle(const std::string& script_uri,
                     const std::string& bundle_path);

  void UpdateViewportMetrics(int width, int height);

 private:
  GLFWwindow* window_;
  std::unique_ptr<ShellView> shell_view_;
  sky::SkyEnginePtr engine_;

  DISALLOW_COPY_AND_ASSIGN(WindowImpl);
};

}  // namespace shell
}  // namespace sky

#endif  // SKY_SHELL_PLATFORM_GLFW_WINDOW_IMPL_H_
