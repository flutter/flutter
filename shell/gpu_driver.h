// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_SHELL_GPU_DRIVER_H_
#define SKY_SHELL_GPU_DRIVER_H_

#include "base/memory/ref_counted.h"
#include "base/memory/weak_ptr.h"
#include "ui/gfx/native_widget_types.h"

namespace gfx {
class GLContext;
class GLShareGroup;
class GLSurface;
}

namespace sky {
namespace shell {

class GPUDriver {
 public:
  explicit GPUDriver();
  ~GPUDriver();

  base::WeakPtr<GPUDriver> GetWeakPtr();

  void Init(gfx::AcceleratedWidget widget);

 private:
  scoped_refptr<gfx::GLShareGroup> share_group_;
  scoped_refptr<gfx::GLSurface> surface_;
  scoped_refptr<gfx::GLContext> context_;

  base::WeakPtrFactory<GPUDriver> weak_factory_;

  DISALLOW_COPY_AND_ASSIGN(GPUDriver);
};

}  // namespace shell
}  // namespace sky

#endif  // SKY_SHELL_GPU_DRIVER_H_
