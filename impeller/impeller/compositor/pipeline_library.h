// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <Metal/Metal.h>

#include <future>
#include <unordered_map>

#include "flutter/fml/macros.h"
#include "impeller/compositor/pipeline.h"
#include "impeller/compositor/pipeline_descriptor.h"

namespace impeller {

class PipelineLibrary {
 public:
  PipelineLibrary(id<MTLDevice> device);

  ~PipelineLibrary();

  std::future<std::shared_ptr<Pipeline>> GetRenderPipeline(
      PipelineDescriptor descriptor);

 private:
  using Pipelines = std::unordered_map<PipelineDescriptor,
                                       std::shared_ptr<const Pipeline>,
                                       PipelineDescriptor::HashEqual,
                                       PipelineDescriptor::HashEqual>;
  id<MTLDevice> device_;
  Pipelines pipelines_;

  FML_DISALLOW_COPY_AND_ASSIGN(PipelineLibrary);
};

}  // namespace impeller
