// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/entity_pass.h"

#include <memory>
#include <utility>
#include <variant>

#include "flutter/fml/logging.h"
#include "flutter/fml/macros.h"
#include "flutter/fml/trace_event.h"
#include "impeller/base/validation.h"
#include "impeller/core/allocator.h"
#include "impeller/core/formats.h"
#include "impeller/core/texture.h"
#include "impeller/entity/contents/clip_contents.h"
#include "impeller/entity/contents/content_context.h"
#include "impeller/entity/contents/filters/color_filter_contents.h"
#include "impeller/entity/contents/filters/inputs/filter_input.h"
#include "impeller/entity/contents/framebuffer_blend_contents.h"
#include "impeller/entity/contents/texture_contents.h"
#include "impeller/entity/entity.h"
#include "impeller/entity/inline_pass_context.h"
#include "impeller/geometry/path_builder.h"
#include "impeller/renderer/command.h"
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
  if (entity.GetBlendMode() > Entity::kLastPipelineBlendMode) {
    advanced_blend_reads_from_pass_texture_ += 1;
  }
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

std::optional<Rect> EntityPass::GetElementsCoverage(
    std::optional<Rect> coverage_crop) const {
  std::optional<Rect> result;
  for (const auto& element : elements_) {
    std::optional<Rect> coverage;

    if (auto entity = std::get_if<Entity>(&element)) {
      coverage = entity->GetCoverage();

      if (coverage.has_value() && coverage_crop.has_value()) {
        coverage = coverage->Intersection(coverage_crop.value());
      }
    } else if (auto subpass =
                   std::get_if<std::unique_ptr<EntityPass>>(&element)) {
      coverage = GetSubpassCoverage(*subpass->get(), coverage_crop);
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
    const EntityPass& subpass,
    std::optional<Rect> coverage_clip) const {
  auto entities_coverage = subpass.GetElementsCoverage(coverage_clip);
  // The entities don't cover anything. There is nothing to do.
  if (!entities_coverage.has_value()) {
    return std::nullopt;
  }

  // The delegates don't have an opinion on what the entity coverage has to be.
  // Just use that as-is.
  auto delegate_coverage = subpass.delegate_->GetCoverageRect();
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

  if (pass->backdrop_filter_proc_.has_value()) {
    backdrop_filter_reads_from_pass_texture_ += 1;
  }
  if (pass->blend_mode_ > Entity::kLastPipelineBlendMode) {
    advanced_blend_reads_from_pass_texture_ += 1;
  }

  auto subpass_pointer = pass.get();
  elements_.emplace_back(std::move(pass));
  return subpass_pointer;
}

static EntityPassTarget CreateRenderTarget(ContentContext& renderer,
                                           ISize size,
                                           bool readable,
                                           const Color& clear_color) {
  auto context = renderer.GetContext();

  /// All of the load/store actions are managed by `InlinePassContext` when
  /// `RenderPasses` are created, so we just set them to `kDontCare` here.
  /// What's important is the `StorageMode` of the textures, which cannot be
  /// changed for the lifetime of the textures.

  RenderTarget target;
  if (context->GetCapabilities()->SupportsOffscreenMSAA()) {
    target = RenderTarget::CreateOffscreenMSAA(
        *context,      // context
        size,          // size
        "EntityPass",  // label
        RenderTarget::AttachmentConfigMSAA{
            .storage_mode = StorageMode::kDeviceTransient,
            .resolve_storage_mode = StorageMode::kDevicePrivate,
            .load_action = LoadAction::kDontCare,
            .store_action = StoreAction::kMultisampleResolve,
            .clear_color = clear_color},  // color_attachment_config
        RenderTarget::AttachmentConfig{
            .storage_mode = readable ? StorageMode::kDevicePrivate
                                     : StorageMode::kDeviceTransient,
            .load_action = LoadAction::kDontCare,
            .store_action = StoreAction::kDontCare,
        }  // stencil_attachment_config
    );
  } else {
    target = RenderTarget::CreateOffscreen(
        *context,      // context
        size,          // size
        "EntityPass",  // label
        RenderTarget::AttachmentConfig{
            .storage_mode = StorageMode::kDevicePrivate,
            .load_action = LoadAction::kDontCare,
            .store_action = StoreAction::kDontCare,
        },  // color_attachment_config
        RenderTarget::AttachmentConfig{
            .storage_mode = readable ? StorageMode::kDevicePrivate
                                     : StorageMode::kDeviceTransient,
            .load_action = LoadAction::kDontCare,
            .store_action = StoreAction::kDontCare,
        }  // stencil_attachment_config
    );
  }

  return EntityPassTarget(
      target, renderer.GetDeviceCapabilities().SupportsReadFromResolve());
}

uint32_t EntityPass::GetTotalPassReads(ContentContext& renderer) const {
  return renderer.GetDeviceCapabilities().SupportsFramebufferFetch()
             ? backdrop_filter_reads_from_pass_texture_
             : backdrop_filter_reads_from_pass_texture_ +
                   advanced_blend_reads_from_pass_texture_;
}

bool EntityPass::Render(ContentContext& renderer,
                        const RenderTarget& render_target) const {
  if (render_target.GetColorAttachments().empty()) {
    VALIDATION_LOG << "The root RenderTarget must have a color attachment.";
    return false;
  }

  StencilCoverageStack stencil_coverage_stack = {StencilCoverageLayer{
      .coverage = Rect::MakeSize(render_target.GetRenderTargetSize()),
      .stencil_depth = 0}};

  if (GetTotalPassReads(renderer) > 0) {
    auto offscreen_target = CreateRenderTarget(
        renderer, render_target.GetRenderTargetSize(), true, clear_color_);

    if (!OnRender(renderer,  // renderer
                  offscreen_target.GetRenderTarget()
                      .GetRenderTargetSize(),  // root_pass_size
                  offscreen_target,            // pass_target
                  Point(),                     // global_pass_position
                  Point(),                     // local_pass_position
                  0,                           // pass_depth
                  stencil_coverage_stack       // stencil_coverage_stack
                  )) {
      return false;
    }

    auto command_buffer = renderer.GetContext()->CreateCommandBuffer();
    command_buffer->SetLabel("EntityPass Root Command Buffer");

    if (renderer.GetContext()
            ->GetCapabilities()
            ->SupportsTextureToTextureBlits()) {
      auto blit_pass = command_buffer->CreateBlitPass();

      blit_pass->AddCopy(
          offscreen_target.GetRenderTarget().GetRenderTargetTexture(),
          render_target.GetRenderTargetTexture());

      if (!blit_pass->EncodeCommands(
              renderer.GetContext()->GetResourceAllocator())) {
        return false;
      }
    } else {
      auto render_pass = command_buffer->CreateRenderPass(render_target);
      render_pass->SetLabel("EntityPass Root Render Pass");

      {
        auto size_rect = Rect::MakeSize(
            offscreen_target.GetRenderTarget().GetRenderTargetSize());
        auto contents = TextureContents::MakeRect(size_rect);
        contents->SetTexture(
            offscreen_target.GetRenderTarget().GetRenderTargetTexture());
        contents->SetSourceRect(size_rect);

        Entity entity;
        entity.SetContents(contents);
        entity.SetBlendMode(BlendMode::kSource);

        entity.Render(renderer, *render_pass);
      }

      if (!render_pass->EncodeCommands()) {
        return false;
      }
    }
    if (!command_buffer->SubmitCommands()) {
      return false;
    }

    return true;
  }

  // Set up the clear color of the root pass.
  auto color0 = render_target.GetColorAttachments().find(0)->second;
  color0.clear_color = clear_color_;

  auto root_render_target = render_target;
  root_render_target.SetColorAttachment(color0, 0);

  EntityPassTarget pass_target(
      root_render_target,
      renderer.GetDeviceCapabilities().SupportsReadFromResolve());

  return OnRender(                               //
      renderer,                                  // renderer
      root_render_target.GetRenderTargetSize(),  // root_pass_size
      pass_target,                               // pass_target
      Point(),                                   // global_pass_position
      Point(),                                   // local_pass_position
      0,                                         // pass_depth
      stencil_coverage_stack);                   // stencil_coverage_stack
}

EntityPass::EntityResult EntityPass::GetEntityForElement(
    const EntityPass::Element& element,
    ContentContext& renderer,
    InlinePassContext& pass_context,
    ISize root_pass_size,
    Point global_pass_position,
    uint32_t pass_depth,
    StencilCoverageStack& stencil_coverage_stack,
    size_t stencil_depth_floor) const {
  Entity element_entity;

  //--------------------------------------------------------------------------
  /// Setup entity element.
  ///

  if (const auto& entity = std::get_if<Entity>(&element)) {
    element_entity = *entity;
    if (!global_pass_position.IsZero()) {
      // If the pass image is going to be rendered with a non-zero position,
      // apply the negative translation to entity copies before rendering them
      // so that they'll end up rendering to the correct on-screen position.
      element_entity.SetTransformation(
          Matrix::MakeTranslation(Vector3(-global_pass_position)) *
          element_entity.GetTransformation());
    }
  }

  //--------------------------------------------------------------------------
  /// Setup subpass element.
  ///

  else if (const auto& subpass_ptr =
               std::get_if<std::unique_ptr<EntityPass>>(&element)) {
    auto subpass = subpass_ptr->get();

    if (subpass->delegate_->CanElide()) {
      return EntityPass::EntityResult::Skip();
    }

    if (!subpass->backdrop_filter_proc_.has_value() &&
        subpass->delegate_->CanCollapseIntoParentPass(subpass)) {
      // Directly render into the parent target and move on.
      if (!subpass->OnRender(
              renderer,                      // renderer
              root_pass_size,                // root_pass_size
              pass_context.GetPassTarget(),  // pass_target
              global_pass_position,          // global_pass_position
              Point(),                       // local_pass_position
              pass_depth,                    // pass_depth
              stencil_coverage_stack,        // stencil_coverage_stack
              stencil_depth_,                // stencil_depth_floor
              nullptr,                       // backdrop_filter_contents
              pass_context.GetRenderPass(pass_depth)  // collapsed_parent_pass
              )) {
        return EntityPass::EntityResult::Failure();
      }
      return EntityPass::EntityResult::Skip();
    }

    std::shared_ptr<Contents> backdrop_filter_contents = nullptr;
    if (subpass->backdrop_filter_proc_.has_value()) {
      auto texture = pass_context.GetTexture();
      // Render the backdrop texture before any of the pass elements.
      const auto& proc = subpass->backdrop_filter_proc_.value();
      backdrop_filter_contents =
          proc(FilterInput::Make(std::move(texture)), subpass->xformation_,
               /*is_subpass*/ true);

      // The subpass will need to read from the current pass texture when
      // rendering the backdrop, so if there's an active pass, end it prior to
      // rendering the subpass.
      pass_context.EndPass();
    }

    auto subpass_coverage =
        GetSubpassCoverage(*subpass, Rect::MakeSize(root_pass_size));
    if (subpass->cover_whole_screen_) {
      subpass_coverage =
          Rect(global_pass_position, Size(pass_context.GetPassTarget()
                                              .GetRenderTarget()
                                              .GetRenderTargetSize()));
    }
    if (backdrop_filter_contents) {
      auto backdrop_coverage = backdrop_filter_contents->GetCoverage(Entity{});
      if (backdrop_coverage.has_value()) {
        backdrop_coverage->origin += global_pass_position;

        subpass_coverage =
            subpass_coverage.has_value()
                ? subpass_coverage->Union(backdrop_coverage.value())
                : backdrop_coverage;
      }
    }

    if (!subpass_coverage.has_value() || subpass_coverage->size.IsEmpty()) {
      // The subpass doesn't contain anything visible, so skip it.
      return EntityPass::EntityResult::Skip();
    }

    subpass_coverage =
        subpass_coverage->Intersection(Rect::MakeSize(root_pass_size));

    auto subpass_target =
        CreateRenderTarget(renderer,                                  //
                           ISize(subpass_coverage->size),             //
                           subpass->GetTotalPassReads(renderer) > 0,  //
                           clear_color_);

    auto subpass_texture =
        subpass_target.GetRenderTarget().GetRenderTargetTexture();

    if (!subpass_texture) {
      return EntityPass::EntityResult::Failure();
    }

    auto offscreen_texture_contents =
        subpass->delegate_->CreateContentsForSubpassTarget(
            subpass_texture,
            Matrix::MakeTranslation(Vector3{-global_pass_position}) *
                subpass->xformation_);

    if (!offscreen_texture_contents) {
      // This is an error because the subpass delegate said the pass couldn't
      // be collapsed into its parent. Yet, when asked how it want's to
      // postprocess the offscreen texture, it couldn't give us an answer.
      //
      // Theoretically, we could collapse the pass now. But that would be
      // wasteful as we already have the offscreen texture and we don't want
      // to discard it without ever using it. Just make the delegate do the
      // right thing.
      return EntityPass::EntityResult::Failure();
    }

    // Stencil textures aren't shared between EntityPasses (as much of the
    // time they are transient).
    if (!subpass->OnRender(renderer,                  // renderer
                           root_pass_size,            // root_pass_size
                           subpass_target,            // pass_target
                           subpass_coverage->origin,  // global_pass_position
                           subpass_coverage->origin -
                               global_pass_position,  // local_pass_position
                           ++pass_depth,              // pass_depth
                           stencil_coverage_stack,    // stencil_coverage_stack
                           subpass->stencil_depth_,   // stencil_depth_floor
                           backdrop_filter_contents  // backdrop_filter_contents
                           )) {
      return EntityPass::EntityResult::Failure();
    }

    element_entity.SetContents(std::move(offscreen_texture_contents));
    element_entity.SetStencilDepth(subpass->stencil_depth_);
    element_entity.SetBlendMode(subpass->blend_mode_);
    element_entity.SetTransformation(Matrix::MakeTranslation(
        Vector3(subpass_coverage->origin - global_pass_position)));
  } else {
    FML_UNREACHABLE();
  }

  return EntityPass::EntityResult::Success(element_entity);
}

bool EntityPass::OnRender(ContentContext& renderer,
                          ISize root_pass_size,
                          EntityPassTarget& pass_target,
                          Point global_pass_position,
                          Point local_pass_position,
                          uint32_t pass_depth,
                          StencilCoverageStack& stencil_coverage_stack,
                          size_t stencil_depth_floor,
                          std::shared_ptr<Contents> backdrop_filter_contents,
                          std::optional<InlinePassContext::RenderPassResult>
                              collapsed_parent_pass) const {
  TRACE_EVENT0("impeller", "EntityPass::OnRender");

  auto context = renderer.GetContext();
  InlinePassContext pass_context(context, pass_target,
                                 GetTotalPassReads(renderer),
                                 std::move(collapsed_parent_pass));
  if (!pass_context.IsValid()) {
    return false;
  }

  auto render_element = [&stencil_depth_floor, &pass_context, &pass_depth,
                         &renderer, &stencil_coverage_stack,
                         &global_pass_position](Entity& element_entity) {
    auto result = pass_context.GetRenderPass(pass_depth);

    if (!result.pass) {
      return false;
    }

    // If the pass context returns a texture, we need to draw it to the current
    // pass. We do this because it's faster and takes significantly less memory
    // than storing/loading large MSAA textures.
    // Also, it's not possible to blit the non-MSAA resolve texture of the
    // previous pass to MSAA textures (let alone a transient one).
    if (result.backdrop_texture) {
      auto size_rect = Rect::MakeSize(result.pass->GetRenderTargetSize());
      auto msaa_backdrop_contents = TextureContents::MakeRect(size_rect);
      msaa_backdrop_contents->SetStencilEnabled(false);
      msaa_backdrop_contents->SetLabel("MSAA backdrop");
      msaa_backdrop_contents->SetSourceRect(size_rect);
      msaa_backdrop_contents->SetTexture(result.backdrop_texture);

      Entity msaa_backdrop_entity;
      msaa_backdrop_entity.SetContents(std::move(msaa_backdrop_contents));
      msaa_backdrop_entity.SetBlendMode(BlendMode::kSource);
      if (!msaa_backdrop_entity.Render(renderer, *result.pass)) {
        return false;
      }
    }

    auto current_stencil_coverage = stencil_coverage_stack.back().coverage;
    if (current_stencil_coverage.has_value()) {
      // Entity transforms are relative to the current pass position, so we need
      // to check stencil coverage in the same space.
      current_stencil_coverage->origin -= global_pass_position;
    }

    if (!element_entity.ShouldRender(current_stencil_coverage)) {
      return true;  // Nothing to render.
    }

    auto stencil_coverage =
        element_entity.GetStencilCoverage(current_stencil_coverage);
    if (stencil_coverage.coverage.has_value()) {
      stencil_coverage.coverage->origin += global_pass_position;
    }

    switch (stencil_coverage.type) {
      case Contents::StencilCoverage::Type::kNoChange:
        break;
      case Contents::StencilCoverage::Type::kAppend: {
        auto op = stencil_coverage_stack.back().coverage;
        stencil_coverage_stack.push_back(StencilCoverageLayer{
            .coverage = stencil_coverage.coverage,
            .stencil_depth = element_entity.GetStencilDepth() + 1});
        FML_DCHECK(stencil_coverage_stack.back().stencil_depth ==
                   stencil_coverage_stack.size() - 1);

        if (!op.has_value()) {
          // Running this append op won't impact the stencil because the whole
          // screen is already being clipped, so skip it.
          return true;
        }
      } break;
      case Contents::StencilCoverage::Type::kRestore: {
        if (stencil_coverage_stack.back().stencil_depth <=
            element_entity.GetStencilDepth()) {
          // Drop stencil restores that will do nothing.
          return true;
        }

        auto restoration_depth = element_entity.GetStencilDepth();
        FML_DCHECK(restoration_depth < stencil_coverage_stack.size());

        // We only need to restore the area that covers the coverage of the
        // stencil rect at target depth + 1.
        std::optional<Rect> restore_coverage =
            (restoration_depth + 1 < stencil_coverage_stack.size())
                ? stencil_coverage_stack[restoration_depth + 1].coverage
                : std::nullopt;
        if (restore_coverage.has_value()) {
          // Make the coverage rectangle relative to the current pass.
          restore_coverage->origin -= global_pass_position;
        }
        stencil_coverage_stack.resize(restoration_depth + 1);

        if (!stencil_coverage_stack.back().coverage.has_value()) {
          // Running this restore op won't make anything renderable, so skip it.
          return true;
        }

        auto restore_contents = static_cast<ClipRestoreContents*>(
            element_entity.GetContents().get());
        restore_contents->SetRestoreCoverage(restore_coverage);

      } break;
    }

    element_entity.SetStencilDepth(element_entity.GetStencilDepth() -
                                   stencil_depth_floor);
    if (!element_entity.Render(renderer, *result.pass)) {
      return false;
    }
    return true;
  };

  if (backdrop_filter_proc_.has_value()) {
    if (!backdrop_filter_contents) {
      return false;
    }

    Entity backdrop_entity;
    backdrop_entity.SetContents(std::move(backdrop_filter_contents));
    backdrop_entity.SetTransformation(
        Matrix::MakeTranslation(Vector3(local_pass_position)));
    backdrop_entity.SetStencilDepth(stencil_depth_floor);

    render_element(backdrop_entity);
  }

  for (const auto& element : elements_) {
    EntityResult result =
        GetEntityForElement(element,                 // element
                            renderer,                // renderer
                            pass_context,            // pass_context
                            root_pass_size,          // root_pass_size
                            global_pass_position,    // global_pass_position
                            pass_depth,              // pass_depth
                            stencil_coverage_stack,  // stencil_coverage_stack
                            stencil_depth_floor);    // stencil_depth_floor

    switch (result.status) {
      case EntityResult::kSuccess:
        break;
      case EntityResult::kFailure:
        return false;
      case EntityResult::kSkip:
        continue;
    };

    //--------------------------------------------------------------------------
    /// Setup advanced blends.
    ///

    if (result.entity.GetBlendMode() > Entity::kLastPipelineBlendMode) {
      if (renderer.GetDeviceCapabilities().SupportsFramebufferFetch()) {
        auto src_contents = result.entity.GetContents();
        auto contents = std::make_shared<FramebufferBlendContents>();
        contents->SetChildContents(src_contents);
        contents->SetBlendMode(result.entity.GetBlendMode());
        result.entity.SetContents(std::move(contents));
        result.entity.SetBlendMode(BlendMode::kSource);
      } else {
        // End the active pass and flush the buffer before rendering "advanced"
        // blends. Advanced blends work by binding the current render target
        // texture as an input ("destination"), blending with a second texture
        // input ("source"), writing the result to an intermediate texture, and
        // finally copying the data from the intermediate texture back to the
        // render target texture. And so all of the commands that have written
        // to the render target texture so far need to execute before it's bound
        // for blending (otherwise the blend pass will end up executing before
        // all the previous commands in the active pass).

        if (!pass_context.EndPass()) {
          return false;
        }

        // Amend an advanced blend filter to the contents, attaching the pass
        // texture.
        auto texture = pass_context.GetTexture();
        if (!texture) {
          return false;
        }

        FilterInput::Vector inputs = {
            FilterInput::Make(texture,
                              result.entity.GetTransformation().Invert()),
            FilterInput::Make(result.entity.GetContents())};
        auto contents = ColorFilterContents::MakeBlend(
            result.entity.GetBlendMode(), inputs);
        contents->SetCoverageCrop(result.entity.GetCoverage());
        result.entity.SetContents(std::move(contents));
        result.entity.SetBlendMode(BlendMode::kSource);
      }
    }

    //--------------------------------------------------------------------------
    /// Render the Element.
    ///

    if (!render_element(result.entity)) {
      return false;
    }
  }

  return true;
}

void EntityPass::IterateAllEntities(
    const std::function<bool(Entity&)>& iterator) {
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

bool EntityPass::IterateUntilSubpass(
    const std::function<bool(Entity&)>& iterator) {
  if (!iterator) {
    return true;
  }

  for (auto& element : elements_) {
    if (auto entity = std::get_if<Entity>(&element)) {
      if (!iterator(*entity)) {
        return false;
      }
      continue;
    }
    return true;
  }
  return false;
}

size_t EntityPass::GetElementCount() const {
  return elements_.size();
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
  xformation_ = xformation;
}

void EntityPass::SetStencilDepth(size_t stencil_depth) {
  stencil_depth_ = stencil_depth;
}

void EntityPass::SetBlendMode(BlendMode blend_mode) {
  blend_mode_ = blend_mode;
  cover_whole_screen_ = Entity::IsBlendModeDestructive(blend_mode);
}

void EntityPass::SetClearColor(Color clear_color) {
  clear_color_ = clear_color;
}

Color EntityPass::GetClearColor() const {
  return clear_color_;
}

void EntityPass::SetBackdropFilter(std::optional<BackdropFilterProc> proc) {
  if (superpass_) {
    VALIDATION_LOG << "Backdrop filters cannot be set on EntityPasses that "
                      "have already been appended to another pass.";
  }

  backdrop_filter_proc_ = std::move(proc);
}

}  // namespace impeller
