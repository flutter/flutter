// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gpu_tracer.h"

namespace impeller {

GPUTracer::GPUTracer() = default;

GPUTracer::~GPUTracer() = default;

bool GPUTracer::StartCapturingFrame(GPUTracerConfiguration configuration) {
  return false;
}

bool GPUTracer::StopCapturingFrame() {
  return false;
}

}  // namespace impeller
