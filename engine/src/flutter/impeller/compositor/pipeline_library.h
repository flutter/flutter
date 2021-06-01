// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <Metal/Metal.h>

#include <future>
#include <memory>
#include <unordered_map>

#include "flutter/fml/macros.h"
#include "impeller/compositor/pipeline.h"
#include "impeller/compositor/pipeline_descriptor.h"

namespace impeller {

class Context;

class PipelineLibrary : public std::enable_shared_from_this<PipelineLibrary> {
 public:
  ~PipelineLibrary();

  std::future<std::shared_ptr<Pipeline>> GetRenderPipeline(
      PipelineDescriptor descriptor);

 private:
  friend Context;

  using Pipelines = std::unordered_map<PipelineDescriptor,
                                       std::shared_ptr<const Pipeline>,
                                       ComparableHash<PipelineDescriptor>,
                                       ComparableEqual<PipelineDescriptor>>;
  id<MTLDevice> device_;
  Pipelines pipelines_;

  PipelineLibrary(id<MTLDevice> device);

  void SavePipeline(PipelineDescriptor descriptor,
                    std::shared_ptr<const Pipeline> pipeline);

  FML_DISALLOW_COPY_AND_ASSIGN(PipelineLibrary);
};

}  // namespace impeller
