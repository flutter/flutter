// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_RENDERER_BACKEND_GLES_CONTEXT_GLES_H_
#define FLUTTER_IMPELLER_RENDERER_BACKEND_GLES_CONTEXT_GLES_H_

#include <string_view>

#include "impeller/base/backend_cast.h"
#include "impeller/core/runtime_types.h"
#include "impeller/renderer/backend/gles/allocator_gles.h"
#include "impeller/renderer/backend/gles/capabilities_gles.h"
#include "impeller/renderer/backend/gles/gpu_tracer_gles.h"
#include "impeller/renderer/backend/gles/pipeline_library_gles.h"
#include "impeller/renderer/backend/gles/reactor_gles.h"
#include "impeller/renderer/backend/gles/sampler_library_gles.h"
#include "impeller/renderer/backend/gles/shader_library_gles.h"
#include "impeller/renderer/capabilities.h"
#include "impeller/renderer/command_queue.h"
#include "impeller/renderer/context.h"

namespace impeller {

class ContextGLES final : public Context,
                          public BackendCast<ContextGLES, Context>,
                          public std::enable_shared_from_this<ContextGLES> {
 public:
  static std::shared_ptr<ContextGLES> Create(
      const Flags& flags,
      std::unique_ptr<ProcTableGLES> gl,
      const std::vector<std::shared_ptr<fml::Mapping>>& shader_libraries,
      bool enable_gpu_tracing);

  // |Context|
  ~ContextGLES() override;

  // |Context|
  BackendType GetBackendType() const override;

  const std::shared_ptr<ReactorGLES>& GetReactor() const;

  std::optional<ReactorGLES::WorkerID> AddReactorWorker(
      const std::shared_ptr<ReactorGLES::Worker>& worker);

  bool RemoveReactorWorker(ReactorGLES::WorkerID id);

  std::shared_ptr<GPUTracerGLES> GetGPUTracer() const { return gpu_tracer_; }

  /// Returns true for platform strings (`ro.board.platform` or
  /// `ro.vendor.mediatek.platform`) of MediaTek SoCs whose PowerVR GL driver
  /// crashes with a null-pointer dereference inside glClear once the
  /// driver's internal job pool is exhausted. Currently only the MT6779 has
  /// confirmed reports. Exposed for testing.
  ///
  /// See: https://github.com/flutter/flutter/issues/189190
  static bool IsJobPoolConstrainedPlatform(std::string_view platform);

  /// Whether the device's GL driver is prone to internal job-pool exhaustion
  /// under many small command submissions. When true, the backend disables
  /// per-upload tracking fences and periodically drains the command queue to
  /// keep the driver's job pool shallow.
  ///
  /// See: https://github.com/flutter/flutter/issues/189190
  static bool IsJobPoolConstrainedDriver();

  // Mutable tracker for command buffer submission bookkeeping.
  const std::shared_ptr<GpuSubmissionTracker>& GetMutableSubmissionTracker()
      const;

 private:
  std::shared_ptr<ReactorGLES> reactor_;
  std::shared_ptr<GpuSubmissionTracker> submission_tracker_ =
      std::make_shared<GpuSubmissionTracker>();
  std::shared_ptr<ShaderLibraryGLES> shader_library_;
  std::shared_ptr<PipelineLibraryGLES> pipeline_library_;
  std::shared_ptr<SamplerLibraryGLES> sampler_library_;
  std::shared_ptr<AllocatorGLES> resource_allocator_;
  std::shared_ptr<CommandQueue> command_queue_;
  std::shared_ptr<GPUTracerGLES> gpu_tracer_;

  // Note: This is stored separately from the ProcTableGLES CapabilitiesGLES
  // in order to satisfy the Context::GetCapabilities signature which returns
  // a reference.
  std::shared_ptr<const Capabilities> device_capabilities_;
  bool is_valid_ = false;

  ContextGLES(
      const Flags& flags,
      std::unique_ptr<ProcTableGLES> gl,
      const std::vector<std::shared_ptr<fml::Mapping>>& shader_libraries,
      bool enable_gpu_tracing);

  // |Context|
  std::string DescribeGpuModel() const override;

  // |Context|
  bool IsValid() const override;

  // |Context|
  std::shared_ptr<Allocator> GetResourceAllocator() const override;

  // |Context|
  std::shared_ptr<const GpuSubmissionTracker> GetSubmissionTracker()
      const override;

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
  std::shared_ptr<CommandQueue> GetCommandQueue() const override;

  // |Context|
  void Shutdown() override;

  // |Context|
  bool AddTrackingFence(const std::shared_ptr<Texture>& texture) const override;

  // |Context|
  void ResetThreadLocalState() const override;

  // |Context|
  [[nodiscard]] bool EnqueueCommandBuffer(
      std::shared_ptr<CommandBuffer> command_buffer) override;

  // |Context|
  [[nodiscard]] bool FlushCommandBuffers() override;

  // |Context|
  [[nodiscard]] bool FinishQueue() override;

  // |Context|
  RuntimeStageBackend GetRuntimeStageBackend() const override;

  ContextGLES(const ContextGLES&) = delete;

  ContextGLES& operator=(const ContextGLES&) = delete;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_RENDERER_BACKEND_GLES_CONTEXT_GLES_H_
