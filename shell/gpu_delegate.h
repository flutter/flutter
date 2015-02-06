// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_SHELL_GPU_DELEGATE_H_
#define SKY_SHELL_GPU_DELEGATE_H_

#include "ui/gfx/native_widget_types.h"

namespace sky {
namespace shell {

class GPUDelegate {
 public:
  virtual void OnAcceleratedWidgetAvailable(gfx::AcceleratedWidget widget) = 0;
  virtual void OnOutputSurfaceDestroyed() = 0;

 protected:
  virtual ~GPUDelegate();
};

}  // namespace shell
}  // namespace sky

#endif  // SKY_SHELL_GPU_DELEGATE_H_
