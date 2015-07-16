// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_GL_GPU_SWITCHING_OBSERVER_H_
#define UI_GL_GPU_SWITCHING_OBSERVER_H_

#include "ui/gl/gl_export.h"

namespace ui {

class GL_EXPORT GpuSwitchingObserver {
 public:
  // Called for any observer when the system switches to a different GPU.
  virtual void OnGpuSwitched() {};
};

}  // namespace ui

#endif  // UI_GL_GPU_SWITCHING_OBSERVER_H_
