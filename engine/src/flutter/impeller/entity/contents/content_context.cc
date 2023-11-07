// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/contents/content_context.h"

#include <memory>
#include <sstream>

#include "impeller/base/strings.h"
#include "impeller/core/formats.h"
#include "impeller/entity/entity.h"
#include "impeller/entity/render_target_cache.h"
#include "impeller/renderer/command_buffer.h"
#include "impeller/renderer/pipeline_library.h"
#include "impeller/renderer/render_pass.h"
#include "impeller/renderer/render_target.h"
#include "impeller/tessellator/tessellator.h"
#include "impeller/typographer/typographer_context.h"

namespace impeller {

void ContentContextOptions::ApplyToPipelineDescriptor(
    PipelineDescriptor& desc) const {
  auto pipeline_blend = blend_mode;
  if (blend_mode > Entity::kLastPipelineBlendMode) {
    VALIDATION_LOG << "Cannot use blend mode " << static_cast<int>(blend_mode)
                   << " as a pipeline blend.";
    pipeline_blend = BlendMode::kSourceOver;
  }

  desc.SetSampleCount(sample_count);

  ColorAttachmentDescriptor color0 = *desc.GetColorAttachmentDescriptor(0u);
  color0.format = color_attachment_pixel_format;
  color0.alpha_blend_op = BlendOperation::kAdd;
  color0.color_blend_op = BlendOperation::kAdd;

  switch (pipeline_blend) {
    case BlendMode::kClear:
      if (is_for_rrect_blur_clear) {
        color0.alpha_blend_op = BlendOperation::kReverseSubtract;
        color0.color_blend_op = BlendOperation::kReverseSubtract;
        color0.dst_alpha_blend_factor = BlendFactor::kOne;
        color0.dst_color_blend_factor = BlendFactor::kOne;
        color0.src_alpha_blend_factor = BlendFactor::kDestinationColor;
        color0.src_color_blend_factor = BlendFactor::kDestinationColor;
      } else {
        color0.dst_alpha_blend_factor = BlendFactor::kZero;
        color0.dst_color_blend_factor = BlendFactor::kZero;
        color0.src_alpha_blend_factor = BlendFactor::kZero;
        color0.src_color_blend_factor = BlendFactor::kZero;
      }
      break;
    case BlendMode::kSource:
      color0.blending_enabled = false;
      color0.dst_alpha_blend_factor = BlendFactor::kZero;
      color0.dst_color_blend_factor = BlendFactor::kZero;
      color0.src_alpha_blend_factor = BlendFactor::kOne;
      color0.src_color_blend_factor = BlendFactor::kOne;
      break;
    case BlendMode::kDestination:
      color0.dst_alpha_blend_factor = BlendFactor::kOne;
      color0.dst_color_blend_factor = BlendFactor::kOne;
      color0.src_alpha_blend_factor = BlendFactor::kZero;
      color0.src_color_blend_factor = BlendFactor::kZero;
      break;
    case BlendMode::kSourceOver:
      color0.dst_alpha_blend_factor = BlendFactor::kOneMinusSourceAlpha;
      color0.dst_color_blend_factor = BlendFactor::kOneMinusSourceAlpha;
      color0.src_alpha_blend_factor = BlendFactor::kOne;
      color0.src_color_blend_factor = BlendFactor::kOne;
      break;
    case BlendMode::kDestinationOver:
      color0.dst_alpha_blend_factor = BlendFactor::kOne;
      color0.dst_color_blend_factor = BlendFactor::kOne;
      color0.src_alpha_blend_factor = BlendFactor::kOneMinusDestinationAlpha;
      color0.src_color_blend_factor = BlendFactor::kOneMinusDestinationAlpha;
      break;
    case BlendMode::kSourceIn:
      color0.dst_alpha_blend_factor = BlendFactor::kZero;
      color0.dst_color_blend_factor = BlendFactor::kZero;
      color0.src_alpha_blend_factor = BlendFactor::kDestinationAlpha;
      color0.src_color_blend_factor = BlendFactor::kDestinationAlpha;
      break;
    case BlendMode::kDestinationIn:
      color0.dst_alpha_blend_factor = BlendFactor::kSourceAlpha;
      color0.dst_color_blend_factor = BlendFactor::kSourceAlpha;
      color0.src_alpha_blend_factor = BlendFactor::kZero;
      color0.src_color_blend_factor = BlendFactor::kZero;
      break;
    case BlendMode::kSourceOut:
      color0.dst_alpha_blend_factor = BlendFactor::kZero;
      color0.dst_color_blend_factor = BlendFactor::kZero;
      color0.src_alpha_blend_factor = BlendFactor::kOneMinusDestinationAlpha;
      color0.src_color_blend_factor = BlendFactor::kOneMinusDestinationAlpha;
      break;
    case BlendMode::kDestinationOut:
      color0.dst_alpha_blend_factor = BlendFactor::kOneMinusSourceAlpha;
      color0.dst_color_blend_factor = BlendFactor::kOneMinusSourceAlpha;
      color0.src_alpha_blend_factor = BlendFactor::kZero;
      color0.src_color_blend_factor = BlendFactor::kZero;
      break;
    case BlendMode::kSourceATop:
      color0.dst_alpha_blend_factor = BlendFactor::kOneMinusSourceAlpha;
      color0.dst_color_blend_factor = BlendFactor::kOneMinusSourceAlpha;
      color0.src_alpha_blend_factor = BlendFactor::kDestinationAlpha;
      color0.src_color_blend_factor = BlendFactor::kDestinationAlpha;
      break;
    case BlendMode::kDestinationATop:
      color0.dst_alpha_blend_factor = BlendFactor::kSourceAlpha;
      color0.dst_color_blend_factor = BlendFactor::kSourceAlpha;
      color0.src_alpha_blend_factor = BlendFactor::kOneMinusDestinationAlpha;
      color0.src_color_blend_factor = BlendFactor::kOneMinusDestinationAlpha;
      break;
    case BlendMode::kXor:
      color0.dst_alpha_blend_factor = BlendFactor::kOneMinusSourceAlpha;
      color0.dst_color_blend_factor = BlendFactor::kOneMinusSourceAlpha;
      color0.src_alpha_blend_factor = BlendFactor::kOneMinusDestinationAlpha;
      color0.src_color_blend_factor = BlendFactor::kOneMinusDestinationAlpha;
      break;
    case BlendMode::kPlus:
      color0.dst_alpha_blend_factor = BlendFactor::kOne;
      color0.dst_color_blend_factor = BlendFactor::kOne;
      color0.src_alpha_blend_factor = BlendFactor::kOne;
      color0.src_color_blend_factor = BlendFactor::kOne;
      break;
    case BlendMode::kModulate:
      color0.dst_alpha_blend_factor = BlendFactor::kSourceAlpha;
      color0.dst_color_blend_factor = BlendFactor::kSourceColor;
      color0.src_alpha_blend_factor = BlendFactor::kZero;
      color0.src_color_blend_factor = BlendFactor::kZero;
      break;
    default:
      FML_UNREACHABLE();
  }
  desc.SetColorAttachmentDescriptor(0u, color0);

  if (!has_stencil_attachment) {
    desc.ClearStencilAttachments();
  }

  auto maybe_stencil = desc.GetFrontStencilAttachmentDescriptor();
  if (maybe_stencil.has_value()) {
    StencilAttachmentDescriptor stencil = maybe_stencil.value();
    stencil.stencil_compare = stencil_compare;
    stencil.depth_stencil_pass = stencil_operation;
    desc.SetStencilAttachmentDescriptors(stencil);
  }

  desc.SetPrimitiveType(primitive_type);

  desc.SetPolygonMode(wireframe ? PolygonMode::kLine : PolygonMode::kFill);
}

template <typename PipelineT>
static std::unique_ptr<PipelineT> CreateDefaultPipeline(
    const Context& context) {
  auto desc = PipelineT::Builder::MakeDefaultPipelineDescriptor(context);
  if (!desc.has_value()) {
    return nullptr;
  }
  // Apply default ContentContextOptions to the descriptor.
  const auto default_color_format =
      context.GetCapabilities()->GetDefaultColorFormat();
  ContentContextOptions{.sample_count = SampleCount::kCount4,
                        .primitive_type = PrimitiveType::kTriangleStrip,
                        .color_attachment_pixel_format = default_color_format}
      .ApplyToPipelineDescriptor(*desc);
  return std::make_unique<PipelineT>(context, desc);
}

ContentContext::ContentContext(
    std::shared_ptr<Context> context,
    std::shared_ptr<TypographerContext> typographer_context,
    std::shared_ptr<RenderTargetAllocator> render_target_allocator)
    : context_(std::move(context)),
      lazy_glyph_atlas_(
          std::make_shared<LazyGlyphAtlas>(std::move(typographer_context))),
      tessellator_(std::make_shared<Tessellator>()),
#if IMPELLER_ENABLE_3D
      scene_context_(std::make_shared<scene::SceneContext>(context_)),
#endif  // IMPELLER_ENABLE_3D
      render_target_cache_(render_target_allocator == nullptr
                               ? std::make_shared<RenderTargetCache>(
                                     context_->GetResourceAllocator())
                               : std::move(render_target_allocator)) {
  if (!context_ || !context_->IsValid()) {
    return;
  }
  auto options = ContentContextOptions{
      .sample_count = SampleCount::kCount4,
      .color_attachment_pixel_format =
          context_->GetCapabilities()->GetDefaultColorFormat()};
  auto options_trianglestrip = ContentContextOptions{
      .sample_count = SampleCount::kCount4,
      .primitive_type = PrimitiveType::kTriangleStrip,
      .color_attachment_pixel_format =
          context_->GetCapabilities()->GetDefaultColorFormat()};

#ifdef IMPELLER_DEBUG
  checkerboard_pipelines_.CreateDefault(*context_, options);
#endif  // IMPELLER_DEBUG

  solid_fill_pipelines_.CreateDefault(*context_, options);

  if (context_->GetCapabilities()->SupportsSSBO()) {
    linear_gradient_ssbo_fill_pipelines_.CreateDefault(*context_, options);
    radial_gradient_ssbo_fill_pipelines_.CreateDefault(*context_, options);
    conical_gradient_ssbo_fill_pipelines_.CreateDefault(*context_, options);
    sweep_gradient_ssbo_fill_pipelines_.CreateDefault(*context_, options);
  } else {
    linear_gradient_fill_pipelines_.CreateDefault(*context_, options);
    radial_gradient_fill_pipelines_.CreateDefault(*context_, options);
    conical_gradient_fill_pipelines_.CreateDefault(*context_, options);
    sweep_gradient_fill_pipelines_.CreateDefault(*context_, options);
  }

  if (context_->GetCapabilities()->SupportsFramebufferFetch()) {
    framebuffer_blend_color_pipelines_.CreateDefault(*context_,
                                                     options_trianglestrip);
    framebuffer_blend_colorburn_pipelines_.CreateDefault(*context_,
                                                         options_trianglestrip);
    framebuffer_blend_colordodge_pipelines_.CreateDefault(
        *context_, options_trianglestrip);
    framebuffer_blend_darken_pipelines_.CreateDefault(*context_,
                                                      options_trianglestrip);
    framebuffer_blend_difference_pipelines_.CreateDefault(
        *context_, options_trianglestrip);
    framebuffer_blend_exclusion_pipelines_.CreateDefault(*context_,
                                                         options_trianglestrip);
    framebuffer_blend_hardlight_pipelines_.CreateDefault(*context_,
                                                         options_trianglestrip);
    framebuffer_blend_hue_pipelines_.CreateDefault(*context_,
                                                   options_trianglestrip);
    framebuffer_blend_lighten_pipelines_.CreateDefault(*context_,
                                                       options_trianglestrip);
    framebuffer_blend_luminosity_pipelines_.CreateDefault(
        *context_, options_trianglestrip);
    framebuffer_blend_multiply_pipelines_.CreateDefault(*context_,
                                                        options_trianglestrip);
    framebuffer_blend_overlay_pipelines_.CreateDefault(*context_,
                                                       options_trianglestrip);
    framebuffer_blend_saturation_pipelines_.CreateDefault(
        *context_, options_trianglestrip);
    framebuffer_blend_screen_pipelines_.CreateDefault(*context_,
                                                      options_trianglestrip);
    framebuffer_blend_softlight_pipelines_.CreateDefault(*context_,
                                                         options_trianglestrip);
  }

  blend_color_pipelines_.CreateDefault(*context_, options_trianglestrip);
  blend_colorburn_pipelines_.CreateDefault(*context_, options_trianglestrip);
  blend_colordodge_pipelines_.CreateDefault(*context_, options_trianglestrip);
  blend_darken_pipelines_.CreateDefault(*context_, options_trianglestrip);
  blend_difference_pipelines_.CreateDefault(*context_, options_trianglestrip);
  blend_exclusion_pipelines_.CreateDefault(*context_, options_trianglestrip);
  blend_hardlight_pipelines_.CreateDefault(*context_, options_trianglestrip);
  blend_hue_pipelines_.CreateDefault(*context_, options_trianglestrip);
  blend_lighten_pipelines_.CreateDefault(*context_, options_trianglestrip);
  blend_luminosity_pipelines_.CreateDefault(*context_, options_trianglestrip);
  blend_multiply_pipelines_.CreateDefault(*context_, options_trianglestrip);
  blend_overlay_pipelines_.CreateDefault(*context_, options_trianglestrip);
  blend_saturation_pipelines_.CreateDefault(*context_, options_trianglestrip);
  blend_screen_pipelines_.CreateDefault(*context_, options_trianglestrip);
  blend_softlight_pipelines_.CreateDefault(*context_, options_trianglestrip);

  rrect_blur_pipelines_.CreateDefault(*context_, options_trianglestrip);
  texture_blend_pipelines_.CreateDefault(*context_, options);
  texture_pipelines_.CreateDefault(*context_, options);
  position_uv_pipelines_.CreateDefault(*context_, options);
  tiled_texture_pipelines_.CreateDefault(*context_, options);
  gaussian_blur_noalpha_decal_pipelines_.CreateDefault(*context_,
                                                       options_trianglestrip);
  gaussian_blur_noalpha_nodecal_pipelines_.CreateDefault(*context_,
                                                         options_trianglestrip);
  border_mask_blur_pipelines_.CreateDefault(*context_, options_trianglestrip);
  morphology_filter_pipelines_.CreateDefault(*context_, options_trianglestrip);
  color_matrix_color_filter_pipelines_.CreateDefault(*context_,
                                                     options_trianglestrip);
  linear_to_srgb_filter_pipelines_.CreateDefault(*context_,
                                                 options_trianglestrip);
  srgb_to_linear_filter_pipelines_.CreateDefault(*context_,
                                                 options_trianglestrip);
  glyph_atlas_pipelines_.CreateDefault(*context_, options);
  glyph_atlas_color_pipelines_.CreateDefault(*context_, options);
  geometry_color_pipelines_.CreateDefault(*context_, options);
  yuv_to_rgb_filter_pipelines_.CreateDefault(*context_, options_trianglestrip);
  porter_duff_blend_pipelines_.CreateDefault(*context_, options_trianglestrip);
  // GLES only shader.
#ifdef IMPELLER_ENABLE_OPENGLES
  if (GetContext()->GetBackendType() == Context::BackendType::kOpenGLES) {
    texture_external_pipelines_.CreateDefault(*context_, options);
  }
#endif  // IMPELLER_ENABLE_OPENGLES
  if (context_->GetCapabilities()->SupportsCompute()) {
    auto pipeline_desc =
        PointsComputeShaderPipeline::MakeDefaultPipelineDescriptor(*context_);
    point_field_compute_pipelines_ =
        context_->GetPipelineLibrary()->GetPipeline(pipeline_desc).Get();

    auto uv_pipeline_desc =
        UvComputeShaderPipeline::MakeDefaultPipelineDescriptor(*context_);
    uv_compute_pipelines_ =
        context_->GetPipelineLibrary()->GetPipeline(uv_pipeline_desc).Get();
  }

  /// Setup default clip pipeline.

  auto clip_pipeline_descriptor =
      ClipPipeline::Builder::MakeDefaultPipelineDescriptor(*context_);
  if (!clip_pipeline_descriptor.has_value()) {
    return;
  }
  ContentContextOptions{
      .sample_count = SampleCount::kCount4,
      .color_attachment_pixel_format =
          context_->GetCapabilities()->GetDefaultColorFormat()}
      .ApplyToPipelineDescriptor(*clip_pipeline_descriptor);
  // Disable write to all color attachments.
  auto clip_color_attachments =
      clip_pipeline_descriptor->GetColorAttachmentDescriptors();
  for (auto& color_attachment : clip_color_attachments) {
    color_attachment.second.write_mask =
        static_cast<uint64_t>(ColorWriteMask::kNone);
  }
  clip_pipeline_descriptor->SetColorAttachmentDescriptors(
      std::move(clip_color_attachments));
  clip_pipelines_.SetDefault(options, std::make_unique<ClipPipeline>(
                                          *context_, clip_pipeline_descriptor));

  is_valid_ = true;
}

ContentContext::~ContentContext() = default;

bool ContentContext::IsValid() const {
  return is_valid_;
}

std::shared_ptr<Texture> ContentContext::MakeSubpass(
    const std::string& label,
    ISize texture_size,
    const SubpassCallback& subpass_callback,
    bool msaa_enabled) const {
  auto context = GetContext();

  RenderTarget subpass_target;
  if (context->GetCapabilities()->SupportsOffscreenMSAA() && msaa_enabled) {
    subpass_target = RenderTarget::CreateOffscreenMSAA(
        *context, *GetRenderTargetCache(), texture_size,
        SPrintF("%s Offscreen", label.c_str()),
        RenderTarget::kDefaultColorAttachmentConfigMSAA,
        std::nullopt  // stencil_attachment_config
    );
  } else {
    subpass_target = RenderTarget::CreateOffscreen(
        *context, *GetRenderTargetCache(), texture_size,
        SPrintF("%s Offscreen", label.c_str()),
        RenderTarget::kDefaultColorAttachmentConfig,  //
        std::nullopt  // stencil_attachment_config
    );
  }
  auto subpass_texture = subpass_target.GetRenderTargetTexture();
  if (!subpass_texture) {
    return nullptr;
  }

  auto sub_command_buffer = context->CreateCommandBuffer();
  sub_command_buffer->SetLabel(SPrintF("%s CommandBuffer", label.c_str()));
  if (!sub_command_buffer) {
    return nullptr;
  }

  auto sub_renderpass = sub_command_buffer->CreateRenderPass(subpass_target);
  if (!sub_renderpass) {
    return nullptr;
  }
  sub_renderpass->SetLabel(SPrintF("%s RenderPass", label.c_str()));

  if (!subpass_callback(*this, *sub_renderpass)) {
    return nullptr;
  }

  if (!sub_command_buffer->SubmitCommandsAsync(std::move(sub_renderpass))) {
    return nullptr;
  }

  return subpass_texture;
}

#if IMPELLER_ENABLE_3D
std::shared_ptr<scene::SceneContext> ContentContext::GetSceneContext() const {
  return scene_context_;
}
#endif  // IMPELLER_ENABLE_3D

std::shared_ptr<Tessellator> ContentContext::GetTessellator() const {
  return tessellator_;
}

std::shared_ptr<Context> ContentContext::GetContext() const {
  return context_;
}

const Capabilities& ContentContext::GetDeviceCapabilities() const {
  return *context_->GetCapabilities();
}

void ContentContext::SetWireframe(bool wireframe) {
  wireframe_ = wireframe;
}

}  // namespace impeller
