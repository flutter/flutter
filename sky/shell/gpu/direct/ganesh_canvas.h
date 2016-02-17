// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_SHELL_GPU_DIRECT_GANESH_CANVAS_H_
#define SKY_SHELL_GPU_DIRECT_GANESH_CANVAS_H_

#include "base/basictypes.h"
#include "skia/ext/refptr.h"
#include "third_party/skia/include/core/SkSize.h"
#include "third_party/skia/include/core/SkSurface.h"
#include "third_party/skia/include/gpu/gl/GrGLInterface.h"
#include "third_party/skia/include/gpu/gl/GrGLInterface.h"
#include "third_party/skia/include/gpu/GrContext.h"

namespace sky {
namespace shell {

class GaneshCanvas {
 public:
  GaneshCanvas();
  ~GaneshCanvas();

  void SetGrGLInterface(const GrGLInterface* interface);
  SkCanvas* GetCanvas(int32_t fbo, const SkISize& size);

  bool IsValid();

  GrContext* gr_context() { return gr_context_.get(); }

 private:
  skia::RefPtr<GrContext> gr_context_;
  skia::RefPtr<SkSurface> sk_surface_;

  DISALLOW_COPY_AND_ASSIGN(GaneshCanvas);
};

}  // namespace shell
}  // namespace sky

#endif  // SKY_SHELL_GPU_DIRECT_GANESH_CANVAS_H_
