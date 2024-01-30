// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/scene/scene.h"

#include <memory>
#include <utility>

#include "flutter/fml/logging.h"
#include "fml/closure.h"
#include "impeller/renderer/render_target.h"
#include "impeller/scene/scene_context.h"
#include "impeller/scene/scene_encoder.h"

namespace impeller {
namespace scene {

Scene::Scene(std::shared_ptr<SceneContext> scene_context)
    : scene_context_(std::move(scene_context)) {
  root_.is_root_ = true;
};

Scene::~Scene() {
  for (auto& child : GetRoot().GetChildren()) {
    child->parent_ = nullptr;
  }
}

Node& Scene::GetRoot() {
  return root_;
}

bool Scene::Render(const RenderTarget& render_target,
                   const Matrix& camera_transform) {
  fml::ScopedCleanupClosure reset_state(
      [context = scene_context_]() { context->GetTransientsBuffer().Reset(); });

  // Collect the render commands from the scene.
  SceneEncoder encoder;
  if (!root_.Render(encoder,
                    *scene_context_->GetContext()->GetResourceAllocator(),
                    Matrix())) {
    FML_LOG(ERROR) << "Failed to render frame.";
    return false;
  }

  // Encode the commands.

  std::shared_ptr<CommandBuffer> command_buffer =
      encoder.BuildSceneCommandBuffer(*scene_context_, camera_transform,
                                      render_target);

  // TODO(bdero): Do post processing.

  if (!scene_context_->GetContext()
           ->GetCommandQueue()
           ->Submit({command_buffer})
           .ok()) {
    FML_LOG(ERROR) << "Failed to submit command buffer.";
    return false;
  }

  return true;
}

bool Scene::Render(const RenderTarget& render_target, const Camera& camera) {
  return Render(render_target,
                camera.GetTransform(render_target.GetRenderTargetSize()));
}

}  // namespace scene
}  // namespace impeller
