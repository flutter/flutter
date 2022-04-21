// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <memory>
#include <optional>
#include <variant>
#include <vector>

#include "impeller/entity/contents/contents.h"
#include "impeller/geometry/rect.h"
#include "impeller/renderer/formats.h"

namespace impeller {

class ContentContext;
class Entity;
class FilterContents;

/*******************************************************************************
 ******* FilterInput
 ******************************************************************************/

/// `FilterInput` is a lazy/single eval `Snapshot` which may be shared across
/// filter parameters and used to evaluate input coverage.
///
/// A `FilterInput` can be re-used for any filter inputs across an entity's
/// filter graph without repeating subpasses unnecessarily.
///
/// Filters may decide to not evaluate inputs in situations where they won't
/// contribute to the filter's output texture.
class FilterInput {
 public:
  using Ref = std::shared_ptr<FilterInput>;
  using Vector = std::vector<FilterInput::Ref>;
  using Variant = std::variant<std::shared_ptr<FilterContents>,
                               std::shared_ptr<Contents>,
                               std::shared_ptr<Texture>>;

  virtual ~FilterInput();

  static FilterInput::Ref Make(Variant input);

  static FilterInput::Vector Make(std::initializer_list<Variant> inputs);

  virtual Variant GetInput() const = 0;

  virtual std::optional<Snapshot> GetSnapshot(const ContentContext& renderer,
                                              const Entity& entity) const = 0;

  virtual std::optional<Rect> GetCoverage(const Entity& entity) const = 0;

  /// @brief  Get the local transform of this filter input. This transform is
  ///         relative to the `Entity` transform space.
  virtual Matrix GetLocalTransform(const Entity& entity) const;

  /// @brief  Get the transform of this `FilterInput`. This is equivalent to
  ///         calling `entity.GetTransformation() * GetLocalTransform()`.
  virtual Matrix GetTransform(const Entity& entity) const;
};

/*******************************************************************************
 ******* FilterContentsFilterInput
 ******************************************************************************/

class FilterContentsFilterInput final : public FilterInput {
 public:
  ~FilterContentsFilterInput() override;

  // |FilterInput|
  Variant GetInput() const override;

  // |FilterInput|
  std::optional<Snapshot> GetSnapshot(const ContentContext& renderer,
                                      const Entity& entity) const override;

  // |FilterInput|
  std::optional<Rect> GetCoverage(const Entity& entity) const override;

  // |FilterInput|
  Matrix GetLocalTransform(const Entity& entity) const override;

  // |FilterInput|
  Matrix GetTransform(const Entity& entity) const override;

 private:
  FilterContentsFilterInput(std::shared_ptr<FilterContents> filter);

  std::shared_ptr<FilterContents> filter_;
  mutable std::optional<Snapshot> snapshot_;

  friend FilterInput;
};

/*******************************************************************************
 ******* ContentsFilterInput
 ******************************************************************************/

class ContentsFilterInput final : public FilterInput {
 public:
  ~ContentsFilterInput() override;

  // |FilterInput|
  Variant GetInput() const override;

  // |FilterInput|
  std::optional<Snapshot> GetSnapshot(const ContentContext& renderer,
                                      const Entity& entity) const override;

  // |FilterInput|
  std::optional<Rect> GetCoverage(const Entity& entity) const override;

 private:
  ContentsFilterInput(std::shared_ptr<Contents> contents);

  std::shared_ptr<Contents> contents_;
  mutable std::optional<Snapshot> snapshot_;

  friend FilterInput;
};

/*******************************************************************************
 ******* TextureFilterInput
 ******************************************************************************/

class TextureFilterInput final : public FilterInput {
 public:
  ~TextureFilterInput() override;

  // |FilterInput|
  Variant GetInput() const override;

  // |FilterInput|
  std::optional<Snapshot> GetSnapshot(const ContentContext& renderer,
                                      const Entity& entity) const override;

  // |FilterInput|
  std::optional<Rect> GetCoverage(const Entity& entity) const override;

  // |FilterInput|
  Matrix GetLocalTransform(const Entity& entity) const override;

 private:
  TextureFilterInput(std::shared_ptr<Texture> texture);

  std::shared_ptr<Texture> texture_;

  friend FilterInput;
};

}  // namespace impeller
