// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <memory>
#include <string>

#include "flutter/fml/macros.h"
#include "impeller/renderer/backend_features.h"
#include "impeller/renderer/formats.h"

namespace impeller {

class ShaderLibrary;
class SamplerLibrary;
class CommandBuffer;
class PipelineLibrary;
class Allocator;
class GPUTracer;
class WorkQueue;

class Context : public std::enable_shared_from_this<Context> {
 public:
  virtual ~Context();

  virtual bool IsValid() const = 0;

  //----------------------------------------------------------------------------
  /// @return     A resource allocator.
  ///
  virtual std::shared_ptr<Allocator> GetResourceAllocator() const = 0;

  virtual std::shared_ptr<ShaderLibrary> GetShaderLibrary() const = 0;

  virtual std::shared_ptr<SamplerLibrary> GetSamplerLibrary() const = 0;

  virtual std::shared_ptr<PipelineLibrary> GetPipelineLibrary() const = 0;

  virtual std::shared_ptr<CommandBuffer> CreateCommandBuffer() const = 0;

  virtual std::shared_ptr<WorkQueue> GetWorkQueue() const = 0;

  //----------------------------------------------------------------------------
  /// @return A GPU Tracer to trace gpu rendering.
  ///
  virtual std::shared_ptr<GPUTracer> GetGPUTracer() const;

  virtual PixelFormat GetColorAttachmentPixelFormat() const;

  virtual bool HasThreadingRestrictions() const;

  virtual bool SupportsOffscreenMSAA() const = 0;

  virtual const BackendFeatures& GetBackendFeatures() const = 0;

 protected:
  Context();

 private:
  FML_DISALLOW_COPY_AND_ASSIGN(Context);
};

}  // namespace impeller
