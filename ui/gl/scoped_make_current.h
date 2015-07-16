// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_GL_SCOPED_MAKE_CURRENT_H_
#define UI_GL_SCOPED_MAKE_CURRENT_H_

#include "base/basictypes.h"
#include "base/memory/ref_counted.h"
#include "ui/gl/gl_export.h"

namespace gfx {
class GLContext;
class GLSurface;
}

namespace ui {

class GL_EXPORT ScopedMakeCurrent {
 public:
  ScopedMakeCurrent(gfx::GLContext* context, gfx::GLSurface* surface);
  ~ScopedMakeCurrent();

  bool Succeeded() const;

 private:
  scoped_refptr<gfx::GLContext> previous_context_;
  scoped_refptr<gfx::GLSurface> previous_surface_;
  scoped_refptr<gfx::GLContext> context_;
  scoped_refptr<gfx::GLSurface> surface_;
  bool succeeded_;

  DISALLOW_COPY_AND_ASSIGN(ScopedMakeCurrent);
};

}  // namespace ui

#endif  // UI_GL_SCOPED_MAKE_CURRENT_H_
