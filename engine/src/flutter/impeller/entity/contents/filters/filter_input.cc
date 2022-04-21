// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/contents/filters/filter_input.h"

#include <cstdarg>
#include <initializer_list>
#include <memory>
#include <optional>
#include <variant>

#include "fml/logging.h"
#include "impeller/entity/contents/filters/filter_contents.h"
#include "impeller/entity/contents/snapshot.h"
#include "impeller/entity/entity.h"

namespace impeller {

/*******************************************************************************
 ******* FilterInput
 ******************************************************************************/

FilterInput::Ref FilterInput::Make(Variant input) {
  if (auto filter = std::get_if<std::shared_ptr<FilterContents>>(&input)) {
    return std::static_pointer_cast<FilterInput>(
        std::shared_ptr<FilterContentsFilterInput>(
            new FilterContentsFilterInput(*filter)));
  }

  if (auto contents = std::get_if<std::shared_ptr<Contents>>(&input)) {
    return std::static_pointer_cast<FilterInput>(
        std::shared_ptr<ContentsFilterInput>(
            new ContentsFilterInput(*contents)));
  }

  if (auto texture = std::get_if<std::shared_ptr<Texture>>(&input)) {
    return std::static_pointer_cast<FilterInput>(
        std::shared_ptr<TextureFilterInput>(new TextureFilterInput(*texture)));
  }

  FML_UNREACHABLE();
}

FilterInput::Vector FilterInput::Make(std::initializer_list<Variant> inputs) {
  FilterInput::Vector result;
  result.reserve(inputs.size());
  for (const auto& input : inputs) {
    result.push_back(Make(input));
  }
  return result;
}

Matrix FilterInput::GetLocalTransform(const Entity& entity) const {
  return Matrix();
}

Matrix FilterInput::GetTransform(const Entity& entity) const {
  return entity.GetTransformation() * GetLocalTransform(entity);
}

FilterInput::~FilterInput() = default;

/*******************************************************************************
 ******* FilterContentsFilterInput
 ******************************************************************************/

FilterContentsFilterInput::FilterContentsFilterInput(
    std::shared_ptr<FilterContents> filter)
    : filter_(filter) {}

FilterContentsFilterInput::~FilterContentsFilterInput() = default;

FilterInput::Variant FilterContentsFilterInput::GetInput() const {
  return filter_;
}

std::optional<Snapshot> FilterContentsFilterInput::GetSnapshot(
    const ContentContext& renderer,
    const Entity& entity) const {
  if (!snapshot_.has_value()) {
    snapshot_ = filter_->RenderToSnapshot(renderer, entity);
  }
  return snapshot_;
}

std::optional<Rect> FilterContentsFilterInput::GetCoverage(
    const Entity& entity) const {
  return filter_->GetCoverage(entity);
}

Matrix FilterContentsFilterInput::GetLocalTransform(
    const Entity& entity) const {
  return filter_->GetLocalTransform();
}

Matrix FilterContentsFilterInput::GetTransform(const Entity& entity) const {
  return filter_->GetTransform(entity.GetTransformation());
}

/*******************************************************************************
 ******* ContentsFilterInput
 ******************************************************************************/

ContentsFilterInput::ContentsFilterInput(std::shared_ptr<Contents> contents)
    : contents_(contents) {}

ContentsFilterInput::~ContentsFilterInput() = default;

FilterInput::Variant ContentsFilterInput::GetInput() const {
  return contents_;
}

std::optional<Snapshot> ContentsFilterInput::GetSnapshot(
    const ContentContext& renderer,
    const Entity& entity) const {
  if (!snapshot_.has_value()) {
    snapshot_ = contents_->RenderToSnapshot(renderer, entity);
  }
  return snapshot_;
}

std::optional<Rect> ContentsFilterInput::GetCoverage(
    const Entity& entity) const {
  return contents_->GetCoverage(entity);
}

/*******************************************************************************
 ******* TextureFilterInput
 ******************************************************************************/

TextureFilterInput::TextureFilterInput(std::shared_ptr<Texture> texture)
    : texture_(texture) {}

TextureFilterInput::~TextureFilterInput() = default;

FilterInput::Variant TextureFilterInput::GetInput() const {
  return texture_;
}

std::optional<Snapshot> TextureFilterInput::GetSnapshot(
    const ContentContext& renderer,
    const Entity& entity) const {
  return Snapshot{.texture = texture_, .transform = GetTransform(entity)};
}

std::optional<Rect> TextureFilterInput::GetCoverage(
    const Entity& entity) const {
  auto path_bounds = entity.GetPath().GetBoundingBox();
  if (!path_bounds.has_value()) {
    return std::nullopt;
  }
  return Rect::MakeSize(Size(texture_->GetSize()))
      .TransformBounds(GetTransform(entity));
}

Matrix TextureFilterInput::GetLocalTransform(const Entity& entity) const {
  // Compute the local transform such that the texture will cover the entity
  // path bounding box.
  auto path_bounds = entity.GetPath().GetBoundingBox();
  if (!path_bounds.has_value()) {
    return Matrix();
  }
  return Matrix::MakeTranslation(path_bounds->origin) *
         Matrix::MakeScale(Vector2(path_bounds->size) / texture_->GetSize());
}

}  // namespace impeller
