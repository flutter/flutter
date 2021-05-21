// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/primitives/box.h"

#include "box.frag.h"
#include "box.vert.h"
#include "impeller/compositor/pipeline_builder.h"

namespace impeller {

void RenderBox(std::shared_ptr<Context> context) {
  PipelineBuilder builder;

  auto fragment_function = context->GetShaderLibrary()->GetFunction(
      shader::BoxFragmentInfo::kEntrypointName, ShaderStage::kFragment);
  auto vertex_function = context->GetShaderLibrary()->GetFunction(
      shader::BoxVertexInfo::kEntrypointName, ShaderStage::kVertex);

  builder.AddStageEntrypoint(vertex_function);
  builder.AddStageEntrypoint(fragment_function);
  builder.SetLabel(shader::BoxVertexInfo::kLabel);
}

}  // namespace impeller
