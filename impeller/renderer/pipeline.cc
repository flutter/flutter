// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/pipeline.h"

#include "impeller/renderer/context.h"
#include "impeller/renderer/pipeline_library.h"

namespace impeller {

Pipeline::Pipeline(PipelineDescriptor desc) : desc_(std::move(desc)) {}

Pipeline::~Pipeline() = default;

PipelineFuture CreatePipelineFuture(const Context& context,
                                    std::optional<PipelineDescriptor> desc) {
  if (!context.IsValid()) {
    std::promise<std::shared_ptr<Pipeline>> promise;
    auto future = promise.get_future();
    promise.set_value(nullptr);
    return future;
  }

  return context.GetPipelineLibrary()->GetRenderPipeline(std::move(desc));
}

const PipelineDescriptor& Pipeline::GetDescriptor() const {
  return desc_;
}

}  // namespace impeller
