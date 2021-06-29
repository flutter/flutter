// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <Metal/Metal.h>

#include <memory>

#include "flutter/fml/macros.h"
#include "impeller/compositor/pipeline_library.h"

namespace impeller {

class ShaderLibrary;
class CommandBuffer;
class Allocator;

class Context {
 public:
  Context(std::string shaders_directory);

  ~Context();

  bool IsValid() const;

  //----------------------------------------------------------------------------
  /// @return     An allocator suitable for allocations that persist between
  ///             frames.
  ///
  std::shared_ptr<Allocator> GetPermanentsAllocator() const;

  //----------------------------------------------------------------------------
  /// @return     An allocator suitable for allocations that used only for one
  ///             frame or render pass.
  ///
  std::shared_ptr<Allocator> GetTransientsAllocator() const;

  std::shared_ptr<ShaderLibrary> GetShaderLibrary() const;

  std::shared_ptr<PipelineLibrary> GetPipelineLibrary() const;

  std::shared_ptr<CommandBuffer> CreateRenderCommandBuffer() const;

 private:
  id<MTLDevice> device_ = nullptr;
  id<MTLCommandQueue> render_queue_ = nullptr;
  id<MTLCommandQueue> transfer_queue_ = nullptr;
  std::shared_ptr<ShaderLibrary> shader_library_;
  std::shared_ptr<PipelineLibrary> pipeline_library_;
  std::shared_ptr<Allocator> permanents_allocator_;
  std::shared_ptr<Allocator> transients_allocator_;
  bool is_valid_ = false;

  FML_DISALLOW_COPY_AND_ASSIGN(Context);
};

}  // namespace impeller
