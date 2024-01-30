// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_RENDERER_BACKEND_METAL_CONTEXT_MTL_H_
#define FLUTTER_IMPELLER_RENDERER_BACKEND_METAL_CONTEXT_MTL_H_

#include <Metal/Metal.h>

#include <deque>
#include <string>

#include "flutter/fml/concurrent_message_loop.h"
#include "flutter/fml/macros.h"
#include "flutter/fml/synchronization/sync_switch.h"
#include "impeller/base/backend_cast.h"
#include "impeller/core/sampler.h"
#include "impeller/renderer/backend/metal/allocator_mtl.h"
#include "impeller/renderer/backend/metal/command_buffer_mtl.h"
#include "impeller/renderer/backend/metal/gpu_tracer_mtl.h"
#include "impeller/renderer/backend/metal/pipeline_library_mtl.h"
#include "impeller/renderer/backend/metal/shader_library_mtl.h"
#include "impeller/renderer/capabilities.h"
#include "impeller/renderer/command_queue.h"
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
  std::shared_ptr<CommandQueue> GetCommandQueue() const override;

  // |Context|
  const std::shared_ptr<const Capabilities>& GetCapabilities() const override;

  void SetCapabilities(const std::shared_ptr<const Capabilities>& capabilities);

  // |Context|
  bool UpdateOffscreenLayerPixelFormat(PixelFormat format) override;

  // |Context|
  void Shutdown() override;

  id<MTLCommandBuffer> CreateMTLCommandBuffer(const std::string& label) const;

  std::shared_ptr<const fml::SyncSwitch> GetIsGpuDisabledSyncSwitch() const;

#ifdef IMPELLER_DEBUG
  std::shared_ptr<GPUTracerMTL> GetGPUTracer() const;
#endif  // IMPELLER_DEBUG

  // |Context|
  void StoreTaskForGPU(const std::function<void()>& task) override;

 private:
  class SyncSwitchObserver : public fml::SyncSwitch::Observer {
   public:
    explicit SyncSwitchObserver(ContextMTL& parent);
    virtual ~SyncSwitchObserver() = default;
    void OnSyncSwitchUpdate(bool new_value) override;

   private:
    ContextMTL& parent_;
  };

  id<MTLDevice> device_ = nullptr;
  id<MTLCommandQueue> command_queue_ = nullptr;
  std::shared_ptr<ShaderLibraryMTL> shader_library_;
  std::shared_ptr<PipelineLibraryMTL> pipeline_library_;
  std::shared_ptr<SamplerLibrary> sampler_library_;
  std::shared_ptr<AllocatorMTL> resource_allocator_;
  std::shared_ptr<const Capabilities> device_capabilities_;
  std::shared_ptr<const fml::SyncSwitch> is_gpu_disabled_sync_switch_;
#ifdef IMPELLER_DEBUG
  std::shared_ptr<GPUTracerMTL> gpu_tracer_;
#endif  // IMPELLER_DEBUG
  std::deque<std::function<void()>> tasks_awaiting_gpu_;
  std::unique_ptr<SyncSwitchObserver> sync_switch_observer_;
  std::shared_ptr<CommandQueue> command_queue_ip_;
  bool is_valid_ = false;

  ContextMTL(
      id<MTLDevice> device,
      id<MTLCommandQueue> command_queue,
      NSArray<id<MTLLibrary>>* shader_libraries,
      std::shared_ptr<const fml::SyncSwitch> is_gpu_disabled_sync_switch);

  std::shared_ptr<CommandBuffer> CreateCommandBufferInQueue(
      id<MTLCommandQueue> queue) const;

  void FlushTasksAwaitingGPU();

  ContextMTL(const ContextMTL&) = delete;

  ContextMTL& operator=(const ContextMTL&) = delete;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_RENDERER_BACKEND_METAL_CONTEXT_MTL_H_
