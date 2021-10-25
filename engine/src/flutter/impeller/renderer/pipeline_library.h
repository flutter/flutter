// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <optional>

#include "flutter/fml/macros.h"
#include "impeller/renderer/pipeline.h"
#include "impeller/renderer/pipeline_descriptor.h"

namespace impeller {

class Context;

class PipelineLibrary : public std::enable_shared_from_this<PipelineLibrary> {
 public:
  virtual ~PipelineLibrary();

  PipelineFuture GetRenderPipeline(
      std::optional<PipelineDescriptor> descriptor);

  virtual PipelineFuture GetRenderPipeline(PipelineDescriptor descriptor) = 0;

 protected:
  PipelineLibrary();

 private:
  FML_DISALLOW_COPY_AND_ASSIGN(PipelineLibrary);
};

}  // namespace impeller
