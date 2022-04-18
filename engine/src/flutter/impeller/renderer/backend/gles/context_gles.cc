// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/gles/context_gles.h"

#include "impeller/base/config.h"
#include "impeller/base/validation.h"

namespace impeller {

ContextGLES::ContextGLES() {
  auto reactor = std::make_shared<ReactorGLES>();
  if (!reactor->IsValid()) {
    VALIDATION_LOG << "Could not create valid reactor.";
    return;
  }

  is_valid_ = true;
}

ContextGLES::~ContextGLES() = default;

bool ContextGLES::IsValid() const {
  return is_valid_;
}

std::shared_ptr<Allocator> ContextGLES::GetPermanentsAllocator() const {
  IMPELLER_UNIMPLEMENTED;
  return permanents_allocator_;
}

std::shared_ptr<Allocator> ContextGLES::GetTransientsAllocator() const {
  IMPELLER_UNIMPLEMENTED;
  return transients_allocator_;
}

std::shared_ptr<ShaderLibrary> ContextGLES::GetShaderLibrary() const {
  IMPELLER_UNIMPLEMENTED;
  return shader_library_;
}

std::shared_ptr<SamplerLibrary> ContextGLES::GetSamplerLibrary() const {
  IMPELLER_UNIMPLEMENTED;
  return sampler_library_;
}

std::shared_ptr<PipelineLibrary> ContextGLES::GetPipelineLibrary() const {
  IMPELLER_UNIMPLEMENTED;
  return pipeline_library_;
}

std::shared_ptr<CommandBuffer> ContextGLES::CreateRenderCommandBuffer() const {
  IMPELLER_UNIMPLEMENTED;
  return std::shared_ptr<CommandBufferGLES>(new CommandBufferGLES());
}

std::shared_ptr<CommandBuffer> ContextGLES::CreateTransferCommandBuffer()
    const {
  IMPELLER_UNIMPLEMENTED;
  return std::shared_ptr<CommandBufferGLES>(new CommandBufferGLES());
}

}  // namespace impeller
