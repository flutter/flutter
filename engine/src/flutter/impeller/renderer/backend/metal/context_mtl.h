// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <Metal/Metal.h>

#include <string>
#include <vector>

#include "flutter/fml/concurrent_message_loop.h"
#include "flutter/fml/macros.h"
#include "flutter/fml/synchronization/sync_switch.h"
#include "impeller/base/backend_cast.h"
#include "impeller/core/sampler.h"
#include "impeller/renderer/backend/metal/allocator_mtl.h"
#include "impeller/renderer/backend/metal/command_buffer_mtl.h"
#include "impeller/renderer/backend/metal/pipeline_library_mtl.h"
#include "impeller/renderer/backend/metal/shader_library_mtl.h"
#include "impeller/renderer/capabilities.h"
#include "impeller/renderer/context.h"

#if TARGET_OS_SIMULATOR
#define IMPELLER_CA_METAL_LAYER_AVAILABLE API_AVAILABLE(macos(10.11), ios(13.0))
#else  // TARGET_OS_SIMULATOR
#define IMPELLER_CA_METAL_LAYER_AVAILABLE API_AVAILABLE(macos(10.11), ios(8.0))
#endif  // TARGET_OS_SIMULATOR

namespace impeller {

class ContextMTL final : public Context,
                         public BackendCast<ContextMTL, Context>,
                         public std::enable_shared_from_this<ContextMTL> {
 public:
  static std::shared_ptr<ContextMTL> Create(
      const std::vector<std::string>& shader_library_paths,
      std::shared_ptr<const fml::SyncSwitch> is_gpu_disabled_sync_switch);

  static std::shared_ptr<ContextMTL> Create(
      const std::vector<std::shared_ptr<fml::Mapping>>& shader_libraries_data,
      std::shared_ptr<const fml::SyncSwitch> is_gpu_disabled_sync_switch,
      const std::string& label);

  static std::shared_ptr<ContextMTL> Create(
      id<MTLDevice> device,
      id<MTLCommandQueue> command_queue,
      const std::vector<std::shared_ptr<fml::Mapping>>& shader_libraries_data,
      std::shared_ptr<const fml::SyncSwitch> is_gpu_disabled_sync_switch,
      const std::string& label);

  // |Context|
  ~ContextMTL() override;

  // |Context|
  BackendType GetBackendType() const override;

  id<MTLDevice> GetMTLDevice() const;

  // |Context|
  std::string DescribeGpuModel() const override;

  // |Context|
  bool IsValid() const override;

  // |Context|
  std::shared_ptr<Allocator> GetResourceAllocator() const override;

  // |Context|
  std::shared_ptr<ShaderLibrary> GetShaderLibrary() const override;

  // |Context|
  std::shared_ptr<SamplerLibrary> GetSamplerLibrary() const override;

  // |Context|
  std::shared_ptr<PipelineLibrary> GetPipelineLibrary() const override;

  // |Context|
  std::shared_ptr<CommandBuffer> CreateCommandBuffer() const override;

  // |Context|
  const std::shared_ptr<const Capabilities>& GetCapabilities() const override;

  // |Context|
  bool UpdateOffscreenLayerPixelFormat(PixelFormat format) override;

  // |Context|
  void Shutdown() override;

  id<MTLCommandBuffer> CreateMTLCommandBuffer(const std::string& label) const;

  const std::shared_ptr<fml::ConcurrentTaskRunner> GetWorkerTaskRunner() const;

  std::shared_ptr<const fml::SyncSwitch> GetIsGpuDisabledSyncSwitch() const;

 private:
  id<MTLDevice> device_ = nullptr;
  id<MTLCommandQueue> command_queue_ = nullptr;
  std::shared_ptr<ShaderLibraryMTL> shader_library_;
  std::shared_ptr<PipelineLibraryMTL> pipeline_library_;
  std::shared_ptr<SamplerLibrary> sampler_library_;
  std::shared_ptr<AllocatorMTL> resource_allocator_;
  std::shared_ptr<const Capabilities> device_capabilities_;
  std::shared_ptr<fml::ConcurrentMessageLoop> raster_message_loop_;
  std::shared_ptr<const fml::SyncSwitch> is_gpu_disabled_sync_switch_;
  bool is_valid_ = false;

  ContextMTL(
      id<MTLDevice> device,
      id<MTLCommandQueue> command_queue,
      NSArray<id<MTLLibrary>>* shader_libraries,
      std::shared_ptr<const fml::SyncSwitch> is_gpu_disabled_sync_switch);

  std::shared_ptr<CommandBuffer> CreateCommandBufferInQueue(
      id<MTLCommandQueue> queue) const;

  FML_DISALLOW_COPY_AND_ASSIGN(ContextMTL);
};

}  // namespace impeller
