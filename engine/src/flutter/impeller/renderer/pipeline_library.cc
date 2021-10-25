// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/pipeline_library.h"

namespace impeller {

PipelineLibrary::PipelineLibrary() = default;

PipelineLibrary::~PipelineLibrary() = default;

PipelineFuture PipelineLibrary::GetRenderPipeline(
    std::optional<PipelineDescriptor> descriptor) {
  if (descriptor.has_value()) {
    return GetRenderPipeline(std::move(descriptor.value()));
  }
  auto promise = std::make_shared<std::promise<std::shared_ptr<Pipeline>>>();
  promise->set_value(nullptr);
  return promise->get_future();
}

}  // namespace impeller
