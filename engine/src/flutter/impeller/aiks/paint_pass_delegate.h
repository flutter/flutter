// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "flutter/fml/macros.h"
#include "impeller/aiks/paint.h"
#include "impeller/entity/entity_pass_delegate.h"

namespace impeller {

class PaintPassDelegate final : public EntityPassDelegate {
 public:
  PaintPassDelegate(Paint paint);

  // |EntityPassDelgate|
  ~PaintPassDelegate() override;

  // |EntityPassDelgate|
  bool CanElide() override;

  // |EntityPassDelgate|
  bool CanCollapseIntoParentPass() override;

  // |EntityPassDelgate|
  std::shared_ptr<Contents> CreateContentsForSubpassTarget(
      std::shared_ptr<Texture> target) override;

 private:
  const Paint paint_;

  FML_DISALLOW_COPY_AND_ASSIGN(PaintPassDelegate);
};

}  // namespace impeller
