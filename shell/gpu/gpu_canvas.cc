// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gpu_canvas.h"
#include "gpu_canvas_gl.h"
#include "gpu_canvas_vulkan.h"

namespace shell {

GPUCanvas::~GPUCanvas() = default;

std::unique_ptr<GPUCanvas> GPUCanvas::CreatePlatformCanvas(
    const PlatformView& platform_view) {
  std::unique_ptr<GPUCanvas> canvas;

  // TODO: Vulkan capability detection will be added here to return a differnt
  // canvas instance.

  canvas.reset(new GPUCanvasGL(platform_view.DefaultFramebuffer()));

  return canvas;
}

}  // namespace shell
