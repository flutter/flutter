// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "flutter/fml/concurrent_message_loop.h"
#include "flutter/fml/macros.h"
#include "flutter/fml/mapping.h"
#include "impeller/base/backend_cast.h"
#include "impeller/base/thread.h"
#include "impeller/renderer/backend/vulkan/pipeline_vk.h"
#include "impeller/renderer/backend/vulkan/vk.h"
#include "impeller/renderer/pipeline_library.h"
#include "vulkan/vulkan_handles.hpp"

namespace impeller {

class ContextVK;

class PipelineLibraryVK final
    : public PipelineLibrary,
      public BackendCast<PipelineLibraryVK, PipelineLibrary> {
 public:
  // |PipelineLibrary|
  ~PipelineLibraryVK() override;

 private:
  friend ContextVK;

  vk::Device device_;
  // On locking around the pipeline cache: The cache is internally synchronized.
  // So there is no need to hold a writer lock around its use when pipelines are
  // being created. The time it takes for implementations to spend within the
  // critical section of the cache is limited compared to the time it
  // takes for the "create pipeline" call itself. The writer lock is only
  // necessary when fetching pipeline cache data for persisting to disk.
  mutable RWMutex cache_mutex_;
  vk::UniquePipelineCache cache_ IPLR_GUARDED_BY(cache_mutex_);
  std::shared_ptr<fml::ConcurrentTaskRunner> worker_task_runner_;
  Mutex pipelines_mutex_;
  PipelineMap pipelines_ IPLR_GUARDED_BY(pipelines_mutex_);
  bool is_valid_ = false;

  PipelineLibraryVK(
      const vk::Device& device,
      const std::shared_ptr<const fml::Mapping>& pipeline_cache_data,
      std::shared_ptr<fml::ConcurrentTaskRunner> worker_task_runner);

  // |PipelineLibrary|
  bool IsValid() const override;

  // |PipelineLibrary|
  PipelineFuture<PipelineDescriptor> GetPipeline(
      PipelineDescriptor descriptor) override;

  // |PipelineLibrary|
  PipelineFuture<ComputePipelineDescriptor> GetPipeline(
      ComputePipelineDescriptor descriptor) override;

  // |PipelineLibrary|
  void RemovePipelinesWithEntryPoint(
      std::shared_ptr<const ShaderFunction> function) override;

  std::unique_ptr<PipelineCreateInfoVK> CreatePipeline(
      const PipelineDescriptor& desc);

  vk::UniqueRenderPass CreateRenderPass(const PipelineDescriptor& desc);

  FML_DISALLOW_COPY_AND_ASSIGN(PipelineLibraryVK);
};

}  // namespace impeller
