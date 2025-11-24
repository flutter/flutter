// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/pipeline_library.h"
#include <unordered_map>
#include "impeller/renderer/pipeline_descriptor.h"

namespace impeller {

PipelineLibrary::PipelineLibrary() = default;

PipelineLibrary::~PipelineLibrary() = default;

PipelineFuture<PipelineDescriptor> PipelineLibrary::GetPipeline(
    std::optional<PipelineDescriptor> descriptor,
    bool async) {
  if (descriptor.has_value()) {
    return GetPipeline(descriptor.value(), async);
  }
  auto promise = std::make_shared<
      std::promise<std::shared_ptr<Pipeline<PipelineDescriptor>>>>();
  promise->set_value(nullptr);
  return {descriptor, promise->get_future()};
}

PipelineFuture<ComputePipelineDescriptor> PipelineLibrary::GetPipeline(
    std::optional<ComputePipelineDescriptor> descriptor,
    bool async) {
  if (descriptor.has_value()) {
    return GetPipeline(descriptor.value(), async);
  }
  auto promise = std::make_shared<
      std::promise<std::shared_ptr<Pipeline<ComputePipelineDescriptor>>>>();
  promise->set_value(nullptr);
  return {descriptor, promise->get_future()};
}

void PipelineLibrary::LogPipelineCreation(const PipelineDescriptor& p) {
  if (!pipeline_use_counts_.contains(p)) {
    pipeline_use_counts_[p] = 0;
  }
}

void PipelineLibrary::LogPipelineUsage(const PipelineDescriptor& p) {
  auto base_pipeline = p.GetBasePipeline();
  if (base_pipeline == nullptr) {
    return;
  }

  if (!pipeline_use_counts_.contains(*base_pipeline)) {
    pipeline_use_counts_[*base_pipeline] = 0;
  }
  ++pipeline_use_counts_[*base_pipeline];
}

std::unordered_map<PipelineDescriptor,
                   int,
                   ComparableHash<PipelineDescriptor>,
                   ComparableEqual<PipelineDescriptor>>
PipelineLibrary::GetPipelineUseCounts() {
  std::unordered_map<PipelineDescriptor, int,
                     ComparableHash<PipelineDescriptor>,
                     ComparableEqual<PipelineDescriptor>>
      counts(pipeline_use_counts_);
  return counts;
}

}  // namespace impeller
