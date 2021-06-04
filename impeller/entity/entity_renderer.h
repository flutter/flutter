// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "flutter/fml/macros.h"
#include "impeller/compositor/renderer.h"
#include "impeller/entity/entity.h"

namespace impeller {

class EntityRenderer final : public Renderer {
 public:
  EntityRenderer(std::string shaders_directory);

  ~EntityRenderer() override;

 private:
  std::shared_ptr<Entity> root_;

  bool OnRender() override;

  bool OnSurfaceSizeDidChange(Size size) override;

  FML_DISALLOW_COPY_AND_ASSIGN(EntityRenderer);
};

}  // namespace impeller
