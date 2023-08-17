// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/contents/scene_contents.h"

#include "impeller/core/formats.h"
#include "impeller/entity/contents/content_context.h"
#include "impeller/entity/contents/tiled_texture_contents.h"
#include "impeller/entity/entity.h"
#include "impeller/geometry/path_builder.h"
#include "impeller/scene/camera.h"
#include "impeller/scene/scene.h"

namespace impeller {

SceneContents::SceneContents() = default;

SceneContents::~SceneContents() = default;

void SceneContents::SetCameraTransform(Matrix matrix) {
  camera_transform_ = matrix;
}

void SceneContents::SetNode(std::shared_ptr<scene::Node> node) {
  node_ = std::move(node);
}

bool SceneContents::Render(const ContentContext& renderer,
                           const Entity& entity,
                           RenderPass& pass) const {
  if (!node_) {
    return true;
  }

  auto coverage = GetCoverage(entity);
  if (!coverage.has_value()) {
    return true;
  }

  // This happens for CoverGeometry (DrawPaint). In this situation,
  // Draw the scene to the full layer.
  if (coverage.value().IsMaximum()) {
    coverage = Rect::MakeSize(pass.GetRenderTargetSize());
  }

  RenderTarget subpass_target = RenderTarget::CreateOffscreenMSAA(
      *renderer.GetContext(),            // context
      *renderer.GetRenderTargetCache(),  // allocator
      ISize(coverage.value().size),      // size
      "SceneContents",                   // label
      RenderTarget::AttachmentConfigMSAA{
          .storage_mode = StorageMode::kDeviceTransient,
          .resolve_storage_mode = StorageMode::kDevicePrivate,
          .load_action = LoadAction::kClear,
          .store_action = StoreAction::kMultisampleResolve,
      },  // color_attachment_config
      RenderTarget::AttachmentConfig{
          .storage_mode = StorageMode::kDeviceTransient,
          .load_action = LoadAction::kDontCare,
          .store_action = StoreAction::kDontCare,
      }  // stencil_attachment_config
  );
  if (!subpass_target.IsValid()) {
    return false;
  }

  scene::Scene scene(renderer.GetSceneContext());
  scene.GetRoot().AddChild(node_);

  if (!scene.Render(subpass_target, camera_transform_)) {
    return false;
  }

  // Render the texture to the pass.
  TiledTextureContents contents;
  contents.SetGeometry(GetGeometry());
  contents.SetTexture(subpass_target.GetRenderTargetTexture());
  contents.SetEffectTransform(
      Matrix::MakeScale(1 / entity.GetTransformation().GetScale()));
  return contents.Render(renderer, entity, pass);
}

}  // namespace impeller
