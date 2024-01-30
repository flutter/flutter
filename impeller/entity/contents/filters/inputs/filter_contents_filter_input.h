// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_ENTITY_CONTENTS_FILTERS_INPUTS_FILTER_CONTENTS_FILTER_INPUT_H_
#define FLUTTER_IMPELLER_ENTITY_CONTENTS_FILTERS_INPUTS_FILTER_CONTENTS_FILTER_INPUT_H_

#include "impeller/entity/contents/filters/inputs/filter_input.h"

namespace impeller {

class FilterContentsFilterInput final : public FilterInput {
 public:
  ~FilterContentsFilterInput() override;

  // |FilterInput|
  Variant GetInput() const override;

  // |FilterInput|
  std::optional<Snapshot> GetSnapshot(const std::string& label,
                                      const ContentContext& renderer,
                                      const Entity& entity,
                                      std::optional<Rect> coverage_limit,
                                      int32_t mip_count) const override;

  // |FilterInput|
  std::optional<Rect> GetCoverage(const Entity& entity) const override;

  // |FilterInput|
  std::optional<Rect> GetSourceCoverage(
      const Matrix& effect_transform,
      const Rect& output_limit) const override;

  // |FilterInput|
  Matrix GetLocalTransform(const Entity& entity) const override;

  // |FilterInput|
  Matrix GetTransform(const Entity& entity) const override;

  // |FilterInput|
  void PopulateGlyphAtlas(
      const std::shared_ptr<LazyGlyphAtlas>& lazy_glyph_atlas,
      Scalar scale) override;

  // |FilterInput|
  bool IsTranslationOnly() const override;

  // |FilterInput|
  bool IsLeaf() const override;

  // |FilterInput|
  void SetLeafInputs(const FilterInput::Vector& inputs) override;

  // |FilterInput|
  virtual void SetEffectTransform(const Matrix& matrix) override;

  // |FilterInput|
  virtual void SetRenderingMode(Entity::RenderingMode rendering_mode) override;

 private:
  explicit FilterContentsFilterInput(std::shared_ptr<FilterContents> filter);

  std::shared_ptr<FilterContents> filter_;
  mutable std::optional<Snapshot> snapshot_;

  friend FilterInput;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_ENTITY_CONTENTS_FILTERS_INPUTS_FILTER_CONTENTS_FILTER_INPUT_H_
