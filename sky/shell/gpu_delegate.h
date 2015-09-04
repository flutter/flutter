// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_SHELL_GPU_DELEGATE_H_
#define SKY_SHELL_GPU_DELEGATE_H_

#include <memory>

#include "base/memory/scoped_ptr.h"
#include "sky/compositor/layer_tree.h"
#include "ui/gfx/geometry/size.h"
#include "ui/gfx/native_widget_types.h"

class SkPicture;

namespace sky {
namespace shell {

class GPUDelegate {
 public:
  virtual void OnAcceleratedWidgetAvailable(gfx::AcceleratedWidget widget) = 0;
  virtual void OnOutputSurfaceDestroyed() = 0;
  virtual void Draw(scoped_ptr<compositor::LayerTree> layer_tree) = 0;

 protected:
  virtual ~GPUDelegate();
};

}  // namespace shell
}  // namespace sky

#endif  // SKY_SHELL_GPU_DELEGATE_H_
