// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_SHELL_GPU_GANESH_SURFACE_H_
#define SKY_SHELL_GPU_GANESH_SURFACE_H_

#include "base/memory/scoped_ptr.h"
#include "skia/ext/refptr.h"
#include "sky/shell/gpu/ganesh_context.h"
#include "third_party/skia/include/core/SkSurface.h"
#include "ui/gfx/geometry/size.h"

namespace sky {
namespace shell {

// GaneshSurface holds an SkSurface configured to render with Ganesh. Using the
// provided GaneshContext, GaneshSurface wraps an SkSurface around the window
// bound FBO so that you can use |canvas()| to draw to that window bound FBO.
class GaneshSurface {
 public:
  GaneshSurface(intptr_t window_fbo,
                GaneshContext* context,
                const gfx::Size& size);
  ~GaneshSurface();

  SkCanvas* canvas() const { return surface_->getCanvas(); }
  gfx::Size size() const {
    return gfx::Size(surface_->width(), surface_->height());
  }

 private:
  skia::RefPtr<SkSurface> surface_;

  DISALLOW_COPY_AND_ASSIGN(GaneshSurface);
};

}  // namespace shell
}  // namespace sky

#endif  // SKY_SHELL_GPU_GANESH_SURFACE_H_
