// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/contents/content_context.h"

#include <memory>
#include <utility>

#include "fml/trace_event.h"
#include "impeller/base/validation.h"
#include "impeller/core/formats.h"
#include "impeller/core/texture_descriptor.h"
#include "impeller/entity/contents/framebuffer_blend_contents.h"
#include "impeller/entity/contents/pipelines.h"
#include "impeller/entity/entity.h"
#include "impeller/entity/render_target_cache.h"
#include "impeller/renderer/command_buffer.h"
#include "impeller/renderer/pipeline_descriptor.h"
#include "impeller/renderer/pipeline_library.h"
#include "impeller/renderer/render_target.h"
#include "impeller/renderer/texture_util.h"
#include "impeller/tessellator/tessellator.h"
#include "impeller/typographer/typographer_context.h"

namespace impeller {

namespace {

/// Holds multiple Pipelines associated with the same PipelineHandle types.
///
/// For example, it may have multiple
/// RenderPipelineHandle<SolidFillVertexShader, SolidFillFragmentShader>
/// instances for different blend modes. From them you can access the
/// Pipeline.
///
/// See also:
///  - impeller::ContentContextOptions - options from which variants are
///    created.
///  - impeller::Pipeline::CreateVariant
///  - impeller::RenderPipelineHandle<> - The type of objects this typically
///    contains.
template <class PipelineHandleT>
class Variants {
  static_assert(
      ShaderStageCompatibilityChecker<
          typename PipelineHandleT::VertexShader,
          typename PipelineHandleT::FragmentShader>::Check(),
      "The output slots for the fragment shader don't have matches in the "
      "vertex shader's output slots. This will result in a linker error.");

 public:
  Variants() = default;

  void Set(const ContentContextOptions& options,
           std::unique_ptr<PipelineHandleT> pipeline) {
    uint64_t p_key = options.ToKey();
    for (const auto& [key, pipeline] : pipelines_) {
      if (key == p_key) {
        return;
      }
    }
    pipelines_.push_back(std::make_pair(p_key, std::move(pipeline)));
  }

  void SetDefault(const ContentContextOptions& options,
                  std::unique_ptr<PipelineHandleT> pipeline) {
    default_options_ = options;
    if (pipeline) {
      Set(options, std::move(pipeline));
    }
  }

  void SetDefaultDescriptor(std::optional<PipelineDescriptor> desc) {
    desc_ = std::move(desc);
  }

  void CreateDefault(const Context& context,
                     const ContentContextOptions& options,
                     const std::vector<Scalar>& constants = {}) {
    auto desc = PipelineHandleT::Builder::MakeDefaultPipelineDescriptor(
        context, constants);
    if (!desc.has_value()) {
      VALIDATION_LOG << "Failed to create default pipeline.";
      return;
    }
    options.ApplyToPipelineDescriptor(*desc);
    desc_ = desc;
    if (context.GetFlags().lazy_shader_mode) {
      SetDefault(options, nullptr);
    } else {
      SetDefault(options, std::make_unique<PipelineHandleT>(context, desc_,
                                                            /*async=*/true));
    }
  }

  PipelineHandleT* Get(const ContentContextOptions& options) const {
    uint64_t p_key = options.ToKey();
    for (const auto& [key, pipeline] : pipelines_) {
      if (key == p_key) {
        return pipeline.get();
      }
    }
    return nullptr;
  }

  bool IsDefault(const ContentContextOptions& opts) {
    return default_options_.has_value() &&
           opts.ToKey() == default_options_.value().ToKey();
  }

  PipelineHandleT* GetDefault(const Context& context) {
    if (!default_options_.has_value()) {
      return nullptr;
    }
    PipelineHandleT* result = Get(default_options_.value());
    if (result != nullptr) {
      return result;
    }
    SetDefault(default_options_.value(), std::make_unique<PipelineHandleT>(
                                             context, desc_, /*async=*/false));
    return Get(default_options_.value());
  }

  size_t GetPipelineCount() const { return pipelines_.size(); }

 private:
  std::optional<PipelineDescriptor> desc_;
  std::optional<ContentContextOptions> default_options_;
  std::vector<std::pair<uint64_t, std::unique_ptr<PipelineHandleT>>> pipelines_;

  Variants(const Variants&) = delete;

  Variants& operator=(const Variants&) = delete;
};

template <class RenderPipelineHandleT>
RenderPipelineHandleT* CreateIfNeeded(
    const ContentContext* context,
    Variants<RenderPipelineHandleT>& container,
    ContentContextOptions opts) {
  if (!context->IsValid()) {
    return nullptr;
  }

  if (RenderPipelineHandleT* found = container.Get(opts)) {
    return found;
  }

  RenderPipelineHandleT* default_handle =
      container.GetDefault(*context->GetContext());
  if (container.IsDefault(opts)) {
    return default_handle;
  }

  // The default must always be initialized in the constructor.
  FML_CHECK(default_handle != nullptr);

  const std::shared_ptr<Pipeline<PipelineDescriptor>>& pipeline =
      default_handle->WaitAndGet();
  if (!pipeline) {
    return nullptr;
  }

  auto variant_future = pipeline->CreateVariant(
      /*async=*/false, [&opts, variants_count = container.GetPipelineCount()](
                           PipelineDescriptor& desc) {
        opts.ApplyToPipelineDescriptor(desc);
        desc.SetLabel(
            SPrintF("%s V#%zu", desc.GetLabel().data(), variants_count));
      });
  std::unique_ptr<RenderPipelineHandleT> variant =
      std::make_unique<RenderPipelineHandleT>(std::move(variant_future));
  container.Set(opts, std::move(variant));
  return container.Get(opts);
}

template <class TypedPipeline>
PipelineRef GetPipeline(const ContentContext* context,
                        Variants<TypedPipeline>& container,
                        ContentContextOptions opts) {
  TypedPipeline* pipeline = CreateIfNeeded(context, container, opts);
  if (!pipeline) {
    return raw_ptr<Pipeline<PipelineDescriptor>>();
  }
  return raw_ptr(pipeline->WaitAndGet());
}

}  // namespace

struct ContentContext::Pipelines {
  // These are mutable because while the prototypes are created eagerly, any
  // variants requested from that are lazily created and cached in the variants
  // map.
  // clang-format off
  mutable Variants<BlendColorBurnPipeline> blend_colorburn_pipelines_;
  mutable Variants<BlendColorDodgePipeline> blend_colordodge_pipelines_;
  mutable Variants<BlendColorPipeline> blend_color_pipelines_;
  mutable Variants<BlendDarkenPipeline> blend_darken_pipelines_;
  mutable Variants<BlendDifferencePipeline> blend_difference_pipelines_;
  mutable Variants<BlendExclusionPipeline> blend_exclusion_pipelines_;
  mutable Variants<BlendHardLightPipeline> blend_hardlight_pipelines_;
  mutable Variants<BlendHuePipeline> blend_hue_pipelines_;
  mutable Variants<BlendLightenPipeline> blend_lighten_pipelines_;
  mutable Variants<BlendLuminosityPipeline> blend_luminosity_pipelines_;
  mutable Variants<BlendMultiplyPipeline> blend_multiply_pipelines_;
  mutable Variants<BlendOverlayPipeline> blend_overlay_pipelines_;
  mutable Variants<BlendSaturationPipeline> blend_saturation_pipelines_;
  mutable Variants<BlendScreenPipeline> blend_screen_pipelines_;
  mutable Variants<BlendSoftLightPipeline> blend_softlight_pipelines_;
  mutable Variants<BorderMaskBlurPipeline> border_mask_blur_pipelines_;
  mutable Variants<ClipPipeline> clip_pipelines_;
  mutable Variants<ColorMatrixColorFilterPipeline> color_matrix_color_filter_pipelines_;
  mutable Variants<ConicalGradientFillConicalPipeline> conical_gradient_fill_pipelines_;
  mutable Variants<ConicalGradientFillRadialPipeline> conical_gradient_fill_radial_pipelines_;
  mutable Variants<ConicalGradientFillStripPipeline> conical_gradient_fill_strip_pipelines_;
  mutable Variants<ConicalGradientFillStripRadialPipeline> conical_gradient_fill_strip_and_radial_pipelines_;
  mutable Variants<ConicalGradientSSBOFillPipeline> conical_gradient_ssbo_fill_pipelines_;
  mutable Variants<ConicalGradientSSBOFillPipeline> conical_gradient_ssbo_fill_radial_pipelines_;
  mutable Variants<ConicalGradientSSBOFillPipeline> conical_gradient_ssbo_fill_strip_and_radial_pipelines_;
  mutable Variants<ConicalGradientSSBOFillPipeline> conical_gradient_ssbo_fill_strip_pipelines_;
  mutable Variants<ConicalGradientUniformFillConicalPipeline> conical_gradient_uniform_fill_pipelines_;
  mutable Variants<ConicalGradientUniformFillRadialPipeline> conical_gradient_uniform_fill_radial_pipelines_;
  mutable Variants<ConicalGradientUniformFillStripPipeline> conical_gradient_uniform_fill_strip_pipelines_;
  mutable Variants<ConicalGradientUniformFillStripRadialPipeline> conical_gradient_uniform_fill_strip_and_radial_pipelines_;
  mutable Variants<FastGradientPipeline> fast_gradient_pipelines_;
  mutable Variants<FramebufferBlendColorBurnPipeline> framebuffer_blend_colorburn_pipelines_;
  mutable Variants<FramebufferBlendColorDodgePipeline> framebuffer_blend_colordodge_pipelines_;
  mutable Variants<FramebufferBlendColorPipeline> framebuffer_blend_color_pipelines_;
  mutable Variants<FramebufferBlendDarkenPipeline> framebuffer_blend_darken_pipelines_;
  mutable Variants<FramebufferBlendDifferencePipeline> framebuffer_blend_difference_pipelines_;
  mutable Variants<FramebufferBlendExclusionPipeline> framebuffer_blend_exclusion_pipelines_;
  mutable Variants<FramebufferBlendHardLightPipeline> framebuffer_blend_hardlight_pipelines_;
  mutable Variants<FramebufferBlendHuePipeline> framebuffer_blend_hue_pipelines_;
  mutable Variants<FramebufferBlendLightenPipeline> framebuffer_blend_lighten_pipelines_;
  mutable Variants<FramebufferBlendLuminosityPipeline> framebuffer_blend_luminosity_pipelines_;
  mutable Variants<FramebufferBlendMultiplyPipeline> framebuffer_blend_multiply_pipelines_;
  mutable Variants<FramebufferBlendOverlayPipeline> framebuffer_blend_overlay_pipelines_;
  mutable Variants<FramebufferBlendSaturationPipeline> framebuffer_blend_saturation_pipelines_;
  mutable Variants<FramebufferBlendScreenPipeline> framebuffer_blend_screen_pipelines_;
  mutable Variants<FramebufferBlendSoftLightPipeline> framebuffer_blend_softlight_pipelines_;
  mutable Variants<GaussianBlurPipeline> gaussian_blur_pipelines_;
  mutable Variants<GlyphAtlasPipeline> glyph_atlas_pipelines_;
  mutable Variants<LinePipeline> line_pipelines_;
  mutable Variants<LinearGradientFillPipeline> linear_gradient_fill_pipelines_;
  mutable Variants<LinearGradientSSBOFillPipeline> linear_gradient_ssbo_fill_pipelines_;
  mutable Variants<LinearGradientUniformFillPipeline> linear_gradient_uniform_fill_pipelines_;
  mutable Variants<LinearToSrgbFilterPipeline> linear_to_srgb_filter_pipelines_;
  mutable Variants<MorphologyFilterPipeline> morphology_filter_pipelines_;
  mutable Variants<PorterDuffBlendPipeline> clear_blend_pipelines_;
  mutable Variants<PorterDuffBlendPipeline> destination_a_top_blend_pipelines_;
  mutable Variants<PorterDuffBlendPipeline> destination_blend_pipelines_;
  mutable Variants<PorterDuffBlendPipeline> destination_in_blend_pipelines_;
  mutable Variants<PorterDuffBlendPipeline> destination_out_blend_pipelines_;
  mutable Variants<PorterDuffBlendPipeline> destination_over_blend_pipelines_;
  mutable Variants<PorterDuffBlendPipeline> modulate_blend_pipelines_;
  mutable Variants<PorterDuffBlendPipeline> plus_blend_pipelines_;
  mutable Variants<PorterDuffBlendPipeline> screen_blend_pipelines_;
  mutable Variants<PorterDuffBlendPipeline> source_a_top_blend_pipelines_;
  mutable Variants<PorterDuffBlendPipeline> source_blend_pipelines_;
  mutable Variants<PorterDuffBlendPipeline> source_in_blend_pipelines_;
  mutable Variants<PorterDuffBlendPipeline> source_out_blend_pipelines_;
  mutable Variants<PorterDuffBlendPipeline> source_over_blend_pipelines_;
  mutable Variants<PorterDuffBlendPipeline> xor_blend_pipelines_;
  mutable Variants<RadialGradientFillPipeline> radial_gradient_fill_pipelines_;
  mutable Variants<RadialGradientSSBOFillPipeline> radial_gradient_ssbo_fill_pipelines_;
  mutable Variants<RadialGradientUniformFillPipeline> radial_gradient_uniform_fill_pipelines_;
  mutable Variants<RRectBlurPipeline> rrect_blur_pipelines_;
  mutable Variants<SolidFillPipeline> solid_fill_pipelines_;
  mutable Variants<SrgbToLinearFilterPipeline> srgb_to_linear_filter_pipelines_;
  mutable Variants<SweepGradientFillPipeline> sweep_gradient_fill_pipelines_;
  mutable Variants<SweepGradientSSBOFillPipeline> sweep_gradient_ssbo_fill_pipelines_;
  mutable Variants<SweepGradientUniformFillPipeline> sweep_gradient_uniform_fill_pipelines_;
  mutable Variants<TextureDownsamplePipeline> texture_downsample_pipelines_;
  mutable Variants<TexturePipeline> texture_pipelines_;
  mutable Variants<TextureStrictSrcPipeline> texture_strict_src_pipelines_;
  mutable Variants<TiledTexturePipeline> tiled_texture_pipelines_;
  mutable Variants<VerticesUberShader> vertices_uber_shader_;
  mutable Variants<YUVToRGBFilterPipeline> yuv_to_rgb_filter_pipelines_;

  #ifdef IMPELLER_ENABLE_OPENGLES
  mutable Variants<TiledTextureExternalPipeline> tiled_texture_external_pipelines_;
  mutable Variants<TextureDownsampleGlesPipeline> texture_downsample_gles_pipelines_;
  mutable Variants<TiledTextureUvExternalPipeline> tiled_texture_uv_external_pipelines_;
#endif  // IMPELLER_ENABLE_OPENGLES
  // clang-format on
};

void ContentContextOptions::ApplyToPipelineDescriptor(
    PipelineDescriptor& desc) const {
  auto pipeline_blend = blend_mode;
  if (blend_mode > Entity::kLastPipelineBlendMode) {
    VALIDATION_LOG << "Cannot use blend mode " << static_cast<int>(blend_mode)
                   << " as a pipeline blend.";
    pipeline_blend = BlendMode::kSrcOver;
  }

  desc.SetSampleCount(sample_count);

  ColorAttachmentDescriptor color0 = *desc.GetColorAttachmentDescriptor(0u);
  color0.format = color_attachment_pixel_format;
  color0.alpha_blend_op = BlendOperation::kAdd;
  color0.color_blend_op = BlendOperation::kAdd;
  color0.write_mask = ColorWriteMaskBits::kAll;

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
    case BlendMode::kSrc:
      color0.blending_enabled = false;
      color0.dst_alpha_blend_factor = BlendFactor::kZero;
      color0.dst_color_blend_factor = BlendFactor::kZero;
      color0.src_alpha_blend_factor = BlendFactor::kOne;
      color0.src_color_blend_factor = BlendFactor::kOne;
      break;
    case BlendMode::kDst:
      color0.dst_alpha_blend_factor = BlendFactor::kOne;
      color0.dst_color_blend_factor = BlendFactor::kOne;
      color0.src_alpha_blend_factor = BlendFactor::kZero;
      color0.src_color_blend_factor = BlendFactor::kZero;
      color0.write_mask = ColorWriteMaskBits::kNone;
      break;
    case BlendMode::kSrcOver:
      color0.dst_alpha_blend_factor = BlendFactor::kOneMinusSourceAlpha;
      color0.dst_color_blend_factor = BlendFactor::kOneMinusSourceAlpha;
      color0.src_alpha_blend_factor = BlendFactor::kOne;
      color0.src_color_blend_factor = BlendFactor::kOne;
      break;
    case BlendMode::kDstOver:
      color0.dst_alpha_blend_factor = BlendFactor::kOne;
      color0.dst_color_blend_factor = BlendFactor::kOne;
      color0.src_alpha_blend_factor = BlendFactor::kOneMinusDestinationAlpha;
      color0.src_color_blend_factor = BlendFactor::kOneMinusDestinationAlpha;
      break;
    case BlendMode::kSrcIn:
      color0.dst_alpha_blend_factor = BlendFactor::kZero;
      color0.dst_color_blend_factor = BlendFactor::kZero;
      color0.src_alpha_blend_factor = BlendFactor::kDestinationAlpha;
      color0.src_color_blend_factor = BlendFactor::kDestinationAlpha;
      break;
    case BlendMode::kDstIn:
      color0.dst_alpha_blend_factor = BlendFactor::kSourceAlpha;
      color0.dst_color_blend_factor = BlendFactor::kSourceAlpha;
      color0.src_alpha_blend_factor = BlendFactor::kZero;
      color0.src_color_blend_factor = BlendFactor::kZero;
      break;
    case BlendMode::kSrcOut:
      color0.dst_alpha_blend_factor = BlendFactor::kZero;
      color0.dst_color_blend_factor = BlendFactor::kZero;
      color0.src_alpha_blend_factor = BlendFactor::kOneMinusDestinationAlpha;
      color0.src_color_blend_factor = BlendFactor::kOneMinusDestinationAlpha;
      break;
    case BlendMode::kDstOut:
      color0.dst_alpha_blend_factor = BlendFactor::kOneMinusSourceAlpha;
      color0.dst_color_blend_factor = BlendFactor::kOneMinusSourceAlpha;
      color0.src_alpha_blend_factor = BlendFactor::kZero;
      color0.src_color_blend_factor = BlendFactor::kZero;
      break;
    case BlendMode::kSrcATop:
      color0.dst_alpha_blend_factor = BlendFactor::kOneMinusSourceAlpha;
      color0.dst_color_blend_factor = BlendFactor::kOneMinusSourceAlpha;
      color0.src_alpha_blend_factor = BlendFactor::kDestinationAlpha;
      color0.src_color_blend_factor = BlendFactor::kDestinationAlpha;
      break;
    case BlendMode::kDstATop:
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

  if (!has_depth_stencil_attachments) {
    desc.ClearDepthAttachment();
    desc.ClearStencilAttachments();
  }

  auto maybe_stencil = desc.GetFrontStencilAttachmentDescriptor();
  auto maybe_depth = desc.GetDepthStencilAttachmentDescriptor();
  FML_DCHECK(has_depth_stencil_attachments == maybe_depth.has_value())
      << "Depth attachment doesn't match expected pipeline state. "
         "has_depth_stencil_attachments="
      << has_depth_stencil_attachments;
  FML_DCHECK(has_depth_stencil_attachments == maybe_stencil.has_value())
      << "Stencil attachment doesn't match expected pipeline state. "
         "has_depth_stencil_attachments="
      << has_depth_stencil_attachments;
  if (maybe_stencil.has_value()) {
    StencilAttachmentDescriptor front_stencil = maybe_stencil.value();
    StencilAttachmentDescriptor back_stencil = front_stencil;

    switch (stencil_mode) {
      case StencilMode::kIgnore:
        front_stencil.stencil_compare = CompareFunction::kAlways;
        front_stencil.depth_stencil_pass = StencilOperation::kKeep;
        desc.SetStencilAttachmentDescriptors(front_stencil);
        break;
      case StencilMode::kStencilNonZeroFill:
        // The stencil ref should be 0 on commands that use this mode.
        front_stencil.stencil_compare = CompareFunction::kAlways;
        front_stencil.depth_stencil_pass = StencilOperation::kIncrementWrap;
        back_stencil.stencil_compare = CompareFunction::kAlways;
        back_stencil.depth_stencil_pass = StencilOperation::kDecrementWrap;
        desc.SetStencilAttachmentDescriptors(front_stencil, back_stencil);
        break;
      case StencilMode::kStencilEvenOddFill:
        // The stencil ref should be 0 on commands that use this mode.
        front_stencil.stencil_compare = CompareFunction::kEqual;
        front_stencil.depth_stencil_pass = StencilOperation::kIncrementWrap;
        front_stencil.stencil_failure = StencilOperation::kDecrementWrap;
        desc.SetStencilAttachmentDescriptors(front_stencil);
        break;
      case StencilMode::kCoverCompare:
        // The stencil ref should be 0 on commands that use this mode.
        front_stencil.stencil_compare = CompareFunction::kNotEqual;
        front_stencil.depth_stencil_pass =
            StencilOperation::kSetToReferenceValue;
        desc.SetStencilAttachmentDescriptors(front_stencil);
        break;
      case StencilMode::kCoverCompareInverted:
        // The stencil ref should be 0 on commands that use this mode.
        front_stencil.stencil_compare = CompareFunction::kEqual;
        front_stencil.stencil_failure = StencilOperation::kSetToReferenceValue;
        desc.SetStencilAttachmentDescriptors(front_stencil);
        break;
      case StencilMode::kOverdrawPreventionIncrement:
        front_stencil.stencil_compare = CompareFunction::kEqual;
        front_stencil.depth_stencil_pass = StencilOperation::kIncrementClamp;
        desc.SetStencilAttachmentDescriptors(front_stencil);
        break;
      case StencilMode::kOverdrawPreventionRestore:
        front_stencil.stencil_compare = CompareFunction::kLess;
        front_stencil.depth_stencil_pass =
            StencilOperation::kSetToReferenceValue;
        desc.SetStencilAttachmentDescriptors(front_stencil);
        break;
    }
  }
  if (maybe_depth.has_value()) {
    DepthAttachmentDescriptor depth = maybe_depth.value();
    depth.depth_write_enabled = depth_write_enabled;
    depth.depth_compare = depth_compare;
    desc.SetDepthStencilAttachmentDescriptor(depth);
  }

  desc.SetPrimitiveType(primitive_type);
  desc.SetPolygonMode(wireframe ? PolygonMode::kLine : PolygonMode::kFill);
}

std::array<std::vector<Scalar>, 15> GetPorterDuffSpecConstants(
    bool supports_decal) {
  Scalar x = supports_decal ? 1 : 0;
  return {{
      {x, 0, 0, 0, 0, 0},    // Clear
      {x, 1, 0, 0, 0, 0},    // Source
      {x, 0, 0, 1, 0, 0},    // Destination
      {x, 1, 0, 1, -1, 0},   // SourceOver
      {x, 1, -1, 1, 0, 0},   // DestinationOver
      {x, 0, 1, 0, 0, 0},    // SourceIn
      {x, 0, 0, 0, 1, 0},    // DestinationIn
      {x, 1, -1, 0, 0, 0},   // SourceOut
      {x, 0, 0, 1, -1, 0},   // DestinationOut
      {x, 0, 1, 1, -1, 0},   // SourceATop
      {x, 1, -1, 0, 1, 0},   // DestinationATop
      {x, 1, -1, 1, -1, 0},  // Xor
      {x, 1, 0, 1, 0, 0},    // Plus
      {x, 0, 0, 0, 0, 1},    // Modulate
      {x, 0, 0, 1, 0, -1},   // Screen
  }};
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
      pipelines_(new Pipelines()),
      tessellator_(std::make_shared<Tessellator>()),
      render_target_cache_(render_target_allocator == nullptr
                               ? std::make_shared<RenderTargetCache>(
                                     context_->GetResourceAllocator())
                               : std::move(render_target_allocator)),
      host_buffer_(HostBuffer::Create(context_->GetResourceAllocator(),
                                      context_->GetIdleWaiter())) {
  if (!context_ || !context_->IsValid()) {
    return;
  }

  {
    TextureDescriptor desc;
    desc.storage_mode = StorageMode::kDevicePrivate;
    desc.format = PixelFormat::kR8G8B8A8UNormInt;
    desc.size = ISize{1, 1};
    empty_texture_ = GetContext()->GetResourceAllocator()->CreateTexture(desc);

    std::array<uint8_t, 4> data = Color::BlackTransparent().ToR8G8B8A8();
    std::shared_ptr<CommandBuffer> cmd_buffer =
        GetContext()->CreateCommandBuffer();
    std::shared_ptr<BlitPass> blit_pass = cmd_buffer->CreateBlitPass();
    HostBuffer& host_buffer = GetTransientsBuffer();
    BufferView buffer_view = host_buffer.Emplace(data);
    blit_pass->AddCopy(buffer_view, empty_texture_);

    if (!blit_pass->EncodeCommands() || !GetContext()
                                             ->GetCommandQueue()
                                             ->Submit({std::move(cmd_buffer)})
                                             .ok()) {
      VALIDATION_LOG << "Failed to create empty texture.";
    }
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
  auto options_no_msaa_no_depth_stencil = ContentContextOptions{
      .sample_count = SampleCount::kCount1,
      .primitive_type = PrimitiveType::kTriangleStrip,
      .color_attachment_pixel_format =
          context_->GetCapabilities()->GetDefaultColorFormat(),
      .has_depth_stencil_attachments = false};
  const auto supports_decal = static_cast<Scalar>(
      context_->GetCapabilities()->SupportsDecalSamplerAddressMode());

  // Futures for the following pipelines may block in case the first frame is
  // rendered without the pipelines being ready. Put pipelines that are more
  // likely to be used first.
  {
    pipelines_->glyph_atlas_pipelines_.CreateDefault(
        *context_, options,
        {static_cast<Scalar>(
            GetContext()->GetCapabilities()->GetDefaultGlyphAtlasFormat() ==
            PixelFormat::kA8UNormInt)});
    pipelines_->solid_fill_pipelines_.CreateDefault(*context_, options);
    pipelines_->texture_pipelines_.CreateDefault(*context_, options);
    pipelines_->fast_gradient_pipelines_.CreateDefault(*context_, options);
    pipelines_->line_pipelines_.CreateDefault(*context_, options);

    if (context_->GetCapabilities()->SupportsSSBO()) {
      pipelines_->linear_gradient_ssbo_fill_pipelines_.CreateDefault(*context_,
                                                                     options);
      pipelines_->radial_gradient_ssbo_fill_pipelines_.CreateDefault(*context_,
                                                                     options);
      pipelines_->conical_gradient_ssbo_fill_pipelines_.CreateDefault(
          *context_, options, {3.0});
      pipelines_->conical_gradient_ssbo_fill_radial_pipelines_.CreateDefault(
          *context_, options, {1.0});
      pipelines_->conical_gradient_ssbo_fill_strip_pipelines_.CreateDefault(
          *context_, options, {2.0});
      pipelines_->conical_gradient_ssbo_fill_strip_and_radial_pipelines_
          .CreateDefault(*context_, options, {0.0});
      pipelines_->sweep_gradient_ssbo_fill_pipelines_.CreateDefault(*context_,
                                                                    options);
    } else {
      pipelines_->linear_gradient_uniform_fill_pipelines_.CreateDefault(
          *context_, options);
      pipelines_->radial_gradient_uniform_fill_pipelines_.CreateDefault(
          *context_, options);
      pipelines_->conical_gradient_uniform_fill_pipelines_.CreateDefault(
          *context_, options);
      pipelines_->conical_gradient_uniform_fill_radial_pipelines_.CreateDefault(
          *context_, options);
      pipelines_->conical_gradient_uniform_fill_strip_pipelines_.CreateDefault(
          *context_, options);
      pipelines_->conical_gradient_uniform_fill_strip_and_radial_pipelines_
          .CreateDefault(*context_, options);
      pipelines_->sweep_gradient_uniform_fill_pipelines_.CreateDefault(
          *context_, options);

      pipelines_->linear_gradient_fill_pipelines_.CreateDefault(*context_,
                                                                options);
      pipelines_->radial_gradient_fill_pipelines_.CreateDefault(*context_,
                                                                options);
      pipelines_->conical_gradient_fill_pipelines_.CreateDefault(*context_,
                                                                 options);
      pipelines_->conical_gradient_fill_radial_pipelines_.CreateDefault(
          *context_, options);
      pipelines_->conical_gradient_fill_strip_pipelines_.CreateDefault(
          *context_, options);
      pipelines_->conical_gradient_fill_strip_and_radial_pipelines_
          .CreateDefault(*context_, options);
      pipelines_->sweep_gradient_fill_pipelines_.CreateDefault(*context_,
                                                               options);
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
      color_attachment.second.write_mask = ColorWriteMaskBits::kNone;
    }
    clip_pipeline_descriptor->SetColorAttachmentDescriptors(
        std::move(clip_color_attachments));
    if (GetContext()->GetFlags().lazy_shader_mode) {
      pipelines_->clip_pipelines_.SetDefaultDescriptor(
          clip_pipeline_descriptor);
      pipelines_->clip_pipelines_.SetDefault(options, nullptr);
    } else {
      pipelines_->clip_pipelines_.SetDefault(
          options,
          std::make_unique<ClipPipeline>(*context_, clip_pipeline_descriptor));
    }
    pipelines_->texture_downsample_pipelines_.CreateDefault(
        *context_, options_no_msaa_no_depth_stencil);
    pipelines_->rrect_blur_pipelines_.CreateDefault(*context_,
                                                    options_trianglestrip);
    pipelines_->texture_strict_src_pipelines_.CreateDefault(*context_, options);
    pipelines_->tiled_texture_pipelines_.CreateDefault(*context_, options,
                                                       {supports_decal});
    pipelines_->gaussian_blur_pipelines_.CreateDefault(
        *context_, options_no_msaa_no_depth_stencil, {supports_decal});
    pipelines_->border_mask_blur_pipelines_.CreateDefault(
        *context_, options_trianglestrip);
    pipelines_->color_matrix_color_filter_pipelines_.CreateDefault(
        *context_, options_trianglestrip);
    pipelines_->vertices_uber_shader_.CreateDefault(*context_, options,
                                                    {supports_decal});

    const std::array<std::vector<Scalar>, 15> porter_duff_constants =
        GetPorterDuffSpecConstants(supports_decal);
    pipelines_->clear_blend_pipelines_.CreateDefault(
        *context_, options_trianglestrip, porter_duff_constants[0]);
    pipelines_->source_blend_pipelines_.CreateDefault(
        *context_, options_trianglestrip, porter_duff_constants[1]);
    pipelines_->destination_blend_pipelines_.CreateDefault(
        *context_, options_trianglestrip, porter_duff_constants[2]);
    pipelines_->source_over_blend_pipelines_.CreateDefault(
        *context_, options_trianglestrip, porter_duff_constants[3]);
    pipelines_->destination_over_blend_pipelines_.CreateDefault(
        *context_, options_trianglestrip, porter_duff_constants[4]);
    pipelines_->source_in_blend_pipelines_.CreateDefault(
        *context_, options_trianglestrip, porter_duff_constants[5]);
    pipelines_->destination_in_blend_pipelines_.CreateDefault(
        *context_, options_trianglestrip, porter_duff_constants[6]);
    pipelines_->source_out_blend_pipelines_.CreateDefault(
        *context_, options_trianglestrip, porter_duff_constants[7]);
    pipelines_->destination_out_blend_pipelines_.CreateDefault(
        *context_, options_trianglestrip, porter_duff_constants[8]);
    pipelines_->source_a_top_blend_pipelines_.CreateDefault(
        *context_, options_trianglestrip, porter_duff_constants[9]);
    pipelines_->destination_a_top_blend_pipelines_.CreateDefault(
        *context_, options_trianglestrip, porter_duff_constants[10]);
    pipelines_->xor_blend_pipelines_.CreateDefault(
        *context_, options_trianglestrip, porter_duff_constants[11]);
    pipelines_->plus_blend_pipelines_.CreateDefault(
        *context_, options_trianglestrip, porter_duff_constants[12]);
    pipelines_->modulate_blend_pipelines_.CreateDefault(
        *context_, options_trianglestrip, porter_duff_constants[13]);
    pipelines_->screen_blend_pipelines_.CreateDefault(
        *context_, options_trianglestrip, porter_duff_constants[14]);
  }

  if (context_->GetCapabilities()->SupportsFramebufferFetch()) {
    pipelines_->framebuffer_blend_color_pipelines_.CreateDefault(
        *context_, options_trianglestrip,
        {static_cast<Scalar>(BlendSelectValues::kColor), supports_decal});
    pipelines_->framebuffer_blend_colorburn_pipelines_.CreateDefault(
        *context_, options_trianglestrip,
        {static_cast<Scalar>(BlendSelectValues::kColorBurn), supports_decal});
    pipelines_->framebuffer_blend_colordodge_pipelines_.CreateDefault(
        *context_, options_trianglestrip,
        {static_cast<Scalar>(BlendSelectValues::kColorDodge), supports_decal});
    pipelines_->framebuffer_blend_darken_pipelines_.CreateDefault(
        *context_, options_trianglestrip,
        {static_cast<Scalar>(BlendSelectValues::kDarken), supports_decal});
    pipelines_->framebuffer_blend_difference_pipelines_.CreateDefault(
        *context_, options_trianglestrip,
        {static_cast<Scalar>(BlendSelectValues::kDifference), supports_decal});
    pipelines_->framebuffer_blend_exclusion_pipelines_.CreateDefault(
        *context_, options_trianglestrip,
        {static_cast<Scalar>(BlendSelectValues::kExclusion), supports_decal});
    pipelines_->framebuffer_blend_hardlight_pipelines_.CreateDefault(
        *context_, options_trianglestrip,
        {static_cast<Scalar>(BlendSelectValues::kHardLight), supports_decal});
    pipelines_->framebuffer_blend_hue_pipelines_.CreateDefault(
        *context_, options_trianglestrip,
        {static_cast<Scalar>(BlendSelectValues::kHue), supports_decal});
    pipelines_->framebuffer_blend_lighten_pipelines_.CreateDefault(
        *context_, options_trianglestrip,
        {static_cast<Scalar>(BlendSelectValues::kLighten), supports_decal});
    pipelines_->framebuffer_blend_luminosity_pipelines_.CreateDefault(
        *context_, options_trianglestrip,
        {static_cast<Scalar>(BlendSelectValues::kLuminosity), supports_decal});
    pipelines_->framebuffer_blend_multiply_pipelines_.CreateDefault(
        *context_, options_trianglestrip,
        {static_cast<Scalar>(BlendSelectValues::kMultiply), supports_decal});
    pipelines_->framebuffer_blend_overlay_pipelines_.CreateDefault(
        *context_, options_trianglestrip,
        {static_cast<Scalar>(BlendSelectValues::kOverlay), supports_decal});
    pipelines_->framebuffer_blend_saturation_pipelines_.CreateDefault(
        *context_, options_trianglestrip,
        {static_cast<Scalar>(BlendSelectValues::kSaturation), supports_decal});
    pipelines_->framebuffer_blend_screen_pipelines_.CreateDefault(
        *context_, options_trianglestrip,
        {static_cast<Scalar>(BlendSelectValues::kScreen), supports_decal});
    pipelines_->framebuffer_blend_softlight_pipelines_.CreateDefault(
        *context_, options_trianglestrip,
        {static_cast<Scalar>(BlendSelectValues::kSoftLight), supports_decal});
  } else {
    pipelines_->blend_color_pipelines_.CreateDefault(
        *context_, options_trianglestrip,
        {static_cast<Scalar>(BlendSelectValues::kColor), supports_decal});
    pipelines_->blend_colorburn_pipelines_.CreateDefault(
        *context_, options_trianglestrip,
        {static_cast<Scalar>(BlendSelectValues::kColorBurn), supports_decal});
    pipelines_->blend_colordodge_pipelines_.CreateDefault(
        *context_, options_trianglestrip,
        {static_cast<Scalar>(BlendSelectValues::kColorDodge), supports_decal});
    pipelines_->blend_darken_pipelines_.CreateDefault(
        *context_, options_trianglestrip,
        {static_cast<Scalar>(BlendSelectValues::kDarken), supports_decal});
    pipelines_->blend_difference_pipelines_.CreateDefault(
        *context_, options_trianglestrip,
        {static_cast<Scalar>(BlendSelectValues::kDifference), supports_decal});
    pipelines_->blend_exclusion_pipelines_.CreateDefault(
        *context_, options_trianglestrip,
        {static_cast<Scalar>(BlendSelectValues::kExclusion), supports_decal});
    pipelines_->blend_hardlight_pipelines_.CreateDefault(
        *context_, options_trianglestrip,
        {static_cast<Scalar>(BlendSelectValues::kHardLight), supports_decal});
    pipelines_->blend_hue_pipelines_.CreateDefault(
        *context_, options_trianglestrip,
        {static_cast<Scalar>(BlendSelectValues::kHue), supports_decal});
    pipelines_->blend_lighten_pipelines_.CreateDefault(
        *context_, options_trianglestrip,
        {static_cast<Scalar>(BlendSelectValues::kLighten), supports_decal});
    pipelines_->blend_luminosity_pipelines_.CreateDefault(
        *context_, options_trianglestrip,
        {static_cast<Scalar>(BlendSelectValues::kLuminosity), supports_decal});
    pipelines_->blend_multiply_pipelines_.CreateDefault(
        *context_, options_trianglestrip,
        {static_cast<Scalar>(BlendSelectValues::kMultiply), supports_decal});
    pipelines_->blend_overlay_pipelines_.CreateDefault(
        *context_, options_trianglestrip,
        {static_cast<Scalar>(BlendSelectValues::kOverlay), supports_decal});
    pipelines_->blend_saturation_pipelines_.CreateDefault(
        *context_, options_trianglestrip,
        {static_cast<Scalar>(BlendSelectValues::kSaturation), supports_decal});
    pipelines_->blend_screen_pipelines_.CreateDefault(
        *context_, options_trianglestrip,
        {static_cast<Scalar>(BlendSelectValues::kScreen), supports_decal});
    pipelines_->blend_softlight_pipelines_.CreateDefault(
        *context_, options_trianglestrip,
        {static_cast<Scalar>(BlendSelectValues::kSoftLight), supports_decal});
  }

  pipelines_->morphology_filter_pipelines_.CreateDefault(
      *context_, options_trianglestrip, {supports_decal});
  pipelines_->linear_to_srgb_filter_pipelines_.CreateDefault(
      *context_, options_trianglestrip);
  pipelines_->srgb_to_linear_filter_pipelines_.CreateDefault(
      *context_, options_trianglestrip);
  pipelines_->yuv_to_rgb_filter_pipelines_.CreateDefault(*context_,
                                                         options_trianglestrip);

#if defined(IMPELLER_ENABLE_OPENGLES)
  if (GetContext()->GetBackendType() == Context::BackendType::kOpenGLES) {
#if !defined(FML_OS_MACOSX)
    // GLES only shader that is unsupported on macOS.
    pipelines_->tiled_texture_external_pipelines_.CreateDefault(*context_,
                                                                options);
    pipelines_->tiled_texture_uv_external_pipelines_.CreateDefault(*context_,
                                                                   options);
#endif  // !defined(FML_OS_MACOSX)
    pipelines_->texture_downsample_gles_pipelines_.CreateDefault(
        *context_, options_trianglestrip);
  }
#endif  // IMPELLER_ENABLE_OPENGLES

  is_valid_ = true;
  InitializeCommonlyUsedShadersIfNeeded();
}

ContentContext::~ContentContext() = default;

bool ContentContext::IsValid() const {
  return is_valid_;
}

std::shared_ptr<Texture> ContentContext::GetEmptyTexture() const {
  return empty_texture_;
}

fml::StatusOr<RenderTarget> ContentContext::MakeSubpass(
    std::string_view label,
    ISize texture_size,
    const std::shared_ptr<CommandBuffer>& command_buffer,
    const SubpassCallback& subpass_callback,
    bool msaa_enabled,
    bool depth_stencil_enabled,
    int32_t mip_count) const {
  const std::shared_ptr<Context>& context = GetContext();
  RenderTarget subpass_target;

  std::optional<RenderTarget::AttachmentConfig> depth_stencil_config =
      depth_stencil_enabled ? RenderTarget::kDefaultStencilAttachmentConfig
                            : std::optional<RenderTarget::AttachmentConfig>();

  if (context->GetCapabilities()->SupportsOffscreenMSAA() && msaa_enabled) {
    subpass_target = GetRenderTargetCache()->CreateOffscreenMSAA(
        *context, texture_size,
        /*mip_count=*/mip_count, label,
        RenderTarget::kDefaultColorAttachmentConfigMSAA, depth_stencil_config);
  } else {
    subpass_target = GetRenderTargetCache()->CreateOffscreen(
        *context, texture_size,
        /*mip_count=*/mip_count, label,
        RenderTarget::kDefaultColorAttachmentConfig, depth_stencil_config);
  }
  return MakeSubpass(label, subpass_target, command_buffer, subpass_callback);
}

fml::StatusOr<RenderTarget> ContentContext::MakeSubpass(
    std::string_view label,
    const RenderTarget& subpass_target,
    const std::shared_ptr<CommandBuffer>& command_buffer,
    const SubpassCallback& subpass_callback) const {
  const std::shared_ptr<Context>& context = GetContext();

  auto subpass_texture = subpass_target.GetRenderTargetTexture();
  if (!subpass_texture) {
    return fml::Status(fml::StatusCode::kUnknown, "");
  }

  auto sub_renderpass = command_buffer->CreateRenderPass(subpass_target);
  if (!sub_renderpass) {
    return fml::Status(fml::StatusCode::kUnknown, "");
  }
  sub_renderpass->SetLabel(label);

  if (!subpass_callback(*this, *sub_renderpass)) {
    return fml::Status(fml::StatusCode::kUnknown, "");
  }

  if (!sub_renderpass->EncodeCommands()) {
    return fml::Status(fml::StatusCode::kUnknown, "");
  }

  const std::shared_ptr<Texture>& target_texture =
      subpass_target.GetRenderTargetTexture();
  if (target_texture->GetMipCount() > 1) {
    fml::Status mipmap_status =
        AddMipmapGeneration(command_buffer, context, target_texture);
    if (!mipmap_status.ok()) {
      return mipmap_status;
    }
  }

  return subpass_target;
}

Tessellator& ContentContext::GetTessellator() const {
  return *tessellator_;
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

PipelineRef ContentContext::GetCachedRuntimeEffectPipeline(
    const std::string& unique_entrypoint_name,
    const ContentContextOptions& options,
    const std::function<std::shared_ptr<Pipeline<PipelineDescriptor>>()>&
        create_callback) const {
  RuntimeEffectPipelineKey key{unique_entrypoint_name, options};
  auto it = runtime_effect_pipelines_.find(key);
  if (it == runtime_effect_pipelines_.end()) {
    it = runtime_effect_pipelines_.insert(it, {key, create_callback()});
  }
  return raw_ptr(it->second);
}

void ContentContext::ClearCachedRuntimeEffectPipeline(
    const std::string& unique_entrypoint_name) const {
  for (auto it = runtime_effect_pipelines_.begin();
       it != runtime_effect_pipelines_.end();) {
    if (it->first.unique_entrypoint_name == unique_entrypoint_name) {
      it = runtime_effect_pipelines_.erase(it);
    } else {
      it++;
    }
  }
}

void ContentContext::InitializeCommonlyUsedShadersIfNeeded() const {
  if (GetContext()->GetFlags().lazy_shader_mode) {
    return;
  }
  GetContext()->InitializeCommonlyUsedShadersIfNeeded();
}

PipelineRef ContentContext::GetFastGradientPipeline(
    ContentContextOptions opts) const {
  return GetPipeline(this, pipelines_->fast_gradient_pipelines_, opts);
}

PipelineRef ContentContext::GetLinearGradientFillPipeline(
    ContentContextOptions opts) const {
  return GetPipeline(this, pipelines_->linear_gradient_fill_pipelines_, opts);
}

PipelineRef ContentContext::GetLinearGradientUniformFillPipeline(
    ContentContextOptions opts) const {
  return GetPipeline(this, pipelines_->linear_gradient_uniform_fill_pipelines_,
                     opts);
}

PipelineRef ContentContext::GetRadialGradientUniformFillPipeline(
    ContentContextOptions opts) const {
  return GetPipeline(this, pipelines_->radial_gradient_uniform_fill_pipelines_,
                     opts);
}

PipelineRef ContentContext::GetSweepGradientUniformFillPipeline(
    ContentContextOptions opts) const {
  return GetPipeline(this, pipelines_->sweep_gradient_uniform_fill_pipelines_,
                     opts);
}

PipelineRef ContentContext::GetLinearGradientSSBOFillPipeline(
    ContentContextOptions opts) const {
  FML_DCHECK(GetDeviceCapabilities().SupportsSSBO());
  return GetPipeline(this, pipelines_->linear_gradient_ssbo_fill_pipelines_,
                     opts);
}

PipelineRef ContentContext::GetRadialGradientSSBOFillPipeline(
    ContentContextOptions opts) const {
  FML_DCHECK(GetDeviceCapabilities().SupportsSSBO());
  return GetPipeline(this, pipelines_->radial_gradient_ssbo_fill_pipelines_,
                     opts);
}

PipelineRef ContentContext::GetConicalGradientUniformFillPipeline(
    ContentContextOptions opts,
    ConicalKind kind) const {
  switch (kind) {
    case ConicalKind::kConical:
      return GetPipeline(
          this, pipelines_->conical_gradient_uniform_fill_pipelines_, opts);
    case ConicalKind::kRadial:
      return GetPipeline(
          this, pipelines_->conical_gradient_uniform_fill_radial_pipelines_,
          opts);
    case ConicalKind::kStrip:
      return GetPipeline(
          this, pipelines_->conical_gradient_uniform_fill_strip_pipelines_,
          opts);
    case ConicalKind::kStripAndRadial:
      return GetPipeline(
          this,
          pipelines_->conical_gradient_uniform_fill_strip_and_radial_pipelines_,
          opts);
  }
}

PipelineRef ContentContext::GetConicalGradientSSBOFillPipeline(
    ContentContextOptions opts,
    ConicalKind kind) const {
  FML_DCHECK(GetDeviceCapabilities().SupportsSSBO());
  switch (kind) {
    case ConicalKind::kConical:
      return GetPipeline(
          this, pipelines_->conical_gradient_ssbo_fill_pipelines_, opts);
    case ConicalKind::kRadial:
      return GetPipeline(
          this, pipelines_->conical_gradient_ssbo_fill_radial_pipelines_, opts);
    case ConicalKind::kStrip:
      return GetPipeline(
          this, pipelines_->conical_gradient_ssbo_fill_strip_pipelines_, opts);
    case ConicalKind::kStripAndRadial:
      return GetPipeline(
          this,
          pipelines_->conical_gradient_ssbo_fill_strip_and_radial_pipelines_,
          opts);
  }
}

PipelineRef ContentContext::GetSweepGradientSSBOFillPipeline(
    ContentContextOptions opts) const {
  FML_DCHECK(GetDeviceCapabilities().SupportsSSBO());
  return GetPipeline(this, pipelines_->sweep_gradient_ssbo_fill_pipelines_,
                     opts);
}

PipelineRef ContentContext::GetRadialGradientFillPipeline(
    ContentContextOptions opts) const {
  return GetPipeline(this, pipelines_->radial_gradient_fill_pipelines_, opts);
}

PipelineRef ContentContext::GetConicalGradientFillPipeline(
    ContentContextOptions opts,
    ConicalKind kind) const {
  switch (kind) {
    case ConicalKind::kConical:
      return GetPipeline(this, pipelines_->conical_gradient_fill_pipelines_,
                         opts);
    case ConicalKind::kRadial:
      return GetPipeline(
          this, pipelines_->conical_gradient_fill_radial_pipelines_, opts);
    case ConicalKind::kStrip:
      return GetPipeline(
          this, pipelines_->conical_gradient_fill_strip_pipelines_, opts);
    case ConicalKind::kStripAndRadial:
      return GetPipeline(
          this, pipelines_->conical_gradient_fill_strip_and_radial_pipelines_,
          opts);
  }
}

PipelineRef ContentContext::GetRRectBlurPipeline(
    ContentContextOptions opts) const {
  return GetPipeline(this, pipelines_->rrect_blur_pipelines_, opts);
}

PipelineRef ContentContext::GetSweepGradientFillPipeline(
    ContentContextOptions opts) const {
  return GetPipeline(this, pipelines_->sweep_gradient_fill_pipelines_, opts);
}

PipelineRef ContentContext::GetSolidFillPipeline(
    ContentContextOptions opts) const {
  return GetPipeline(this, pipelines_->solid_fill_pipelines_, opts);
}

PipelineRef ContentContext::GetTexturePipeline(
    ContentContextOptions opts) const {
  return GetPipeline(this, pipelines_->texture_pipelines_, opts);
}

PipelineRef ContentContext::GetTextureStrictSrcPipeline(
    ContentContextOptions opts) const {
  return GetPipeline(this, pipelines_->texture_strict_src_pipelines_, opts);
}

PipelineRef ContentContext::GetTiledTexturePipeline(
    ContentContextOptions opts) const {
  return GetPipeline(this, pipelines_->tiled_texture_pipelines_, opts);
}

PipelineRef ContentContext::GetGaussianBlurPipeline(
    ContentContextOptions opts) const {
  return GetPipeline(this, pipelines_->gaussian_blur_pipelines_, opts);
}

PipelineRef ContentContext::GetBorderMaskBlurPipeline(
    ContentContextOptions opts) const {
  return GetPipeline(this, pipelines_->border_mask_blur_pipelines_, opts);
}

PipelineRef ContentContext::GetMorphologyFilterPipeline(
    ContentContextOptions opts) const {
  return GetPipeline(this, pipelines_->morphology_filter_pipelines_, opts);
}

PipelineRef ContentContext::GetColorMatrixColorFilterPipeline(
    ContentContextOptions opts) const {
  return GetPipeline(this, pipelines_->color_matrix_color_filter_pipelines_,
                     opts);
}

PipelineRef ContentContext::GetLinearToSrgbFilterPipeline(
    ContentContextOptions opts) const {
  return GetPipeline(this, pipelines_->linear_to_srgb_filter_pipelines_, opts);
}

PipelineRef ContentContext::GetSrgbToLinearFilterPipeline(
    ContentContextOptions opts) const {
  return GetPipeline(this, pipelines_->srgb_to_linear_filter_pipelines_, opts);
}

PipelineRef ContentContext::GetClipPipeline(ContentContextOptions opts) const {
  return GetPipeline(this, pipelines_->clip_pipelines_, opts);
}

PipelineRef ContentContext::GetGlyphAtlasPipeline(
    ContentContextOptions opts) const {
  return GetPipeline(this, pipelines_->glyph_atlas_pipelines_, opts);
}

PipelineRef ContentContext::GetYUVToRGBFilterPipeline(
    ContentContextOptions opts) const {
  return GetPipeline(this, pipelines_->yuv_to_rgb_filter_pipelines_, opts);
}

PipelineRef ContentContext::GetPorterDuffPipeline(
    BlendMode mode,
    ContentContextOptions opts) const {
  switch (mode) {
    case BlendMode::kClear:
      return GetClearBlendPipeline(opts);
    case BlendMode::kSrc:
      return GetSourceBlendPipeline(opts);
    case BlendMode::kDst:
      return GetDestinationBlendPipeline(opts);
    case BlendMode::kSrcOver:
      return GetSourceOverBlendPipeline(opts);
    case BlendMode::kDstOver:
      return GetDestinationOverBlendPipeline(opts);
    case BlendMode::kSrcIn:
      return GetSourceInBlendPipeline(opts);
    case BlendMode::kDstIn:
      return GetDestinationInBlendPipeline(opts);
    case BlendMode::kSrcOut:
      return GetSourceOutBlendPipeline(opts);
    case BlendMode::kDstOut:
      return GetDestinationOutBlendPipeline(opts);
    case BlendMode::kSrcATop:
      return GetSourceATopBlendPipeline(opts);
    case BlendMode::kDstATop:
      return GetDestinationATopBlendPipeline(opts);
    case BlendMode::kXor:
      return GetXorBlendPipeline(opts);
    case BlendMode::kPlus:
      return GetPlusBlendPipeline(opts);
    case BlendMode::kModulate:
      return GetModulateBlendPipeline(opts);
    case BlendMode::kScreen:
      return GetScreenBlendPipeline(opts);
    case BlendMode::kOverlay:
    case BlendMode::kDarken:
    case BlendMode::kLighten:
    case BlendMode::kColorDodge:
    case BlendMode::kColorBurn:
    case BlendMode::kHardLight:
    case BlendMode::kSoftLight:
    case BlendMode::kDifference:
    case BlendMode::kExclusion:
    case BlendMode::kMultiply:
    case BlendMode::kHue:
    case BlendMode::kSaturation:
    case BlendMode::kColor:
    case BlendMode::kLuminosity:
      VALIDATION_LOG << "Invalid porter duff blend mode "
                     << BlendModeToString(mode);
      return GetClearBlendPipeline(opts);
      break;
  }
}

PipelineRef ContentContext::GetClearBlendPipeline(
    ContentContextOptions opts) const {
  return GetPipeline(this, pipelines_->clear_blend_pipelines_, opts);
}

PipelineRef ContentContext::GetSourceBlendPipeline(
    ContentContextOptions opts) const {
  return GetPipeline(this, pipelines_->source_blend_pipelines_, opts);
}

PipelineRef ContentContext::GetDestinationBlendPipeline(
    ContentContextOptions opts) const {
  return GetPipeline(this, pipelines_->destination_blend_pipelines_, opts);
}

PipelineRef ContentContext::GetSourceOverBlendPipeline(
    ContentContextOptions opts) const {
  return GetPipeline(this, pipelines_->source_over_blend_pipelines_, opts);
}

PipelineRef ContentContext::GetDestinationOverBlendPipeline(
    ContentContextOptions opts) const {
  return GetPipeline(this, pipelines_->destination_over_blend_pipelines_, opts);
}

PipelineRef ContentContext::GetSourceInBlendPipeline(
    ContentContextOptions opts) const {
  return GetPipeline(this, pipelines_->source_in_blend_pipelines_, opts);
}

PipelineRef ContentContext::GetDestinationInBlendPipeline(
    ContentContextOptions opts) const {
  return GetPipeline(this, pipelines_->destination_in_blend_pipelines_, opts);
}

PipelineRef ContentContext::GetSourceOutBlendPipeline(
    ContentContextOptions opts) const {
  return GetPipeline(this, pipelines_->source_out_blend_pipelines_, opts);
}

PipelineRef ContentContext::GetDestinationOutBlendPipeline(
    ContentContextOptions opts) const {
  return GetPipeline(this, pipelines_->destination_out_blend_pipelines_, opts);
}

PipelineRef ContentContext::GetSourceATopBlendPipeline(
    ContentContextOptions opts) const {
  return GetPipeline(this, pipelines_->source_a_top_blend_pipelines_, opts);
}

PipelineRef ContentContext::GetDestinationATopBlendPipeline(
    ContentContextOptions opts) const {
  return GetPipeline(this, pipelines_->destination_a_top_blend_pipelines_,
                     opts);
}

PipelineRef ContentContext::GetXorBlendPipeline(
    ContentContextOptions opts) const {
  return GetPipeline(this, pipelines_->xor_blend_pipelines_, opts);
}

PipelineRef ContentContext::GetPlusBlendPipeline(
    ContentContextOptions opts) const {
  return GetPipeline(this, pipelines_->plus_blend_pipelines_, opts);
}

PipelineRef ContentContext::GetModulateBlendPipeline(
    ContentContextOptions opts) const {
  return GetPipeline(this, pipelines_->modulate_blend_pipelines_, opts);
}

PipelineRef ContentContext::GetScreenBlendPipeline(
    ContentContextOptions opts) const {
  return GetPipeline(this, pipelines_->screen_blend_pipelines_, opts);
}

PipelineRef ContentContext::GetBlendColorPipeline(
    ContentContextOptions opts) const {
  return GetPipeline(this, pipelines_->blend_color_pipelines_, opts);
}

PipelineRef ContentContext::GetBlendColorBurnPipeline(
    ContentContextOptions opts) const {
  return GetPipeline(this, pipelines_->blend_colorburn_pipelines_, opts);
}

PipelineRef ContentContext::GetBlendColorDodgePipeline(
    ContentContextOptions opts) const {
  return GetPipeline(this, pipelines_->blend_colordodge_pipelines_, opts);
}

PipelineRef ContentContext::GetBlendDarkenPipeline(
    ContentContextOptions opts) const {
  return GetPipeline(this, pipelines_->blend_darken_pipelines_, opts);
}

PipelineRef ContentContext::GetBlendDifferencePipeline(
    ContentContextOptions opts) const {
  return GetPipeline(this, pipelines_->blend_difference_pipelines_, opts);
}

PipelineRef ContentContext::GetBlendExclusionPipeline(
    ContentContextOptions opts) const {
  return GetPipeline(this, pipelines_->blend_exclusion_pipelines_, opts);
}

PipelineRef ContentContext::GetBlendHardLightPipeline(
    ContentContextOptions opts) const {
  return GetPipeline(this, pipelines_->blend_hardlight_pipelines_, opts);
}

PipelineRef ContentContext::GetBlendHuePipeline(
    ContentContextOptions opts) const {
  return GetPipeline(this, pipelines_->blend_hue_pipelines_, opts);
}

PipelineRef ContentContext::GetBlendLightenPipeline(
    ContentContextOptions opts) const {
  return GetPipeline(this, pipelines_->blend_lighten_pipelines_, opts);
}

PipelineRef ContentContext::GetBlendLuminosityPipeline(
    ContentContextOptions opts) const {
  return GetPipeline(this, pipelines_->blend_luminosity_pipelines_, opts);
}

PipelineRef ContentContext::GetBlendMultiplyPipeline(
    ContentContextOptions opts) const {
  return GetPipeline(this, pipelines_->blend_multiply_pipelines_, opts);
}

PipelineRef ContentContext::GetBlendOverlayPipeline(
    ContentContextOptions opts) const {
  return GetPipeline(this, pipelines_->blend_overlay_pipelines_, opts);
}

PipelineRef ContentContext::GetBlendSaturationPipeline(
    ContentContextOptions opts) const {
  return GetPipeline(this, pipelines_->blend_saturation_pipelines_, opts);
}

PipelineRef ContentContext::GetBlendScreenPipeline(
    ContentContextOptions opts) const {
  return GetPipeline(this, pipelines_->blend_screen_pipelines_, opts);
}

PipelineRef ContentContext::GetBlendSoftLightPipeline(
    ContentContextOptions opts) const {
  return GetPipeline(this, pipelines_->blend_softlight_pipelines_, opts);
}

PipelineRef ContentContext::GetDownsamplePipeline(
    ContentContextOptions opts) const {
  return GetPipeline(this, pipelines_->texture_downsample_pipelines_, opts);
}

PipelineRef ContentContext::GetFramebufferBlendColorPipeline(
    ContentContextOptions opts) const {
  FML_DCHECK(GetDeviceCapabilities().SupportsFramebufferFetch());
  return GetPipeline(this, pipelines_->framebuffer_blend_color_pipelines_,
                     opts);
}

PipelineRef ContentContext::GetFramebufferBlendColorBurnPipeline(
    ContentContextOptions opts) const {
  FML_DCHECK(GetDeviceCapabilities().SupportsFramebufferFetch());
  return GetPipeline(this, pipelines_->framebuffer_blend_colorburn_pipelines_,
                     opts);
}

PipelineRef ContentContext::GetFramebufferBlendColorDodgePipeline(
    ContentContextOptions opts) const {
  FML_DCHECK(GetDeviceCapabilities().SupportsFramebufferFetch());
  return GetPipeline(this, pipelines_->framebuffer_blend_colordodge_pipelines_,
                     opts);
}

PipelineRef ContentContext::GetFramebufferBlendDarkenPipeline(
    ContentContextOptions opts) const {
  FML_DCHECK(GetDeviceCapabilities().SupportsFramebufferFetch());
  return GetPipeline(this, pipelines_->framebuffer_blend_darken_pipelines_,
                     opts);
}

PipelineRef ContentContext::GetFramebufferBlendDifferencePipeline(
    ContentContextOptions opts) const {
  FML_DCHECK(GetDeviceCapabilities().SupportsFramebufferFetch());
  return GetPipeline(this, pipelines_->framebuffer_blend_difference_pipelines_,
                     opts);
}

PipelineRef ContentContext::GetFramebufferBlendExclusionPipeline(
    ContentContextOptions opts) const {
  FML_DCHECK(GetDeviceCapabilities().SupportsFramebufferFetch());
  return GetPipeline(this, pipelines_->framebuffer_blend_exclusion_pipelines_,
                     opts);
}

PipelineRef ContentContext::GetFramebufferBlendHardLightPipeline(
    ContentContextOptions opts) const {
  FML_DCHECK(GetDeviceCapabilities().SupportsFramebufferFetch());
  return GetPipeline(this, pipelines_->framebuffer_blend_hardlight_pipelines_,
                     opts);
}

PipelineRef ContentContext::GetFramebufferBlendHuePipeline(
    ContentContextOptions opts) const {
  FML_DCHECK(GetDeviceCapabilities().SupportsFramebufferFetch());
  return GetPipeline(this, pipelines_->framebuffer_blend_hue_pipelines_, opts);
}

PipelineRef ContentContext::GetFramebufferBlendLightenPipeline(
    ContentContextOptions opts) const {
  FML_DCHECK(GetDeviceCapabilities().SupportsFramebufferFetch());
  return GetPipeline(this, pipelines_->framebuffer_blend_lighten_pipelines_,
                     opts);
}

PipelineRef ContentContext::GetFramebufferBlendLuminosityPipeline(
    ContentContextOptions opts) const {
  FML_DCHECK(GetDeviceCapabilities().SupportsFramebufferFetch());
  return GetPipeline(this, pipelines_->framebuffer_blend_luminosity_pipelines_,
                     opts);
}

PipelineRef ContentContext::GetFramebufferBlendMultiplyPipeline(
    ContentContextOptions opts) const {
  FML_DCHECK(GetDeviceCapabilities().SupportsFramebufferFetch());
  return GetPipeline(this, pipelines_->framebuffer_blend_multiply_pipelines_,
                     opts);
}

PipelineRef ContentContext::GetFramebufferBlendOverlayPipeline(
    ContentContextOptions opts) const {
  FML_DCHECK(GetDeviceCapabilities().SupportsFramebufferFetch());
  return GetPipeline(this, pipelines_->framebuffer_blend_overlay_pipelines_,
                     opts);
}

PipelineRef ContentContext::GetFramebufferBlendSaturationPipeline(
    ContentContextOptions opts) const {
  FML_DCHECK(GetDeviceCapabilities().SupportsFramebufferFetch());
  return GetPipeline(this, pipelines_->framebuffer_blend_saturation_pipelines_,
                     opts);
}

PipelineRef ContentContext::GetFramebufferBlendScreenPipeline(
    ContentContextOptions opts) const {
  FML_DCHECK(GetDeviceCapabilities().SupportsFramebufferFetch());
  return GetPipeline(this, pipelines_->framebuffer_blend_screen_pipelines_,
                     opts);
}

PipelineRef ContentContext::GetFramebufferBlendSoftLightPipeline(
    ContentContextOptions opts) const {
  FML_DCHECK(GetDeviceCapabilities().SupportsFramebufferFetch());
  return GetPipeline(this, pipelines_->framebuffer_blend_softlight_pipelines_,
                     opts);
}

PipelineRef ContentContext::GetDrawVerticesUberShader(
    ContentContextOptions opts) const {
  return GetPipeline(this, pipelines_->vertices_uber_shader_, opts);
}

PipelineRef ContentContext::GetLinePipeline(ContentContextOptions opts) const {
  return GetPipeline(this, pipelines_->line_pipelines_, opts);
}

#ifdef IMPELLER_ENABLE_OPENGLES
PipelineRef ContentContext::GetDownsampleTextureGlesPipeline(
    ContentContextOptions opts) const {
  return GetPipeline(this, pipelines_->texture_downsample_gles_pipelines_,
                     opts);
}

PipelineRef ContentContext::GetTiledTextureExternalPipeline(
    ContentContextOptions opts) const {
  FML_DCHECK(GetContext()->GetBackendType() == Context::BackendType::kOpenGLES);
  return GetPipeline(this, pipelines_->tiled_texture_external_pipelines_, opts);
}

PipelineRef ContentContext::GetTiledTextureUvExternalPipeline(
    ContentContextOptions opts) const {
  FML_DCHECK(GetContext()->GetBackendType() == Context::BackendType::kOpenGLES);
  return GetPipeline(this, pipelines_->tiled_texture_uv_external_pipelines_,
                     opts);
}
#endif  // IMPELLER_ENABLE_OPENGLES

}  // namespace impeller
