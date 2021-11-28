// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/aiks/canvas_pass.h"

#include "impeller/entity/content_renderer.h"
#include "impeller/geometry/path_builder.h"
#include "impeller/renderer/command_buffer.h"
#include "impeller/renderer/render_pass.h"

namespace impeller {

CanvasPass::CanvasPass(std::unique_ptr<CanvasPassDelegate> delegate)
    : delegate_(std::move(delegate)) {
  if (!delegate_) {
    delegate_ = CanvasPassDelegate::MakeDefault();
  }
}

CanvasPass::~CanvasPass() = default;

void CanvasPass::AddEntity(Entity entity) {
  entities_.emplace_back(std::move(entity));
}

const std::vector<Entity>& CanvasPass::GetEntities() const {
  return entities_;
}

void CanvasPass::SetEntities(Entities entities) {
  entities_ = std::move(entities);
}

size_t CanvasPass::GetSubpassesDepth() const {
  size_t max_subpass_depth = 0u;
  for (const auto& subpass : subpasses_) {
    max_subpass_depth =
        std::max(max_subpass_depth, subpass->GetSubpassesDepth());
  }
  return max_subpass_depth + 1u;
}

Rect CanvasPass::GetCoverageRect() const {
  std::optional<Point> min, max;
  for (const auto& entity : entities_) {
    auto coverage = entity.GetPath().GetMinMaxCoveragePoints();
    if (!coverage.has_value()) {
      continue;
    }
    if (!min.has_value()) {
      min = coverage->first;
    }
    if (!max.has_value()) {
      max = coverage->second;
    }
    min = min->Min(coverage->first);
    max = max->Max(coverage->second);
  }
  if (!min.has_value() || !max.has_value()) {
    return {};
  }
  const auto diff = *max - *min;
  return {min->x, min->y, diff.x, diff.y};
}

CanvasPass* CanvasPass::GetSuperpass() const {
  return superpass_;
}

const CanvasPass::Subpasses& CanvasPass::GetSubpasses() const {
  return subpasses_;
}

CanvasPass* CanvasPass::AddSubpass(std::unique_ptr<CanvasPass> pass) {
  if (!pass) {
    return nullptr;
  }
  FML_DCHECK(pass->superpass_ == nullptr);
  pass->superpass_ = this;
  return subpasses_.emplace_back(std::move(pass)).get();
}

bool CanvasPass::Render(ContentRenderer& renderer,
                        RenderPass& parent_pass) const {
  for (const auto& entity : entities_) {
    if (!entity.Render(renderer, parent_pass)) {
      return false;
    }
  }
  for (const auto& subpass : subpasses_) {
    if (delegate_->CanCollapseIntoParentPass()) {
      // Directly render into the parent pass and move on.
      if (!subpass->Render(renderer, parent_pass)) {
        return false;
      }
      continue;
    }

    const auto subpass_coverage = subpass->GetCoverageRect();

    if (subpass_coverage.IsEmpty()) {
      // It is not an error to have an empty subpass. But subpasses that can't
      // create their intermediates must trip errors.
      continue;
    }

    auto context = renderer.GetContext();

    auto subpass_target = RenderTarget::CreateOffscreen(
        *context, ISize::Ceil(subpass_coverage.size));

    auto subpass_texture = subpass_target.GetRenderTargetTexture();

    if (!subpass_texture) {
      return false;
    }

    auto offscreen_texture_contents =
        delegate_->CreateContentsForSubpassTarget(*subpass_texture);

    if (!offscreen_texture_contents) {
      // This is an error because the subpass delegate said the pass couldn't be
      // collapsed into its parent. Yet, when asked how it want's to postprocess
      // the offscreen texture, it couldn't give us an answer.
      //
      // Theoretically, we could collapse the pass now. But that would be
      // wasteful as we already have the offscreen texture and we don't want to
      // discard it without ever using it. Just make the delegate do the right
      // thing.
      return false;
    }

    auto sub_command_buffer = context->CreateRenderCommandBuffer();

    sub_command_buffer->SetLabel("Offscreen Command Buffer");

    if (!sub_command_buffer) {
      return false;
    }

    auto sub_renderpass = sub_command_buffer->CreateRenderPass(subpass_target);

    if (!sub_renderpass) {
      return false;
    }

    sub_renderpass->SetLabel("OffscreenPass");

    if (!subpass->Render(renderer, *sub_renderpass)) {
      return false;
    }

    if (!sub_renderpass->EncodeCommands(*context->GetTransientsAllocator())) {
      return false;
    }

    if (!sub_command_buffer->SubmitCommands()) {
      return false;
    }

    Entity entity;
    entity.SetPath(PathBuilder{}.AddRect(subpass_coverage).CreatePath());
    entity.SetContents(std::move(offscreen_texture_contents));
    entity.SetStencilDepth(stencil_depth_);
    entity.SetTransformation(xformation_);
    if (!entity.Render(renderer, parent_pass)) {
      return false;
    }
  }

  return true;
}

void CanvasPass::IterateAllEntities(std::function<bool(Entity&)> iterator) {
  if (!iterator) {
    return;
  }

  for (auto& entity : entities_) {
    if (!iterator(entity)) {
      return;
    }
  }

  for (auto& subpass : subpasses_) {
    subpass->IterateAllEntities(iterator);
  }
}

std::unique_ptr<CanvasPass> CanvasPass::Clone() const {
  auto pass = std::make_unique<CanvasPass>();
  pass->SetEntities(entities_);
  for (const auto& subpass : subpasses_) {
    pass->AddSubpass(subpass->Clone());
  }
  return pass;
}

void CanvasPass::SetTransformation(Matrix xformation) {
  xformation_ = std::move(xformation);
}

void CanvasPass::SetStencilDepth(size_t stencil_depth) {
  stencil_depth_ = stencil_depth;
}

}  // namespace impeller
