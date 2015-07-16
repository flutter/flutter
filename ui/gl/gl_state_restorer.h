// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_GL_GL_STATE_RESTORER_H_
#define UI_GL_GL_STATE_RESTORER_H_

#include "base/basictypes.h"
#include "ui/gl/gl_export.h"

namespace gfx {

// An interface for Restoring GL State.
// This will expand over time to provide an more optimizable implementation.
class GL_EXPORT GLStateRestorer {
 public:
  GLStateRestorer();
  virtual ~GLStateRestorer();

  virtual bool IsInitialized() = 0;
  virtual void RestoreState(const GLStateRestorer* prev_state) = 0;
  virtual void RestoreAllTextureUnitBindings() = 0;
  virtual void RestoreActiveTextureUnitBinding(unsigned int target) = 0;
  virtual void RestoreFramebufferBindings() = 0;

  DISALLOW_COPY_AND_ASSIGN(GLStateRestorer);
};

}  // namespace gfx

#endif  // UI_GL_GL_STATE_RESTORER_H_
