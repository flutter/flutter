// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/entity.h"

#include <algorithm>
#include <optional>

#include "impeller/base/validation.h"
#include "impeller/entity/contents/content_context.h"
#include "impeller/entity/contents/filters/filter_contents.h"
#include "impeller/entity/contents/texture_contents.h"
#include "impeller/entity/entity_pass.h"
#include "impeller/geometry/color.h"
#include "impeller/geometry/vector.h"
#include "impeller/renderer/render_pass.h"

namespace impeller {

std::optional<Entity> Entity::FromSnapshot(
    const std::optional<Snapshot>& snapshot,
    BlendMode blend_mode,
    uint32_t stencil_depth) {
  if (!snapshot.has_value()) {
    return std::nullopt;
  }

  auto texture_rect = Rect::MakeSize(snapshot->texture->GetSize());

  auto contents = TextureContents::MakeRect(texture_rect);
  contents->SetTexture(snapshot->texture);
  contents->SetSamplerDescriptor(snapshot->sampler_descriptor);
  contents->SetSourceRect(texture_rect);
  contents->SetOpacity(snapshot->opacity);

  Entity entity;
  entity.SetBlendMode(blend_mode);
  entity.SetStencilDepth(stencil_depth);
  entity.SetTransformation(snapshot->transform);
  entity.SetContents(contents);
  return entity;
}

Entity::Entity() = default;

Entity::~Entity() = default;

const Matrix& Entity::GetTransformation() const {
  return transformation_;
}

void Entity::SetTransformation(const Matrix& transformation) {
  transformation_ = transformation;
}

std::optional<Rect> Entity::GetCoverage() const {
  if (!contents_) {
    return std::nullopt;
  }

  return contents_->GetCoverage(*this);
}

Contents::StencilCoverage Entity::GetStencilCoverage(
    const std::optional<Rect>& current_stencil_coverage) const {
  if (!contents_) {
    return {};
  }
  return contents_->GetStencilCoverage(*this, current_stencil_coverage);
}

bool Entity::ShouldRender(const std::optional<Rect>& stencil_coverage) const {
  return contents_->ShouldRender(*this, stencil_coverage);
}

void Entity::SetContents(std::shared_ptr<Contents> contents) {
  contents_ = std::move(contents);
}

const std::shared_ptr<Contents>& Entity::GetContents() const {
  return contents_;
}

void Entity::SetStencilDepth(uint32_t depth) {
  stencil_depth_ = depth;
}

uint32_t Entity::GetStencilDepth() const {
  return stencil_depth_;
}

void Entity::IncrementStencilDepth(uint32_t increment) {
  stencil_depth_ += increment;
}

void Entity::SetBlendMode(BlendMode blend_mode) {
  blend_mode_ = blend_mode;
}

BlendMode Entity::GetBlendMode() const {
  return blend_mode_;
}

bool Entity::CanInheritOpacity() const {
  if (!contents_) {
    return false;
  }
  if (!((blend_mode_ == BlendMode::kSource && contents_->IsOpaque()) ||
        blend_mode_ == BlendMode::kSourceOver)) {
    return false;
  }
  return contents_->CanInheritOpacity(*this);
}

bool Entity::SetInheritedOpacity(Scalar alpha) {
  if (!CanInheritOpacity()) {
    return false;
  }
  if (blend_mode_ == BlendMode::kSource && contents_->IsOpaque()) {
    blend_mode_ = BlendMode::kSourceOver;
  }
  contents_->SetInheritedOpacity(alpha);
  return true;
}

/// @brief  Returns true if the blend mode is "destructive", meaning that even
///         fully transparent source colors would result in the destination
///         getting changed.
///
///         This is useful for determining if EntityPass textures can be
///         shrinkwrapped to their Entities' coverage; they can be shrinkwrapped
///         if all of the contained Entities have non-destructive blends.
bool Entity::IsBlendModeDestructive(BlendMode blend_mode) {
  switch (blend_mode) {
    case BlendMode::kClear:
    case BlendMode::kSource:
    case BlendMode::kSourceIn:
    case BlendMode::kDestinationIn:
    case BlendMode::kSourceOut:
    case BlendMode::kDestinationOut:
    case BlendMode::kDestinationATop:
    case BlendMode::kXor:
    case BlendMode::kModulate:
      return true;
    default:
      return false;
  }
}

bool Entity::Render(const ContentContext& renderer,
                    RenderPass& parent_pass) const {
  if (!contents_) {
    return true;
  }

  return contents_->Render(renderer, *this, parent_pass);
}

}  // namespace impeller
