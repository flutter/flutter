// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/impeller/impeller/compositor/pipeline.h"

namespace impeller {

Pipeline::Pipeline(id<MTLRenderPipelineState> state) : state_(state) {
  if (state_ != nil) {
    type_ = Type::kRender;
  }
}

Pipeline::~Pipeline() = default;

}  // namespace impeller
