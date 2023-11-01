// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/entity_pass.h"

#include <memory>
#include <utility>
#include <variant>

#include "flutter/fml/closure.h"
#include "flutter/fml/logging.h"
#include "flutter/fml/trace_event.h"
#include "impeller/base/strings.h"
#include "impeller/base/validation.h"
#include "impeller/core/formats.h"
#include "impeller/entity/contents/clip_contents.h"
#include "impeller/entity/contents/content_context.h"
#include "impeller/entity/contents/filters/color_filter_contents.h"
#include "impeller/entity/contents/filters/inputs/filter_input.h"
#include "impeller/entity/contents/framebuffer_blend_contents.h"
#include "impeller/entity/contents/texture_contents.h"
#include "impeller/entity/entity.h"
#include "impeller/entity/inline_pass_context.h"
#include "impeller/geometry/color.h"
#include "impeller/geometry/rect.h"
#include "impeller/renderer/command_buffer.h"

#ifdef IMPELLER_DEBUG
#include "impeller/entity/contents/checkerboard_contents.h"
#endif  // IMPELLER_DEBUG

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

const std::string EntityPass::kCaptureDocumentName = "EntityPass";

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
      entity.GetContents()->IsOpaque()) {
    entity.SetBlendMode(BlendMode::kSource);
  }

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
    std::optional<Rect> coverage_limit) const {
  std::optional<Rect> accumulated_coverage;
  for (const auto& element : elements_) {
    std::optional<Rect> element_coverage;

    if (auto entity = std::get_if<Entity>(&element)) {
      element_coverage = entity->GetCoverage();

      // When the coverage limit is std::nullopt, that means there is no limit,
      // as opposed to empty coverage.
      if (element_coverage.has_value() && coverage_limit.has_value()) {
        const auto* filter = entity->GetContents()->AsFilter();
        if (!filter || filter->IsTranslationOnly()) {
          element_coverage =
              element_coverage->Intersection(coverage_limit.value());
        }
      }
    } else if (auto subpass_ptr =
                   std::get_if<std::unique_ptr<EntityPass>>(&element)) {
      auto& subpass = *subpass_ptr->get();

      std::optional<Rect> unfiltered_coverage =
          GetSubpassCoverage(subpass, std::nullopt);

      // If the current pass elements have any coverage so far and there's a
      // backdrop filter, then incorporate the backdrop filter in the
      // pre-filtered coverage of the subpass.
      if (accumulated_coverage.has_value() && subpass.backdrop_filter_proc_) {
        std::shared_ptr<FilterContents> backdrop_filter =
            subpass.backdrop_filter_proc_(
                FilterInput::Make(accumulated_coverage.value()),
                subpass.xformation_, Entity::RenderingMode::kSubpass);
        if (backdrop_filter) {
          auto backdrop_coverage = backdrop_filter->GetCoverage({});
          unfiltered_coverage =
              Rect::Union(unfiltered_coverage, backdrop_coverage);
        } else {
          VALIDATION_LOG << "The EntityPass backdrop filter proc didn't return "
                            "a valid filter.";
        }
      }

      if (!unfiltered_coverage.has_value()) {
        continue;
      }

      // Additionally, subpass textures may be passed through filters, which may
      // modify the coverage.
      //
      // Note that we currently only assume that ImageFilters (such as blurs and
      // matrix transforms) may modify coverage, although it's technically
      // possible ColorFilters to affect coverage as well. For example: A
      // ColorMatrixFilter could output a completely transparent result, and
      // we could potentially detect this case as zero coverage in the future.
      std::shared_ptr<FilterContents> image_filter =
          subpass.delegate_->WithImageFilter(*unfiltered_coverage,
                                             subpass.xformation_);
      if (image_filter) {
        Entity subpass_entity;
        subpass_entity.SetTransformation(subpass.xformation_);
        element_coverage = image_filter->GetCoverage(subpass_entity);
      } else {
        element_coverage = unfiltered_coverage;
      }

      element_coverage = Rect::Intersection(element_coverage, coverage_limit);
    } else {
      FML_UNREACHABLE();
    }

    accumulated_coverage = Rect::Union(accumulated_coverage, element_coverage);
  }
  return accumulated_coverage;
}

std::optional<Rect> EntityPass::GetSubpassCoverage(
    const EntityPass& subpass,
    std::optional<Rect> coverage_limit) const {
  std::shared_ptr<FilterContents> image_filter =
      subpass.delegate_->WithImageFilter(Rect(), subpass.xformation_);

  // If the subpass has an image filter, then its coverage space may deviate
  // from the parent pass and make intersecting with the pass coverage limit
  // unsafe.
  if (image_filter && coverage_limit.has_value()) {
    coverage_limit = image_filter->GetSourceCoverage(subpass.xformation_,
                                                     coverage_limit.value());
  }

  auto entities_coverage = subpass.GetElementsCoverage(coverage_limit);
  // The entities don't cover anything. There is nothing to do.
  if (!entities_coverage.has_value()) {
    return std::nullopt;
  }

  if (!subpass.bounds_limit_.has_value()) {
    return entities_coverage;
  }
  auto user_bounds_coverage =
      subpass.bounds_limit_->TransformBounds(subpass.xformation_);
  return entities_coverage->Intersection(user_bounds_coverage);
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

  if (pass->backdrop_filter_proc_) {
    backdrop_filter_reads_from_pass_texture_ += 1;
  }
  if (pass->blend_mode_ > Entity::kLastPipelineBlendMode) {
    advanced_blend_reads_from_pass_texture_ += 1;
  }

  auto subpass_pointer = pass.get();
  elements_.emplace_back(std::move(pass));
  return subpass_pointer;
}

void EntityPass::AddSubpassInline(std::unique_ptr<EntityPass> pass) {
  if (!pass) {
    return;
  }
  FML_DCHECK(pass->superpass_ == nullptr);

  elements_.insert(elements_.end(),
                   std::make_move_iterator(pass->elements_.begin()),
                   std::make_move_iterator(pass->elements_.end()));

  backdrop_filter_reads_from_pass_texture_ +=
      pass->backdrop_filter_reads_from_pass_texture_;
  advanced_blend_reads_from_pass_texture_ +=
      pass->advanced_blend_reads_from_pass_texture_;
}

static const constexpr RenderTarget::AttachmentConfig kDefaultStencilConfig =
    RenderTarget::AttachmentConfig{
        .storage_mode = StorageMode::kDeviceTransient,
        .load_action = LoadAction::kDontCare,
        .store_action = StoreAction::kDontCare,
    };

static EntityPassTarget CreateRenderTarget(ContentContext& renderer,
                                           ISize size,
                                           const Color& clear_color) {
  auto context = renderer.GetContext();

  /// All of the load/store actions are managed by `InlinePassContext` when
  /// `RenderPasses` are created, so we just set them to `kDontCare` here.
  /// What's important is the `StorageMode` of the textures, which cannot be
  /// changed for the lifetime of the textures.

  RenderTarget target;
  if (context->GetCapabilities()->SupportsOffscreenMSAA()) {
    target = RenderTarget::CreateOffscreenMSAA(
        *context,                          // context
        *renderer.GetRenderTargetCache(),  // allocator
        size,                              // size
        "EntityPass",                      // label
        RenderTarget::AttachmentConfigMSAA{
            .storage_mode = StorageMode::kDeviceTransient,
            .resolve_storage_mode = StorageMode::kDevicePrivate,
            .load_action = LoadAction::kDontCare,
            .store_action = StoreAction::kMultisampleResolve,
            .clear_color = clear_color},  // color_attachment_config
        kDefaultStencilConfig             // stencil_attachment_config
    );
  } else {
    target = RenderTarget::CreateOffscreen(
        *context,                          // context
        *renderer.GetRenderTargetCache(),  // allocator
        size,                              // size
        "EntityPass",                      // label
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
  auto capture =
      renderer.GetContext()->capture.GetDocument(kCaptureDocumentName);

  renderer.GetRenderTargetCache()->Start();

  auto root_render_target = render_target;

  if (root_render_target.GetColorAttachments().find(0u) ==
      root_render_target.GetColorAttachments().end()) {
    VALIDATION_LOG << "The root RenderTarget must have a color attachment.";
    return false;
  }

  capture.AddRect("Coverage",
                  Rect::MakeSize(root_render_target.GetRenderTargetSize()),
                  {.readonly = true});

  fml::ScopedCleanupClosure reset_state([&renderer]() {
    renderer.GetLazyGlyphAtlas()->ResetTextFrames();
    renderer.GetRenderTargetCache()->End();
  });

  IterateAllEntities([lazy_glyph_atlas =
                          renderer.GetLazyGlyphAtlas()](const Entity& entity) {
    if (auto contents = entity.GetContents()) {
      contents->PopulateGlyphAtlas(lazy_glyph_atlas, entity.DeriveTextScale());
    }
    return true;
  });

  ClipCoverageStack clip_coverage_stack = {ClipCoverageLayer{
      .coverage = Rect::MakeSize(root_render_target.GetRenderTargetSize()),
      .clip_depth = 0}};

  bool supports_onscreen_backdrop_reads =
      renderer.GetDeviceCapabilities().SupportsReadFromOnscreenTexture() &&
      // If the backend doesn't have `SupportsReadFromResolve`, we need to flip
      // between two textures when restoring a previous MSAA pass.
      renderer.GetDeviceCapabilities().SupportsReadFromResolve();
  bool reads_from_onscreen_backdrop = GetTotalPassReads(renderer) > 0;
  // In this branch path, we need to render everything to an offscreen texture
  // and then blit the results onto the onscreen texture. If using this branch,
  // there's no need to set up a stencil attachment on the root render target.
  if (!supports_onscreen_backdrop_reads && reads_from_onscreen_backdrop) {
    auto offscreen_target =
        CreateRenderTarget(renderer, root_render_target.GetRenderTargetSize(),
                           GetClearColor(render_target.GetRenderTargetSize()));

    if (!OnRender(renderer,  // renderer
                  capture,   // capture
                  offscreen_target.GetRenderTarget()
                      .GetRenderTargetSize(),  // root_pass_size
                  offscreen_target,            // pass_target
                  Point(),                     // global_pass_position
                  Point(),                     // local_pass_position
                  0,                           // pass_depth
                  clip_coverage_stack          // clip_coverage_stack
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

        entity.Render(renderer, *render_pass);
      }

      if (!render_pass->EncodeCommands()) {
        VALIDATION_LOG << "Failed to encode root pass command buffer.";
        return false;
      }
    }
    if (!command_buffer->SubmitCommands()) {
      VALIDATION_LOG << "Failed to submit root pass command buffer.";
      return false;
    }

    return true;
  }

  // If we make it this far, that means the context is capable of rendering
  // everything directly to the onscreen texture.

  // The safety check for fetching this color attachment is at the beginning of
  // this method.
  auto color0 = root_render_target.GetColorAttachments().find(0u)->second;

  // If a root stencil was provided by the caller, then verify that it has a
  // configuration which can be used to render this pass.
  auto stencil_attachment = root_render_target.GetStencilAttachment();
  if (stencil_attachment.has_value()) {
    auto stencil_texture = stencil_attachment->texture;
    if (!stencil_texture) {
      VALIDATION_LOG << "The root RenderTarget must have a stencil texture.";
      return false;
    }

    auto stencil_storage_mode =
        stencil_texture->GetTextureDescriptor().storage_mode;
    if (reads_from_onscreen_backdrop &&
        stencil_storage_mode == StorageMode::kDeviceTransient) {
      VALIDATION_LOG << "The given root RenderTarget stencil needs to be read, "
                        "but it's marked as transient.";
      return false;
    }
  }
  // Setup a new root stencil with an optimal configuration if one wasn't
  // provided by the caller.
  else {
    root_render_target.SetupStencilAttachment(
        *renderer.GetContext(), *renderer.GetRenderTargetCache(),
        color0.texture->GetSize(),
        renderer.GetContext()->GetCapabilities()->SupportsOffscreenMSAA(),
        "ImpellerOnscreen", kDefaultStencilConfig);
  }

  // Set up the clear color of the root pass.
  color0.clear_color = GetClearColor(render_target.GetRenderTargetSize());
  root_render_target.SetColorAttachment(color0, 0);

  EntityPassTarget pass_target(
      root_render_target,
      renderer.GetDeviceCapabilities().SupportsReadFromResolve());

  return OnRender(                               //
      renderer,                                  // renderer
      capture,                                   // capture
      root_render_target.GetRenderTargetSize(),  // root_pass_size
      pass_target,                               // pass_target
      Point(),                                   // global_pass_position
      Point(),                                   // local_pass_position
      0,                                         // pass_depth
      clip_coverage_stack);                      // clip_coverage_stack
}

EntityPass::EntityResult EntityPass::GetEntityForElement(
    const EntityPass::Element& element,
    ContentContext& renderer,
    Capture& capture,
    InlinePassContext& pass_context,
    ISize root_pass_size,
    Point global_pass_position,
    uint32_t pass_depth,
    ClipCoverageStack& clip_coverage_stack,
    size_t clip_depth_floor) const {
  Entity element_entity;

  //--------------------------------------------------------------------------
  /// Setup entity element.
  ///
  if (const auto& entity = std::get_if<Entity>(&element)) {
    element_entity = *entity;
    element_entity.SetCapture(capture.CreateChild("Entity"));

    if (!global_pass_position.IsZero()) {
      // If the pass image is going to be rendered with a non-zero position,
      // apply the negative translation to entity copies before rendering them
      // so that they'll end up rendering to the correct on-screen position.
      element_entity.SetTransformation(
          Matrix::MakeTranslation(Vector3(-global_pass_position)) *
          element_entity.GetTransformation());
    }
    return EntityPass::EntityResult::Success(element_entity);
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
      auto subpass_capture = capture.CreateChild("EntityPass (Collapsed)");
      // Directly render into the parent target and move on.
      if (!subpass->OnRender(
              renderer,                      // renderer
              subpass_capture,               // capture
              root_pass_size,                // root_pass_size
              pass_context.GetPassTarget(),  // pass_target
              global_pass_position,          // global_pass_position
              Point(),                       // local_pass_position
              pass_depth,                    // pass_depth
              clip_coverage_stack,           // clip_coverage_stack
              clip_depth_,                   // clip_depth_floor
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
      subpass_backdrop_filter_contents =
          proc(FilterInput::Make(std::move(texture)),
               subpass->xformation_.Basis(), Entity::RenderingMode::kSubpass);

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

    if (clip_coverage_stack.empty()) {
      // The current clip is empty. This means the pass texture won't be
      // visible, so skip it.
      capture.CreateChild("Subpass Entity (Skipped: Empty clip A)");
      return EntityPass::EntityResult::Skip();
    }
    auto clip_coverage_back = clip_coverage_stack.back().coverage;
    if (!clip_coverage_back.has_value()) {
      capture.CreateChild("Subpass Entity (Skipped: Empty clip B)");
      return EntityPass::EntityResult::Skip();
    }

    // The maximum coverage of the subpass. Subpasses textures should never
    // extend outside the parent pass texture or the current clip coverage.
    auto coverage_limit =
        Rect(global_pass_position, Size(pass_context.GetPassTarget()
                                            .GetRenderTarget()
                                            .GetRenderTargetSize()))
            .Intersection(clip_coverage_back.value());
    if (!coverage_limit.has_value()) {
      capture.CreateChild("Subpass Entity (Skipped: Empty coverage limit A)");
      return EntityPass::EntityResult::Skip();
    }

    coverage_limit =
        coverage_limit->Intersection(Rect::MakeSize(root_pass_size));
    if (!coverage_limit.has_value()) {
      capture.CreateChild("Subpass Entity (Skipped: Empty coverage limit B)");
      return EntityPass::EntityResult::Skip();
    }

    auto subpass_coverage =
        (subpass->flood_clip_ || subpass_backdrop_filter_contents)
            ? coverage_limit
            : GetSubpassCoverage(*subpass, coverage_limit);
    if (!subpass_coverage.has_value()) {
      capture.CreateChild("Subpass Entity (Skipped: Empty subpass coverage A)");
      return EntityPass::EntityResult::Skip();
    }

    subpass_coverage = Rect::RoundOut(subpass_coverage.value());

    auto subpass_size = ISize(subpass_coverage->size);
    if (subpass_size.IsEmpty()) {
      capture.CreateChild("Subpass Entity (Skipped: Empty subpass coverage B)");
      return EntityPass::EntityResult::Skip();
    }

    auto subpass_target = CreateRenderTarget(
        renderer,                               // renderer
        subpass_size,                           // size
        subpass->GetClearColor(subpass_size));  // clear_color

    if (!subpass_target.IsValid()) {
      VALIDATION_LOG << "Subpass render target is invalid.";
      return EntityPass::EntityResult::Failure();
    }

    auto subpass_capture = capture.CreateChild("EntityPass");
    subpass_capture.AddRect("Coverage", *subpass_coverage, {.readonly = true});

    // Start non-collapsed subpasses with a fresh clip coverage stack limited by
    // the subpass coverage. This is important because image filters applied to
    // save layers may transform the subpass texture after it's rendered,
    // causing parent clip coverage to get misaligned with the actual area that
    // the subpass will affect in the parent pass.
    ClipCoverageStack subpass_clip_coverage_stack = {ClipCoverageLayer{
        .coverage = subpass_coverage, .clip_depth = subpass->clip_depth_}};

    // Stencil textures aren't shared between EntityPasses (as much of the
    // time they are transient).
    if (!subpass->OnRender(
            renderer,                  // renderer
            subpass_capture,           // capture
            root_pass_size,            // root_pass_size
            subpass_target,            // pass_target
            subpass_coverage->origin,  // global_pass_position
            subpass_coverage->origin -
                global_pass_position,         // local_pass_position
            ++pass_depth,                     // pass_depth
            subpass_clip_coverage_stack,      // clip_coverage_stack
            subpass->clip_depth_,             // clip_depth_floor
            subpass_backdrop_filter_contents  // backdrop_filter_contents
            )) {
      // Validation error messages are triggered for all `OnRender()` failure
      // cases.
      return EntityPass::EntityResult::Failure();
    }

    // The subpass target's texture may have changed during OnRender.
    auto subpass_texture =
        subpass_target.GetRenderTarget().GetRenderTargetTexture();

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
    Capture subpass_texture_capture =
        capture.CreateChild("Entity (Subpass texture)");
    element_entity.SetCapture(subpass_texture_capture);
    element_entity.SetContents(std::move(offscreen_texture_contents));
    element_entity.SetClipDepth(subpass->clip_depth_);
    element_entity.SetBlendMode(subpass->blend_mode_);
    element_entity.SetTransformation(subpass_texture_capture.AddMatrix(
        "Transform", Matrix::MakeTranslation(Vector3(subpass_coverage->origin -
                                                     global_pass_position))));

    return EntityPass::EntityResult::Success(element_entity);
  }
  FML_UNREACHABLE();
}

bool EntityPass::RenderElement(Entity& element_entity,
                               size_t clip_depth_floor,
                               InlinePassContext& pass_context,
                               int32_t pass_depth,
                               ContentContext& renderer,
                               ClipCoverageStack& clip_coverage_stack,
                               Point global_pass_position) const {
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
    // Restore any clips that were recorded before the backdrop filter was
    // applied.
    auto& replay_entities = clip_replay_->GetReplayEntities();
    for (const auto& entity : replay_entities) {
      if (!entity.Render(renderer, *result.pass)) {
        VALIDATION_LOG << "Failed to render entity for clip restore.";
      }
    }

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
      VALIDATION_LOG << "Failed to render MSAA backdrop filter entity.";
      return false;
    }
  }

  auto current_clip_coverage = clip_coverage_stack.back().coverage;
  if (current_clip_coverage.has_value()) {
    // Entity transforms are relative to the current pass position, so we need
    // to check clip coverage in the same space.
    current_clip_coverage->origin -= global_pass_position;
  }

  if (!element_entity.ShouldRender(current_clip_coverage)) {
    return true;  // Nothing to render.
  }

  auto clip_coverage = element_entity.GetClipCoverage(current_clip_coverage);
  if (clip_coverage.coverage.has_value()) {
    clip_coverage.coverage->origin += global_pass_position;
  }

  // The coverage hint tells the rendered Contents which portion of the
  // rendered output will actually be used, and so we set this to the current
  // clip coverage (which is the max clip bounds). The contents may
  // optionally use this hint to avoid unnecessary rendering work.
  auto element_coverage_hint = element_entity.GetContents()->GetCoverageHint();
  element_entity.GetContents()->SetCoverageHint(
      Rect::Intersection(element_coverage_hint, current_clip_coverage));

  switch (clip_coverage.type) {
    case Contents::ClipCoverage::Type::kNoChange:
      break;
    case Contents::ClipCoverage::Type::kAppend: {
      auto op = clip_coverage_stack.back().coverage;
      clip_coverage_stack.push_back(
          ClipCoverageLayer{.coverage = clip_coverage.coverage,
                            .clip_depth = element_entity.GetClipDepth() + 1});
      FML_DCHECK(clip_coverage_stack.back().clip_depth ==
                 clip_coverage_stack.front().clip_depth +
                     clip_coverage_stack.size() - 1);

      if (!op.has_value()) {
        // Running this append op won't impact the clip buffer because the
        // whole screen is already being clipped, so skip it.
        return true;
      }
    } break;
    case Contents::ClipCoverage::Type::kRestore: {
      if (clip_coverage_stack.back().clip_depth <=
          element_entity.GetClipDepth()) {
        // Drop clip restores that will do nothing.
        return true;
      }

      auto restoration_index = element_entity.GetClipDepth() -
                               clip_coverage_stack.front().clip_depth;
      FML_DCHECK(restoration_index < clip_coverage_stack.size());

      // We only need to restore the area that covers the coverage of the
      // clip rect at target depth + 1.
      std::optional<Rect> restore_coverage =
          (restoration_index + 1 < clip_coverage_stack.size())
              ? clip_coverage_stack[restoration_index + 1].coverage
              : std::nullopt;
      if (restore_coverage.has_value()) {
        // Make the coverage rectangle relative to the current pass.
        restore_coverage->origin -= global_pass_position;
      }
      clip_coverage_stack.resize(restoration_index + 1);

      if (!clip_coverage_stack.back().coverage.has_value()) {
        // Running this restore op won't make anything renderable, so skip it.
        return true;
      }

      auto restore_contents =
          static_cast<ClipRestoreContents*>(element_entity.GetContents().get());
      restore_contents->SetRestoreCoverage(restore_coverage);

    } break;
  }

#ifdef IMPELLER_ENABLE_CAPTURE
  {
    auto element_entity_coverage = element_entity.GetCoverage();
    if (element_entity_coverage.has_value()) {
      element_entity_coverage->origin += global_pass_position;
      element_entity.GetCapture().AddRect("Coverage", *element_entity_coverage,
                                          {.readonly = true});
    }
  }
#endif

  element_entity.SetClipDepth(element_entity.GetClipDepth() - clip_depth_floor);
  clip_replay_->RecordEntity(element_entity, clip_coverage.type);
  if (!element_entity.Render(renderer, *result.pass)) {
    VALIDATION_LOG << "Failed to render entity.";
    return false;
  }
  return true;
}

bool EntityPass::OnRender(
    ContentContext& renderer,
    Capture& capture,
    ISize root_pass_size,
    EntityPassTarget& pass_target,
    Point global_pass_position,
    Point local_pass_position,
    uint32_t pass_depth,
    ClipCoverageStack& clip_coverage_stack,
    size_t clip_depth_floor,
    std::shared_ptr<Contents> backdrop_filter_contents,
    const std::optional<InlinePassContext::RenderPassResult>&
        collapsed_parent_pass) const {
  TRACE_EVENT0("impeller", "EntityPass::OnRender");

  auto context = renderer.GetContext();
  InlinePassContext pass_context(
      context, pass_target, GetTotalPassReads(renderer), collapsed_parent_pass);
  if (!pass_context.IsValid()) {
    VALIDATION_LOG << SPrintF("Pass context invalid (Depth=%d)", pass_depth);
    return false;
  }
  auto clear_color_size = pass_target.GetRenderTarget().GetRenderTargetSize();

  if (!collapsed_parent_pass &&
      !GetClearColor(clear_color_size).IsTransparent()) {
    // Force the pass context to create at least one new pass if the clear color
    // is present.
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
    backdrop_entity.SetTransformation(
        Matrix::MakeTranslation(Vector3(-local_pass_position)));
    backdrop_entity.SetClipDepth(clip_depth_floor);

    RenderElement(backdrop_entity, clip_depth_floor, pass_context, pass_depth,
                  renderer, clip_coverage_stack, global_pass_position);
  }

  bool is_collapsing_clear_colors = !collapsed_parent_pass &&
                                    // Backdrop filters act as a entity before
                                    // everything and disrupt the optimization.
                                    !backdrop_filter_proc_;
  for (const auto& element : elements_) {
    // Skip elements that are incorporated into the clear color.
    if (is_collapsing_clear_colors) {
      auto [entity_color, _] =
          ElementAsBackgroundColor(element, clear_color_size);
      if (entity_color.has_value()) {
        continue;
      }
      is_collapsing_clear_colors = false;
    }

    EntityResult result =
        GetEntityForElement(element,               // element
                            renderer,              // renderer
                            capture,               // capture
                            pass_context,          // pass_context
                            root_pass_size,        // root_pass_size
                            global_pass_position,  // global_pass_position
                            pass_depth,            // pass_depth
                            clip_coverage_stack,   // clip_coverage_stack
                            clip_depth_floor);     // clip_depth_floor

    switch (result.status) {
      case EntityResult::kSuccess:
        break;
      case EntityResult::kFailure:
        // All failure cases should be covered by specific validation messages
        // in `GetEntityForElement()`.
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
          VALIDATION_LOG
              << "Failed to end the current render pass in order to read from "
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
            FilterInput::Make(texture,
                              result.entity.GetTransformation().Invert()),
            FilterInput::Make(result.entity.GetContents())};
        auto contents = ColorFilterContents::MakeBlend(
            result.entity.GetBlendMode(), inputs);
        contents->SetCoverageHint(result.entity.GetCoverage());
        result.entity.SetContents(std::move(contents));
        result.entity.SetBlendMode(BlendMode::kSource);
      }
    }

    //--------------------------------------------------------------------------
    /// Render the Element.
    ///
    if (!RenderElement(result.entity, clip_depth_floor, pass_context,
                       pass_depth, renderer, clip_coverage_stack,
                       global_pass_position)) {
      // Specific validation logs are handled in `render_element()`.
      return false;
    }
  }

#ifdef IMPELLER_DEBUG
  //--------------------------------------------------------------------------
  /// Draw debug checkerboard over offscreen textures.
  ///

  // When the pass depth is > 0, this EntityPass is being rendered to an
  // offscreen texture.
  if (enable_offscreen_debug_checkerboard_ &&
      !collapsed_parent_pass.has_value() && pass_depth > 0) {
    auto result = pass_context.GetRenderPass(pass_depth);
    if (!result.pass) {
      // Failure to produce a render pass should be explained by specific errors
      // in `InlinePassContext::GetRenderPass()`.
      return false;
    }
    auto checkerboard = CheckerboardContents();
    auto color = ColorHSB(0,                                    // hue
                          1,                                    // saturation
                          std::max(0.0, 0.6 - pass_depth / 5),  // brightness
                          0.25);                                // alpha
    checkerboard.SetColor(Color(color));
    checkerboard.Render(renderer, {}, *result.pass);
  }
#endif

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
  pass->backdrop_filter_reads_from_pass_texture_ =
      backdrop_filter_reads_from_pass_texture_;
  pass->advanced_blend_reads_from_pass_texture_ =
      advanced_blend_reads_from_pass_texture_;
  pass->backdrop_filter_proc_ = backdrop_filter_proc_;
  pass->blend_mode_ = blend_mode_;
  pass->delegate_ = delegate_;
  // Note: I tried also adding flood clip and bounds limit but one of the
  // two caused rendering in wonderous to break. It's 10:51 PM, and I'm
  // ready to move on.
  return pass;
}

void EntityPass::SetTransformation(Matrix xformation) {
  xformation_ = xformation;
}

void EntityPass::SetClipDepth(size_t clip_depth) {
  clip_depth_ = clip_depth;
}

size_t EntityPass::GetClipDepth() {
  return clip_depth_;
}

void EntityPass::SetBlendMode(BlendMode blend_mode) {
  blend_mode_ = blend_mode;
  flood_clip_ = Entity::IsBlendModeDestructive(blend_mode);
}

Color EntityPass::GetClearColor(ISize target_size) const {
  Color result = Color::BlackTransparent();
  if (backdrop_filter_proc_) {
    return result;
  }

  for (const Element& element : elements_) {
    auto [entity_color, blend_mode] =
        ElementAsBackgroundColor(element, target_size);
    if (!entity_color.has_value()) {
      break;
    }
    result = result.Blend(entity_color.value(), blend_mode);
  }
  return result.Premultiply();
}

void EntityPass::SetBackdropFilter(BackdropFilterProc proc) {
  if (superpass_) {
    VALIDATION_LOG << "Backdrop filters cannot be set on EntityPasses that "
                      "have already been appended to another pass.";
  }

  backdrop_filter_proc_ = std::move(proc);
}

void EntityPass::SetEnableOffscreenCheckerboard(bool enabled) {
  enable_offscreen_debug_checkerboard_ = enabled;
}

EntityPassClipRecorder::EntityPassClipRecorder() {}

void EntityPassClipRecorder::RecordEntity(const Entity& entity,
                                          Contents::ClipCoverage::Type type) {
  switch (type) {
    case Contents::ClipCoverage::Type::kNoChange:
      return;
    case Contents::ClipCoverage::Type::kAppend:
      rendered_clip_entities_.push_back(entity);
      break;
    case Contents::ClipCoverage::Type::kRestore:
      rendered_clip_entities_.pop_back();
      break;
  }
}

const std::vector<Entity>& EntityPassClipRecorder::GetReplayEntities() const {
  return rendered_clip_entities_;
}

}  // namespace impeller
