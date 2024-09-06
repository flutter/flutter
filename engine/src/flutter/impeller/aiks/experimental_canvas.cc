// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/aiks/experimental_canvas.h"

#include <limits>
#include <optional>

#include "fml/logging.h"
#include "fml/trace_event.h"
#include "impeller/aiks/canvas.h"
#include "impeller/aiks/paint_pass_delegate.h"
#include "impeller/base/validation.h"
#include "impeller/core/allocator.h"
#include "impeller/core/formats.h"
#include "impeller/entity/contents/clip_contents.h"
#include "impeller/entity/contents/filters/filter_contents.h"
#include "impeller/entity/contents/framebuffer_blend_contents.h"
#include "impeller/entity/contents/text_contents.h"
#include "impeller/entity/entity.h"
#include "impeller/entity/entity_pass_clip_stack.h"
#include "impeller/entity/save_layer_utils.h"
#include "impeller/geometry/color.h"
#include "impeller/renderer/render_target.h"

namespace impeller {

namespace {

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

static void ApplyFramebufferBlend(Entity& entity) {
  auto src_contents = entity.GetContents();
  auto contents = std::make_shared<FramebufferBlendContents>();
  contents->SetChildContents(src_contents);
  contents->SetBlendMode(entity.GetBlendMode());
  entity.SetContents(std::move(contents));
  entity.SetBlendMode(BlendMode::kSource);
}

/// End the current render pass, saving the result as a texture, and then
/// restart it with the backdrop cleared to the previous contents.
///
/// This method is used to set up the input for emulated advanced blends and
/// backdrop filters.
///
/// Returns the previous render pass stored as a texture, or nullptr if there
/// was a validation failure.
static std::shared_ptr<Texture> FlipBackdrop(
    std::vector<LazyRenderingConfig>& render_passes,
    Point global_pass_position,
    EntityPassClipStack& clip_coverage_stack,
    ContentContext& renderer) {
  auto rendering_config = std::move(render_passes.back());
  render_passes.pop_back();

  // If the very first thing we render in this EntityPass is a subpass that
  // happens to have a backdrop filter or advanced blend, than that backdrop
  // filter/blend will sample from an uninitialized texture.
  //
  // By calling `pass_context.GetRenderPass` here, we force the texture to pass
  // through at least one RenderPass with the correct clear configuration before
  // any sampling occurs.
  //
  // In cases where there are no contents, we
  // could instead check the clear color and initialize a 1x2 CPU texture
  // instead of ending the pass.
  rendering_config.inline_pass_context->GetRenderPass(0);
  if (!rendering_config.inline_pass_context->EndPass()) {
    VALIDATION_LOG
        << "Failed to end the current render pass in order to read from "
           "the backdrop texture and apply an advanced blend or backdrop "
           "filter.";
    // Note: adding this render pass ensures there are no later crashes from
    // unbalanced save layers. Ideally, this method would return false and the
    // renderer could handle that by terminating dispatch.
    render_passes.push_back(LazyRenderingConfig(
        renderer, std::move(rendering_config.entity_pass_target),
        std::move(rendering_config.inline_pass_context)));
    return nullptr;
  }

  std::shared_ptr<Texture> input_texture =
      rendering_config.inline_pass_context->GetTexture();

  if (!input_texture) {
    VALIDATION_LOG << "Failed to fetch the color texture in order to "
                      "apply an advanced blend or backdrop filter.";

    // Note: see above.
    render_passes.push_back(LazyRenderingConfig(
        renderer, std::move(rendering_config.entity_pass_target),
        std::move(rendering_config.inline_pass_context)));
    return nullptr;
  }

  render_passes.push_back(LazyRenderingConfig(
      renderer, std::move(rendering_config.entity_pass_target),
      std::move(rendering_config.inline_pass_context)));
  // Eagerly restore the BDF contents.

  // If the pass context returns a backdrop texture, we need to draw it to the
  // current pass. We do this because it's faster and takes significantly less
  // memory than storing/loading large MSAA textures. Also, it's not possible
  // to blit the non-MSAA resolve texture of the previous pass to MSAA
  // textures (let alone a transient one).
  Rect size_rect = Rect::MakeSize(input_texture->GetSize());
  auto msaa_backdrop_contents = TextureContents::MakeRect(size_rect);
  msaa_backdrop_contents->SetStencilEnabled(false);
  msaa_backdrop_contents->SetLabel("MSAA backdrop");
  msaa_backdrop_contents->SetSourceRect(size_rect);
  msaa_backdrop_contents->SetTexture(input_texture);

  Entity msaa_backdrop_entity;
  msaa_backdrop_entity.SetContents(std::move(msaa_backdrop_contents));
  msaa_backdrop_entity.SetBlendMode(BlendMode::kSource);
  msaa_backdrop_entity.SetClipDepth(std::numeric_limits<uint32_t>::max());
  if (!msaa_backdrop_entity.Render(
          renderer,
          *render_passes.back().inline_pass_context->GetRenderPass(0).pass)) {
    VALIDATION_LOG << "Failed to render MSAA backdrop entity.";
    return nullptr;
  }

  // Restore any clips that were recorded before the backdrop filter was
  // applied.
  auto& replay_entities = clip_coverage_stack.GetReplayEntities();
  for (const auto& replay : replay_entities) {
    SetClipScissor(
        replay.clip_coverage,
        *render_passes.back().inline_pass_context->GetRenderPass(0).pass,
        global_pass_position);
    if (!replay.entity.Render(
            renderer,
            *render_passes.back().inline_pass_context->GetRenderPass(0).pass)) {
      VALIDATION_LOG << "Failed to render entity for clip restore.";
    }
  }

  return input_texture;
}

}  // namespace

static const constexpr RenderTarget::AttachmentConfig kDefaultStencilConfig =
    RenderTarget::AttachmentConfig{
        .storage_mode = StorageMode::kDeviceTransient,
        .load_action = LoadAction::kDontCare,
        .store_action = StoreAction::kDontCare,
    };

static std::unique_ptr<EntityPassTarget> CreateRenderTarget(
    ContentContext& renderer,
    ISize size,
    const Color& clear_color) {
  const std::shared_ptr<Context>& context = renderer.GetContext();

  /// All of the load/store actions are managed by `InlinePassContext` when
  /// `RenderPasses` are created, so we just set them to `kDontCare` here.
  /// What's important is the `StorageMode` of the textures, which cannot be
  /// changed for the lifetime of the textures.

  RenderTarget target;
  if (context->GetCapabilities()->SupportsOffscreenMSAA()) {
    target = renderer.GetRenderTargetCache()->CreateOffscreenMSAA(
        /*context=*/*context,
        /*size=*/size,
        /*mip_count=*/1,
        /*label=*/"EntityPass",
        /*color_attachment_config=*/
        RenderTarget::AttachmentConfigMSAA{
            .storage_mode = StorageMode::kDeviceTransient,
            .resolve_storage_mode = StorageMode::kDevicePrivate,
            .load_action = LoadAction::kDontCare,
            .store_action = StoreAction::kMultisampleResolve,
            .clear_color = clear_color},
        /*stencil_attachment_config=*/kDefaultStencilConfig);
  } else {
    target = renderer.GetRenderTargetCache()->CreateOffscreen(
        *context,  // context
        size,      // size
        /*mip_count=*/1,
        "EntityPass",  // label
        RenderTarget::AttachmentConfig{
            .storage_mode = StorageMode::kDevicePrivate,
            .load_action = LoadAction::kDontCare,
            .store_action = StoreAction::kDontCare,
            .clear_color = clear_color,
        },                     // color_attachment_config
        kDefaultStencilConfig  //
    );
  }

  return std::make_unique<EntityPassTarget>(
      target, renderer.GetDeviceCapabilities().SupportsReadFromResolve(),
      renderer.GetDeviceCapabilities().SupportsImplicitResolvingMSAA());
}

ExperimentalCanvas::ExperimentalCanvas(ContentContext& renderer,
                                       RenderTarget& render_target,
                                       bool requires_readback)
    : Canvas(),
      renderer_(renderer),
      render_target_(render_target),
      requires_readback_(requires_readback),
      clip_coverage_stack_(EntityPassClipStack(
          Rect::MakeSize(render_target.GetRenderTargetSize()))) {
  SetupRenderPass();
}

ExperimentalCanvas::ExperimentalCanvas(ContentContext& renderer,
                                       RenderTarget& render_target,
                                       bool requires_readback,
                                       Rect cull_rect)
    : Canvas(cull_rect),
      renderer_(renderer),
      render_target_(render_target),
      requires_readback_(requires_readback),
      clip_coverage_stack_(EntityPassClipStack(
          Rect::MakeSize(render_target.GetRenderTargetSize()))) {
  SetupRenderPass();
}

ExperimentalCanvas::ExperimentalCanvas(ContentContext& renderer,
                                       RenderTarget& render_target,
                                       bool requires_readback,
                                       IRect cull_rect)
    : Canvas(cull_rect),
      renderer_(renderer),
      render_target_(render_target),
      requires_readback_(requires_readback),
      clip_coverage_stack_(EntityPassClipStack(
          Rect::MakeSize(render_target.GetRenderTargetSize()))) {
  SetupRenderPass();
}

void ExperimentalCanvas::SetupRenderPass() {
  renderer_.GetRenderTargetCache()->Start();
  auto color0 = render_target_.GetColorAttachments().find(0u)->second;

  auto& stencil_attachment = render_target_.GetStencilAttachment();
  auto& depth_attachment = render_target_.GetDepthAttachment();
  if (!stencil_attachment.has_value() || !depth_attachment.has_value()) {
    // Setup a new root stencil with an optimal configuration if one wasn't
    // provided by the caller.
    render_target_.SetupDepthStencilAttachments(
        *renderer_.GetContext(),
        *renderer_.GetContext()->GetResourceAllocator(),
        color0.texture->GetSize(),
        renderer_.GetContext()->GetCapabilities()->SupportsOffscreenMSAA(),
        "ImpellerOnscreen", kDefaultStencilConfig);
  }

  // Set up the clear color of the root pass.
  color0.clear_color = Color::BlackTransparent();
  render_target_.SetColorAttachment(color0, 0);

  // If requires_readback is true, then there is a backdrop filter or emulated
  // advanced blend in the first save layer. This requires a readback, which
  // isn't supported by onscreen textures. To support this, we immediately begin
  // a second save layer with the same dimensions as the onscreen. When
  // rendering is completed, we must blit this saveLayer to the onscreen.
  if (requires_readback_) {
    auto entity_pass_target =
        CreateRenderTarget(renderer_,                  //
                           color0.texture->GetSize(),  //
                           /*clear_color=*/Color::BlackTransparent());
    render_passes_.push_back(
        LazyRenderingConfig(renderer_, std::move(entity_pass_target)));
  } else {
    auto entity_pass_target = std::make_unique<EntityPassTarget>(
        render_target_,                                                    //
        renderer_.GetDeviceCapabilities().SupportsReadFromResolve(),       //
        renderer_.GetDeviceCapabilities().SupportsImplicitResolvingMSAA()  //
    );
    render_passes_.push_back(
        LazyRenderingConfig(renderer_, std::move(entity_pass_target)));
  }
}

void ExperimentalCanvas::SkipUntilMatchingRestore(size_t total_content_depth) {
  auto entry = CanvasStackEntry{};
  entry.skipping = true;
  entry.clip_depth = current_depth_ + total_content_depth;
  transform_stack_.push_back(entry);
}

void ExperimentalCanvas::Save(uint32_t total_content_depth) {
  if (IsSkipping()) {
    return SkipUntilMatchingRestore(total_content_depth);
  }

  auto entry = CanvasStackEntry{};
  entry.transform = transform_stack_.back().transform;
  entry.cull_rect = transform_stack_.back().cull_rect;
  entry.clip_depth = current_depth_ + total_content_depth;
  entry.distributed_opacity = transform_stack_.back().distributed_opacity;
  FML_DCHECK(entry.clip_depth <= transform_stack_.back().clip_depth)
      << entry.clip_depth << " <=? " << transform_stack_.back().clip_depth
      << " after allocating " << total_content_depth;
  entry.clip_height = transform_stack_.back().clip_height;
  entry.rendering_mode = Entity::RenderingMode::kDirect;
  transform_stack_.push_back(entry);
}

std::optional<Rect> ExperimentalCanvas::ComputeCoverageLimit() const {
  if (!clip_coverage_stack_.HasCoverage()) {
    // The current clip is empty. This means the pass texture won't be
    // visible, so skip it.
    return std::nullopt;
  }

  auto maybe_current_clip_coverage = clip_coverage_stack_.CurrentClipCoverage();
  if (!maybe_current_clip_coverage.has_value()) {
    return std::nullopt;
  }

  auto current_clip_coverage = maybe_current_clip_coverage.value();

  // The maximum coverage of the subpass. Subpasses textures should never
  // extend outside the parent pass texture or the current clip coverage.
  std::optional<Rect> maybe_coverage_limit =
      Rect::MakeOriginSize(GetGlobalPassPosition(),
                           Size(render_passes_.back()
                                    .inline_pass_context->GetTexture()
                                    ->GetSize()))
          .Intersection(current_clip_coverage);

  if (!maybe_coverage_limit.has_value() || maybe_coverage_limit->IsEmpty()) {
    return std::nullopt;
  }

  return maybe_coverage_limit->Intersection(
      Rect::MakeSize(render_target_.GetRenderTargetSize()));
}

void ExperimentalCanvas::SaveLayer(
    const Paint& paint,
    std::optional<Rect> bounds,
    const std::shared_ptr<ImageFilter>& backdrop_filter,
    ContentBoundsPromise bounds_promise,
    uint32_t total_content_depth,
    bool can_distribute_opacity) {
  TRACE_EVENT0("flutter", "Canvas::saveLayer");
  if (IsSkipping()) {
    return SkipUntilMatchingRestore(total_content_depth);
  }

  auto maybe_coverage_limit = ComputeCoverageLimit();
  if (!maybe_coverage_limit.has_value()) {
    return SkipUntilMatchingRestore(total_content_depth);
  }
  auto coverage_limit = maybe_coverage_limit.value();

  if (can_distribute_opacity && !backdrop_filter &&
      Paint::CanApplyOpacityPeephole(paint) &&
      bounds_promise != ContentBoundsPromise::kMayClipContents) {
    Save(total_content_depth);
    transform_stack_.back().distributed_opacity *= paint.color.alpha;
    return;
  }

  std::shared_ptr<FilterContents> filter_contents = paint.WithImageFilter(
      Rect(), transform_stack_.back().transform,
      Entity::RenderingMode::kSubpassPrependSnapshotTransform);

  std::optional<Rect> maybe_subpass_coverage = ComputeSaveLayerCoverage(
      bounds.value_or(Rect::MakeMaximum()),
      transform_stack_.back().transform,  //
      coverage_limit,                     //
      filter_contents,                    //
      /*flood_output_coverage=*/
      Entity::IsBlendModeDestructive(paint.blend_mode),  //
      /*flood_input_coverage=*/!!backdrop_filter         //
  );

  if (!maybe_subpass_coverage.has_value()) {
    return SkipUntilMatchingRestore(total_content_depth);
  }

  auto subpass_coverage = maybe_subpass_coverage.value();

  // When an image filter is present, clamp to avoid flicking due to nearest
  // sampled image. For other cases, round out to ensure than any geometry is
  // not cut off.
  //
  // See also this bug: https://github.com/flutter/flutter/issues/144213
  //
  // TODO(jonahwilliams): this could still round out for filters that use decal
  // sampling mode.
  ISize subpass_size;
  bool did_round_out = false;
  if (paint.image_filter) {
    subpass_size = ISize(subpass_coverage.GetSize());
  } else {
    did_round_out = true;
    subpass_size = ISize(IRect::RoundOut(subpass_coverage).GetSize());
  }
  if (subpass_size.IsEmpty()) {
    return SkipUntilMatchingRestore(total_content_depth);
  }

  // Backdrop filter state, ignored if there is no BDF.
  std::shared_ptr<FilterContents> backdrop_filter_contents;
  Point local_position = {0, 0};
  if (backdrop_filter) {
    local_position = subpass_coverage.GetOrigin() - GetGlobalPassPosition();
    EntityPass::BackdropFilterProc backdrop_filter_proc =
        [backdrop_filter = backdrop_filter->Clone()](
            const FilterInput::Ref& input, const Matrix& effect_transform,
            Entity::RenderingMode rendering_mode) {
          auto filter = backdrop_filter->WrapInput(input);
          filter->SetEffectTransform(effect_transform);
          filter->SetRenderingMode(rendering_mode);
          return filter;
        };

    auto input_texture = FlipBackdrop(render_passes_,           //
                                      GetGlobalPassPosition(),  //
                                      clip_coverage_stack_,     //
                                      renderer_                 //
    );
    if (!input_texture) {
      // Validation failures are logged in FlipBackdrop.
      return;
    }

    backdrop_filter_contents = backdrop_filter_proc(
        FilterInput::Make(std::move(input_texture)),
        transform_stack_.back().transform.Basis(),
        // When the subpass has a translation that means the math with
        // the snapshot has to be different.
        transform_stack_.back().transform.HasTranslation()
            ? Entity::RenderingMode::kSubpassPrependSnapshotTransform
            : Entity::RenderingMode::kSubpassAppendSnapshotTransform);
  }

  // When applying a save layer, absorb any pending distributed opacity.
  Paint paint_copy = paint;
  paint_copy.color.alpha *= transform_stack_.back().distributed_opacity;
  transform_stack_.back().distributed_opacity = 1.0;

  render_passes_.push_back(
      LazyRenderingConfig(renderer_,                                    //
                          CreateRenderTarget(renderer_,                 //
                                             subpass_size,              //
                                             Color::BlackTransparent()  //
                                             )));
  save_layer_state_.push_back(SaveLayerState{paint_copy, subpass_coverage});

  CanvasStackEntry entry;
  entry.transform = transform_stack_.back().transform;
  entry.cull_rect = transform_stack_.back().cull_rect;
  entry.clip_depth = current_depth_ + total_content_depth;
  FML_DCHECK(entry.clip_depth <= transform_stack_.back().clip_depth)
      << entry.clip_depth << " <=? " << transform_stack_.back().clip_depth
      << " after allocating " << total_content_depth;
  entry.clip_height = transform_stack_.back().clip_height;
  entry.rendering_mode = Entity::RenderingMode::kSubpassAppendSnapshotTransform;
  entry.did_round_out = did_round_out;
  transform_stack_.emplace_back(entry);

  // The current clip aiks clip culling can not handle image filters.
  // Remove this once we've migrated to exp canvas and removed it.
  if (paint.image_filter) {
    transform_stack_.back().cull_rect = std::nullopt;
  }

  // Start non-collapsed subpasses with a fresh clip coverage stack limited by
  // the subpass coverage. This is important because image filters applied to
  // save layers may transform the subpass texture after it's rendered,
  // causing parent clip coverage to get misaligned with the actual area that
  // the subpass will affect in the parent pass.
  clip_coverage_stack_.PushSubpass(subpass_coverage, GetClipHeight());

  if (backdrop_filter_contents) {
    // Render the backdrop entity.
    Entity backdrop_entity;
    backdrop_entity.SetContents(std::move(backdrop_filter_contents));
    backdrop_entity.SetTransform(
        Matrix::MakeTranslation(Vector3(-local_position)));
    backdrop_entity.SetClipDepth(std::numeric_limits<uint32_t>::max());

    backdrop_entity.Render(
        renderer_,
        *render_passes_.back().inline_pass_context->GetRenderPass(0).pass);
  }
}

bool ExperimentalCanvas::Restore() {
  FML_DCHECK(transform_stack_.size() > 0);
  if (transform_stack_.size() == 1) {
    return false;
  }

  // This check is important to make sure we didn't exceed the depth
  // that the clips were rendered at while rendering any of the
  // rendering ops. It is OK for the current depth to equal the
  // outgoing clip depth because that means the clipping would have
  // been successful up through the last rendering op, but it cannot
  // be greater.
  // Also, we bump the current rendering depth to the outgoing clip
  // depth so that future rendering operations are not clipped by
  // any of the pixels set by the expiring clips. It is OK for the
  // estimates used to determine the clip depth in save/saveLayer
  // to be overly conservative, but we need to jump the depth to
  // the clip depth so that the next rendering op will get a
  // larger depth (it will pre-increment the current_depth_ value).
  FML_DCHECK(current_depth_ <= transform_stack_.back().clip_depth)
      << current_depth_ << " <=? " << transform_stack_.back().clip_depth;
  current_depth_ = transform_stack_.back().clip_depth;

  if (IsSkipping()) {
    transform_stack_.pop_back();
    return true;
  }

  if (transform_stack_.back().rendering_mode ==
          Entity::RenderingMode::kSubpassAppendSnapshotTransform ||
      transform_stack_.back().rendering_mode ==
          Entity::RenderingMode::kSubpassPrependSnapshotTransform) {
    auto lazy_render_pass = std::move(render_passes_.back());
    render_passes_.pop_back();
    // Force the render pass to be constructed if it never was.
    lazy_render_pass.inline_pass_context->GetRenderPass(0);

    SaveLayerState save_layer_state = save_layer_state_.back();
    save_layer_state_.pop_back();
    auto global_pass_position = GetGlobalPassPosition();

    std::shared_ptr<Contents> contents =
        PaintPassDelegate(save_layer_state.paint)
            .CreateContentsForSubpassTarget(
                lazy_render_pass.inline_pass_context->GetTexture(),
                Matrix::MakeTranslation(Vector3{-global_pass_position}) *
                    transform_stack_.back().transform);

    lazy_render_pass.inline_pass_context->EndPass();

    // Round the subpass texture position for pixel alignment with the parent
    // pass render target. By default, we draw subpass textures with nearest
    // sampling, so aligning here is important for avoiding visual nearest
    // sampling errors caused by limited floating point precision when
    // straddling a half pixel boundary.
    Point subpass_texture_position;
    if (transform_stack_.back().did_round_out) {
      // Subpass coverage was rounded out, origin potentially moved "down" by
      // as much as a pixel.
      subpass_texture_position =
          (save_layer_state.coverage.GetOrigin() - global_pass_position)
              .Floor();
    } else {
      // Subpass coverage was truncated. Pick the closest phyiscal pixel.
      subpass_texture_position =
          (save_layer_state.coverage.GetOrigin() - global_pass_position)
              .Round();
    }

    Entity element_entity;
    element_entity.SetClipDepth(++current_depth_);
    element_entity.SetContents(std::move(contents));
    element_entity.SetBlendMode(save_layer_state.paint.blend_mode);
    element_entity.SetTransform(
        Matrix::MakeTranslation(Vector3(subpass_texture_position)));

    if (element_entity.GetBlendMode() > Entity::kLastPipelineBlendMode) {
      if (renderer_.GetDeviceCapabilities().SupportsFramebufferFetch()) {
        ApplyFramebufferBlend(element_entity);
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
        auto input_texture =
            FlipBackdrop(render_passes_, GetGlobalPassPosition(),
                         clip_coverage_stack_, renderer_);
        if (!input_texture) {
          return false;
        }

        FilterInput::Vector inputs = {
            FilterInput::Make(input_texture,
                              element_entity.GetTransform().Invert()),
            FilterInput::Make(element_entity.GetContents())};
        auto contents = ColorFilterContents::MakeBlend(
            element_entity.GetBlendMode(), inputs);
        contents->SetCoverageHint(element_entity.GetCoverage());
        element_entity.SetContents(std::move(contents));
        element_entity.SetBlendMode(BlendMode::kSource);
      }
    }

    element_entity.Render(
        renderer_,                                                         //
        *render_passes_.back().inline_pass_context->GetRenderPass(0).pass  //
    );
    clip_coverage_stack_.PopSubpass();
    transform_stack_.pop_back();

    // We don't need to restore clips if a saveLayer was performed, as the clip
    // state is per render target, and no more rendering operations will be
    // performed as the render target workloaded is completed in the restore.
    return true;
  }

  size_t num_clips = transform_stack_.back().num_clips;
  transform_stack_.pop_back();

  if (num_clips > 0) {
    Entity entity;
    entity.SetTransform(
        Matrix::MakeTranslation(Vector3(-GetGlobalPassPosition())) *
        GetCurrentTransform());
    // This path is empty because ClipRestoreContents just generates a quad that
    // takes up the full render target.
    auto clip_restore = std::make_shared<ClipRestoreContents>();
    clip_restore->SetRestoreHeight(GetClipHeight());
    entity.SetContents(std::move(clip_restore));

    auto current_clip_coverage = clip_coverage_stack_.CurrentClipCoverage();
    if (current_clip_coverage.has_value()) {
      // Entity transforms are relative to the current pass position, so we need
      // to check clip coverage in the same space.
      current_clip_coverage =
          current_clip_coverage->Shift(-GetGlobalPassPosition());
    }

    auto clip_coverage = entity.GetClipCoverage(current_clip_coverage);
    if (clip_coverage.coverage.has_value()) {
      clip_coverage.coverage =
          clip_coverage.coverage->Shift(GetGlobalPassPosition());
    }

    EntityPassClipStack::ClipStateResult clip_state_result =
        clip_coverage_stack_.ApplyClipState(clip_coverage, entity,
                                            GetClipHeightFloor(),
                                            GetGlobalPassPosition());

    if (clip_state_result.clip_did_change) {
      // We only need to update the pass scissor if the clip state has changed.
      SetClipScissor(
          clip_coverage_stack_.CurrentClipCoverage(),                         //
          *render_passes_.back().inline_pass_context->GetRenderPass(0).pass,  //
          GetGlobalPassPosition()                                             //
      );
    }

    if (!clip_state_result.should_render) {
      return true;
    }

    entity.Render(
        renderer_,
        *render_passes_.back().inline_pass_context->GetRenderPass(0).pass);
  }

  return true;
}

void ExperimentalCanvas::DrawTextFrame(
    const std::shared_ptr<TextFrame>& text_frame,
    Point position,
    const Paint& paint) {
  Entity entity;
  entity.SetClipDepth(GetClipHeight());
  entity.SetBlendMode(paint.blend_mode);

  auto text_contents = std::make_shared<TextContents>();
  text_contents->SetTextFrame(text_frame);
  text_contents->SetForceTextColor(paint.mask_blur_descriptor.has_value());
  text_contents->SetScale(GetCurrentTransform().GetMaxBasisLengthXY());
  text_contents->SetColor(paint.color);
  text_contents->SetOffset(position);
  text_contents->SetTextProperties(paint.color,                           //
                                   paint.style == Paint::Style::kStroke,  //
                                   paint.stroke_width,                    //
                                   paint.stroke_cap,                      //
                                   paint.stroke_join,                     //
                                   paint.stroke_miter                     //
  );

  entity.SetTransform(GetCurrentTransform() *
                      Matrix::MakeTranslation(position));

  // TODO(bdero): This mask blur application is a hack. It will always wind up
  //              doing a gaussian blur that affects the color source itself
  //              instead of just the mask. The color filter text support
  //              needs to be reworked in order to interact correctly with
  //              mask filters.
  //              https://github.com/flutter/flutter/issues/133297
  entity.SetContents(paint.WithFilters(paint.WithMaskBlur(
      std::move(text_contents), true, GetCurrentTransform())));

  AddRenderEntityToCurrentPass(std::move(entity), false);
}

void ExperimentalCanvas::AddRenderEntityToCurrentPass(Entity entity,
                                                      bool reuse_depth) {
  if (IsSkipping()) {
    return;
  }

  entity.SetTransform(
      Matrix::MakeTranslation(Vector3(-GetGlobalPassPosition())) *
      entity.GetTransform());
  entity.SetInheritedOpacity(transform_stack_.back().distributed_opacity);
  if (entity.GetBlendMode() == BlendMode::kSourceOver &&
      entity.GetContents()->IsOpaque(entity.GetTransform())) {
    entity.SetBlendMode(BlendMode::kSource);
  }

  // If the entity covers the current render target and is a solid color, then
  // conditionally update the backdrop color to its solid color value blended
  // with the current backdrop.
  if (render_passes_.back().IsApplyingClearColor()) {
    std::optional<Color> maybe_color = entity.AsBackgroundColor(
        render_passes_.back().inline_pass_context->GetTexture()->GetSize());
    if (maybe_color.has_value()) {
      Color color = maybe_color.value();
      RenderTarget& render_target = render_passes_.back()
                                        .inline_pass_context->GetPassTarget()
                                        .GetRenderTarget();
      ColorAttachment attachment =
          render_target.GetColorAttachments().find(0u)->second;
      // Attachment.clear color needs to be premultiplied at all times, but the
      // Color::Blend function requires unpremultiplied colors.
      attachment.clear_color = attachment.clear_color.Unpremultiply()
                                   .Blend(color, entity.GetBlendMode())
                                   .Premultiply();
      render_target.SetColorAttachment(attachment, 0u);
      return;
    }
  }

  if (!reuse_depth) {
    ++current_depth_;
  }
  // We can render at a depth up to and including the depth of the currently
  // active clips and we will still be clipped out, but we cannot render at
  // a depth that is greater than the current clips or we will not be clipped.
  FML_DCHECK(current_depth_ <= transform_stack_.back().clip_depth)
      << current_depth_ << " <=? " << transform_stack_.back().clip_depth;
  entity.SetClipDepth(current_depth_);

  if (entity.GetBlendMode() > Entity::kLastPipelineBlendMode) {
    if (renderer_.GetDeviceCapabilities().SupportsFramebufferFetch()) {
      ApplyFramebufferBlend(entity);
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
      auto input_texture = FlipBackdrop(render_passes_, GetGlobalPassPosition(),
                                        clip_coverage_stack_, renderer_);
      if (!input_texture) {
        return;
      }

      // The coverage hint tells the rendered Contents which portion of the
      // rendered output will actually be used, and so we set this to the
      // current clip coverage (which is the max clip bounds). The contents may
      // optionally use this hint to avoid unnecessary rendering work.
      auto element_coverage_hint = entity.GetContents()->GetCoverageHint();
      entity.GetContents()->SetCoverageHint(Rect::Intersection(
          element_coverage_hint, clip_coverage_stack_.CurrentClipCoverage()));

      FilterInput::Vector inputs = {
          FilterInput::Make(input_texture, entity.GetTransform().Invert()),
          FilterInput::Make(entity.GetContents())};
      auto contents =
          ColorFilterContents::MakeBlend(entity.GetBlendMode(), inputs);
      entity.SetContents(std::move(contents));
      entity.SetBlendMode(BlendMode::kSource);
    }
  }

  InlinePassContext::RenderPassResult result =
      render_passes_.back().inline_pass_context->GetRenderPass(0);
  if (!result.pass) {
    // Failure to produce a render pass should be explained by specific errors
    // in `InlinePassContext::GetRenderPass()`, so avoid log spam and don't
    // append a validation log here.
    return;
  }

  entity.Render(renderer_, *result.pass);
}

void ExperimentalCanvas::AddClipEntityToCurrentPass(Entity entity) {
  if (IsSkipping()) {
    return;
  }

  auto transform = entity.GetTransform();
  entity.SetTransform(
      Matrix::MakeTranslation(Vector3(-GetGlobalPassPosition())) * transform);

  // Ideally the clip depth would be greater than the current rendering
  // depth because any rendering calls that follow this clip operation will
  // pre-increment the depth and then be rendering above our clip depth,
  // but that case will be caught by the CHECK in AddRenderEntity above.
  // In practice we sometimes have a clip set with no rendering after it
  // and in such cases the current depth will equal the clip depth.
  // Eventually the DisplayList should optimize these out, but it is hard
  // to know if a clip will actually be used in advance of storing it in
  // the DisplayList buffer.
  // See https://github.com/flutter/flutter/issues/147021
  FML_DCHECK(current_depth_ <= transform_stack_.back().clip_depth)
      << current_depth_ << " <=? " << transform_stack_.back().clip_depth;
  entity.SetClipDepth(transform_stack_.back().clip_depth);

  auto current_clip_coverage = clip_coverage_stack_.CurrentClipCoverage();
  if (current_clip_coverage.has_value()) {
    // Entity transforms are relative to the current pass position, so we need
    // to check clip coverage in the same space.
    current_clip_coverage =
        current_clip_coverage->Shift(-GetGlobalPassPosition());
  }

  auto clip_coverage = entity.GetClipCoverage(current_clip_coverage);
  if (clip_coverage.coverage.has_value()) {
    clip_coverage.coverage =
        clip_coverage.coverage->Shift(GetGlobalPassPosition());
  }

  EntityPassClipStack::ClipStateResult clip_state_result =
      clip_coverage_stack_.ApplyClipState(
          clip_coverage, entity, GetClipHeightFloor(), GetGlobalPassPosition());

  if (clip_state_result.clip_did_change) {
    // We only need to update the pass scissor if the clip state has changed.
    SetClipScissor(
        clip_coverage_stack_.CurrentClipCoverage(),
        *render_passes_.back().inline_pass_context->GetRenderPass(0).pass,
        GetGlobalPassPosition());
  }

  if (!clip_state_result.should_render) {
    return;
  }

  entity.Render(
      renderer_,
      *render_passes_.back().inline_pass_context->GetRenderPass(0).pass);
}

bool ExperimentalCanvas::BlitToOnscreen() {
  auto command_buffer = renderer_.GetContext()->CreateCommandBuffer();
  command_buffer->SetLabel("EntityPass Root Command Buffer");
  auto offscreen_target = render_passes_.back()
                              .inline_pass_context->GetPassTarget()
                              .GetRenderTarget();

  if (renderer_.GetContext()
          ->GetCapabilities()
          ->SupportsTextureToTextureBlits()) {
    auto blit_pass = command_buffer->CreateBlitPass();
    blit_pass->AddCopy(offscreen_target.GetRenderTargetTexture(),
                       render_target_.GetRenderTargetTexture());
    if (!blit_pass->EncodeCommands(
            renderer_.GetContext()->GetResourceAllocator())) {
      VALIDATION_LOG << "Failed to encode root pass blit command.";
      return false;
    }
    if (!renderer_.GetContext()
             ->GetCommandQueue()
             ->Submit({command_buffer})
             .ok()) {
      return false;
    }
  } else {
    auto render_pass = command_buffer->CreateRenderPass(render_target_);
    render_pass->SetLabel("EntityPass Root Render Pass");

    {
      auto size_rect = Rect::MakeSize(offscreen_target.GetRenderTargetSize());
      auto contents = TextureContents::MakeRect(size_rect);
      contents->SetTexture(offscreen_target.GetRenderTargetTexture());
      contents->SetSourceRect(size_rect);
      contents->SetLabel("Root pass blit");

      Entity entity;
      entity.SetContents(contents);
      entity.SetBlendMode(BlendMode::kSource);

      if (!entity.Render(renderer_, *render_pass)) {
        VALIDATION_LOG << "Failed to render EntityPass root blit.";
        return false;
      }
    }

    if (!render_pass->EncodeCommands()) {
      VALIDATION_LOG << "Failed to encode root pass command buffer.";
      return false;
    }
    if (!renderer_.GetContext()
             ->GetCommandQueue()
             ->Submit({command_buffer})
             .ok()) {
      return false;
    }
  }
  return true;
}

void ExperimentalCanvas::EndReplay() {
  FML_DCHECK(render_passes_.size() == 1u);
  render_passes_.back().inline_pass_context->GetRenderPass(0);
  render_passes_.back().inline_pass_context->EndPass();

  // If requires_readback_ was true, then we rendered to an offscreen texture
  // instead of to the onscreen provided in the render target. Now we need to
  // draw or blit the offscreen back to the onscreen.
  if (requires_readback_) {
    BlitToOnscreen();
  }

  render_passes_.clear();
  renderer_.GetRenderTargetCache()->End();

  Reset();
  Initialize(initial_cull_rect_);
}

}  // namespace impeller
