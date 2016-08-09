// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_SKIA_GANESH_FRAMEBUFFER_SURFACE_H_
#define MOJO_SKIA_GANESH_FRAMEBUFFER_SURFACE_H_

#include "base/macros.h"
#include "mojo/skia/ganesh_context.h"
#include "third_party/skia/include/core/SkRefCnt.h"
#include "third_party/skia/include/core/SkSurface.h"

namespace mojo {
namespace skia {

// This class represents an SkSurface backed by a GL framebuffer, which is
// appropriate for use with Ganesh.  This is useful for rendering Skia
// commands directly to the display framebuffer.
class GaneshFramebufferSurface {
 public:
  // Creates a surface that wraps the currently bound GL framebuffer.
  // The size of the surface is determined by querying the current viewport.
  explicit GaneshFramebufferSurface(const GaneshContext::Scope& scope);
  ~GaneshFramebufferSurface();

  SkSurface* surface() const { return surface_.get(); }
  SkCanvas* canvas() const { return surface_->getCanvas(); }

 private:
  sk_sp<SkSurface> surface_;

  DISALLOW_COPY_AND_ASSIGN(GaneshFramebufferSurface);
};

}  // namespace skia
}  // namespace mojo

#endif  // MOJO_SKIA_GANESH_FRAMEBUFFER_SURFACE_H_
