// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_SHELL_PLATFORM_GLFW_PLATFORM_VIEW_GLFW_H_
#define SKY_SHELL_PLATFORM_GLFW_PLATFORM_VIEW_GLFW_H_

#include "sky/shell/platform_view.h"

namespace sky {
namespace shell {

class PlatformViewGLFW : public PlatformView {
 public:
  explicit PlatformViewGLFW(const Config& config);
  ~PlatformViewGLFW() override;

  void SurfaceCreated(gfx::AcceleratedWidget widget);
  void SurfaceDestroyed(void);

 private:
  gfx::AcceleratedWidget window_;

  DISALLOW_COPY_AND_ASSIGN(PlatformViewGLFW);
};

}  // namespace shell
}  // namespace sky

#endif  // SKY_SHELL_PLATFORM_GLFW_PLATFORM_VIEW_GLFW_H_
