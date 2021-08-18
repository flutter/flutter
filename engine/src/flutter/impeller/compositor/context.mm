// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "context.h"

#include "flutter/fml/file.h"
#include "flutter/fml/logging.h"
#include "flutter/fml/paths.h"
#include "impeller/compositor/allocator.h"
#include "impeller/compositor/command_buffer.h"
#include "impeller/compositor/sampler_descriptor.h"
#include "impeller/compositor/shader_library.h"

namespace impeller {

Context::Context(std::string shaders_directory,
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
        std::shared_ptr<ShaderLibrary>(new ShaderLibrary(library));
  }

  // Setup the pipeline library.
  {  //
    pipeline_library_ =
        std::shared_ptr<PipelineLibrary>(new PipelineLibrary(device_));
  }

  // Setup the sampler library.
  {  //
    sampler_library_ =
        std::shared_ptr<SamplerLibrary>(new SamplerLibrary(device_));
  }

  {
    transients_allocator_ = std::shared_ptr<Allocator>(
        new Allocator(device_, "Impeller Transients Allocator"));
    if (!transients_allocator_) {
      return;
    }

    permanents_allocator_ = std::shared_ptr<Allocator>(
        new Allocator(device_, "Impeller Permanents Allocator"));
    if (!permanents_allocator_) {
      return;
    }
  }

  is_valid_ = true;
}

Context::~Context() = default;

bool Context::IsValid() const {
  return is_valid_;
}

std::shared_ptr<ShaderLibrary> Context::GetShaderLibrary() const {
  return shader_library_;
}

std::shared_ptr<PipelineLibrary> Context::GetPipelineLibrary() const {
  return pipeline_library_;
}

std::shared_ptr<SamplerLibrary> Context::GetSamplerLibrary() const {
  return sampler_library_;
}

std::shared_ptr<CommandBuffer> Context::CreateRenderCommandBuffer() const {
  if (!IsValid()) {
    return nullptr;
  }

  auto buffer =
      std::shared_ptr<CommandBuffer>(new CommandBuffer(render_queue_));
  if (!buffer->IsValid()) {
    return nullptr;
  }
  return buffer;
}

std::shared_ptr<Allocator> Context::GetPermanentsAllocator() const {
  return permanents_allocator_;
}

std::shared_ptr<Allocator> Context::GetTransientsAllocator() const {
  return transients_allocator_;
}

id<MTLDevice> Context::GetMTLDevice() const {
  return device_;
}

}  // namespace impeller
