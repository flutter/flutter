// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/pipeline.h"

#include "impeller/base/promise.h"
#include "impeller/renderer/context.h"
#include "impeller/renderer/pipeline_library.h"

namespace impeller {

Pipeline::Pipeline(std::weak_ptr<PipelineLibrary> library,
                   PipelineDescriptor desc)
    : library_(std::move(library)), desc_(std::move(desc)) {}

Pipeline::~Pipeline() = default;

PipelineFuture CreatePipelineFuture(const Context& context,
                                    std::optional<PipelineDescriptor> desc) {
  if (!context.IsValid()) {
    return RealizedFuture<std::shared_ptr<Pipeline>>(nullptr);
  }

  return context.GetPipelineLibrary()->GetRenderPipeline(std::move(desc));
}

const PipelineDescriptor& Pipeline::GetDescriptor() const {
  return desc_;
}

PipelineFuture Pipeline::CreateVariant(
    std::function<void(PipelineDescriptor& desc)> descriptor_callback) const {
  if (!descriptor_callback) {
    return RealizedFuture<std::shared_ptr<Pipeline>>(nullptr);
  }

  auto copied_desc = desc_;

  descriptor_callback(copied_desc);

  auto library = library_.lock();
  if (!library) {
    VALIDATION_LOG << "The library from which this pipeline was created was "
                      "already collected.";
    return RealizedFuture<std::shared_ptr<Pipeline>>(nullptr);
  }

  return library->GetRenderPipeline(std::move(copied_desc));
}

}  // namespace impeller
