// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "flutter/fml/macros.h"

#include <Metal/Metal.h>

namespace impeller {

class PipelineLibrary;

class Pipeline {
 public:
  enum class Type {
    kUnknown,
    kRender,
  };

  ~Pipeline();

 private:
  friend class PipelineLibrary;

  Type type_ = Type::kUnknown;
  id<MTLRenderPipelineState> state_;

  Pipeline(id<MTLRenderPipelineState> state);

  FML_DISALLOW_COPY_AND_ASSIGN(Pipeline);
};

}  // namespace impeller
