// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <memory>

#include "flutter/fml/macros.h"
#include "impeller/core/texture.h"
#include "impeller/entity/contents/contents.h"

namespace impeller {

class EntityPass;

class EntityPassDelegate {
 public:
  static std::unique_ptr<EntityPassDelegate> MakeDefault();

  EntityPassDelegate();

  virtual ~EntityPassDelegate();

  virtual bool CanElide() = 0;

  /// @brief  Whether or not this entity pass can be collapsed into the parent.
  ///         If true, this method may modify the entities for the current pass.
  virtual bool CanCollapseIntoParentPass(EntityPass* entity_pass) = 0;

  virtual std::shared_ptr<Contents> CreateContentsForSubpassTarget(
      std::shared_ptr<Texture> target,
      const Matrix& effect_transform) = 0;

 private:
  FML_DISALLOW_COPY_AND_ASSIGN(EntityPassDelegate);
};

}  // namespace impeller
