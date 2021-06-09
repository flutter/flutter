// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/primitives/box_primitive.h"

#include <memory>

#include "flutter/fml/logging.h"
#include "impeller/compositor/pipeline_descriptor.h"
#include "impeller/compositor/shader_library.h"
#include "impeller/compositor/vertex_descriptor.h"

namespace impeller {

BoxPrimitive::BoxPrimitive(std::shared_ptr<Context> context)
    : Primitive(context) {
  PipelineDescriptor desc;
  desc.SetLabel(shader::BoxVertexInfo::kLabel);

  {
    auto fragment_function = context->GetShaderLibrary()->GetFunction(
        shader::BoxFragmentInfo::kEntrypointName, ShaderStage::kFragment);
    auto vertex_function = context->GetShaderLibrary()->GetFunction(
        shader::BoxVertexInfo::kEntrypointName, ShaderStage::kVertex);

    desc.AddStageEntrypoint(vertex_function);
    desc.AddStageEntrypoint(fragment_function);
  }

  {
    auto vertex_descriptor = std::make_shared<VertexDescriptor>();
    if (!vertex_descriptor->SetStageInputs(
            shader::BoxVertexInfo::kAllShaderStageInputs)) {
      FML_LOG(ERROR) << "Could not configure vertex descriptor.";
      return;
    }
    desc.SetVertexDescriptor(std::move(vertex_descriptor));
  }

  {
    // Configure the sole color attachments pixel format.
    ColorAttachmentDescriptor color0;
    color0.format = PixelFormat::kPixelFormat_B8G8R8A8_UNormInt_SRGB;
    desc.SetColorAttachmentDescriptor(0u, std::move(color0));
  }

  {
    // Configure the stencil attachment.
    // TODO(wip): Make this configurable if possible as the D32 compoment is
    // wasted.
    const auto combined_depth_stencil_format =
        PixelFormat::kPixelFormat_D32_Float_S8_UNormInt;
    desc.SetDepthPixelFormat(combined_depth_stencil_format);
    desc.SetStencilPixelFormat(combined_depth_stencil_format);
  }

  pipeline_ =
      context->GetPipelineLibrary()->GetRenderPipeline(std::move(desc)).get();
  if (!pipeline_) {
    FML_LOG(ERROR) << "Could not create the render pipeline.";
    return;
  }

  is_valid_ = true;
}

BoxPrimitive::~BoxPrimitive() = default;

std::shared_ptr<Pipeline> BoxPrimitive::GetPipeline() const {
  return pipeline_;
}

bool BoxPrimitive::IsValid() const {
  return is_valid_;
}

bool BoxPrimitive::Encode(RenderPass& pass) const {
  return false;
}

}  // namespace impeller
