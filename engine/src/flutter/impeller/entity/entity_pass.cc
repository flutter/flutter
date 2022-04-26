// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/entity_pass.h"
#include <variant>

#include "flutter/fml/logging.h"
#include "flutter/fml/trace_event.h"
#include "impeller/base/validation.h"
#include "impeller/entity/contents/content_context.h"
#include "impeller/geometry/path_builder.h"
#include "impeller/renderer/command_buffer.h"
#include "impeller/renderer/render_pass.h"
#include "impeller/renderer/texture.h"

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
  elements_.emplace_back(std::move(entity));
}

void EntityPass::SetElements(std::vector<Element> elements) {
  elements_ = std::move(elements);
}

size_t EntityPass::GetSubpassesDepth() const {
  size_t max_subpass_depth = 0u;
  for (const auto& element : elements_) {
    if (auto subpass = std::get_if<std::unique_ptr<EntityPass>>(&element)) {
      max_subpass_depth =
          std::max(max_subpass_depth, subpass->get()->GetSubpassesDepth());
    }
  }
  return max_subpass_depth + 1u;
}

const std::shared_ptr<LazyGlyphAtlas>& EntityPass::GetLazyGlyphAtlas() const {
  return lazy_glyph_atlas_;
}

std::optional<Rect> EntityPass::GetElementsCoverage() const {
  std::optional<Rect> result;
  for (const auto& element : elements_) {
    std::optional<Rect> coverage;

    if (auto entity = std::get_if<Entity>(&element)) {
      coverage = entity->GetCoverage();
    } else if (auto subpass =
                   std::get_if<std::unique_ptr<EntityPass>>(&element)) {
      coverage = subpass->get()->GetElementsCoverage();
    } else {
      FML_UNREACHABLE();
    }

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
  auto entities_coverage = subpass.GetElementsCoverage();
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
  // The delegate coverage hint is in given in local space, so apply the subpass
  // transformation.
  delegate_coverage = delegate_coverage->TransformBounds(subpass.xformation_);

  // If the delegate tells us the coverage is smaller than it needs to be, then
  // great. OTOH, if the delegate is being wasteful, limit coverage to what is
  // actually needed.
  return entities_coverage->Intersection(delegate_coverage.value());
}

EntityPass* EntityPass::GetSuperpass() const {
  return superpass_;
}

EntityPass* EntityPass::AddSubpass(std::unique_ptr<EntityPass> pass) {
  if (!pass) {
    return nullptr;
  }
  FML_DCHECK(pass->superpass_ == nullptr);
  pass->superpass_ = this;
  auto subpass_pointer = pass.get();
  elements_.emplace_back(std::move(pass));
  return subpass_pointer;
}

bool EntityPass::Render(ContentContext& renderer,
                        RenderPass& parent_pass,
                        Point position) const {
  TRACE_EVENT0("impeller", "EntityPass::Render");

  for (const auto& element : elements_) {
    // =========================================================================
    // Entity rendering ========================================================
    // =========================================================================
    if (const auto& entity = std::get_if<Entity>(&element)) {
      Entity e = *entity;
      if (!position.IsZero()) {
        // If the pass image is going to be rendered with a non-zero position,
        // apply the negative translation to entity copies before rendering them
        // so that they'll end up rendering to the correct on-screen position.
        e.SetTransformation(Matrix::MakeTranslation(Vector3(-position)) *
                            e.GetTransformation());
      }
      if (!e.Render(renderer, parent_pass)) {
        return false;
      }
      continue;
    }

    // =========================================================================
    // Subpass rendering =======================================================
    // =========================================================================
    if (const auto& subpass_ptr =
            std::get_if<std::unique_ptr<EntityPass>>(&element)) {
      auto subpass = subpass_ptr->get();

      if (delegate_->CanElide()) {
        continue;
      }

      if (delegate_->CanCollapseIntoParentPass()) {
        // Directly render into the parent pass and move on.
        if (!subpass->Render(renderer, parent_pass, position)) {
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
        // This is an error because the subpass delegate said the pass couldn't
        // be collapsed into its parent. Yet, when asked how it want's to
        // postprocess the offscreen texture, it couldn't give us an answer.
        //
        // Theoretically, we could collapse the pass now. But that would be
        // wasteful as we already have the offscreen texture and we don't want
        // to discard it without ever using it. Just make the delegate do the
        // right thing.
        return false;
      }

      auto sub_command_buffer = context->CreateRenderCommandBuffer();

      if (!sub_command_buffer) {
        return false;
      }

      sub_command_buffer->SetLabel("Offscreen Command Buffer");

      auto sub_renderpass =
          sub_command_buffer->CreateRenderPass(subpass_target);

      if (!sub_renderpass) {
        return false;
      }

      sub_renderpass->SetLabel("OffscreenPass");

      if (!subpass->Render(renderer, *sub_renderpass,
                           subpass_coverage->origin)) {
        return false;
      }

      if (!sub_renderpass->EncodeCommands(*context->GetTransientsAllocator())) {
        return false;
      }

      if (!sub_command_buffer->SubmitCommands()) {
        return false;
      }

      Entity entity;
      entity.SetContents(std::move(offscreen_texture_contents));
      entity.SetStencilDepth(stencil_depth_);
      entity.SetBlendMode(subpass->blend_mode_);
      // Once we have filters being applied for SaveLayer, some special sauce
      // may be needed here (or in PaintPassDelegate) to ensure the filter
      // parameters are transformed by the `xformation_` matrix, while
      // continuing to apply only the subpass offset to the offscreen texture.
      entity.SetTransformation(Matrix::MakeTranslation(
          Vector3(subpass_coverage->origin - position)));
      if (!entity.Render(renderer, parent_pass)) {
        return false;
      }

      continue;
    }

    FML_UNREACHABLE();
  }

  return true;
}

void EntityPass::IterateAllEntities(std::function<bool(Entity&)> iterator) {
  if (!iterator) {
    return;
  }

  for (auto& element : elements_) {
    if (auto entity = std::get_if<Entity>(&element)) {
      if (!iterator(*entity)) {
        return;
      }
      continue;
    }
    if (auto subpass = std::get_if<std::unique_ptr<EntityPass>>(&element)) {
      subpass->get()->IterateAllEntities(iterator);
      continue;
    }
    FML_UNREACHABLE();
  }
}

std::unique_ptr<EntityPass> EntityPass::Clone() const {
  std::vector<Element> new_elements;
  new_elements.reserve(elements_.size());

  for (const auto& element : elements_) {
    if (auto entity = std::get_if<Entity>(&element)) {
      new_elements.push_back(*entity);
      continue;
    }
    if (auto subpass = std::get_if<std::unique_ptr<EntityPass>>(&element)) {
      new_elements.push_back(subpass->get()->Clone());
      continue;
    }
    FML_UNREACHABLE();
  }

  auto pass = std::make_unique<EntityPass>();
  pass->SetElements(std::move(new_elements));
  return pass;
}

void EntityPass::SetTransformation(Matrix xformation) {
  xformation_ = std::move(xformation);
}

void EntityPass::SetStencilDepth(size_t stencil_depth) {
  stencil_depth_ = stencil_depth;
}

void EntityPass::SetBlendMode(Entity::BlendMode blend_mode) {
  blend_mode_ = blend_mode;
}

}  // namespace impeller
