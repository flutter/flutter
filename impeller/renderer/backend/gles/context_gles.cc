// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/gles/context_gles.h"

#include "impeller/base/config.h"
#include "impeller/base/validation.h"

namespace impeller {

std::shared_ptr<ContextGLES> ContextGLES::Create(
    std::unique_ptr<ProcTableGLES> gl,
    std::vector<std::shared_ptr<fml::Mapping>> shader_libraries) {
  return std::shared_ptr<ContextGLES>(
      new ContextGLES(std::move(gl), std::move(shader_libraries)));
}

ContextGLES::ContextGLES(
    std::unique_ptr<ProcTableGLES> gl,
    std::vector<std::shared_ptr<fml::Mapping>> shader_libraries_mappings) {
  reactor_ = std::make_shared<ReactorGLES>(std::move(gl));
  if (!reactor_->IsValid()) {
    VALIDATION_LOG << "Could not create valid reactor.";
    return;
  }

  // Create the shader library.
  {
    auto library = std::shared_ptr<ShaderLibraryGLES>(
        new ShaderLibraryGLES(std::move(shader_libraries_mappings)));
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

  // Create all allocators.
  {
    permanents_allocator_ =
        std::shared_ptr<AllocatorGLES>(new AllocatorGLES(reactor_));
    if (!permanents_allocator_->IsValid()) {
      VALIDATION_LOG << "Could not create permanents allocator.";
      return;
    }

    transients_allocator_ =
        std::shared_ptr<AllocatorGLES>(new AllocatorGLES(reactor_));
    if (!transients_allocator_->IsValid()) {
      VALIDATION_LOG << "Could not create transients allocator.";
      return;
    }
  }

  // Create the sampler library
  {
    sampler_library_ =
        std::shared_ptr<SamplerLibraryGLES>(new SamplerLibraryGLES());
  }

  is_valid_ = true;
}

ContextGLES::~ContextGLES() = default;

const ReactorGLES::Ref& ContextGLES::GetReactor() const {
  return reactor_;
}

std::optional<ReactorGLES::WorkerID> ContextGLES::AddReactorWorker(
    std::shared_ptr<ReactorGLES::Worker> worker) {
  if (!IsValid()) {
    return std::nullopt;
  }
  return reactor_->AddWorker(std::move(worker));
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

std::shared_ptr<Allocator> ContextGLES::GetPermanentsAllocator() const {
  return permanents_allocator_;
}

std::shared_ptr<Allocator> ContextGLES::GetTransientsAllocator() const {
  return transients_allocator_;
}

std::shared_ptr<ShaderLibrary> ContextGLES::GetShaderLibrary() const {
  return shader_library_;
}

std::shared_ptr<SamplerLibrary> ContextGLES::GetSamplerLibrary() const {
  return sampler_library_;
}

std::shared_ptr<PipelineLibrary> ContextGLES::GetPipelineLibrary() const {
  return pipeline_library_;
}

std::shared_ptr<CommandBuffer> ContextGLES::CreateRenderCommandBuffer() const {
  return std::shared_ptr<CommandBufferGLES>(new CommandBufferGLES(reactor_));
}

std::shared_ptr<CommandBuffer> ContextGLES::CreateTransferCommandBuffer()
    const {
  // There is no such concept. Just use a render command buffer.
  return CreateRenderCommandBuffer();
}

// |Context|
bool ContextGLES::HasThreadingRestrictions() const {
  return true;
}

}  // namespace impeller
