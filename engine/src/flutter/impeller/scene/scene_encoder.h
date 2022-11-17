// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <memory>

#include "flutter/fml/macros.h"

#include "impeller/renderer/command_buffer.h"

namespace impeller {
namespace scene {

class Scene;

class SceneEncoder {
 private:
  SceneEncoder();

  std::shared_ptr<CommandBuffer> BuildSceneCommandBuffer(
      Context& context,
      const RenderTarget& render_target) const;

  friend Scene;

  FML_DISALLOW_COPY_AND_ASSIGN(SceneEncoder);
};

}  // namespace scene
}  // namespace impeller
