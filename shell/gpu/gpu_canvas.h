// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SHELL_GPU_GPU_CANVAS_H_
#define SHELL_GPU_GPU_CANVAS_H_

#include "flutter/shell/common/platform_view.h"
#include "lib/ftl/macros.h"
#include "lib/ftl/compiler_specific.h"
#include "third_party/skia/include/core/SkCanvas.h"

namespace shell {

class GPUCanvas {
 public:
  static std::unique_ptr<GPUCanvas> CreatePlatformCanvas(
      const PlatformView& platform_view);

  virtual ~GPUCanvas();

  FTL_WARN_UNUSED_RESULT
  virtual bool Setup() = 0;

  virtual bool IsValid() = 0;

  virtual SkCanvas* AcquireCanvas(const SkISize& size) = 0;

  virtual GrContext* GetContext() = 0;
};

}  // namespace shell

#endif  // SHELL_GPU_GPU_CANVAS_H_
