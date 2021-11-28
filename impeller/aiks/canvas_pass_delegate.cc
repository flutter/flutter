// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/aiks/canvas_pass_delegate.h"

namespace impeller {

CanvasPassDelegate::CanvasPassDelegate() = default;

CanvasPassDelegate::~CanvasPassDelegate() = default;

class DefaultCanvasPassDelegate final : public CanvasPassDelegate {
 public:
  DefaultCanvasPassDelegate() = default;

  ~DefaultCanvasPassDelegate() override = default;

  bool CanCollapseIntoParentPass() override { return true; }

  std::shared_ptr<Contents> CreateContentsForSubpassTarget(
      const Texture& target) override {
    // Not possible since this pass always collapses into its parent.
    FML_UNREACHABLE();
  }

 private:
  FML_DISALLOW_COPY_AND_ASSIGN(DefaultCanvasPassDelegate);
};

std::unique_ptr<CanvasPassDelegate> CanvasPassDelegate::MakeDefault() {
  return std::make_unique<DefaultCanvasPassDelegate>();
}

}  // namespace impeller
