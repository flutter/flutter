// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <Metal/Metal.h>

#include "flutter/fml/macros.h"
#include "impeller/base/backend_cast.h"
#include "impeller/renderer/gpu_tracer.h"

namespace impeller {

class GPUTracerMTL final : public GPUTracer,
                           public BackendCast<GPUTracerMTL, GPUTracer> {
 public:
  // |GPUTracer|
  ~GPUTracerMTL() override;

  // |GPUTracer|
  bool StartCapturingFrame(GPUTracerConfiguration configuration) override;

  // |GPUTracer|
  bool StopCapturingFrame() override;

 private:
  friend class ContextMTL;

  id<MTLDevice> device_;
  GPUTracerMTL(id<MTLDevice> device);

  NSURL* GetUniqueGPUTraceSavedURL() const;
  NSURL* GetGPUTraceSavedDictionaryURL() const;
  bool CreateGPUTraceSavedDictionaryIfNeeded() const;

  FML_DISALLOW_COPY_AND_ASSIGN(GPUTracerMTL);
};

}  // namespace impeller
