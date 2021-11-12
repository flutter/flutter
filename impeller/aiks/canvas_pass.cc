// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/aiks/canvas_pass.h"

namespace impeller {

CanvasPass::CanvasPass() = default;

CanvasPass::~CanvasPass() = default;

void CanvasPass::PushEntity(Entity entity) {
  ops_.emplace_back(std::move(entity));
}

const std::vector<Entity>& CanvasPass::GetPassEntities() const {
  return ops_;
}

}  // namespace impeller
