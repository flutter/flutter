// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <memory>
#include <string>

#include "flutter/fml/macros.h"
#include "impeller/core/formats.h"
#include "impeller/renderer/capabilities.h"

namespace impeller {

class ShaderLibrary;
class SamplerLibrary;
class CommandBuffer;
class PipelineLibrary;
class Allocator;

class Context {
 public:
  virtual ~Context();

  virtual std::string DescribeGpuModel() const = 0;

  virtual bool IsValid() const = 0;

  virtual const std::shared_ptr<const Capabilities>& GetCapabilities()
      const = 0;

  virtual bool UpdateOffscreenLayerPixelFormat(PixelFormat format);

  virtual std::shared_ptr<Allocator> GetResourceAllocator() const = 0;

  virtual std::shared_ptr<ShaderLibrary> GetShaderLibrary() const = 0;

  virtual std::shared_ptr<SamplerLibrary> GetSamplerLibrary() const = 0;

  virtual std::shared_ptr<PipelineLibrary> GetPipelineLibrary() const = 0;

  virtual std::shared_ptr<CommandBuffer> CreateCommandBuffer() const = 0;

 protected:
  Context();

 private:
  FML_DISALLOW_COPY_AND_ASSIGN(Context);
};

}  // namespace impeller
