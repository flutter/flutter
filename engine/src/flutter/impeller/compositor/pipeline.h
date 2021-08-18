// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <Metal/Metal.h>

#include <future>

#include "flutter/fml/macros.h"
#include "impeller/compositor/context.h"
#include "impeller/compositor/pipeline_builder.h"

namespace impeller {

class PipelineLibrary;
class Pipeline;

using PipelineFuture = std::future<std::shared_ptr<Pipeline>>;

class Pipeline {
 public:
  enum class Type {
    kUnknown,
    kRender,
  };

  ~Pipeline();

  bool IsValid() const;

  id<MTLRenderPipelineState> GetMTLRenderPipelineState() const;

  id<MTLDepthStencilState> GetMTLDepthStencilState() const;

 private:
  friend class PipelineLibrary;

  Type type_ = Type::kUnknown;
  id<MTLRenderPipelineState> pipeline_state_;
  id<MTLDepthStencilState> depth_stencil_state_;
  bool is_valid_ = false;

  Pipeline(id<MTLRenderPipelineState> state,
           id<MTLDepthStencilState> depth_stencil_state);

  FML_DISALLOW_COPY_AND_ASSIGN(Pipeline);
};

PipelineFuture CreatePipelineFuture(const Context& context,
                                    std::optional<PipelineDescriptor> desc);

template <class VertexShader_, class FragmentShader_>
class PipelineT {
 public:
  using VertexShader = VertexShader_;
  using FragmentShader = FragmentShader_;
  using Builder = PipelineBuilder<VertexShader, FragmentShader>;

  explicit PipelineT(const Context& context)
      : pipeline_future_(CreatePipelineFuture(
            context,
            Builder::MakeDefaultPipelineDescriptor(context))) {}

  const Pipeline* WaitAndGet() { return pipeline_future_.get().get(); }

 private:
  PipelineFuture pipeline_future_;

  FML_DISALLOW_COPY_AND_ASSIGN(PipelineT);
};

}  // namespace impeller
