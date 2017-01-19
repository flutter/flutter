// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_COMMON_SURFACE_H_
#define FLUTTER_SHELL_COMMON_SURFACE_H_

#include <memory>

#include "lib/ftl/compiler_specific.h"
#include "lib/ftl/macros.h"
#include "third_party/skia/include/core/SkCanvas.h"

namespace shell {

class SurfaceFrame {
 public:
  SurfaceFrame();

  virtual ~SurfaceFrame();

  bool Submit();

  virtual SkCanvas* SkiaCanvas() = 0;

 private:
  bool submitted_;

  virtual bool PerformSubmit() = 0;

  FTL_DISALLOW_COPY_AND_ASSIGN(SurfaceFrame);
};

class Surface {
 public:
  Surface();

  virtual ~Surface();

  virtual bool Setup() = 0;

  virtual bool IsValid() = 0;

  virtual std::unique_ptr<SurfaceFrame> AcquireFrame(const SkISize& size) = 0;

  virtual GrContext* GetContext() = 0;

 private:
  FTL_DISALLOW_COPY_AND_ASSIGN(Surface);
};

}  // namespace shell

#endif  // FLUTTER_SHELL_COMMON_SURFACE_H_
