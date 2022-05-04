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

  PipelineLibraryGLES(ReactorGLES::Ref reactor);

  // |PipelineLibrary|
  PipelineFuture GetRenderPipeline(PipelineDescriptor descriptor) override;

  FML_DISALLOW_COPY_AND_ASSIGN(PipelineLibraryGLES);
};

}  // namespace impeller
