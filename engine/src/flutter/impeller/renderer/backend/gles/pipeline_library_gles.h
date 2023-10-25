// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "flutter/fml/macros.h"
#include "impeller/renderer/backend/gles/reactor_gles.h"
#include "impeller/renderer/pipeline_library.h"

namespace impeller {

class ContextGLES;

class PipelineLibraryGLES final : public PipelineLibrary {
 public:
  // |PipelineLibrary|
  ~PipelineLibraryGLES() override;

 private:
  friend ContextGLES;

  ReactorGLES::Ref reactor_;
  PipelineMap pipelines_;

  explicit PipelineLibraryGLES(ReactorGLES::Ref reactor);

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

  PipelineLibraryGLES(const PipelineLibraryGLES&) = delete;

  PipelineLibraryGLES& operator=(const PipelineLibraryGLES&) = delete;
};

}  // namespace impeller
