// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/aiks/experimental_canvas.h"
#include "fml/logging.h"
#include "impeller/aiks/canvas.h"
#include "impeller/aiks/paint_pass_delegate.h"
#include "impeller/base/validation.h"
#include "impeller/entity/contents/framebuffer_blend_contents.h"
#include "impeller/entity/contents/text_contents.h"
#include "impeller/entity/entity.h"
#include "impeller/entity/entity_pass_clip_stack.h"
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
    int mip_count,
    const Color& clear_color) {
  const std::shared_ptr<Context>& context = renderer.GetContext();

  /// All of the load/store actions are managed by `InlinePassContext` when
  /// `RenderPasses` are created, so we just set them to `kDontCare` here.
  /// What's important is the `StorageMode` of the textures, which cannot be
  /// changed for the lifetime of the textures.

  if (context->GetBackendType() == Context::BackendType::kOpenGLES) {
    // TODO(https://github.com/flutter/flutter/issues/141732): Implement mip map
    // generation on opengles.
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
    entity_pass_targets_.push_back(CreateRenderTarget(
        renderer_, color0.texture->GetSize(), /*mip_count=*/1,
        /*clear_color=*/Color::BlackTransparent()));
  } else {
    entity_pass_targets_.push_back(std::make_unique<EntityPassTarget>(
        render_target_,
        renderer_.GetDeviceCapabilities().SupportsReadFromResolve(),
        renderer_.GetDeviceCapabilities().SupportsImplicitResolvingMSAA()));
  }

  auto inline_pass = std::make_unique<InlinePassContext>(
      renderer_, *entity_pass_targets_.back(), 0);
  inline_pass_contexts_.emplace_back(std::move(inline_pass));
  auto result = inline_pass_contexts_.back()->GetRenderPass(0u);
  render_passes_.push_back(result.pass);
}

void ExperimentalCanvas::Save(uint32_t total_content_depth) {
  auto entry = CanvasStackEntry{};
  entry.transform = transform_stack_.back().transform;
  entry.cull_rect = transform_stack_.back().cull_rect;
  entry.clip_depth = current_depth_ + total_content_depth;
  entry.distributed_opacity = transform_stack_.back().distributed_opacity;
  FML_CHECK(entry.clip_depth <= transform_stack_.back().clip_depth)
      << entry.clip_depth << " <=? " << transform_stack_.back().clip_depth
      << " after allocating " << total_content_depth;
  entry.clip_height = transform_stack_.back().clip_height;
  entry.rendering_mode = Entity::RenderingMode::kDirect;
  transform_stack_.emplace_back(entry);
}

void ExperimentalCanvas::SaveLayer(
    const Paint& paint,
    std::optional<Rect> bounds,
    const std::shared_ptr<ImageFilter>& backdrop_filter,
    ContentBoundsPromise bounds_promise,
    uint32_t total_content_depth,
    bool can_distribute_opacity) {
  if (can_distribute_opacity && !backdrop_filter &&
      Paint::CanApplyOpacityPeephole(paint)) {
    Save(total_content_depth);
    transform_stack_.back().distributed_opacity *= paint.color.alpha;
    return;
  }
  // Can we always guarantee that we get a bounds? Does a lack of bounds
  // indicate something?
  if (!bounds.has_value()) {
    bounds = Rect::MakeSize(render_target_.GetRenderTargetSize());
  }

  // When applying a save layer, absorb any pending distributed opacity.
  Paint paint_copy = paint;
  paint_copy.color.alpha *= transform_stack_.back().distributed_opacity;
  transform_stack_.back().distributed_opacity = 1.0;

  Rect subpass_coverage = bounds->TransformBounds(GetCurrentTransform());
  auto target =
      CreateRenderTarget(renderer_,
                         ISize::MakeWH(subpass_coverage.GetSize().width,
                                       subpass_coverage.GetSize().height),
                         1u, Color::BlackTransparent());
  entity_pass_targets_.push_back(std::move(target));
  save_layer_state_.push_back(SaveLayerState{paint_copy, subpass_coverage});

  CanvasStackEntry entry;
  entry.transform = transform_stack_.back().transform;
  entry.cull_rect = transform_stack_.back().cull_rect;
  entry.clip_depth = current_depth_ + total_content_depth;
  FML_CHECK(entry.clip_depth <= transform_stack_.back().clip_depth)
      << entry.clip_depth << " <=? " << transform_stack_.back().clip_depth
      << " after allocating " << total_content_depth;
  entry.clip_height = transform_stack_.back().clip_height;
  entry.rendering_mode = Entity::RenderingMode::kSubpassAppendSnapshotTransform;
  transform_stack_.emplace_back(entry);

  auto inline_pass = std::make_unique<InlinePassContext>(
      renderer_, *entity_pass_targets_.back(), 0);
  inline_pass_contexts_.emplace_back(std::move(inline_pass));

  auto result = inline_pass_contexts_.back()->GetRenderPass(0u);
  render_passes_.push_back(result.pass);

  // Start non-collapsed subpasses with a fresh clip coverage stack limited by
  // the subpass coverage. This is important because image filters applied to
  // save layers may transform the subpass texture after it's rendered,
  // causing parent clip coverage to get misaligned with the actual area that
  // the subpass will affect in the parent pass.
  clip_coverage_stack_.PushSubpass(subpass_coverage, GetClipHeight());
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
  FML_CHECK(current_depth_ <= transform_stack_.back().clip_depth)
      << current_depth_ << " <=? " << transform_stack_.back().clip_depth;
  current_depth_ = transform_stack_.back().clip_depth;

  if (transform_stack_.back().rendering_mode ==
          Entity::RenderingMode::kSubpassAppendSnapshotTransform ||
      transform_stack_.back().rendering_mode ==
          Entity::RenderingMode::kSubpassPrependSnapshotTransform) {
    auto inline_pass = std::move(inline_pass_contexts_.back());

    SaveLayerState save_layer_state = save_layer_state_.back();
    save_layer_state_.pop_back();

    std::shared_ptr<Contents> contents =
        PaintPassDelegate(save_layer_state.paint)
            .CreateContentsForSubpassTarget(inline_pass->GetTexture(),
                                            transform_stack_.back().transform);

    inline_pass->EndPass();
    render_passes_.pop_back();
    inline_pass_contexts_.pop_back();

    Entity element_entity;
    element_entity.SetClipDepth(++current_depth_);
    element_entity.SetContents(std::move(contents));
    element_entity.SetBlendMode(save_layer_state.paint.blend_mode);
    element_entity.SetTransform(Matrix::MakeTranslation(
        Vector3(save_layer_state.coverage.GetOrigin())));

    if (element_entity.GetBlendMode() > Entity::kLastPipelineBlendMode) {
      if (renderer_.GetDeviceCapabilities().SupportsFramebufferFetch()) {
        ApplyFramebufferBlend(element_entity);
      } else {
        VALIDATION_LOG << "Emulated advanced blends are currently unsupported.";
        element_entity.SetBlendMode(BlendMode::kSourceOver);
      }
    }

    element_entity.Render(renderer_, *render_passes_.back());
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
      SetClipScissor(clip_coverage_stack_.CurrentClipCoverage(),
                     *render_passes_.back(), GetGlobalPassPosition());
    }

    if (!clip_state_result.should_render) {
      return true;
    }

    entity.Render(renderer_, *render_passes_.back());
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
  entity.SetContents(
      paint.WithFilters(paint.WithMaskBlur(std::move(text_contents), true)));

  AddRenderEntityToCurrentPass(std::move(entity), false);
}

void ExperimentalCanvas::AddRenderEntityToCurrentPass(Entity entity,
                                                      bool reuse_depth) {
  entity.SetInheritedOpacity(transform_stack_.back().distributed_opacity);

  auto transform = entity.GetTransform();
  entity.SetTransform(
      Matrix::MakeTranslation(Vector3(-GetGlobalPassPosition())) * transform);
  if (!reuse_depth) {
    ++current_depth_;
  }
  // We can render at a depth up to and including the depth of the currently
  // active clips and we will still be clipped out, but we cannot render at
  // a depth that is greater than the current clips or we will not be clipped.
  FML_CHECK(current_depth_ <= transform_stack_.back().clip_depth)
      << current_depth_ << " <=? " << transform_stack_.back().clip_depth;
  entity.SetClipDepth(current_depth_);

  if (entity.GetBlendMode() > Entity::kLastPipelineBlendMode) {
    if (renderer_.GetDeviceCapabilities().SupportsFramebufferFetch()) {
      ApplyFramebufferBlend(entity);
    } else {
      VALIDATION_LOG << "Emulated advanced blends are currently unsupported.";
      return;
    }
  }

  entity.Render(renderer_, *render_passes_.back());
}

void ExperimentalCanvas::AddClipEntityToCurrentPass(Entity entity) {
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
  FML_CHECK(current_depth_ <= transform_stack_.back().clip_depth)
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
    SetClipScissor(clip_coverage_stack_.CurrentClipCoverage(),
                   *render_passes_.back(), GetGlobalPassPosition());
  }

  if (!clip_state_result.should_render) {
    return;
  }

  entity.Render(renderer_, *render_passes_.back());
}

bool ExperimentalCanvas::BlitToOnscreen() {
  auto command_buffer = renderer_.GetContext()->CreateCommandBuffer();
  command_buffer->SetLabel("EntityPass Root Command Buffer");
  auto offscreen_target = entity_pass_targets_.back()->GetRenderTarget();

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
  FML_DCHECK(inline_pass_contexts_.size() == 1u);
  inline_pass_contexts_.back()->EndPass();

  // If requires_readback_ was true, then we rendered to an offscreen texture
  // instead of to the onscreen provided in the render target. Now we need to
  // draw or blit the offscreen back to the onscreen.
  if (requires_readback_) {
    BlitToOnscreen();
  }

  render_passes_.clear();
  inline_pass_contexts_.clear();
  renderer_.GetRenderTargetCache()->End();

  Reset();
  Initialize(initial_cull_rect_);
}

}  // namespace impeller
