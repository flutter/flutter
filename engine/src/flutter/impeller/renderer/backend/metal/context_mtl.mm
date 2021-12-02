// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/metal/context_mtl.h"

#include <Foundation/Foundation.h>

#include "flutter/fml/file.h"
#include "flutter/fml/logging.h"
#include "flutter/fml/paths.h"
#include "impeller/renderer/backend/metal/sampler_library_mtl.h"
#include "impeller/renderer/sampler_descriptor.h"

namespace impeller {

static NSArray<id<MTLLibrary>>* ShaderLibrariesFromFiles(
    id<MTLDevice> device,
    const std::vector<std::string>& libraries_paths) {
  NSMutableArray<id<MTLLibrary>>* found_libraries = [NSMutableArray array];
  for (const auto& library_path : libraries_paths) {
    if (!fml::IsFile(library_path)) {
      VALIDATION_LOG << "Shader library does not exist at path '"
                     << library_path << "'";
      continue;
    }
    NSError* shader_library_error = nil;
    auto library = [device newLibraryWithFile:@(library_path.c_str())
                                        error:&shader_library_error];
    if (!library) {
      FML_LOG(ERROR) << "Could not create shader library: "
                     << shader_library_error.localizedDescription.UTF8String;
      continue;
    }
    [found_libraries addObject:library];
  }
  return found_libraries;
}

ContextMTL::ContextMTL(const std::vector<std::string>& libraries_paths)
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
    // std::make_shared disallowed because of private friend ctor.
    auto library = std::shared_ptr<ShaderLibraryMTL>(new ShaderLibraryMTL(
        ShaderLibrariesFromFiles(device_, libraries_paths)));
    if (!library->IsValid()) {
      VALIDATION_LOG << "Could not create valid Metal shader library.";
      return;
    }
    shader_library_ = std::move(library);
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
