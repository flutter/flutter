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

/// `FilterInput` is a lazy/single eval `Snapshot` which may be shared across
/// filter parameters and used to evaluate input bounds.
///
/// A `FilterInput` can be created from either a `Texture` or any `Contents`
/// class (including `FilterContents`), and can be re-used for any filter inputs
/// across an entity's filter graph without repeating subpasses unnecessarily.
///
/// Filters may decide to not evaluate inputs in situations where they won't
/// contribute to the filter's output texture.
class FilterInput final {
 public:
  using Ref = std::shared_ptr<FilterInput>;
  using Vector = std::vector<FilterInput::Ref>;
  using Variant =
      std::variant<std::shared_ptr<Texture>, std::shared_ptr<Contents>>;

  ~FilterInput();

  static FilterInput::Ref Make(Variant input);

  static FilterInput::Vector Make(std::initializer_list<Variant> inputs);

  Variant GetInput() const;

  std::optional<Rect> GetCoverage(const Entity& entity) const;

  std::optional<Snapshot> GetSnapshot(const ContentContext& renderer,
                                      const Entity& entity) const;

 private:
  FilterInput(Variant input);

  std::optional<Snapshot> RenderToTexture(const ContentContext& renderer,
                                          const Entity& entity) const;

  Variant input_;
  mutable std::optional<Snapshot> snapshot_;
};

}  // namespace impeller
