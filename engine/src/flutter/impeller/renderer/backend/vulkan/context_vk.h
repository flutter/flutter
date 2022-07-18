// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <memory>

#include "flutter/fml/concurrent_message_loop.h"
#include "flutter/fml/macros.h"
#include "flutter/fml/mapping.h"
#include "impeller/base/backend_cast.h"
#include "impeller/renderer/backend/vulkan/allocator_vk.h"
#include "impeller/renderer/backend/vulkan/pipeline_library_vk.h"
#include "impeller/renderer/backend/vulkan/sampler_library_vk.h"
#include "impeller/renderer/backend/vulkan/shader_library_vk.h"
#include "impeller/renderer/backend/vulkan/vk.h"
#include "impeller/renderer/context.h"

namespace impeller {

class ContextVK final : public Context, public BackendCast<ContextVK, Context> {
 public:
  static std::shared_ptr<ContextVK> Create(
      PFN_vkGetInstanceProcAddr proc_address_callback,
      const std::vector<std::shared_ptr<fml::Mapping>>& shader_libraries_data,
      const std::shared_ptr<const fml::Mapping>& pipeline_cache_data,
      std::shared_ptr<fml::ConcurrentTaskRunner> worker_task_runner,
      const std::string& label);

  // |Context|
  ~ContextVK() override;

  // |Context|
  bool IsValid() const override;

 private:
  std::shared_ptr<fml::ConcurrentTaskRunner> worker_task_runner_;
  vk::UniqueInstance instance_;
  vk::UniqueDebugUtilsMessengerEXT debug_messenger_;
  vk::UniqueDevice device_;
  std::shared_ptr<AllocatorVK> allocator_;
  std::shared_ptr<ShaderLibraryVK> shader_library_;
  std::shared_ptr<SamplerLibraryVK> sampler_library_;
  std::shared_ptr<PipelineLibraryVK> pipeline_library_;
  vk::Queue graphics_queue_;
  vk::Queue compute_queue_;
  vk::Queue transfer_queue_;
  bool is_valid_ = false;

  ContextVK(
      PFN_vkGetInstanceProcAddr proc_address_callback,
      const std::vector<std::shared_ptr<fml::Mapping>>& shader_libraries_data,
      const std::shared_ptr<const fml::Mapping>& pipeline_cache_data,
      std::shared_ptr<fml::ConcurrentTaskRunner> worker_task_runner,
      const std::string& label);

  // |Context|
  std::shared_ptr<Allocator> GetPermanentsAllocator() const override;

  // |Context|
  std::shared_ptr<Allocator> GetTransientsAllocator() const override;

  // |Context|
  std::shared_ptr<ShaderLibrary> GetShaderLibrary() const override;

  // |Context|
  std::shared_ptr<SamplerLibrary> GetSamplerLibrary() const override;

  // |Context|
  std::shared_ptr<PipelineLibrary> GetPipelineLibrary() const override;

  // |Context|
  std::shared_ptr<CommandBuffer> CreateRenderCommandBuffer() const override;

  // |Context|
  std::shared_ptr<CommandBuffer> CreateTransferCommandBuffer() const override;

  FML_DISALLOW_COPY_AND_ASSIGN(ContextVK);
};

}  // namespace impeller
