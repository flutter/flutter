// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/entity_renderer_impl.h"
#include "impeller/compositor/vertex_buffer_builder.h"

namespace impeller {

EntityRendererImpl::EntityRendererImpl(std::shared_ptr<Context> context)
    : context_(std::move(context)) {
  if (!context_ || !context_->IsValid()) {
    return;
  }

  solid_fill_pipeline_ = std::make_unique<SolidFillPipeline>(*context_);

  is_valid_ = true;
}

EntityRendererImpl::~EntityRendererImpl() = default;

bool EntityRendererImpl::IsValid() const {
  return is_valid_;
}

bool EntityRendererImpl::RenderEntity(const Surface& surface,
                                      RenderPass& pass,
                                      const Entity& entity) {
  if (!entity.HasRenderableContents()) {
    return true;
  }

  if (entity.HasContents()) {
    using VS = SolidFillPipeline::VertexShader;

    Command cmd;
    cmd.pipeline = solid_fill_pipeline_->WaitAndGet();
    if (cmd.pipeline == nullptr) {
      return false;
    }

    VertexBufferBuilder<VS::PerVertexData> builder;

    VS::FrameInfo frame_info;
    frame_info.mvp = Matrix::MakeOrthographic(surface.GetSize()) *
                     entity.GetTransformation();
    VS::BindFrameInfo(cmd,
                      pass.GetTransientsBuffer().EmplaceUniform(frame_info));
  }

  return true;
}

}  // namespace impeller
