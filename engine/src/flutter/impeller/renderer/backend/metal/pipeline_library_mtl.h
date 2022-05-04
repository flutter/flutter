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

  PipelineLibraryMTL(id<MTLDevice> device);

  // |PipelineLibrary|
  PipelineFuture GetRenderPipeline(PipelineDescriptor descriptor) override;

  FML_DISALLOW_COPY_AND_ASSIGN(PipelineLibraryMTL);
};

}  // namespace impeller
