// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_ENTITY_CONTENTS_FILTERS_INPUTS_FILTER_INPUT_H_
#define FLUTTER_IMPELLER_ENTITY_CONTENTS_FILTERS_INPUTS_FILTER_INPUT_H_

#include <memory>
#include <optional>
#include <variant>
#include <vector>

#include "impeller/entity/contents/contents.h"
#include "impeller/entity/entity.h"
#include "impeller/geometry/rect.h"

namespace impeller {

class ContentContext;
class FilterContents;

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
                               std::shared_ptr<Texture>,
                               Rect>;

  virtual ~FilterInput();

  static FilterInput::Ref Make(Variant input, bool msaa_enabled = true);

  static FilterInput::Ref Make(std::shared_ptr<Texture> input,
                               Matrix local_transform);

  static FilterInput::Vector Make(std::initializer_list<Variant> inputs);

  /// Evaluates the filter input and returns a snapshot of the result.
  ///
  /// This method renders the input (which could be another filter, contents,
  /// or a texture) into a `Snapshot` object, which contains the resulting
  /// texture and its transform relative to the current render target.
  ///
  /// Implementations are typically lazy and may cache the result, ensuring
  /// that the input is only rendered once even if `GetSnapshot` is called
  /// multiple times.
  ///
  /// @param[in] label A debug label for the rendering operation and the
  /// resulting snapshot texture.
  /// @param[in] renderer The content context providing rendering resources.
  /// @param[in] entity The entity associated with this filter input, providing
  /// transform and other contextual information.
  /// @param[in] coverage_limit An optional rectangle to limit the area of the
  /// input that needs to be rendered. This can be used as an optimization.
  /// @param[in] mip_count The number of mip levels to generate for the snapshot
  /// texture. Defaults to 1 (no mips).
  ///
  /// @return A `Snapshot` containing the rendered texture and its transform, or
  /// `std::nullopt` if the input cannot be rendered or results in an empty
  /// output.
  virtual std::optional<Snapshot> GetSnapshot(
      std::string_view label,
      const ContentContext& renderer,
      const Entity& entity,
      std::optional<Rect> coverage_limit = std::nullopt,
      int32_t mip_count = 1) const = 0;

  std::optional<Rect> GetLocalCoverage(const Entity& entity) const;

  virtual std::optional<Rect> GetCoverage(const Entity& entity) const = 0;

  virtual std::optional<Rect> GetSourceCoverage(const Matrix& effect_transform,
                                                const Rect& output_limit) const;

  /// @brief  Get the local transform of this filter input. This transform is
  ///         relative to the `Entity` transform space.
  virtual Matrix GetLocalTransform(const Entity& entity) const;

  /// @brief  Get the transform of this `FilterInput`. This is equivalent to
  ///         calling `entity.GetTransform() * GetLocalTransform()`.
  virtual Matrix GetTransform(const Entity& entity) const;

  /// @brief  Sets the effect transform of filter inputs.
  virtual void SetEffectTransform(const Matrix& matrix);

  /// @brief  Turns on subpass mode for filter inputs.
  virtual void SetRenderingMode(Entity::RenderingMode rendering_mode);
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_ENTITY_CONTENTS_FILTERS_INPUTS_FILTER_INPUT_H_
