// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/fml/macros.h"

#include "flutter/fml/logging.h"
#include "impeller/renderer/command.h"
#include "impeller/renderer/render_target.h"
#include "impeller/scene/scene_context.h"
#include "impeller/scene/scene_encoder.h"

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
  auto& host_buffer = scene_context.GetTransientsBuffer();

  render_pass.SetCommandLabel(scene_command.label);
  // TODO(bdero): Configurable stencil ref per-command.
  render_pass.SetStencilReference(0);

  render_pass.SetPipeline(scene_context.GetPipeline(
      PipelineKey{scene_command.geometry->GetGeometryType(),
                  scene_command.material->GetMaterialType()},
      scene_command.material->GetContextOptions(render_pass)));

  scene_command.geometry->BindToCommand(
      scene_context, host_buffer, view_transform * scene_command.transform,
      render_pass);
  scene_command.material->BindToCommand(scene_context, host_buffer,
                                        render_pass);

  render_pass.Draw();
  ;
}

std::shared_ptr<CommandBuffer> SceneEncoder::BuildSceneCommandBuffer(
    const SceneContext& scene_context,
    const Matrix& camera_transform,
    RenderTarget render_target) const {
  {
    TextureDescriptor ds_texture;
    ds_texture.type = TextureType::kTexture2DMultisample;
    ds_texture.format = PixelFormat::kD32FloatS8UInt;
    ds_texture.size = render_target.GetRenderTargetSize();
    ds_texture.usage = TextureUsage::kRenderTarget;
    ds_texture.sample_count = SampleCount::kCount4;
    ds_texture.storage_mode = StorageMode::kDeviceTransient;
    auto texture =
        scene_context.GetContext()->GetResourceAllocator()->CreateTexture(
            ds_texture);

    DepthAttachment depth;
    depth.load_action = LoadAction::kClear;
    depth.store_action = StoreAction::kDontCare;
    depth.clear_depth = 1.0;
    depth.texture = texture;
    render_target.SetDepthAttachment(depth);

    // The stencil and depth buffers must be the same texture for MacOS ARM
    // and Vulkan.
    StencilAttachment stencil;
    stencil.load_action = LoadAction::kClear;
    stencil.store_action = StoreAction::kDontCare;
    stencil.clear_stencil = 0u;
    stencil.texture = texture;
    render_target.SetStencilAttachment(stencil);
  }

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
    EncodeCommand(scene_context, camera_transform, *render_pass, command);
  }

  if (!render_pass->EncodeCommands()) {
    FML_LOG(ERROR) << "Failed to encode render pass commands.";
    return nullptr;
  }

  return command_buffer;
}

}  // namespace scene
}  // namespace impeller
