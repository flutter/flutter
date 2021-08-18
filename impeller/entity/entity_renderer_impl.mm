// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/entity_renderer_impl.h"

namespace impeller {

EntityRendererImpl::EntityRendererImpl(std::shared_ptr<Context> context)
    : context_(std::move(context)) {
  if (!context_ || !context_->IsValid()) {
    return;
  }

  solid_fill_pipeline_ = std::make_unique<SolidFillPipeline>(*context);

  is_valid_ = true;
}

EntityRendererImpl::~EntityRendererImpl() = default;

bool EntityRendererImpl::IsValid() const {
  return is_valid_;
}

bool EntityRendererImpl::RenderEntity(const Surface& surface,
                                      const RenderPass& onscreen_pass,
                                      const Entity& entity) {
  if (!entity.HasRenderableContents()) {
    return true;
  }

  return true;
}

}  // namespace impeller
