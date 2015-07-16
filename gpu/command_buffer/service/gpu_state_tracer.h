// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef GPU_COMMAND_BUFFER_SERVICE_GPU_STATE_TRACER_H_
#define GPU_COMMAND_BUFFER_SERVICE_GPU_STATE_TRACER_H_

#include "base/basictypes.h"
#include "base/memory/scoped_ptr.h"

namespace gfx {
class Size;
}

namespace gpu {
namespace gles2 {

struct ContextState;

// Saves GPU state such as framebuffer contents while tracing.
class GPUStateTracer {
 public:
  static scoped_ptr<GPUStateTracer> Create(const ContextState* state);
  ~GPUStateTracer();

  // Take a state snapshot with a screenshot of the currently bound framebuffer.
  void TakeSnapshotWithCurrentFramebuffer(const gfx::Size& size);

 private:
  explicit GPUStateTracer(const ContextState* state);

  const ContextState* state_;
  DISALLOW_COPY_AND_ASSIGN(GPUStateTracer);
};

}  // namespace gles2
}  // namespace gpu

#endif  // GPU_COMMAND_BUFFER_SERVICE_GPU_STATE_TRACER_H_
