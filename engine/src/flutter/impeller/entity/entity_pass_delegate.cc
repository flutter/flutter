// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/entity_pass_delegate.h"
#include "impeller/entity/entity_pass.h"

namespace impeller {

EntityPassDelegate::EntityPassDelegate() = default;

EntityPassDelegate::~EntityPassDelegate() = default;

class DefaultEntityPassDelegate final : public EntityPassDelegate {
 public:
  DefaultEntityPassDelegate() = default;

  // |EntityPassDelegate|
  ~DefaultEntityPassDelegate() override = default;

  // |EntityPassDelegate|
  bool CanElide() override { return false; }

  // |EntityPassDelegate|
  bool CanCollapseIntoParentPass(EntityPass* entity_pass) override {
    return true;
  }

  // |EntityPassDelegate|
  std::shared_ptr<Contents> CreateContentsForSubpassTarget(
      std::shared_ptr<Texture> target,
      const Matrix& effect_transform) override {
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
