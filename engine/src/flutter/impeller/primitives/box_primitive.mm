// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/primitives/box_primitive.h"

#include <memory>

#include "box.frag.h"
#include "box.vert.h"
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

  auto pipeline =
      context->GetPipelineLibrary()->GetRenderPipeline(std::move(desc)).get();
  if (!pipeline) {
    FML_LOG(ERROR) << "Could not create the render pipeline.";
    return;
  }

  is_valid_ = true;
}

BoxPrimitive::~BoxPrimitive() = default;

bool BoxPrimitive::Encode(RenderPass& pass) const {
  return false;
}

}  // namespace impeller
