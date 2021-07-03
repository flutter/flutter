// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/primitives/box_primitive.h"

#include <memory>

#include "flutter/fml/logging.h"
#include "impeller/base/base.h"
#include "impeller/compositor/pipeline_builder.h"
#include "impeller/compositor/pipeline_descriptor.h"
#include "impeller/compositor/shader_library.h"
#include "impeller/compositor/vertex_descriptor.h"

namespace impeller {

BoxPrimitive::BoxPrimitive(std::shared_ptr<Context> context)
    : Primitive(context) {
  using Builder = PipelineBuilder<BoxVertexShader, BoxFragmentShader>;
  auto pipeline_descriptor = Builder::MakeDefaultPipelineDescriptor(*context);
  if (!pipeline_descriptor.has_value()) {
    return;
  }
  pipeline_ = context->GetPipelineLibrary()
                  ->GetRenderPipeline(pipeline_descriptor.value())
                  .get();
  if (!pipeline_) {
    return;
  }
  is_valid_ = true;
}

size_t BoxPrimitive::GetVertexBufferIndex() const {
  return vertex_buffer_index_;
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
