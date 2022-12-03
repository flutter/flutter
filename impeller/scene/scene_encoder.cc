// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/fml/macros.h"

#include "flutter/fml/logging.h"
#include "impeller/renderer/command.h"
#include "impeller/renderer/render_target.h"
#include "impeller/scene/scene_context.h"
#include "impeller/scene/scene_encoder.h"
#include "impeller/scene/shaders/geometry.vert.h"

namespace impeller {
namespace scene {

SceneEncoder::SceneEncoder() = default;

void SceneEncoder::Add(const SceneCommand& command) {
  // TODO(bdero): Manage multi-pass translucency ordering.
  commands_.push_back(command);
}

static void EncodeCommand(const SceneContext& scene_context,
                          const Matrix& view_transform,
                          RenderPass& render_pass,
                          const SceneCommand& scene_command) {
  auto& host_buffer = render_pass.GetTransientsBuffer();

  Command cmd;
  cmd.label = scene_command.label;
  cmd.stencil_reference =
      0;  // TODO(bdero): Configurable stencil ref per-command.

  cmd.BindVertices(scene_command.geometry->GetVertexBuffer(
      *scene_context.GetContext()->GetResourceAllocator()));

  cmd.pipeline =
      scene_command.material->GetPipeline(scene_context, render_pass);
  scene_command.material->BindToCommand(scene_context, host_buffer, cmd);

  GeometryVertexShader::VertInfo info;
  info.mvp = view_transform * scene_command.transform;
  GeometryVertexShader::BindVertInfo(cmd, host_buffer.EmplaceUniform(info));

  render_pass.AddCommand(std::move(cmd));
}

std::shared_ptr<CommandBuffer> SceneEncoder::BuildSceneCommandBuffer(
    const SceneContext& scene_context,
    const Camera& camera,
    const RenderTarget& render_target) const {
  auto command_buffer = scene_context.GetContext()->CreateCommandBuffer();
  if (!command_buffer) {
    FML_LOG(ERROR) << "Failed to create command buffer.";
    return nullptr;
  }

  auto render_pass = command_buffer->CreateRenderPass(render_target);
  if (!render_pass) {
    FML_LOG(ERROR) << "Failed to create render pass.";
    return nullptr;
  }

  for (auto& command : commands_) {
    Matrix view_transform =
        camera.GetTransform(render_pass->GetRenderTargetSize());
    EncodeCommand(scene_context, view_transform, *render_pass, command);
  }

  if (!render_pass->EncodeCommands()) {
    FML_LOG(ERROR) << "Failed to encode render pass commands.";
    return nullptr;
  }

  return command_buffer;
}

}  // namespace scene
}  // namespace impeller
