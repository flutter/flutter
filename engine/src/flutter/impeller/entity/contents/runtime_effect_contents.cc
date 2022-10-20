// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/contents/runtime_effect_contents.h"

#include <future>
#include <memory>

#include "flutter/fml/logging.h"
#include "flutter/fml/make_copyable.h"
#include "impeller/base/validation.h"
#include "impeller/entity/contents/clip_contents.h"
#include "impeller/entity/contents/content_context.h"
#include "impeller/entity/position_no_color.vert.h"
#include "impeller/renderer/formats.h"
#include "impeller/renderer/pipeline_library.h"
#include "impeller/renderer/render_pass.h"
#include "impeller/renderer/shader_function.h"
#include "impeller/renderer/shader_types.h"

namespace impeller {

void RuntimeEffectContents::SetRuntimeStage(
    std::shared_ptr<RuntimeStage> runtime_stage) {
  runtime_stage_ = std::move(runtime_stage);
}

void RuntimeEffectContents::SetUniformData(std::vector<uint8_t> uniform_data) {
  uniform_data_ = std::move(uniform_data);
}

bool RuntimeEffectContents::Render(const ContentContext& renderer,
                                   const Entity& entity,
                                   RenderPass& pass) const {
  auto context = renderer.GetContext();
  auto library = context->GetShaderLibrary();

  //--------------------------------------------------------------------------
  /// Get or register shader.
  ///

  // TODO(113719): Register the shader function earlier.

  std::shared_ptr<const ShaderFunction> function = library->GetFunction(
      runtime_stage_->GetEntrypoint(), ShaderStage::kFragment);

  if (!function) {
    std::promise<bool> promise;
    auto future = promise.get_future();

    library->RegisterFunction(
        runtime_stage_->GetEntrypoint(),
        ToShaderStage(runtime_stage_->GetShaderStage()),
        runtime_stage_->GetCodeMapping(),
        fml::MakeCopyable([promise = std::move(promise)](bool result) mutable {
          promise.set_value(result);
        }));

    if (!future.get()) {
      VALIDATION_LOG << "Failed to build runtime effect (entry point: "
                     << runtime_stage_->GetEntrypoint() << ")";
      return false;
    }

    function = library->GetFunction(runtime_stage_->GetEntrypoint(),
                                    ShaderStage::kFragment);
    if (!function) {
      VALIDATION_LOG
          << "Failed to fetch runtime effect function immediately after "
             "registering it (entry point: "
          << runtime_stage_->GetEntrypoint() << ")";
      return false;
    }
  }

  //--------------------------------------------------------------------------
  /// Resolve geometry.
  ///

  auto geometry_result = GetGeometry()->GetPositionBuffer(
      context->GetResourceAllocator(), pass.GetTransientsBuffer(),
      renderer.GetTessellator(), pass.GetRenderTargetSize(),
      entity.GetTransformation().GetMaxBasisLength());

  //--------------------------------------------------------------------------
  /// Get or create runtime stage pipeline.
  ///

  using VS = PositionNoColorVertexShader;
  PipelineDescriptor desc;
  desc.SetLabel("Runtime Stage");
  desc.AddStageEntrypoint(
      library->GetFunction(VS::kEntrypointName, ShaderStage::kVertex));
  desc.AddStageEntrypoint(library->GetFunction(runtime_stage_->GetEntrypoint(),
                                               ShaderStage::kFragment));
  auto vertex_descriptor = std::make_shared<VertexDescriptor>();
  if (!vertex_descriptor->SetStageInputs(VS::kAllShaderStageInputs)) {
    VALIDATION_LOG << "Failed to set stage inputs for runtime effect pipeline.";
  }
  desc.SetVertexDescriptor(std::move(vertex_descriptor));
  desc.SetColorAttachmentDescriptor(0u, {.format = PixelFormat::kDefaultColor});
  desc.SetStencilAttachmentDescriptors({});
  desc.SetStencilPixelFormat(PixelFormat::kDefaultStencil);

  auto options = OptionsFromPassAndEntity(pass, entity);
  if (geometry_result.prevent_overdraw) {
    options.stencil_compare = CompareFunction::kEqual;
    options.stencil_operation = StencilOperation::kIncrementClamp;
  }
  options.ApplyToPipelineDescriptor(desc);

  auto pipeline = context->GetPipelineLibrary()->GetPipeline(desc).get();
  if (!pipeline) {
    VALIDATION_LOG << "Failed to get or create runtime effect pipeline.";
    return false;
  }

  Command cmd;
  cmd.label = "RuntimeEffectContents";
  cmd.pipeline = pipeline;
  cmd.stencil_reference = entity.GetStencilDepth();
  cmd.BindVertices(geometry_result.vertex_buffer);
  cmd.primitive_type = geometry_result.type;

  //--------------------------------------------------------------------------
  /// Vertex stage uniforms.
  ///

  VS::VertInfo frame_info;
  frame_info.mvp = Matrix::MakeOrthographic(pass.GetRenderTargetSize()) *
                   entity.GetTransformation();
  VS::BindVertInfo(cmd, pass.GetTransientsBuffer().EmplaceUniform(frame_info));

  //--------------------------------------------------------------------------
  /// Fragment stage uniforms.
  ///

  size_t buffer_index = 0;
  for (auto uniform : runtime_stage_->GetUniforms()) {
    // TODO(113715): Populate this metadata once GLES is able to handle
    //               non-struct uniform names.
    ShaderMetadata metadata;

    size_t alignment =
        std::max(uniform.bit_width / 8, DefaultUniformAlignment());
    auto buffer_view = pass.GetTransientsBuffer().Emplace(
        &uniform_data_[uniform.location * sizeof(float)], uniform.GetSize(),
        alignment);

    ShaderUniformSlot slot;
    slot.name = uniform.name.c_str();
    slot.ext_res_0 = buffer_index;
    cmd.BindResource(ShaderStage::kFragment, slot, metadata, buffer_view);

    buffer_index++;
  }

  pass.AddCommand(std::move(cmd));

  if (geometry_result.prevent_overdraw) {
    return ClipRestoreContents().Render(renderer, entity, pass);
  }
  return true;
}

}  // namespace impeller
