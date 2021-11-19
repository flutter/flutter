// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/aiks/picture_renderer.h"

#include "impeller/aiks/picture.h"

namespace impeller {

PictureRenderer::PictureRenderer(std::shared_ptr<Context> context)
    : entity_renderer_(std::move(context)) {
  if (!entity_renderer_.IsValid()) {
    return;
  }
  is_valid_ = true;
}

PictureRenderer::~PictureRenderer() = default;

bool PictureRenderer::IsValid() const {
  return is_valid_;
}

bool PictureRenderer::Render(const Surface& surface,
                             RenderPass& parent_pass,
                             const Picture& picture) {
  if (!IsValid()) {
    return false;
  }

  for (const auto& pass : picture.passes) {
    if (!entity_renderer_.RenderEntities(surface, parent_pass,
                                         pass.GetPassEntities())) {
      return false;
    }
  }

  return true;
}

}  // namespace impeller
