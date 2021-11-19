// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <memory>

#include "flutter/fml/macros.h"
#include "impeller/entity/contents.h"
#include "impeller/entity/entity.h"

namespace impeller {

class CanvasPass {
 public:
  CanvasPass();

  ~CanvasPass();

  void PushEntity(Entity entity);

  const std::vector<Entity>& GetPassEntities() const;

  void SetPostProcessingEntity(Entity entity);

  const Entity& GetPostProcessingEntity() const;

 private:
  std::vector<Entity> ops_;
  Entity post_processing_entity_;
};

}  // namespace impeller
