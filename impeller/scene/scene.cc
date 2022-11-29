// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/scene/scene.h"

#include <memory>
#include <utility>

#include "flutter/fml/logging.h"
#include "impeller/renderer/render_target.h"
#include "impeller/scene/scene_context.h"
#include "impeller/scene/scene_encoder.h"

namespace impeller {
namespace scene {

Scene::Scene(std::shared_ptr<Context> context)
    : scene_context_(std::make_unique<SceneContext>(std::move(context))){};

void Scene::Add(const std::shared_ptr<SceneEntity>& child) {
  root_.Add(child);
}

bool Scene::Render(const RenderTarget& render_target,
                   const Camera& camera) const {
  // Collect the render commands from the scene.
  SceneEncoder encoder;
  if (!root_.Render(encoder, camera)) {
    FML_LOG(ERROR) << "Failed to render frame.";
    return false;
  }

  // Encode the commands.
  std::shared_ptr<CommandBuffer> command_buffer =
      encoder.BuildSceneCommandBuffer(*scene_context_->GetContext(),
                                      render_target);

  // TODO(bdero): Do post processing.

  if (!command_buffer->SubmitCommands()) {
    FML_LOG(ERROR) << "Failed to submit command buffer.";
    return false;
  }

  return true;
}

}  // namespace scene
}  // namespace impeller
