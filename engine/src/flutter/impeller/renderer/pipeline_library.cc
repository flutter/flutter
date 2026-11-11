// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/pipeline_library.h"
#include <unordered_map>

#include "impeller/base/thread.h"
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
#if FLUTTER_RUNTIME_MODE == FLUTTER_RUNTIME_MODE_DEBUG || \
    FLUTTER_RUNTIME_MODE == FLUTTER_RUNTIME_MODE_PROFILE
  WriterLock lock(pipeline_usage_mutex_);
  pipeline_usage_[p].eagerly_created = true;
#endif
}

void PipelineLibrary::LogPipelineUsage(const PipelineDescriptor& p) {
#if FLUTTER_RUNTIME_MODE == FLUTTER_RUNTIME_MODE_DEBUG || \
    FLUTTER_RUNTIME_MODE == FLUTTER_RUNTIME_MODE_PROFILE
  WriterLock lock(pipeline_usage_mutex_);
  ++pipeline_usage_[p].count;
#endif
}

PipelineUsageMap PipelineLibrary::GetPipelineUsage() const {
  PipelineUsageMap usage;

#if FLUTTER_RUNTIME_MODE == FLUTTER_RUNTIME_MODE_DEBUG || \
    FLUTTER_RUNTIME_MODE == FLUTTER_RUNTIME_MODE_PROFILE
  ReaderLock lock(pipeline_usage_mutex_);
  usage = pipeline_usage_;
#endif
  return usage;
}

void PipelineLibrary::PerformEagerly(const PipelineDescriptor& descriptor) {}

}  // namespace impeller
