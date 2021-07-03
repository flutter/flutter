// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/compositor/pipeline_library.h"

#include <memory>

#include "flutter/fml/logging.h"

namespace impeller {

PipelineLibrary::PipelineLibrary(id<MTLDevice> device) : device_(device) {}

PipelineLibrary::~PipelineLibrary() = default;

std::future<std::shared_ptr<Pipeline>> PipelineLibrary::GetRenderPipeline(
    std::optional<PipelineDescriptor> descriptor) {
  if (descriptor.has_value()) {
    return GetRenderPipeline(std::move(descriptor.value()));
  }
  auto promise = std::make_shared<std::promise<std::shared_ptr<Pipeline>>>();
  promise->set_value(nullptr);
  return promise->get_future();
}

std::future<std::shared_ptr<Pipeline>> PipelineLibrary::GetRenderPipeline(
    PipelineDescriptor descriptor) {
  auto promise = std::make_shared<std::promise<std::shared_ptr<Pipeline>>>();
  auto future = promise->get_future();
  if (auto found = pipelines_.find(descriptor); found != pipelines_.end()) {
    promise->set_value(nullptr);
    return future;
  }

  auto thiz = shared_from_this();

  auto completion_handler =
      ^(id<MTLRenderPipelineState> _Nullable render_pipeline_state,
        NSError* _Nullable error) {
        if (error != nil) {
          FML_LOG(ERROR) << "Could not create render pipeline: "
                         << error.localizedDescription.UTF8String;
          promise->set_value(nullptr);
        } else {
          auto new_pipeline = std::shared_ptr<Pipeline>(
              new Pipeline(render_pipeline_state,
                           descriptor.CreateDepthStencilDescriptor(device_)));
          promise->set_value(new_pipeline);
          this->SavePipeline(descriptor, new_pipeline);
        }
      };
  [device_
      newRenderPipelineStateWithDescriptor:descriptor
                                               .GetMTLRenderPipelineDescriptor()
                         completionHandler:completion_handler];
  return future;
}

void PipelineLibrary::SavePipeline(PipelineDescriptor descriptor,
                                   std::shared_ptr<const Pipeline> pipeline) {
  pipelines_[descriptor] = std::move(pipeline);
}

}  // namespace impeller
