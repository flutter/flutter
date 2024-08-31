// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/entity_pass.h"

#include <limits>
#include <memory>
#include <utility>
#include <variant>

#include "flutter/fml/closure.h"
#include "flutter/fml/logging.h"
#include "flutter/fml/trace_event.h"
#include "impeller/base/strings.h"
#include "impeller/base/validation.h"
#include "impeller/core/formats.h"
#include "impeller/entity/contents/content_context.h"
#include "impeller/entity/contents/filters/color_filter_contents.h"
#include "impeller/entity/contents/filters/inputs/filter_input.h"
#include "impeller/entity/contents/framebuffer_blend_contents.h"
#include "impeller/entity/contents/texture_contents.h"
#include "impeller/entity/draw_order_resolver.h"
#include "impeller/entity/entity.h"
#include "impeller/entity/entity_pass_clip_stack.h"
#include "impeller/entity/inline_pass_context.h"
#include "impeller/entity/save_layer_utils.h"
#include "impeller/geometry/color.h"
#include "impeller/geometry/rect.h"
#include "impeller/geometry/size.h"
#include "impeller/renderer/command_buffer.h"

namespace impeller {

namespace {
std::tuple<std::optional<Color>, BlendMode> ElementAsBackgroundColor(
    const EntityPass::Element& element,
    ISize target_size) {
  if (const Entity* entity = std::get_if<Entity>(&element)) {
    std::optional<Color> entity_color = entity->AsBackgroundColor(target_size);
    if (entity_color.has_value()) {
      return {entity_color.value(), entity->GetBlendMode()};
    }
  }
  return {};
}
}  // namespace

bool EntityPass::IsSubpass(const Element& element) {
  return std::holds_alternative<std::unique_ptr<EntityPass>>(element);
}

EntityPass::EntityPass() = default;

EntityPass::~EntityPass() = default;

void EntityPass::SetDelegate(std::shared_ptr<EntityPassDelegate> delegate) {
  if (!delegate) {
    return;
  }
  delegate_ = std::move(delegate);
}

void EntityPass::SetBoundsLimit(std::optional<Rect> bounds_limit) {
  bounds_limit_ = bounds_limit;
}

std::optional<Rect> EntityPass::GetBoundsLimit() const {
  return bounds_limit_;
}

void EntityPass::AddEntity(Entity entity) {
  if (entity.GetBlendMode() == BlendMode::kSourceOver &&
      entity.GetContents()->IsOpaque(entity.GetTransform())) {
    entity.SetBlendMode(BlendMode::kSource);
  }

  if (entity.GetBlendMode() > Entity::kLastPipelineBlendMode) {
    advanced_blend_reads_from_pass_texture_ = true;
  }
  draw_order_resolver_.AddElement(elements_.size(),
                                  entity.GetBlendMode() == BlendMode::kSource);
  elements_.emplace_back(std::move(entity));
}

void EntityPass::PushClip(Entity entity) {
  elements_.emplace_back(std::move(entity));
  draw_order_resolver_.PushClip(elements_.size() - 1);
  active_clips_.emplace_back(elements_.size() - 1);
}

void EntityPass::PopClips(size_t num_clips, uint64_t depth) {
  if (num_clips > active_clips_.size()) {
    VALIDATION_LOG
        << "Attempted to pop more clips than are currently active. Active: "
        << active_clips_.size() << ", Popped: " << num_clips
        << ", Depth: " << depth;
  }

  size_t max = std::min(num_clips, active_clips_.size());
  for (size_t i = 0; i < max; i++) {
    FML_DCHECK(active_clips_.back() < elements_.size());
    Entity* element = std::get_if<Entity>(&elements_[active_clips_.back()]);
    FML_DCHECK(element);
    element->SetClipDepth(depth);
    active_clips_.pop_back();
    draw_order_resolver_.PopClip();
  }
}

void EntityPass::PopAllClips(uint64_t depth) {
  PopClips(active_clips_.size(), depth);
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

EntityPass* EntityPass::GetSuperpass() const {
  return superpass_;
}

EntityPass* EntityPass::AddSubpass(std::unique_ptr<EntityPass> pass) {
  if (!pass) {
    return nullptr;
  }
  FML_DCHECK(pass->superpass_ == nullptr);
  pass->superpass_ = this;

  bool has_backdrop_filter = pass->backdrop_filter_proc_ != nullptr;
  if (has_backdrop_filter) {
    backdrop_filter_reads_from_pass_texture_ = true;

    // Since backdrop filters trigger the RenderPass to end and lose all depth
    // information for opaque draws, this is a hard barrier for the draw order
    // optimization. Flush all sorted draws accumulated up to this point.
    draw_order_resolver_.Flush();
  }
  if (pass->blend_mode_ > Entity::kLastPipelineBlendMode) {
    advanced_blend_reads_from_pass_texture_ = true;
  }

  auto subpass_pointer = pass.get();
  elements_.emplace_back(std::move(pass));

  draw_order_resolver_.AddElement(elements_.size() - 1, false);
  if (has_backdrop_filter) {
    draw_order_resolver_.Flush();
  }

  return subpass_pointer;
}

static const constexpr RenderTarget::AttachmentConfig kDefaultStencilConfig =
    RenderTarget::AttachmentConfig{
        .storage_mode = StorageMode::kDeviceTransient,
        .load_action = LoadAction::kDontCare,
        .store_action = StoreAction::kDontCare,
    };

static EntityPassTarget CreateRenderTarget(ContentContext& renderer,
                                           ISize size,
                                           int mip_count,
                                           const Color& clear_color) {
  const std::shared_ptr<Context>& context = renderer.GetContext();

  /// All of the load/store actions are managed by `InlinePassContext` when
  /// `RenderPasses` are created, so we just set them to `kDontCare` here.
  /// What's important is the `StorageMode` of the textures, which cannot be
  /// changed for the lifetime of the textures.

  if (context->GetBackendType() == Context::BackendType::kOpenGLES) {
    // TODO(141732): Implement mip map generation on opengles.
    mip_count = 1;
  }

  RenderTarget target;
  if (context->GetCapabilities()->SupportsOffscreenMSAA()) {
    target = renderer.GetRenderTargetCache()->CreateOffscreenMSAA(
        /*context=*/*context,
        /*size=*/size,
        /*mip_count=*/mip_count,
        /*label=*/"EntityPass",
        /*color_attachment_config=*/
        RenderTarget::AttachmentConfigMSAA{
            .storage_mode = StorageMode::kDeviceTransient,
            .resolve_storage_mode = StorageMode::kDevicePrivate,
            .load_action = LoadAction::kDontCare,
            .store_action = StoreAction::kMultisampleResolve,
            .clear_color = clear_color},
        /*stencil_attachment_config=*/
        kDefaultStencilConfig);
  } else {
    target = renderer.GetRenderTargetCache()->CreateOffscreen(
        *context,  // context
        size,      // size
        /*mip_count=*/mip_count,
        "EntityPass",  // label
        RenderTarget::AttachmentConfig{
            .storage_mode = StorageMode::kDevicePrivate,
            .load_action = LoadAction::kDontCare,
            .store_action = StoreAction::kDontCare,
            .clear_color = clear_color,
        },                     // color_attachment_config
        kDefaultStencilConfig  // stencil_attachment_config
    );
  }

  return EntityPassTarget(
      target, renderer.GetDeviceCapabilities().SupportsReadFromResolve(),
      renderer.GetDeviceCapabilities().SupportsImplicitResolvingMSAA());
}

bool EntityPass::DoesBackdropGetRead(ContentContext& renderer) const {
  return renderer.GetDeviceCapabilities().SupportsFramebufferFetch()
             ? backdrop_filter_reads_from_pass_texture_
             : backdrop_filter_reads_from_pass_texture_ ||
                   advanced_blend_reads_from_pass_texture_;
}

bool EntityPass::Render(ContentContext& renderer,
                        const RenderTarget& render_target) const {
  renderer.GetRenderTargetCache()->Start();
  fml::ScopedCleanupClosure reset_state([&renderer]() {
    renderer.GetLazyGlyphAtlas()->ResetTextFrames();
    renderer.GetRenderTargetCache()->End();
  });

  auto root_render_target = render_target;

  if (root_render_target.GetColorAttachments().find(0u) ==
      root_render_target.GetColorAttachments().end()) {
    VALIDATION_LOG << "The root RenderTarget must have a color attachment.";
    return false;
  }
  if (root_render_target.GetDepthAttachment().has_value() !=
      root_render_target.GetStencilAttachment().has_value()) {
    VALIDATION_LOG << "The root RenderTarget should have a stencil attachment "
                      "iff it has a depth attachment.";
    return false;
  }

  const auto& lazy_glyph_atlas = renderer.GetLazyGlyphAtlas();
  IterateAllEntities([&lazy_glyph_atlas](const Entity& entity) {
    if (const auto& contents = entity.GetContents()) {
      contents->PopulateGlyphAtlas(lazy_glyph_atlas, entity.DeriveTextScale());
    }
    return true;
  });

  EntityPassClipStack clip_stack = EntityPassClipStack(
      Rect::MakeSize(root_render_target.GetRenderTargetSize()));

  // In this branch path, we need to render everything to an offscreen texture
  // and then blit the results onto the onscreen texture. If using this branch,
  // there's no need to set up a stencil attachment on the root render target.
  if (DoesBackdropGetRead(renderer)) {
    EntityPassTarget offscreen_target = CreateRenderTarget(
        renderer, root_render_target.GetRenderTargetSize(),
        GetRequiredMipCount(),
        GetClearColorOrDefault(render_target.GetRenderTargetSize()));

    if (!OnRender(renderer,  // renderer
                  offscreen_target.GetRenderTarget()
                      .GetRenderTargetSize(),  // root_pass_size
                  offscreen_target,            // pass_target
                  Point(),                     // global_pass_position
                  Point(),                     // local_pass_position
                  0,                           // pass_depth
                  clip_stack                   // clip_coverage_stack
                  )) {
      // Validation error messages are triggered for all `OnRender()` failure
      // cases.
      return false;
    }

    auto command_buffer = renderer.GetContext()->CreateCommandBuffer();
    command_buffer->SetLabel("EntityPass Root Command Buffer");

    // If the context supports blitting, blit the offscreen texture to the
    // onscreen texture. Otherwise, draw it to the parent texture using a
    // pipeline (slower).
    if (renderer.GetContext()
            ->GetCapabilities()
            ->SupportsTextureToTextureBlits()) {
      auto blit_pass = command_buffer->CreateBlitPass();
      blit_pass->AddCopy(
          offscreen_target.GetRenderTarget().GetRenderTargetTexture(),
          root_render_target.GetRenderTargetTexture());
      if (!blit_pass->EncodeCommands(
              renderer.GetContext()->GetResourceAllocator())) {
        VALIDATION_LOG << "Failed to encode root pass blit command.";
        return false;
      }
      if (!renderer.GetContext()
               ->GetCommandQueue()
               ->Submit({command_buffer})
               .ok()) {
        return false;
      }
    } else {
      auto render_pass = command_buffer->CreateRenderPass(root_render_target);
      render_pass->SetLabel("EntityPass Root Render Pass");

      {
        auto size_rect = Rect::MakeSize(
            offscreen_target.GetRenderTarget().GetRenderTargetSize());
        auto contents = TextureContents::MakeRect(size_rect);
        contents->SetTexture(
            offscreen_target.GetRenderTarget().GetRenderTargetTexture());
        contents->SetSourceRect(size_rect);
        contents->SetLabel("Root pass blit");

        Entity entity;
        entity.SetContents(contents);
        entity.SetBlendMode(BlendMode::kSource);

        if (!entity.Render(renderer, *render_pass)) {
          VALIDATION_LOG << "Failed to render EntityPass root blit.";
          return false;
        }
      }

      if (!render_pass->EncodeCommands()) {
        VALIDATION_LOG << "Failed to encode root pass command buffer.";
        return false;
      }
      if (!renderer.GetContext()
               ->GetCommandQueue()
               ->Submit({command_buffer})
               .ok()) {
        return false;
      }
    }

    return true;
  }

  // If we make it this far, that means the context is capable of rendering
  // everything directly to the onscreen texture.

  // The safety check for fetching this color attachment is at the beginning of
  // this method.
  auto color0 = root_render_target.GetColorAttachments().find(0u)->second;

  auto stencil_attachment = root_render_target.GetStencilAttachment();
  auto depth_attachment = root_render_target.GetDepthAttachment();
  if (!stencil_attachment.has_value() || !depth_attachment.has_value()) {
    // Setup a new root stencil with an optimal configuration if one wasn't
    // provided by the caller.
    root_render_target.SetupDepthStencilAttachments(
        *renderer.GetContext(), *renderer.GetContext()->GetResourceAllocator(),
        color0.texture->GetSize(),
        renderer.GetContext()->GetCapabilities()->SupportsOffscreenMSAA(),
        "ImpellerOnscreen", kDefaultStencilConfig);
  }

  // Set up the clear color of the root pass.
  color0.clear_color =
      GetClearColorOrDefault(render_target.GetRenderTargetSize());
  root_render_target.SetColorAttachment(color0, 0);

  EntityPassTarget pass_target(
      root_render_target,
      renderer.GetDeviceCapabilities().SupportsReadFromResolve(),
      renderer.GetDeviceCapabilities().SupportsImplicitResolvingMSAA());

  return OnRender(                               //
      renderer,                                  // renderer
      root_render_target.GetRenderTargetSize(),  // root_pass_size
      pass_target,                               // pass_target
      Point(),                                   // global_pass_position
      Point(),                                   // local_pass_position
      0,                                         // pass_depth
      clip_stack);                               // clip_coverage_stack
}

EntityPass::EntityResult EntityPass::GetEntityForElement(
    const EntityPass::Element& element,
    ContentContext& renderer,
    InlinePassContext& pass_context,
    ISize root_pass_size,
    Point global_pass_position,
    uint32_t pass_depth,
    EntityPassClipStack& clip_coverage_stack,
    size_t clip_height_floor) const {
  //--------------------------------------------------------------------------
  /// Setup entity element.
  ///
  if (const auto& entity = std::get_if<Entity>(&element)) {
    Entity element_entity = entity->Clone();

    if (!global_pass_position.IsZero()) {
      // If the pass image is going to be rendered with a non-zero position,
      // apply the negative translation to entity copies before rendering them
      // so that they'll end up rendering to the correct on-screen position.
      element_entity.SetTransform(
          Matrix::MakeTranslation(Vector3(-global_pass_position)) *
          element_entity.GetTransform());
    }
    return EntityPass::EntityResult::Success(std::move(element_entity));
  }

  //--------------------------------------------------------------------------
  /// Setup subpass element.
  ///
  if (const auto& subpass_ptr =
          std::get_if<std::unique_ptr<EntityPass>>(&element)) {
    auto subpass = subpass_ptr->get();
    if (subpass->delegate_->CanElide()) {
      return EntityPass::EntityResult::Skip();
    }

    if (!subpass->backdrop_filter_proc_ &&
        subpass->delegate_->CanCollapseIntoParentPass(subpass)) {
      // Directly render into the parent target and move on.
      if (!subpass->OnRender(
              renderer,                      // renderer
              root_pass_size,                // root_pass_size
              pass_context.GetPassTarget(),  // pass_target
              global_pass_position,          // global_pass_position
              Point(),                       // local_pass_position
              pass_depth,                    // pass_depth
              clip_coverage_stack,           // clip_coverage_stack
              clip_height_,                  // clip_height_floor
              nullptr,                       // backdrop_filter_contents
              pass_context.GetRenderPass(pass_depth)  // collapsed_parent_pass
              )) {
        // Validation error messages are triggered for all `OnRender()` failure
        // cases.
        return EntityPass::EntityResult::Failure();
      }
      return EntityPass::EntityResult::Skip();
    }

    std::shared_ptr<Contents> subpass_backdrop_filter_contents = nullptr;
    if (subpass->backdrop_filter_proc_) {
      auto texture = pass_context.GetTexture();
      // Render the backdrop texture before any of the pass elements.
      const auto& proc = subpass->backdrop_filter_proc_;

      subpass_backdrop_filter_contents = proc(
          FilterInput::Make(std::move(texture)), subpass->transform_.Basis(),
          // When the subpass has a translation that means the math with
          // the snapshot has to be different.
          subpass->transform_.HasTranslation()
              ? Entity::RenderingMode::kSubpassPrependSnapshotTransform
              : Entity::RenderingMode::kSubpassAppendSnapshotTransform);

      // If the very first thing we render in this EntityPass is a subpass that
      // happens to have a backdrop filter, than that backdrop filter will end
      // may wind up sampling from the raw, uncleared texture that came straight
      // out of the texture cache. By calling `pass_context.GetRenderPass` here,
      // we force the texture to pass through at least one RenderPass with the
      // correct clear configuration before any sampling occurs.
      pass_context.GetRenderPass(pass_depth);

      // The subpass will need to read from the current pass texture when
      // rendering the backdrop, so if there's an active pass, end it prior to
      // rendering the subpass.
      pass_context.EndPass();
    }

    if (!clip_coverage_stack.HasCoverage()) {
      // The current clip is empty. This means the pass texture won't be
      // visible, so skip it.
      return EntityPass::EntityResult::Skip();
    }
    auto clip_coverage_back = clip_coverage_stack.CurrentClipCoverage();
    if (!clip_coverage_back.has_value()) {
      return EntityPass::EntityResult::Skip();
    }

    // The maximum coverage of the subpass. Subpasses textures should never
    // extend outside the parent pass texture or the current clip coverage.
    auto coverage_limit = Rect::MakeOriginSize(global_pass_position,
                                               Size(pass_context.GetPassTarget()
                                                        .GetRenderTarget()
                                                        .GetRenderTargetSize()))
                              .Intersection(clip_coverage_back.value());
    if (!coverage_limit.has_value()) {
      return EntityPass::EntityResult::Skip();
    }

    coverage_limit =
        coverage_limit->Intersection(Rect::MakeSize(root_pass_size));
    if (!coverage_limit.has_value()) {
      return EntityPass::EntityResult::Skip();
    }

    std::shared_ptr<FilterContents> image_filter =
        subpass->delegate_->WithImageFilter(Rect(), subpass->transform_);

    auto subpass_coverage = ComputeSaveLayerCoverage(
        subpass->bounds_limit_.value_or(Rect::MakeMaximum()),        //
        subpass->transform_,                                         //
        coverage_limit.value(),                                      //
        image_filter,                                                //
        /*flood_output_coverage=*/subpass->flood_clip_,              //
        /*flood_input_coverage=*/!!subpass_backdrop_filter_contents  //
    );

    if (!subpass_coverage.has_value()) {
      return EntityPass::EntityResult::Skip();
    }

    auto subpass_size = ISize(subpass_coverage->GetSize());
    if (subpass_size.IsEmpty()) {
      return EntityPass::EntityResult::Skip();
    }

    auto subpass_target = CreateRenderTarget(
        renderer,      // renderer
        subpass_size,  // size
        subpass->GetRequiredMipCount(),
        subpass->GetClearColorOrDefault(subpass_size));  // clear_color

    if (!subpass_target.IsValid()) {
      VALIDATION_LOG << "Subpass render target is invalid.";
      return EntityPass::EntityResult::Failure();
    }

    // Start non-collapsed subpasses with a fresh clip coverage stack limited by
    // the subpass coverage. This is important because image filters applied to
    // save layers may transform the subpass texture after it's rendered,
    // causing parent clip coverage to get misaligned with the actual area that
    // the subpass will affect in the parent pass.
    clip_coverage_stack.PushSubpass(subpass_coverage, subpass->clip_height_);

    // Stencil textures aren't shared between EntityPasses (as much of the
    // time they are transient).
    if (!subpass->OnRender(
            renderer,                       // renderer
            root_pass_size,                 // root_pass_size
            subpass_target,                 // pass_target
            subpass_coverage->GetOrigin(),  // global_pass_position
            subpass_coverage->GetOrigin() -
                global_pass_position,         // local_pass_position
            ++pass_depth,                     // pass_depth
            clip_coverage_stack,              // clip_coverage_stack
            subpass->clip_height_,            // clip_height_floor
            subpass_backdrop_filter_contents  // backdrop_filter_contents
            )) {
      // Validation error messages are triggered for all `OnRender()` failure
      // cases.
      return EntityPass::EntityResult::Failure();
    }

    clip_coverage_stack.PopSubpass();

    // The subpass target's texture may have changed during OnRender.
    auto subpass_texture =
        subpass_target.GetRenderTarget().GetRenderTargetTexture();

    auto offscreen_texture_contents =
        subpass->delegate_->CreateContentsForSubpassTarget(
            subpass_texture,
            Matrix::MakeTranslation(Vector3{-global_pass_position}) *
                subpass->transform_);

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

    // Round the subpass texture position for pixel alignment with the parent
    // pass render target. By default, we draw subpass textures with nearest
    // sampling, so aligning here is important for avoiding visual nearest
    // sampling errors caused by limited floating point precision when
    // straddling a half pixel boundary.
    //
    // We do this in lieu of expanding/rounding out the subpass coverage in
    // order to keep the bounds wrapping consistently tight around subpass
    // elements. Which is necessary to avoid intense flickering in cases
    // where a subpass texture has a large blur filter with clamp sampling.
    //
    // See also this bug: https://github.com/flutter/flutter/issues/144213
    Point subpass_texture_position =
        (subpass_coverage->GetOrigin() - global_pass_position).Round();

    Entity element_entity;
    element_entity.SetClipDepth(subpass->clip_depth_);
    element_entity.SetContents(std::move(offscreen_texture_contents));
    element_entity.SetBlendMode(subpass->blend_mode_);
    element_entity.SetTransform(
        Matrix::MakeTranslation(Vector3(subpass_texture_position)));

    return EntityPass::EntityResult::Success(std::move(element_entity));
  }
  FML_UNREACHABLE();
}

static void SetClipScissor(std::optional<Rect> clip_coverage,
                           RenderPass& pass,
                           Point global_pass_position) {
  // Set the scissor to the clip coverage area. We do this prior to rendering
  // the clip itself and all its contents.
  IRect scissor;
  if (clip_coverage.has_value()) {
    clip_coverage = clip_coverage->Shift(-global_pass_position);
    scissor = IRect::RoundOut(clip_coverage.value());
    // The scissor rect must not exceed the size of the render target.
    scissor = scissor.Intersection(IRect::MakeSize(pass.GetRenderTargetSize()))
                  .value_or(IRect());
  }
  pass.SetScissor(scissor);
}

bool EntityPass::RenderElement(Entity& element_entity,
                               size_t clip_height_floor,
                               InlinePassContext& pass_context,
                               int32_t pass_depth,
                               ContentContext& renderer,
                               EntityPassClipStack& clip_coverage_stack,
                               Point global_pass_position) const {
  // Setup advanced blends.
  if (element_entity.GetBlendMode() > Entity::kLastPipelineBlendMode) {
    if (renderer.GetDeviceCapabilities().SupportsFramebufferFetch()) {
      auto src_contents = element_entity.GetContents();
      auto contents = std::make_shared<FramebufferBlendContents>();
      contents->SetChildContents(src_contents);
      contents->SetBlendMode(element_entity.GetBlendMode());
      element_entity.SetContents(std::move(contents));
      element_entity.SetBlendMode(BlendMode::kSource);
    } else {
      // End the active pass and flush the buffer before rendering
      // "advanced" blends. Advanced blends work by binding the current
      // render target texture as an input ("destination"), blending with a
      // second texture input ("source"), writing the result to an
      // intermediate texture, and finally copying the data from the
      // intermediate texture back to the render target texture. And so all
      // of the commands that have written to the render target texture so
      // far need to execute before it's bound for blending (otherwise the
      // blend pass will end up executing before all the previous commands
      // in the active pass).

      if (!pass_context.EndPass()) {
        VALIDATION_LOG
            << "Failed to end the current render pass in order to read "
               "from "
               "the backdrop texture and apply an advanced blend.";
        return false;
      }

      // Amend an advanced blend filter to the contents, attaching the pass
      // texture.
      auto texture = pass_context.GetTexture();
      if (!texture) {
        VALIDATION_LOG << "Failed to fetch the color texture in order to "
                          "apply an advanced blend.";
        return false;
      }

      FilterInput::Vector inputs = {
          FilterInput::Make(texture, element_entity.GetTransform().Invert()),
          FilterInput::Make(element_entity.GetContents())};
      auto contents =
          ColorFilterContents::MakeBlend(element_entity.GetBlendMode(), inputs);
      contents->SetCoverageHint(element_entity.GetCoverage());
      element_entity.SetContents(std::move(contents));
      element_entity.SetBlendMode(BlendMode::kSource);
    }
  }

  auto result = pass_context.GetRenderPass(pass_depth);
  if (!result.pass) {
    // Failure to produce a render pass should be explained by specific errors
    // in `InlinePassContext::GetRenderPass()`, so avoid log spam and don't
    // append a validation log here.
    return false;
  }

  // If the pass context returns a backdrop texture, we need to draw it to the
  // current pass. We do this because it's faster and takes significantly less
  // memory than storing/loading large MSAA textures. Also, it's not possible to
  // blit the non-MSAA resolve texture of the previous pass to MSAA textures
  // (let alone a transient one).
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
    msaa_backdrop_entity.SetClipDepth(std::numeric_limits<uint32_t>::max());
    if (!msaa_backdrop_entity.Render(renderer, *result.pass)) {
      VALIDATION_LOG << "Failed to render MSAA backdrop filter entity.";
      return false;
    }
  }

  if (result.just_created) {
    clip_coverage_stack.ActivateClipReplay();
  }

  // If there are any pending clips to replay, render any that may affect
  // the entity we're about to render.
  while (const EntityPassClipStack::ReplayResult* next_replay_clip =
             clip_coverage_stack.GetNextReplayResult(
                 element_entity.GetClipDepth())) {
    auto& replay_entity = next_replay_clip->entity;
    SetClipScissor(next_replay_clip->clip_coverage, *result.pass,
                   global_pass_position);
    if (!replay_entity.Render(renderer, *result.pass)) {
      VALIDATION_LOG << "Failed to render entity for clip replay.";
      return false;
    }
  }

  auto current_clip_coverage = clip_coverage_stack.CurrentClipCoverage();
  if (current_clip_coverage.has_value()) {
    // Entity transforms are relative to the current pass position, so we need
    // to check clip coverage in the same space.
    current_clip_coverage = current_clip_coverage->Shift(-global_pass_position);
  }

  if (!element_entity.ShouldRender(current_clip_coverage)) {
    return true;  // Nothing to render.
  }

  auto clip_coverage = element_entity.GetClipCoverage(current_clip_coverage);
  if (clip_coverage.coverage.has_value()) {
    clip_coverage.coverage =
        clip_coverage.coverage->Shift(global_pass_position);
  }

  // The coverage hint tells the rendered Contents which portion of the
  // rendered output will actually be used, and so we set this to the current
  // clip coverage (which is the max clip bounds). The contents may
  // optionally use this hint to avoid unnecessary rendering work.
  auto element_coverage_hint = element_entity.GetContents()->GetCoverageHint();
  element_entity.GetContents()->SetCoverageHint(
      Rect::Intersection(element_coverage_hint, current_clip_coverage));

  EntityPassClipStack::ClipStateResult clip_state_result =
      clip_coverage_stack.ApplyClipState(clip_coverage, element_entity,
                                         clip_height_floor,
                                         global_pass_position);

  if (clip_state_result.clip_did_change) {
    // We only need to update the pass scissor if the clip state has changed.
    SetClipScissor(clip_coverage_stack.CurrentClipCoverage(), *result.pass,
                   global_pass_position);
  }

  if (!clip_state_result.should_render) {
    return true;
  }

  if (!element_entity.Render(renderer, *result.pass)) {
    VALIDATION_LOG << "Failed to render entity.";
    return false;
  }
  return true;
}

bool EntityPass::OnRender(
    ContentContext& renderer,
    ISize root_pass_size,
    EntityPassTarget& pass_target,
    Point global_pass_position,
    Point local_pass_position,
    uint32_t pass_depth,
    EntityPassClipStack& clip_coverage_stack,
    size_t clip_height_floor,
    std::shared_ptr<Contents> backdrop_filter_contents,
    const std::optional<InlinePassContext::RenderPassResult>&
        collapsed_parent_pass) const {
  TRACE_EVENT0("impeller", "EntityPass::OnRender");

  if (!active_clips_.empty()) {
    VALIDATION_LOG << SPrintF(
        "EntityPass (Depth=%d) contains one or more clips with an unresolved "
        "depth value.",
        pass_depth);
  }

  InlinePassContext pass_context(renderer, pass_target, GetElementCount(),
                                 collapsed_parent_pass);
  if (!pass_context.IsValid()) {
    VALIDATION_LOG << SPrintF("Pass context invalid (Depth=%d)", pass_depth);
    return false;
  }
  auto clear_color_size = pass_target.GetRenderTarget().GetRenderTargetSize();

  if (!collapsed_parent_pass) {
    // Always force the pass to construct the render pass object, even if there
    // is not a clear color. This ensures that the attachment textures are
    // cleared/transitioned to the right state.
    pass_context.GetRenderPass(pass_depth);
  }

  if (backdrop_filter_proc_) {
    if (!backdrop_filter_contents) {
      VALIDATION_LOG
          << "EntityPass contains a backdrop filter, but no backdrop filter "
             "contents was supplied by the parent pass at render time. This is "
             "a bug in EntityPass. Parent passes are responsible for setting "
             "up backdrop filters for their children.";
      return false;
    }

    Entity backdrop_entity;
    backdrop_entity.SetContents(std::move(backdrop_filter_contents));
    backdrop_entity.SetTransform(
        Matrix::MakeTranslation(Vector3(-local_pass_position)));
    backdrop_entity.SetClipDepth(std::numeric_limits<uint32_t>::max());

    RenderElement(backdrop_entity, clip_height_floor, pass_context, pass_depth,
                  renderer, clip_coverage_stack, global_pass_position);
  }

  bool should_collapse_clear_colors =
      !collapsed_parent_pass &&
      // Backdrop filters act as a entity before
      // everything and disrupt the optimization.
      !backdrop_filter_proc_;

  // Count the number of elements eaten by the clear color optimization. Break
  // it down in terms of opaque and translucent elements so that we can skip
  // over these entities when applying the clear color optimization.
  size_t opaque_clear_entity_count = 0;
  size_t translucent_clear_entity_count = 0;
  if (should_collapse_clear_colors) {
    for (const auto& element : elements_) {
      if (const Entity* entity = std::get_if<Entity>(&element)) {
        std::optional<Color> entity_color =
            entity->AsBackgroundColor(clear_color_size);
        if (entity_color.has_value()) {
          if (entity->GetBlendMode() == BlendMode::kSource) {
            opaque_clear_entity_count++;
          } else {
            translucent_clear_entity_count++;
          }
          // We've found an entity that replaces the whole background color of
          // this layer, so continue counting.
          continue;
        }
      }
      // We came across an element that doesn't replace the background color of
      // this layer, so stop counting.
      break;
    }
  }

  using ElementCallback = std::function<bool(const Element&)>;
  using ElementIterator = std::function<bool(const ElementCallback&)>;

  ElementIterator element_iterator;

  if (renderer.GetDeviceCapabilities().SupportsFramebufferFetch()) {
    element_iterator =
        [this, &opaque_clear_entity_count,
         &translucent_clear_entity_count](const ElementCallback& callback) {
          const auto& sorted_elements = draw_order_resolver_.GetSortedDraws(
              opaque_clear_entity_count, translucent_clear_entity_count);

          for (const auto& element_ref : sorted_elements) {
            const Element& element = elements_[element_ref];
            if (!callback(element)) {
              return false;
            }
          }
          return true;
        };
  } else {
    // If framebuffer fetch isn't supported, just disable the draw order
    // optimization. We could technically make it work by flushing each time
    // we encounter an advanced blend at recording time down the road.
    element_iterator = [this, &opaque_clear_entity_count,
                        &translucent_clear_entity_count](
                           const ElementCallback& callback) {
      size_t skips = opaque_clear_entity_count + translucent_clear_entity_count;
      for (const auto& element : elements_) {
        if (skips > 0) {
          skips--;
          continue;
        }
        if (!callback(element)) {
          return false;
        }
      }
      return true;
    };
  }

  const auto& render_element = [&, this](Entity& entity) {
    return RenderElement(entity, clip_height_floor, pass_context, pass_depth,
                         renderer, clip_coverage_stack, global_pass_position);
  };

  std::optional<Entity> deferred_entity;
  bool result = element_iterator([&](const Element& element) {
    EntityResult result =
        GetEntityForElement(element,               // element
                            renderer,              // renderer
                            pass_context,          // pass_context
                            root_pass_size,        // root_pass_size
                            global_pass_position,  // global_pass_position
                            pass_depth,            // pass_depth
                            clip_coverage_stack,   // clip_coverage_stack
                            clip_height_floor);    // clip_height_floor

    switch (result.status) {
      case EntityResult::kSuccess:
        break;
      case EntityResult::kFailure:
        // All failure cases should be covered by specific validation messages
        // in `GetEntityForElement()`.
        return false;
      case EntityResult::kSkip:
        return true;
    };

    if (deferred_entity.has_value() &&
        result.entity.GetBlendMode() != BlendMode::kSource) {
      if (!render_element(*deferred_entity)) {
        return false;
      }
      deferred_entity.reset();
    }

    if (IsSubpass(element)) {
      if (deferred_entity.has_value()) {
        if (!render_element(*deferred_entity)) {
          return false;
        }
      }
      deferred_entity = std::move(result.entity);
      return true;
    }

    return render_element(result.entity);
  });
  if (!result) {
    return false;
  }

  if (deferred_entity.has_value() && !render_element(*deferred_entity)) {
    return false;
  }
  return true;
}

void EntityPass::IterateAllElements(
    const std::function<bool(Element&)>& iterator) {
  if (!iterator) {
    return;
  }

  for (auto& element : elements_) {
    if (!iterator(element)) {
      return;
    }
    if (auto subpass = std::get_if<std::unique_ptr<EntityPass>>(&element)) {
      subpass->get()->IterateAllElements(iterator);
    }
  }
}

void EntityPass::IterateAllElements(
    const std::function<bool(const Element&)>& iterator) const {
  /// TODO(gaaclarke): Remove duplication here between const and non-const
  /// versions.
  if (!iterator) {
    return;
  }

  for (auto& element : elements_) {
    if (!iterator(element)) {
      return;
    }
    if (auto subpass = std::get_if<std::unique_ptr<EntityPass>>(&element)) {
      const EntityPass* entity_pass = subpass->get();
      entity_pass->IterateAllElements(iterator);
    }
  }
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

void EntityPass::IterateAllEntities(
    const std::function<bool(const Entity&)>& iterator) const {
  if (!iterator) {
    return;
  }

  for (const auto& element : elements_) {
    if (auto entity = std::get_if<Entity>(&element)) {
      if (!iterator(*entity)) {
        return;
      }
      continue;
    }
    if (auto subpass = std::get_if<std::unique_ptr<EntityPass>>(&element)) {
      const EntityPass* entity_pass = subpass->get();
      entity_pass->IterateAllEntities(iterator);
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

void EntityPass::SetTransform(Matrix transform) {
  transform_ = transform;
}

void EntityPass::SetClipHeight(size_t clip_height) {
  clip_height_ = clip_height;
}

size_t EntityPass::GetClipHeight() const {
  return clip_height_;
}

void EntityPass::SetClipDepth(size_t clip_depth) {
  clip_depth_ = clip_depth;
}

uint32_t EntityPass::GetClipDepth() const {
  return clip_depth_;
}

void EntityPass::SetBlendMode(BlendMode blend_mode) {
  blend_mode_ = blend_mode;
  flood_clip_ = Entity::IsBlendModeDestructive(blend_mode);
}

Color EntityPass::GetClearColorOrDefault(ISize size) const {
  return GetClearColor(size).value_or(Color::BlackTransparent());
}

std::optional<Color> EntityPass::GetClearColor(ISize target_size) const {
  if (backdrop_filter_proc_) {
    return std::nullopt;
  }

  std::optional<Color> result = std::nullopt;
  for (const Element& element : elements_) {
    auto [entity_color, blend_mode] =
        ElementAsBackgroundColor(element, target_size);
    if (!entity_color.has_value()) {
      break;
    }
    result = result.value_or(Color::BlackTransparent())
                 .Blend(entity_color.value(), blend_mode);
  }
  if (result.has_value()) {
    return result->Premultiply();
  }
  return result;
}

void EntityPass::SetBackdropFilter(BackdropFilterProc proc) {
  if (superpass_) {
    VALIDATION_LOG << "Backdrop filters cannot be set on EntityPasses that "
                      "have already been appended to another pass.";
  }

  backdrop_filter_proc_ = std::move(proc);
}

}  // namespace impeller
