// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_SKIA_GANESH_SURFACE_H_
#define MOJO_SKIA_GANESH_SURFACE_H_

#include "base/memory/scoped_ptr.h"
#include "mojo/gpu/gl_texture.h"
#include "mojo/skia/ganesh_context.h"
#include "skia/ext/refptr.h"
#include "third_party/skia/include/core/SkSurface.h"

namespace mojo {

// This class represents an SkSurface backed by a GL texture, which is
// appropriate for use with Ganesh. Note: There's a name collision with
// mojo::Surface, which is a different concept.
class GaneshSurface {
 public:
  GaneshSurface(GaneshContext* context, scoped_ptr<GLTexture> texture);
  ~GaneshSurface();

  SkCanvas* canvas() const { return surface_->getCanvas(); }
  scoped_ptr<GLTexture> TakeTexture();

 private:
  scoped_ptr<GLTexture> texture_;
  skia::RefPtr<SkSurface> surface_;

  DISALLOW_COPY_AND_ASSIGN(GaneshSurface);
};

}  // namespace mojo

#endif  // MOJO_SKIA_GANESH_SURFACE_H_
