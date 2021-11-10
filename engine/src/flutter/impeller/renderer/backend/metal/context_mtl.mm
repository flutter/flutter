// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/metal/context_mtl.h"

#include "flutter/fml/file.h"
#include "flutter/fml/logging.h"
#include "flutter/fml/paths.h"
#include "impeller/renderer/backend/metal/sampler_library_mtl.h"
#include "impeller/renderer/sampler_descriptor.h"

namespace impeller {

ContextMTL::ContextMTL(std::string shaders_directory,
                       std::string main_library_file_name)
    : device_(::MTLCreateSystemDefaultDevice()) {
  // Setup device.
  if (!device_) {
    return;
  }

  // Setup command queues.
  render_queue_ = device_.newCommandQueue;
  transfer_queue_ = device_.newCommandQueue;

  if (!render_queue_ || !transfer_queue_) {
    return;
  }

  render_queue_.label = @"Impeller Render Queue";
  transfer_queue_.label = @"Impeller Transfer Queue";

  // Setup the shader library.
  {
    NSError* shader_library_error = nil;
    auto shader_library_path =
        fml::paths::JoinPaths({shaders_directory, main_library_file_name});

    auto library_exists = fml::IsFile(shader_library_path);

    if (!library_exists) {
      FML_LOG(ERROR) << "Shader library does not exist at path '"
                     << shader_library_path
                     << "'. No piplines can be created in this context.";
    }
    auto library =
        library_exists
            ? [device_ newLibraryWithFile:@(shader_library_path.c_str())
                                    error:&shader_library_error]
            : [device_ newDefaultLibrary];
    if (!library && shader_library_error) {
      FML_LOG(ERROR) << "Could not create shader library: "
                     << shader_library_error.localizedDescription.UTF8String;
      return;
    }

    // std::make_shared disallowed because of private friend ctor.
    shader_library_ =
        std::shared_ptr<ShaderLibraryMTL>(new ShaderLibraryMTL(library));
  }

  // Setup the pipeline library.
  {  //
    pipeline_library_ =
        std::shared_ptr<PipelineLibraryMTL>(new PipelineLibraryMTL(device_));
  }

  // Setup the sampler library.
  {  //
    sampler_library_ =
        std::shared_ptr<SamplerLibraryMTL>(new SamplerLibraryMTL(device_));
  }

  {
    transients_allocator_ = std::shared_ptr<AllocatorMTL>(
        new AllocatorMTL(device_, "Impeller Transients Allocator"));
    if (!transients_allocator_) {
      return;
    }

    permanents_allocator_ = std::shared_ptr<AllocatorMTL>(
        new AllocatorMTL(device_, "Impeller Permanents Allocator"));
    if (!permanents_allocator_) {
      return;
    }
  }

  is_valid_ = true;
}

ContextMTL::~ContextMTL() = default;

bool ContextMTL::IsValid() const {
  return is_valid_;
}

std::shared_ptr<ShaderLibrary> ContextMTL::GetShaderLibrary() const {
  return shader_library_;
}

std::shared_ptr<PipelineLibrary> ContextMTL::GetPipelineLibrary() const {
  return pipeline_library_;
}

std::shared_ptr<SamplerLibrary> ContextMTL::GetSamplerLibrary() const {
  return sampler_library_;
}

std::shared_ptr<CommandBuffer> ContextMTL::CreateRenderCommandBuffer() const {
  return CreateCommandBufferInQueue(render_queue_);
}

std::shared_ptr<CommandBuffer> ContextMTL::CreateTransferCommandBuffer() const {
  return CreateCommandBufferInQueue(transfer_queue_);
}

std::shared_ptr<CommandBuffer> ContextMTL::CreateCommandBufferInQueue(
    id<MTLCommandQueue> queue) const {
  if (!IsValid()) {
    return nullptr;
  }

  auto buffer = std::shared_ptr<CommandBufferMTL>(new CommandBufferMTL(queue));
  if (!buffer->IsValid()) {
    return nullptr;
  }
  return buffer;
}

std::shared_ptr<Allocator> ContextMTL::GetPermanentsAllocator() const {
  return permanents_allocator_;
}

std::shared_ptr<Allocator> ContextMTL::GetTransientsAllocator() const {
  return transients_allocator_;
}

id<MTLDevice> ContextMTL::GetMTLDevice() const {
  return device_;
}

}  // namespace impeller
