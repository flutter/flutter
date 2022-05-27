// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <memory>
#include <string>

#include "flutter/fml/macros.h"

namespace impeller {

class ShaderLibrary;
class SamplerLibrary;
class CommandBuffer;
class PipelineLibrary;
class Allocator;

class Context {
 public:
  virtual ~Context();

  virtual bool IsValid() const = 0;

  //----------------------------------------------------------------------------
  /// @return     An allocator suitable for allocations that persist between
  ///             frames.
  ///
  virtual std::shared_ptr<Allocator> GetPermanentsAllocator() const = 0;

  //----------------------------------------------------------------------------
  /// @return     An allocator suitable for allocations that used only for one
  ///             frame or render pass.
  ///
  virtual std::shared_ptr<Allocator> GetTransientsAllocator() const = 0;

  virtual std::shared_ptr<ShaderLibrary> GetShaderLibrary() const = 0;

  virtual std::shared_ptr<SamplerLibrary> GetSamplerLibrary() const = 0;

  virtual std::shared_ptr<PipelineLibrary> GetPipelineLibrary() const = 0;

  virtual std::shared_ptr<CommandBuffer> CreateRenderCommandBuffer() const = 0;

  virtual std::shared_ptr<CommandBuffer> CreateTransferCommandBuffer()
      const = 0;

  virtual bool HasThreadingRestrictions() const;

 protected:
  Context();

 private:
  FML_DISALLOW_COPY_AND_ASSIGN(Context);
};

}  // namespace impeller
