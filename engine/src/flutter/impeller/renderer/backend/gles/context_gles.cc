// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/gles/context_gles.h"
#include <memory>

#include "impeller/base/config.h"
#include "impeller/base/validation.h"
#include "impeller/base/version.h"
#include "impeller/core/runtime_types.h"
#include "impeller/renderer/backend/gles/command_buffer_gles.h"
#include "impeller/renderer/backend/gles/gpu_tracer_gles.h"
#include "impeller/renderer/backend/gles/handle_gles.h"
#include "impeller/renderer/backend/gles/render_pass_gles.h"
#include "impeller/renderer/backend/gles/texture_gles.h"
#include "impeller/renderer/command_queue.h"

#if defined(__ANDROID__)
#include <sys/system_properties.h>
#endif  // defined(__ANDROID__)

#include "flutter/fml/logging.h"

namespace impeller {

// static
bool ContextGLES::IsJobPoolConstrainedPlatform(std::string_view platform) {
  // The MT6779 (Helio P90, PowerVR Rogue GM9446) GL driver has a fixed-size
  // internal job pool and dereferences null when an allocation from that
  // pool fails inside glClear. Other MT67xx SoCs with PowerVR GPUs (e.g.
  // MT6762/MT6765 with the GE8320) share the driver architecture and may
  // need to be added here if reports confirm the same RM_GrowJobPool
  // failure signature; MT67xx SoCs with Mali GPUs are unaffected.
  return platform.starts_with("mt6779") || platform.starts_with("MT6779");
}

// static
bool ContextGLES::IsJobPoolConstrainedDriver() {
#if defined(__ANDROID__)
  static const bool is_constrained = [] {
    for (const char* name :
         {"ro.board.platform", "ro.vendor.mediatek.platform"}) {
      char value[PROP_VALUE_MAX];
      if (__system_property_get(name, value) > 0 &&
          IsJobPoolConstrainedPlatform(value)) {
        FML_LOG(INFO) << "Impeller job-pool exhaustion mitigation active "
                         "for platform: "
                      << value;
        return true;
      }
    }
    return false;
  }();
  return is_constrained;
#else
  return false;
#endif  // defined(__ANDROID__)
}

std::shared_ptr<ContextGLES> ContextGLES::Create(
    const Flags& flags,
    std::unique_ptr<ProcTableGLES> gl,
    const std::vector<std::shared_ptr<fml::Mapping>>& shader_libraries,
    bool enable_gpu_tracing) {
  return std::shared_ptr<ContextGLES>(new ContextGLES(
      flags, std::move(gl), shader_libraries, enable_gpu_tracing));
}

ContextGLES::ContextGLES(
    const Flags& flags,
    std::unique_ptr<ProcTableGLES> gl,
    const std::vector<std::shared_ptr<fml::Mapping>>& shader_libraries_mappings,
    bool enable_gpu_tracing)
    : Context(flags) {
  reactor_ = std::make_shared<ReactorGLES>(std::move(gl));
  if (!reactor_->IsValid()) {
    VALIDATION_LOG << "Could not create valid reactor.";
    return;
  }

  // Create the shader library.
  {
    auto library = std::shared_ptr<ShaderLibraryGLES>(
        new ShaderLibraryGLES(shader_libraries_mappings));
    if (!library->IsValid()) {
      VALIDATION_LOG << "Could not create valid shader library.";
      return;
    }
    shader_library_ = std::move(library);
  }

  // Create the pipeline library.
  {
    pipeline_library_ =
        std::shared_ptr<PipelineLibraryGLES>(new PipelineLibraryGLES(reactor_));
  }

  // Create allocators.
  {
    resource_allocator_ =
        std::shared_ptr<AllocatorGLES>(new AllocatorGLES(reactor_));
    if (!resource_allocator_->IsValid()) {
      VALIDATION_LOG << "Could not create a resource allocator.";
      return;
    }
  }

  device_capabilities_ = reactor_->GetProcTable().GetCapabilities();

  // Create the sampler library.
  {
    sampler_library_ =
        std::shared_ptr<SamplerLibraryGLES>(new SamplerLibraryGLES(
            device_capabilities_->SupportsDecalSamplerAddressMode()));
  }
  gpu_tracer_ = std::make_shared<GPUTracerGLES>(GetReactor()->GetProcTable(),
                                                enable_gpu_tracing);
  command_queue_ = std::make_shared<CommandQueue>();
  is_valid_ = true;
}

ContextGLES::~ContextGLES() = default;

Context::BackendType ContextGLES::GetBackendType() const {
  return Context::BackendType::kOpenGLES;
}

const std::shared_ptr<ReactorGLES>& ContextGLES::GetReactor() const {
  return reactor_;
}

std::optional<ReactorGLES::WorkerID> ContextGLES::AddReactorWorker(
    const std::shared_ptr<ReactorGLES::Worker>& worker) {
  if (!IsValid()) {
    return std::nullopt;
  }
  return reactor_->AddWorker(worker);
}

bool ContextGLES::RemoveReactorWorker(ReactorGLES::WorkerID id) {
  if (!IsValid()) {
    return false;
  }
  return reactor_->RemoveWorker(id);
}

bool ContextGLES::IsValid() const {
  return is_valid_;
}

void ContextGLES::Shutdown() {}

// |Context|
std::string ContextGLES::DescribeGpuModel() const {
  return reactor_->GetProcTable().GetDescription()->GetString();
}

// |Context|
std::shared_ptr<Allocator> ContextGLES::GetResourceAllocator() const {
  return resource_allocator_;
}

std::shared_ptr<const GpuSubmissionTracker> ContextGLES::GetSubmissionTracker()
    const {
  return submission_tracker_;
}

const std::shared_ptr<GpuSubmissionTracker>&
ContextGLES::GetMutableSubmissionTracker() const {
  return submission_tracker_;
}

// |Context|
std::shared_ptr<ShaderLibrary> ContextGLES::GetShaderLibrary() const {
  return shader_library_;
}

// |Context|
std::shared_ptr<SamplerLibrary> ContextGLES::GetSamplerLibrary() const {
  return sampler_library_;
}

// |Context|
std::shared_ptr<PipelineLibrary> ContextGLES::GetPipelineLibrary() const {
  return pipeline_library_;
}

// |Context|
std::shared_ptr<CommandBuffer> ContextGLES::CreateCommandBuffer() const {
  return std::shared_ptr<CommandBufferGLES>(
      new CommandBufferGLES(weak_from_this(), reactor_));
}

// |Context|
const std::shared_ptr<const Capabilities>& ContextGLES::GetCapabilities()
    const {
  return device_capabilities_;
}

// |Context|
std::shared_ptr<CommandQueue> ContextGLES::GetCommandQueue() const {
  return command_queue_;
}

// |Context|
void ContextGLES::ResetThreadLocalState() const {
  if (!IsValid()) {
    return;
  }
  [[maybe_unused]] auto result =
      reactor_->AddOperation([](const ReactorGLES& reactor) {
        RenderPassGLES::ResetGLState(reactor.GetProcTable());
      });
}

bool ContextGLES::EnqueueCommandBuffer(
    std::shared_ptr<CommandBuffer> command_buffer) {
  return true;
}

// |Context|
[[nodiscard]] bool ContextGLES::FlushCommandBuffers() {
  return reactor_->React();
}

bool ContextGLES::FinishQueue() {
  reactor_->GetProcTable().Finish();
  return true;
}

// |Context|
bool ContextGLES::AddTrackingFence(
    const std::shared_ptr<Texture>& texture) const {
  if (IsJobPoolConstrainedDriver()) {
    // Report fences as unavailable so image uploads take the
    // WaitUntilCompleted (glFinish) path. This retires the driver's internal
    // jobs immediately instead of accumulating a fence (and its implicit
    // flush) per uploaded texture, which exhausts the driver's job pool and
    // crashes it. See https://github.com/flutter/flutter/issues/189190.
    return false;
  }
  if (!reactor_->GetProcTable().FenceSync.IsAvailable()) {
    return false;
  }
  HandleGLES fence = reactor_->CreateHandle(HandleType::kFence);
  TextureGLES::Cast(*texture).SetFence(fence);
  return true;
}

// |Context|
RuntimeStageBackend ContextGLES::GetRuntimeStageBackend() const {
  if (GetReactor()->GetProcTable().GetDescription()->GetGlVersion().IsAtLeast(
          Version{3, 0, 0})) {
    return RuntimeStageBackend::kOpenGLES3;
  }
  return RuntimeStageBackend::kOpenGLES;
}

}  // namespace impeller
