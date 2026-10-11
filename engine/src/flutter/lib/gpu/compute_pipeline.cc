// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/gpu/compute_pipeline.h"

#include <optional>
#include <utility>

#include "impeller/renderer/capabilities.h"
#include "impeller/renderer/pipeline_library.h"
#include "impeller/renderer/shader_library.h"
#include "tonic/converter/dart_converter.h"

namespace flutter {
namespace gpu {

IMPLEMENT_WRAPPERTYPEINFO(flutter_gpu, ComputePipeline);

ComputePipeline::ComputePipeline(fml::RefPtr<Shader> shader)
    : shader_(std::move(shader)) {}

ComputePipeline::~ComputePipeline() = default;

const fml::RefPtr<Shader>& ComputePipeline::GetShader() const {
  return shader_;
}

std::shared_ptr<impeller::Pipeline<impeller::ComputePipelineDescriptor>>
ComputePipeline::GetOrCreatePipeline(impeller::Context& context,
                                     std::string& out_error) {
  // A dirty shader was reloaded since it was registered. Re-registering it
  // evicts every pipeline built from the old code, including `pipeline_`.
  if (shader_->IsDirty() && !shader_->RegisterSync(context)) {
    pipeline_ = nullptr;
    out_error = "Failed to register the compute shader '" +
                shader_->GetEntrypoint() + "' with the shader library.";
    return nullptr;
  }

  auto function = shader_->GetFunctionFromLibrary(*context.GetShaderLibrary());
  if (!function) {
    pipeline_ = nullptr;
    out_error = "Unable to resolve the compute shader function '" +
                shader_->GetEntrypoint() + "' from the shader library.";
    return nullptr;
  }

  // The library hands out a new function object whenever the shader is
  // registered again, including by another pipeline built from the same
  // shader after a reload, so a matching function means `pipeline_` was built
  // from the current code.
  if (pipeline_ &&
      pipeline_->GetDescriptor().GetStageEntrypoint() == function) {
    return pipeline_;
  }
  pipeline_ = nullptr;

  const std::optional<std::array<uint32_t, 3>>& workgroup_size =
      shader_->GetWorkgroupSize();
  if (!workgroup_size.has_value()) {
    out_error = "The shader '" + shader_->GetEntrypoint() +
                "' is not a compute shader.";
    return nullptr;
  }

  impeller::ComputePipelineDescriptor desc;
  desc.SetLabel(shader_->GetEntrypoint());
  desc.SetStageEntrypoint(std::move(function));
  desc.SetWorkgroupSize(workgroup_size.value());
  desc.RegisterDescriptorSetLayouts(shader_->GetDescriptorSetLayouts().data(),
                                    shader_->GetDescriptorSetLayouts().size());

  // Check the device limits here, rather than leaving it to the backend, so
  // that the reason reaches Dart instead of only the validation log.
  const auto& capabilities = context.GetCapabilities();
  if (std::optional<std::string> error = desc.CheckWorkgroupSize(
          capabilities->GetMaximumComputeWorkgroupSize(),
          capabilities->GetMaximumComputeWorkgroupInvocations());
      error.has_value()) {
    out_error = std::move(error.value());
    return nullptr;
  }

  auto pipeline =
      context.GetPipelineLibrary()->GetPipeline(desc, /*async=*/false).Get();
  if (!pipeline) {
    // On Metal a pipeline can allow fewer invocations per workgroup than the
    // device, for example when the shader uses many registers. That is only
    // known once the backend builds the pipeline, which logs the reason.
    const auto& size = workgroup_size.value();
    out_error = "Failed to build the compute pipeline for the shader '" +
                shader_->GetEntrypoint() + "'. Its workgroup size of " +
                std::to_string(size[0]) + "x" + std::to_string(size[1]) + "x" +
                std::to_string(size[2]) +
                " may exceed what this pipeline supports on this device; the "
                "Impeller validation log has the reason.";
    return nullptr;
  }
  pipeline_ = std::move(pipeline);
  return pipeline_;
}

}  // namespace gpu
}  // namespace flutter

//----------------------------------------------------------------------------
/// Exports
///

Dart_Handle InternalFlutterGpu_ComputePipeline_Initialize(
    Dart_Handle wrapper,
    flutter::gpu::Context* gpu_context,
    flutter::gpu::Shader* compute_shader) {
  impeller::Context& context = gpu_context->GetContext();
  if (!flutter::gpu::SupportsCompute(context)) {
    return tonic::ToDart(
        "Compute is not supported on this backend. Check "
        "GpuContext.supportsCompute before creating a ComputePipeline.");
  }
  if (compute_shader->GetShaderStage() != impeller::ShaderStage::kCompute) {
    return tonic::ToDart("The shader '" + compute_shader->GetEntrypoint() +
                         "' is not a compute shader.");
  }

  auto pipeline = fml::MakeRefCounted<flutter::gpu::ComputePipeline>(
      fml::RefPtr<flutter::gpu::Shader>(compute_shader));
  // Build the backend pipeline now, so that a shader the device cannot run
  // fails here rather than at the first dispatch.
  std::string error;
  if (!pipeline->GetOrCreatePipeline(context, error)) {
    return tonic::ToDart(error);
  }
  pipeline->AssociateWithDartWrapper(wrapper);
  return Dart_Null();
}
