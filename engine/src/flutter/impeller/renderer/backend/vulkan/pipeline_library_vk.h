// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <atomic>

#include "flutter/fml/concurrent_message_loop.h"
#include "flutter/fml/macros.h"
#include "flutter/fml/mapping.h"
#include "flutter/fml/unique_fd.h"
#include "impeller/base/backend_cast.h"
#include "impeller/base/thread.h"
#include "impeller/renderer/backend/vulkan/pipeline_cache_vk.h"
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

  void DidAcquireSurfaceFrame();

 private:
  friend ContextVK;

  std::weak_ptr<DeviceHolder> device_holder_;
  std::shared_ptr<PipelineCacheVK> pso_cache_;
  std::shared_ptr<fml::ConcurrentTaskRunner> worker_task_runner_;
  Mutex pipelines_mutex_;
  PipelineMap pipelines_ IPLR_GUARDED_BY(pipelines_mutex_);
  std::atomic_size_t frames_acquired_ = 0u;
  bool is_valid_ = false;

  PipelineLibraryVK(
      const std::weak_ptr<DeviceHolder>& device_holder,
      const vk::Device& device,
      std::shared_ptr<const Capabilities> caps,
      fml::UniqueFD cache_directory,
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

  std::unique_ptr<PipelineVK> CreatePipeline(const PipelineDescriptor& desc);

  void PersistPipelineCacheToDisk();

  FML_DISALLOW_COPY_AND_ASSIGN(PipelineLibraryVK);
};

}  // namespace impeller
