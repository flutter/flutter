// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/contents/clear_contents.h"

#include "impeller/entity/entity.h"
#include "impeller/geometry/path_builder.h"
#include "impeller/renderer/render_pass.h"

namespace impeller {

ClearContents::ClearContents(std::shared_ptr<Contents> contents)
    : contents_(std::move(contents)) {}

ClearContents::~ClearContents() = default;

// |Contents|
bool ClearContents::Render(const ContentContext& renderer,
                           const Entity& entity,
                           RenderPass& pass) const {
  if (contents_ == nullptr) {
    return false;
  }
  // Instead of an entity that doesn't know its size because the render target
  // size was unknown to it at construction time, create a copy but substitute
  // the contents with the replacements.
  Entity clear_entity = entity;
  clear_entity.SetPath(
      PathBuilder{}.AddRect(Size(pass.GetRenderTargetSize())).TakePath());
  return contents_->Render(renderer, clear_entity, pass);
}

}  // namespace impeller
