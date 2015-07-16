// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_SHELL_GPU_GANESH_CONTEXT_H_
#define SKY_SHELL_GPU_GANESH_CONTEXT_H_

#include "base/basictypes.h"
#include "base/memory/ref_counted.h"
#include "skia/ext/refptr.h"
#include "third_party/skia/include/gpu/GrContext.h"
#include "ui/gl/gl_context.h"

namespace sky {
namespace shell {

// GaneshContext holds the top-level context object for Ganesh (known as
// GrContext). We construct the GrContext using the OpenGL interface provided by
// gfx::GLContext.
class GaneshContext {
 public:
  explicit GaneshContext(scoped_refptr<gfx::GLContext> gl_context);
  ~GaneshContext();

  GrContext* gr() const { return gr_context_.get(); }

 private:
  scoped_refptr<gfx::GLContext> gl_context_;
  skia::RefPtr<GrContext> gr_context_;

  DISALLOW_COPY_AND_ASSIGN(GaneshContext);
};

}  // namespace shell
}  // namespace sky

#endif  // SKY_SHELL_GPU_GANESH_CONTEXT_H_
