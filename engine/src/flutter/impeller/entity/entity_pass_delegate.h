// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <memory>

#include "flutter/fml/macros.h"
#include "impeller/entity/contents/contents.h"
#include "impeller/renderer/texture.h"

namespace impeller {

class EntityPassDelegate {
 public:
  static std::unique_ptr<EntityPassDelegate> MakeDefault();

  EntityPassDelegate();

  virtual std::optional<Rect> GetCoverageRect() = 0;

  virtual ~EntityPassDelegate();

  virtual bool CanElide() = 0;

  virtual bool CanCollapseIntoParentPass() = 0;

  virtual std::shared_ptr<Contents> CreateContentsForSubpassTarget(
      std::shared_ptr<Texture> target) = 0;

 private:
  FML_DISALLOW_COPY_AND_ASSIGN(EntityPassDelegate);
};

}  // namespace impeller
