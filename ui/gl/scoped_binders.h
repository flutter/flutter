// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_GL_SCOPED_BINDERS_H_
#define UI_GL_SCOPED_BINDERS_H_

#include "base/basictypes.h"
#include "ui/gl/gl_export.h"

namespace gfx {
class GLStateRestorer;

class GL_EXPORT ScopedFrameBufferBinder {
 public:
  explicit ScopedFrameBufferBinder(unsigned int fbo);
  ~ScopedFrameBufferBinder();

 private:
  // Whenever possible we prefer to use the current GLContext's
  // GLStateRestorer to maximize driver compabitility.
  GLStateRestorer* state_restorer_;

  // Failing that we use GL calls to save and restore state.
  int old_fbo_;

  DISALLOW_COPY_AND_ASSIGN(ScopedFrameBufferBinder);
};


class GL_EXPORT ScopedTextureBinder {
 public:
  ScopedTextureBinder(unsigned int target, unsigned int id);
  ~ScopedTextureBinder();

 private:
  // Whenever possible we prefer to use the current GLContext's
  // GLStateRestorer to maximize driver compabitility.
  GLStateRestorer* state_restorer_;

  // Failing that we use GL calls to save and restore state.
  int target_;
  int old_id_;

  DISALLOW_COPY_AND_ASSIGN(ScopedTextureBinder);
};

}  // namespace gfx

#endif  // UI_GL_SCOPED_BINDERS_H_
