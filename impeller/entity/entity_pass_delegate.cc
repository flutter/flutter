// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/entity_pass_delegate.h"

namespace impeller {

EntityPassDelegate::EntityPassDelegate() = default;

EntityPassDelegate::~EntityPassDelegate() = default;

class DefaultEntityPassDelegate final : public EntityPassDelegate {
 public:
  DefaultEntityPassDelegate() = default;

  ~DefaultEntityPassDelegate() override = default;

  bool CanElide() override { return false; }

  bool CanCollapseIntoParentPass() override { return true; }

  std::shared_ptr<Contents> CreateContentsForSubpassTarget(
      std::shared_ptr<Texture> target) override {
    // Not possible since this pass always collapses into its parent.
    FML_UNREACHABLE();
  }

 private:
  FML_DISALLOW_COPY_AND_ASSIGN(DefaultEntityPassDelegate);
};

std::unique_ptr<EntityPassDelegate> EntityPassDelegate::MakeDefault() {
  return std::make_unique<DefaultEntityPassDelegate>();
}

}  // namespace impeller
