// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_GPU_GPU_SURFACE_SOFTWARE_H_
#define FLUTTER_SHELL_GPU_GPU_SURFACE_SOFTWARE_H_

#include "flutter/shell/common/surface.h"
#include "lib/fxl/macros.h"
#include "lib/fxl/memory/weak_ptr.h"
#include "third_party/skia/include/core/SkSurface.h"

namespace shell {

class GPUSurfaceSoftwareDelegate {
 public:
  virtual sk_sp<SkSurface> AcquireBackingStore(const SkISize& size) = 0;
  virtual bool PresentBackingStore(sk_sp<SkSurface> backing_store) = 0;
};

class GPUSurfaceSoftware : public Surface {
 public:
  GPUSurfaceSoftware(GPUSurfaceSoftwareDelegate* delegate);

  ~GPUSurfaceSoftware() override;

  bool IsValid() override;

  std::unique_ptr<SurfaceFrame> AcquireFrame(const SkISize& size) override;

  GrContext* GetContext() override;

 private:
  GPUSurfaceSoftwareDelegate* delegate_;
  fxl::WeakPtrFactory<GPUSurfaceSoftware> weak_factory_;

  FXL_DISALLOW_COPY_AND_ASSIGN(GPUSurfaceSoftware);
};

}  // namespace shell

#endif  // FLUTTER_SHELL_GPU_GPU_SURFACE_SOFTWARE_H_
