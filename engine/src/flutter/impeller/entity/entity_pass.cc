// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/entity_pass.h"

#include "impeller/entity/content_renderer.h"
#include "impeller/geometry/path_builder.h"
#include "impeller/renderer/command_buffer.h"
#include "impeller/renderer/render_pass.h"

namespace impeller {

EntityPass::EntityPass() = default;

EntityPass::~EntityPass() = default;

void EntityPass::SetDelegate(std::unique_ptr<EntityPassDelegate> delegate) {
  if (!delegate) {
    return;
  }
  delegate_ = std::move(delegate);
}

void EntityPass::AddEntity(Entity entity) {
  entities_.emplace_back(std::move(entity));
}

const std::vector<Entity>& EntityPass::GetEntities() const {
  return entities_;
}

void EntityPass::SetEntities(Entities entities) {
  entities_ = std::move(entities);
}

size_t EntityPass::GetSubpassesDepth() const {
  size_t max_subpass_depth = 0u;
  for (const auto& subpass : subpasses_) {
    max_subpass_depth =
        std::max(max_subpass_depth, subpass->GetSubpassesDepth());
  }
  return max_subpass_depth + 1u;
}

std::optional<Rect> EntityPass::GetEntitiesCoverage() const {
  std::optional<Rect> result;
  for (const auto& entity : entities_) {
    auto coverage = entity.GetCoverage();
    if (!result.has_value() && coverage.has_value()) {
      result = coverage;
      continue;
    }
    if (!coverage.has_value()) {
      continue;
    }
    result = result->Union(coverage.value());
  }
  return result;
}

std::optional<Rect> EntityPass::GetSubpassCoverage(
    const EntityPass& subpass) const {
  auto entities_coverage = subpass.GetEntitiesCoverage();
  // The entities don't cover anything. There is nothing to do.
  if (!entities_coverage.has_value()) {
    return std::nullopt;
  }

  // The delegates don't have an opinion on what the entity coverage has to be.
  // Just use that as-is.
  auto delegate_coverage = delegate_->GetCoverageRect();
  if (!delegate_coverage.has_value()) {
    return entities_coverage;
  }

  // If the delete tells us the coverage is smaller than it needs to be, then
  // great. OTOH, if the delegate is being wasteful, limit coverage to what is
  // actually needed.
  return entities_coverage->Intersection(delegate_coverage.value());
}

EntityPass* EntityPass::GetSuperpass() const {
  return superpass_;
}

const EntityPass::Subpasses& EntityPass::GetSubpasses() const {
  return subpasses_;
}

EntityPass* EntityPass::AddSubpass(std::unique_ptr<EntityPass> pass) {
  if (!pass) {
    return nullptr;
  }
  FML_DCHECK(pass->superpass_ == nullptr);
  pass->superpass_ = this;
  return subpasses_.emplace_back(std::move(pass)).get();
}

bool EntityPass::Render(ContentRenderer& renderer,
                        RenderPass& parent_pass) const {
  for (const auto& entity : entities_) {
    if (!entity.Render(renderer, parent_pass)) {
      return false;
    }
  }
  for (const auto& subpass : subpasses_) {
    if (delegate_->CanElide()) {
      continue;
    }

    if (delegate_->CanCollapseIntoParentPass()) {
      // Directly render into the parent pass and move on.
      if (!subpass->Render(renderer, parent_pass)) {
        return false;
      }
      continue;
    }

    const auto subpass_coverage = GetSubpassCoverage(*subpass);

    if (!subpass_coverage.has_value()) {
      continue;
    }

    if (subpass_coverage->size.IsEmpty()) {
      // It is not an error to have an empty subpass. But subpasses that can't
      // create their intermediates must trip errors.
      continue;
    }

    auto context = renderer.GetContext();

    auto subpass_target = RenderTarget::CreateOffscreen(
        *context, ISize::Ceil(subpass_coverage->size));

    auto subpass_texture = subpass_target.GetRenderTargetTexture();

    if (!subpass_texture) {
      return false;
    }

    auto offscreen_texture_contents =
        delegate_->CreateContentsForSubpassTarget(subpass_texture);

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
    entity.SetPath(PathBuilder{}.AddRect(subpass_coverage.value()).TakePath());
    entity.SetContents(std::move(offscreen_texture_contents));
    entity.SetStencilDepth(stencil_depth_);
    entity.SetTransformation(xformation_);
    if (!entity.Render(renderer, parent_pass)) {
      return false;
    }
  }

  return true;
}

void EntityPass::IterateAllEntities(std::function<bool(Entity&)> iterator) {
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

std::unique_ptr<EntityPass> EntityPass::Clone() const {
  auto pass = std::make_unique<EntityPass>();
  pass->SetEntities(entities_);
  for (const auto& subpass : subpasses_) {
    pass->AddSubpass(subpass->Clone());
  }
  return pass;
}

void EntityPass::SetTransformation(Matrix xformation) {
  xformation_ = std::move(xformation);
}

void EntityPass::SetStencilDepth(size_t stencil_depth) {
  stencil_depth_ = stencil_depth;
}

}  // namespace impeller
