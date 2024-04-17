// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/aiks/experimental_canvas.h"
#include "fml/logging.h"
#include "impeller/aiks/canvas.h"
#include "impeller/aiks/paint_pass_delegate.h"
#include "impeller/entity/contents/text_contents.h"

namespace impeller {

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
                                       RenderTarget& render_target)
    : Canvas(), renderer_(renderer), render_target_(render_target) {
  SetupRenderPass();
}

ExperimentalCanvas::ExperimentalCanvas(ContentContext& renderer,
                                       RenderTarget& render_target,
                                       Rect cull_rect)
    : Canvas(cull_rect), renderer_(renderer), render_target_(render_target) {
  SetupRenderPass();
}

ExperimentalCanvas::ExperimentalCanvas(ContentContext& renderer,
                                       RenderTarget& render_target,
                                       IRect cull_rect)
    : Canvas(cull_rect), renderer_(renderer), render_target_(render_target) {
  SetupRenderPass();
}

void ExperimentalCanvas::SetupRenderPass() {
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

  entity_pass_targets_.push_back(std::make_unique<EntityPassTarget>(
      render_target_,
      renderer_.GetDeviceCapabilities().SupportsReadFromResolve(),
      renderer_.GetDeviceCapabilities().SupportsImplicitResolvingMSAA()));

  auto inline_pass = std::make_unique<InlinePassContext>(
      renderer_, *entity_pass_targets_.back(), 0);
  inline_pass_contexts_.emplace_back(std::move(inline_pass));
  auto result = inline_pass_contexts_.back()->GetRenderPass(0u);
  render_passes_.push_back(result.pass);

  renderer_.GetRenderTargetCache()->Start();
}

void ExperimentalCanvas::Save() {
  auto entry = CanvasStackEntry{};
  entry.transform = transform_stack_.back().transform;
  entry.cull_rect = transform_stack_.back().cull_rect;
  entry.clip_height = transform_stack_.back().clip_height;
  entry.rendering_mode = Entity::RenderingMode::kDirect;
  transform_stack_.emplace_back(entry);
}

void ExperimentalCanvas::SaveLayer(
    const Paint& paint,
    std::optional<Rect> bounds,
    const std::shared_ptr<ImageFilter>& backdrop_filter,
    ContentBoundsPromise bounds_promise) {
  // Can we always guarantee that we get a bounds? Does a lack of bounds
  // indicate something?
  if (!bounds.has_value()) {
    bounds = Rect::MakeSize(render_target_.GetRenderTargetSize());
  }
  Rect subpass_coverage = bounds->TransformBounds(GetCurrentTransform());
  auto target =
      CreateRenderTarget(renderer_,
                         ISize::MakeWH(subpass_coverage.GetSize().width,
                                       subpass_coverage.GetSize().height),
                         1u, Color::BlackTransparent());
  entity_pass_targets_.push_back(std::move(target));
  save_layer_state_.push_back(SaveLayerState{paint, subpass_coverage});

  CanvasStackEntry entry;
  entry.transform = transform_stack_.back().transform;
  entry.cull_rect = transform_stack_.back().cull_rect;
  entry.clip_height = transform_stack_.back().clip_height;
  entry.rendering_mode = Entity::RenderingMode::kSubpass;
  transform_stack_.emplace_back(entry);

  auto inline_pass = std::make_unique<InlinePassContext>(
      renderer_, *entity_pass_targets_.back(), 0);
  inline_pass_contexts_.emplace_back(std::move(inline_pass));

  auto result = inline_pass_contexts_.back()->GetRenderPass(0u);
  render_passes_.push_back(result.pass);
}

bool ExperimentalCanvas::Restore() {
  FML_DCHECK(transform_stack_.size() > 0);
  if (transform_stack_.size() == 1) {
    return false;
  }

  if (transform_stack_.back().rendering_mode ==
      Entity::RenderingMode::kSubpass) {
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
    element_entity.SetClipDepth(GetClipHeight());
    element_entity.SetContents(std::move(contents));
    element_entity.SetBlendMode(save_layer_state.paint.blend_mode);
    element_entity.SetTransform(Matrix::MakeTranslation(
        Vector3(save_layer_state.coverage.GetOrigin())));
    element_entity.Render(renderer_, *render_passes_.back());
  }

  transform_stack_.pop_back();

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
  text_contents->SetColor(paint.color);
  text_contents->SetForceTextColor(paint.mask_blur_descriptor.has_value());
  text_contents->SetScale(GetCurrentTransform().GetMaxBasisLengthXY());

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

  AddEntityToCurrentPass(std::move(entity));
}

void ExperimentalCanvas::AddEntityToCurrentPass(Entity entity) {
  auto transform = entity.GetTransform();
  entity.SetTransform(
      Matrix::MakeTranslation(Vector3(-GetGlobalPassPosition())) * transform);
  entity.Render(renderer_, *render_passes_.back());
}

}  // namespace impeller
