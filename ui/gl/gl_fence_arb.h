// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_GL_GL_FENCE_ARB_H_
#define UI_GL_GL_FENCE_ARB_H_

#include "base/macros.h"
#include "ui/gl/gl_bindings.h"
#include "ui/gl/gl_fence.h"

namespace gfx {

class GL_EXPORT GLFenceARB : public GLFence {
 public:
  GLFenceARB();
  ~GLFenceARB() override;

  // GLFence implementation:
  bool HasCompleted() override;
  void ClientWait() override;
  void ServerWait() override;

 private:
  GLsync sync_;

  DISALLOW_COPY_AND_ASSIGN(GLFenceARB);
};

}  // namespace gfx

#endif  // UI_GL_GL_FENCE_ARB_H_
