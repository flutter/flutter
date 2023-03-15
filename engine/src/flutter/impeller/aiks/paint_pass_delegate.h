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
  PaintPassDelegate(Paint paint, std::optional<Rect> coverage);

  // |EntityPassDelgate|
  ~PaintPassDelegate() override;

  // |EntityPassDelegate|
  std::optional<Rect> GetCoverageRect() override;

  // |EntityPassDelgate|
  bool CanElide() override;

  // |EntityPassDelgate|
  bool CanCollapseIntoParentPass(EntityPass* entity_pass) override;

  // |EntityPassDelgate|
  std::shared_ptr<Contents> CreateContentsForSubpassTarget(
      std::shared_ptr<Texture> target,
      const Matrix& effect_transform) override;

 private:
  const Paint paint_;
  const std::optional<Rect> coverage_;

  FML_DISALLOW_COPY_AND_ASSIGN(PaintPassDelegate);
};

/// A delegate that attempts to forward opacity from a save layer to
/// child contents.
///
/// Currently this has a hardcoded limit of 3 entities in a pass, and
/// cannot forward to child subpass delegates.
class OpacityPeepholePassDelegate final : public EntityPassDelegate {
 public:
  OpacityPeepholePassDelegate(Paint paint, std::optional<Rect> coverage);

  // |EntityPassDelgate|
  ~OpacityPeepholePassDelegate() override;

  // |EntityPassDelegate|
  std::optional<Rect> GetCoverageRect() override;

  // |EntityPassDelgate|
  bool CanElide() override;

  // |EntityPassDelgate|
  bool CanCollapseIntoParentPass(EntityPass* entity_pass) override;

  // |EntityPassDelgate|
  std::shared_ptr<Contents> CreateContentsForSubpassTarget(
      std::shared_ptr<Texture> target,
      const Matrix& effect_transform) override;

 private:
  const Paint paint_;
  const std::optional<Rect> coverage_;

  FML_DISALLOW_COPY_AND_ASSIGN(OpacityPeepholePassDelegate);
};

}  // namespace impeller
