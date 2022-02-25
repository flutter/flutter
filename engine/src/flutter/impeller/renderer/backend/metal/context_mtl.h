// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <Metal/Metal.h>

#include <string>
#include <vector>

#include "flutter/fml/macros.h"
#include "impeller/base/backend_cast.h"
#include "impeller/renderer/backend/metal/allocator_mtl.h"
#include "impeller/renderer/backend/metal/command_buffer_mtl.h"
#include "impeller/renderer/backend/metal/pipeline_library_mtl.h"
#include "impeller/renderer/backend/metal/shader_library_mtl.h"
#include "impeller/renderer/context.h"
#include "impeller/renderer/sampler.h"

namespace impeller {

class ContextMTL final : public Context,
                         public BackendCast<ContextMTL, Context> {
 public:
  static std::shared_ptr<Context> Create(
      const std::vector<std::string>& shader_library_paths);

  static std::shared_ptr<Context> Create(
      const std::vector<std::shared_ptr<fml::Mapping>>& shader_libraries_data,
      const std::string& label);

  // |Context|
  ~ContextMTL() override;

  id<MTLDevice> GetMTLDevice() const;

 private:
  id<MTLDevice> device_ = nullptr;
  id<MTLCommandQueue> render_queue_ = nullptr;
  id<MTLCommandQueue> transfer_queue_ = nullptr;
  std::shared_ptr<ShaderLibraryMTL> shader_library_;
  std::shared_ptr<PipelineLibraryMTL> pipeline_library_;
  std::shared_ptr<SamplerLibrary> sampler_library_;
  std::shared_ptr<AllocatorMTL> permanents_allocator_;
  std::shared_ptr<AllocatorMTL> transients_allocator_;
  bool is_valid_ = false;

  ContextMTL(id<MTLDevice> device, NSArray<id<MTLLibrary>>* shader_libraries);

  // |Context|
  bool IsValid() const override;

  // |Context|
  std::shared_ptr<Allocator> GetPermanentsAllocator() const override;

  // |Context|
  std::shared_ptr<Allocator> GetTransientsAllocator() const override;

  // |Context|
  std::shared_ptr<ShaderLibrary> GetShaderLibrary() const override;

  // |Context|
  std::shared_ptr<SamplerLibrary> GetSamplerLibrary() const override;

  // |Context|
  std::shared_ptr<PipelineLibrary> GetPipelineLibrary() const override;

  // |Context|
  std::shared_ptr<CommandBuffer> CreateRenderCommandBuffer() const override;

  // |Context|
  std::shared_ptr<CommandBuffer> CreateTransferCommandBuffer() const override;

  std::shared_ptr<CommandBuffer> CreateCommandBufferInQueue(
      id<MTLCommandQueue> queue) const;

  FML_DISALLOW_COPY_AND_ASSIGN(ContextMTL);
};

}  // namespace impeller
