// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/primitives/box.h"

#include "box.frag.h"
#include "box.vert.h"
#include "impeller/compositor/pipeline_descriptor.h"
#include "impeller/compositor/shader_library.h"

namespace impeller {

void RenderBox(std::shared_ptr<Context> context) {
  auto fragment_function = context->GetShaderLibrary()->GetFunction(
      shader::BoxFragmentInfo::kEntrypointName, ShaderStage::kFragment);
  auto vertex_function = context->GetShaderLibrary()->GetFunction(
      shader::BoxVertexInfo::kEntrypointName, ShaderStage::kVertex);

  PipelineDescriptor builder;
  builder.SetLabel(shader::BoxVertexInfo::kLabel);
  builder.AddStageEntrypoint(vertex_function);
  builder.AddStageEntrypoint(fragment_function);
}

}  // namespace impeller
