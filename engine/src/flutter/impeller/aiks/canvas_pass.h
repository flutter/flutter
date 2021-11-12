// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <vector>

#include "flutter/fml/macros.h"
#include "impeller/entity/entity.h"

namespace impeller {

class CanvasPass {
 public:
  CanvasPass();

  ~CanvasPass();

  void PushEntity(Entity entity);

  const std::vector<Entity>& GetPassEntities() const;

 private:
  std::vector<Entity> ops_;
};

}  // namespace impeller
