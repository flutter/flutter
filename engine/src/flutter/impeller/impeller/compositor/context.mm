// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "context.h"

#include "flutter/fml/logging.h"
#include "flutter/fml/paths.h"
#include "impeller/compositor/shader_library.h"

namespace impeller {

Context::Context(std::string shaders_directory)
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
        fml::paths::JoinPaths({shaders_directory, "impeller.metallib"});
    id<MTLLibrary> library =
        [device_ newLibraryWithFile:@(shader_library_path.c_str())
                              error:&shader_library_error];
    if (!library) {
      FML_LOG(ERROR) << "Could not create shader library: "
                     << shader_library_error.localizedDescription.UTF8String;
      return;
    }

    // std::make_shared disallowed because of private friend ctor.
    shader_library_ =
        std::shared_ptr<ShaderLibrary>(new ShaderLibrary(library));
  }

  is_valid_ = true;
}

Context::~Context() = default;

bool Context::IsValid() const {
  return is_valid_;
}

id<MTLCommandQueue> Context::GetRenderQueue() const {
  return render_queue_;
}

id<MTLCommandQueue> Context::GetTransferQueue() const {
  return transfer_queue_;
}

}  // namespace impeller
