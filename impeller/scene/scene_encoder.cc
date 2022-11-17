// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/fml/macros.h"

#include "fml/logging.h"
#include "impeller/renderer/render_target.h"
#include "impeller/scene/scene_encoder.h"

namespace impeller {
namespace scene {

SceneEncoder::SceneEncoder() = default;

std::shared_ptr<CommandBuffer> SceneEncoder::BuildSceneCommandBuffer(
    Context& context,
    const RenderTarget& render_target) const {
  auto command_buffer = context.CreateCommandBuffer();
  if (!command_buffer) {
    FML_LOG(ERROR) << "Failed to create command buffer.";
    return nullptr;
  }

  return command_buffer;
}

}  // namespace scene
}  // namespace impeller
