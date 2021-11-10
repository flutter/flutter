// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <Metal/Metal.h>

#include "flutter/fml/macros.h"
#include "impeller/renderer/backend/metal/backend_cast.h"
#include "impeller/renderer/pipeline.h"

namespace impeller {

class PipelineMTL final : public Pipeline,
                          public BackendCast<PipelineMTL, Pipeline> {
 public:
  // |PipelineMTL|
  ~PipelineMTL() override;

  id<MTLRenderPipelineState> GetMTLRenderPipelineState() const;

  id<MTLDepthStencilState> GetMTLDepthStencilState() const;

 private:
  friend class PipelineLibraryMTL;

  Type type_ = Type::kUnknown;
  id<MTLRenderPipelineState> pipeline_state_;
  id<MTLDepthStencilState> depth_stencil_state_;
  bool is_valid_ = false;

  PipelineMTL(PipelineDescriptor desc,
              id<MTLRenderPipelineState> state,
              id<MTLDepthStencilState> depth_stencil_state);

  // |PipelineMTL|
  bool IsValid() const override;

  FML_DISALLOW_COPY_AND_ASSIGN(PipelineMTL);
};

}  // namespace impeller
