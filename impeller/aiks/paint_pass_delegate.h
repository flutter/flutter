// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <optional>

#include "flutter/fml/macros.h"
#include "impeller/aiks/paint.h"
#include "impeller/entity/entity_pass_delegate.h"

namespace impeller {

class EntityPass;

class PaintPassDelegate final : public EntityPassDelegate {
 public:
  explicit PaintPassDelegate(Paint paint);

  // |EntityPassDelgate|
  ~PaintPassDelegate() override;

  // |EntityPassDelgate|
  bool CanElide() override;

  // |EntityPassDelgate|
  bool CanCollapseIntoParentPass(EntityPass* entity_pass) override;

  // |EntityPassDelgate|
  std::shared_ptr<Contents> CreateContentsForSubpassTarget(
      std::shared_ptr<Texture> target,
      const Matrix& effect_transform) override;

  // |EntityPassDelgate|
  std::shared_ptr<FilterContents> WithImageFilter(
      const FilterInput::Variant& input,
      const Matrix& effect_transform) const override;

 private:
  const Paint paint_;

  PaintPassDelegate(const PaintPassDelegate&) = delete;

  PaintPassDelegate& operator=(const PaintPassDelegate&) = delete;
};

/// A delegate that attempts to forward opacity from a save layer to
/// child contents.
///
/// Currently this has a hardcoded limit of 3 entities in a pass, and
/// cannot forward to child subpass delegates.
class OpacityPeepholePassDelegate final : public EntityPassDelegate {
 public:
  explicit OpacityPeepholePassDelegate(Paint paint);

  // |EntityPassDelgate|
  ~OpacityPeepholePassDelegate() override;

  // |EntityPassDelgate|
  bool CanElide() override;

  // |EntityPassDelgate|
  bool CanCollapseIntoParentPass(EntityPass* entity_pass) override;

  // |EntityPassDelgate|
  std::shared_ptr<Contents> CreateContentsForSubpassTarget(
      std::shared_ptr<Texture> target,
      const Matrix& effect_transform) override;

  // |EntityPassDelgate|
  std::shared_ptr<FilterContents> WithImageFilter(
      const FilterInput::Variant& input,
      const Matrix& effect_transform) const override;

 private:
  const Paint paint_;

  OpacityPeepholePassDelegate(const OpacityPeepholePassDelegate&) = delete;

  OpacityPeepholePassDelegate& operator=(const OpacityPeepholePassDelegate&) =
      delete;
};

}  // namespace impeller
