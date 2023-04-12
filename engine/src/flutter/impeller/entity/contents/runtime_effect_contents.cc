// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/contents/runtime_effect_contents.h"

#include <future>
#include <memory>

#include "flutter/fml/logging.h"
#include "flutter/fml/make_copyable.h"
#include "impeller/base/validation.h"
#include "impeller/core/formats.h"
#include "impeller/core/shader_types.h"
#include "impeller/entity/contents/clip_contents.h"
#include "impeller/entity/contents/content_context.h"
#include "impeller/entity/runtime_effect.vert.h"
#include "impeller/renderer/pipeline_library.h"
#include "impeller/renderer/render_pass.h"
#include "impeller/renderer/sampler_library.h"
#include "impeller/renderer/shader_function.h"

namespace impeller {

void RuntimeEffectContents::SetRuntimeStage(
    std::shared_ptr<RuntimeStage> runtime_stage) {
  runtime_stage_ = std::move(runtime_stage);
}

void RuntimeEffectContents::SetUniformData(
    std::shared_ptr<std::vector<uint8_t>> uniform_data) {
  uniform_data_ = std::move(uniform_data);
}

void RuntimeEffectContents::SetTextureInputs(
    std::vector<TextureInput> texture_inputs) {
  texture_inputs_ = std::move(texture_inputs);
}

bool RuntimeEffectContents::CanInheritOpacity(const Entity& entity) const {
  return false;
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

  if (function && runtime_stage_->IsDirty()) {
    context->GetPipelineLibrary()->RemovePipelinesWithEntryPoint(function);
    library->UnregisterFunction(runtime_stage_->GetEntrypoint(),
                                ShaderStage::kFragment);

    function = nullptr;
  }

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

    runtime_stage_->SetClean();
  }

  //--------------------------------------------------------------------------
  /// Resolve geometry.
  ///

  auto geometry_result =
      GetGeometry()->GetPositionBuffer(renderer, entity, pass);

  //--------------------------------------------------------------------------
  /// Get or create runtime stage pipeline.
  ///

  const auto& caps = context->GetCapabilities();
  const auto color_attachment_format = caps->GetDefaultColorFormat();
  const auto stencil_attachment_format = caps->GetDefaultStencilFormat();

  using VS = RuntimeEffectVertexShader;
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
  desc.SetColorAttachmentDescriptor(
      0u, {.format = color_attachment_format, .blending_enabled = true});
  desc.SetStencilAttachmentDescriptors({});
  desc.SetStencilPixelFormat(stencil_attachment_format);

  auto options = OptionsFromPassAndEntity(pass, entity);
  if (geometry_result.prevent_overdraw) {
    options.stencil_compare = CompareFunction::kEqual;
    options.stencil_operation = StencilOperation::kIncrementClamp;
  }
  options.primitive_type = geometry_result.type;
  options.ApplyToPipelineDescriptor(desc);

  auto pipeline = context->GetPipelineLibrary()->GetPipeline(desc).Get();
  if (!pipeline) {
    VALIDATION_LOG << "Failed to get or create runtime effect pipeline.";
    return false;
  }

  Command cmd;
  cmd.label = "RuntimeEffectContents";
  cmd.pipeline = pipeline;
  cmd.stencil_reference = entity.GetStencilDepth();
  cmd.BindVertices(geometry_result.vertex_buffer);

  //--------------------------------------------------------------------------
  /// Vertex stage uniforms.
  ///

  VS::FrameInfo frame_info;
  frame_info.mvp = geometry_result.transform;
  VS::BindFrameInfo(cmd, pass.GetTransientsBuffer().EmplaceUniform(frame_info));

  //--------------------------------------------------------------------------
  /// Fragment stage uniforms.
  ///

  size_t minimum_sampler_index = 100000000;
  size_t buffer_index = 0;
  size_t buffer_offset = 0;
  for (auto uniform : runtime_stage_->GetUniforms()) {
    // TODO(113715): Populate this metadata once GLES is able to handle
    //               non-struct uniform names.
    std::shared_ptr<ShaderMetadata> metadata =
        std::make_shared<ShaderMetadata>();

    switch (uniform.type) {
      case kSampledImage: {
        // Sampler uniforms are ordered in the IPLR according to their
        // declaration and the uniform location reflects the correct offset to
        // be mapped to - except that it may include all proceeding float
        // uniforms. For example, a float sampler that comes after 4 float
        // uniforms may have a location of 4. To convert to the actual offset we
        // need to find the largest location assigned to a float uniform and
        // then subtract this from all uniform locations. This is more or less
        // the same operation we previously performed in the shader compiler.
        minimum_sampler_index =
            std::min(minimum_sampler_index, uniform.location);
        break;
      }
      case kFloat: {
        size_t alignment =
            std::max(uniform.bit_width / 8, DefaultUniformAlignment());
        auto buffer_view = pass.GetTransientsBuffer().Emplace(
            uniform_data_->data() + buffer_offset, uniform.GetSize(),
            alignment);

        ShaderUniformSlot uniform_slot;
        uniform_slot.name = uniform.name.c_str();
        uniform_slot.ext_res_0 = uniform.location;
        cmd.BindResource(ShaderStage::kFragment, uniform_slot, metadata,
                         buffer_view);
        buffer_index++;
        buffer_offset += uniform.GetSize();
        break;
      }
      case kBoolean:
      case kSignedByte:
      case kUnsignedByte:
      case kSignedShort:
      case kUnsignedShort:
      case kSignedInt:
      case kUnsignedInt:
      case kSignedInt64:
      case kUnsignedInt64:
      case kHalfFloat:
      case kDouble:
        VALIDATION_LOG << "Unsupported uniform type for " << uniform.name
                       << ".";
        return true;
    }
  }

  size_t sampler_index = 0;
  for (auto uniform : runtime_stage_->GetUniforms()) {
    // TODO(113715): Populate this metadata once GLES is able to handle
    //               non-struct uniform names.
    ShaderMetadata metadata;

    switch (uniform.type) {
      case kSampledImage: {
        FML_DCHECK(sampler_index < texture_inputs_.size());
        auto& input = texture_inputs_[sampler_index];

        auto sampler =
            context->GetSamplerLibrary()->GetSampler(input.sampler_descriptor);

        SampledImageSlot image_slot;
        image_slot.name = uniform.name.c_str();
        image_slot.texture_index = uniform.location - minimum_sampler_index;
        image_slot.sampler_index = uniform.location - minimum_sampler_index;
        cmd.BindResource(ShaderStage::kFragment, image_slot, metadata,
                         input.texture, sampler);

        sampler_index++;
        break;
      }
      default:
        continue;
    }
  }

  pass.AddCommand(std::move(cmd));

  if (geometry_result.prevent_overdraw) {
    auto restore = ClipRestoreContents();
    restore.SetRestoreCoverage(GetCoverage(entity));
    return restore.Render(renderer, entity, pass);
  }
  return true;
}

}  // namespace impeller
