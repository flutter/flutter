// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <Metal/Metal.h>

#include "flutter/fml/macros.h"
#include "impeller/renderer/pipeline_library.h"

namespace impeller {

class ContextMTL;

class PipelineLibraryMTL final : public PipelineLibrary {
 public:
  PipelineLibraryMTL();

  // |PipelineLibrary|
  ~PipelineLibraryMTL() override;

 private:
  friend ContextMTL;

  id<MTLDevice> device_ = nullptr;
  PipelineMap pipelines_;
  ComputePipelineMap compute_pipelines_;

  explicit PipelineLibraryMTL(id<MTLDevice> device);

  // |PipelineLibrary|
  bool IsValid() const override;

  // |PipelineLibrary|
  PipelineFuture<PipelineDescriptor> GetPipeline(
      PipelineDescriptor descriptor) override;

  // |PipelineLibrary|
  PipelineFuture<ComputePipelineDescriptor> GetPipeline(
      ComputePipelineDescriptor descriptor) override;

  // |PipelineLibrary|
  void RemovePipelinesWithEntryPoint(
      std::shared_ptr<const ShaderFunction> function) override;

  PipelineLibraryMTL(const PipelineLibraryMTL&) = delete;

  PipelineLibraryMTL& operator=(const PipelineLibraryMTL&) = delete;
};

}  // namespace impeller
