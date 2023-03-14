// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <memory>
#include <optional>
#include <unordered_map>

#include "flutter/fml/hash_combine.h"
#include "flutter/fml/logging.h"
#include "flutter/fml/macros.h"
#include "impeller/base/validation.h"
#include "impeller/entity/blend.frag.h"
#include "impeller/entity/blend.vert.h"
#include "impeller/entity/border_mask_blur.frag.h"
#include "impeller/entity/border_mask_blur.vert.h"
#include "impeller/entity/color_matrix_color_filter.frag.h"
#include "impeller/entity/color_matrix_color_filter.vert.h"
#include "impeller/entity/conical_gradient_fill.frag.h"
#include "impeller/entity/entity.h"
#include "impeller/entity/gaussian_blur.frag.h"
#include "impeller/entity/gaussian_blur.vert.h"
#include "impeller/entity/gaussian_blur_decal.frag.h"
#include "impeller/entity/glyph_atlas.frag.h"
#include "impeller/entity/glyph_atlas.vert.h"
#include "impeller/entity/glyph_atlas_sdf.frag.h"
#include "impeller/entity/glyph_atlas_sdf.vert.h"
#include "impeller/entity/gradient_fill.vert.h"
#include "impeller/entity/linear_gradient_fill.frag.h"
#include "impeller/entity/linear_to_srgb_filter.frag.h"
#include "impeller/entity/linear_to_srgb_filter.vert.h"
#include "impeller/entity/morphology_filter.frag.h"
#include "impeller/entity/morphology_filter.vert.h"
#include "impeller/entity/radial_gradient_fill.frag.h"
#include "impeller/entity/rrect_blur.frag.h"
#include "impeller/entity/rrect_blur.vert.h"
#include "impeller/entity/solid_fill.frag.h"
#include "impeller/entity/solid_fill.vert.h"
#include "impeller/entity/srgb_to_linear_filter.frag.h"
#include "impeller/entity/srgb_to_linear_filter.vert.h"
#include "impeller/entity/sweep_gradient_fill.frag.h"
#include "impeller/entity/texture_fill.frag.h"
#include "impeller/entity/texture_fill.vert.h"
#include "impeller/entity/tiled_texture_fill.frag.h"
#include "impeller/entity/tiled_texture_fill.vert.h"
#include "impeller/entity/vertices.frag.h"
#include "impeller/entity/yuv_to_rgb_filter.frag.h"
#include "impeller/entity/yuv_to_rgb_filter.vert.h"
#include "impeller/renderer/device_capabilities.h"
#include "impeller/renderer/formats.h"
#include "impeller/renderer/pipeline.h"
#include "impeller/scene/scene_context.h"

#include "impeller/entity/position_color.vert.h"

#include "impeller/scene/scene_context.h"
#include "impeller/typographer/glyph_atlas.h"

#include "impeller/entity/conical_gradient_ssbo_fill.frag.h"
#include "impeller/entity/linear_gradient_ssbo_fill.frag.h"
#include "impeller/entity/radial_gradient_ssbo_fill.frag.h"
#include "impeller/entity/sweep_gradient_ssbo_fill.frag.h"

#include "impeller/entity/advanced_blend.vert.h"
#include "impeller/entity/advanced_blend_color.frag.h"
#include "impeller/entity/advanced_blend_colorburn.frag.h"
#include "impeller/entity/advanced_blend_colordodge.frag.h"
#include "impeller/entity/advanced_blend_darken.frag.h"
#include "impeller/entity/advanced_blend_difference.frag.h"
#include "impeller/entity/advanced_blend_exclusion.frag.h"
#include "impeller/entity/advanced_blend_hardlight.frag.h"
#include "impeller/entity/advanced_blend_hue.frag.h"
#include "impeller/entity/advanced_blend_lighten.frag.h"
#include "impeller/entity/advanced_blend_luminosity.frag.h"
#include "impeller/entity/advanced_blend_multiply.frag.h"
#include "impeller/entity/advanced_blend_overlay.frag.h"
#include "impeller/entity/advanced_blend_saturation.frag.h"
#include "impeller/entity/advanced_blend_screen.frag.h"
#include "impeller/entity/advanced_blend_softlight.frag.h"

#include "impeller/entity/framebuffer_blend.vert.h"
#include "impeller/entity/framebuffer_blend_color.frag.h"
#include "impeller/entity/framebuffer_blend_colorburn.frag.h"
#include "impeller/entity/framebuffer_blend_colordodge.frag.h"
#include "impeller/entity/framebuffer_blend_darken.frag.h"
#include "impeller/entity/framebuffer_blend_difference.frag.h"
#include "impeller/entity/framebuffer_blend_exclusion.frag.h"
#include "impeller/entity/framebuffer_blend_hardlight.frag.h"
#include "impeller/entity/framebuffer_blend_hue.frag.h"
#include "impeller/entity/framebuffer_blend_lighten.frag.h"
#include "impeller/entity/framebuffer_blend_luminosity.frag.h"
#include "impeller/entity/framebuffer_blend_multiply.frag.h"
#include "impeller/entity/framebuffer_blend_overlay.frag.h"
#include "impeller/entity/framebuffer_blend_saturation.frag.h"
#include "impeller/entity/framebuffer_blend_screen.frag.h"
#include "impeller/entity/framebuffer_blend_softlight.frag.h"

namespace impeller {

using LinearGradientFillPipeline =
    RenderPipelineT<GradientFillVertexShader, LinearGradientFillFragmentShader>;
using SolidFillPipeline =
    RenderPipelineT<SolidFillVertexShader, SolidFillFragmentShader>;
using RadialGradientFillPipeline =
    RenderPipelineT<GradientFillVertexShader, RadialGradientFillFragmentShader>;
using ConicalGradientFillPipeline =
    RenderPipelineT<GradientFillVertexShader,
                    ConicalGradientFillFragmentShader>;
using SweepGradientFillPipeline =
    RenderPipelineT<GradientFillVertexShader, SweepGradientFillFragmentShader>;
using LinearGradientSSBOFillPipeline =
    RenderPipelineT<GradientFillVertexShader,
                    LinearGradientSsboFillFragmentShader>;
using ConicalGradientSSBOFillPipeline =
    RenderPipelineT<GradientFillVertexShader,
                    ConicalGradientSsboFillFragmentShader>;
using RadialGradientSSBOFillPipeline =
    RenderPipelineT<GradientFillVertexShader,
                    RadialGradientSsboFillFragmentShader>;
using SweepGradientSSBOFillPipeline =
    RenderPipelineT<GradientFillVertexShader,
                    SweepGradientSsboFillFragmentShader>;
using BlendPipeline = RenderPipelineT<BlendVertexShader, BlendFragmentShader>;
using RRectBlurPipeline =
    RenderPipelineT<RrectBlurVertexShader, RrectBlurFragmentShader>;
using BlendPipeline = RenderPipelineT<BlendVertexShader, BlendFragmentShader>;
using TexturePipeline =
    RenderPipelineT<TextureFillVertexShader, TextureFillFragmentShader>;
using PositionUVPipeline =
    RenderPipelineT<TextureFillVertexShader, TiledTextureFillFragmentShader>;
using TiledTexturePipeline = RenderPipelineT<TiledTextureFillVertexShader,
                                             TiledTextureFillFragmentShader>;
using GaussianBlurPipeline =
    RenderPipelineT<GaussianBlurVertexShader, GaussianBlurFragmentShader>;
using GaussianBlurDecalPipeline =
    RenderPipelineT<GaussianBlurVertexShader, GaussianBlurDecalFragmentShader>;
using BorderMaskBlurPipeline =
    RenderPipelineT<BorderMaskBlurVertexShader, BorderMaskBlurFragmentShader>;
using MorphologyFilterPipeline =
    RenderPipelineT<MorphologyFilterVertexShader,
                    MorphologyFilterFragmentShader>;
using ColorMatrixColorFilterPipeline =
    RenderPipelineT<ColorMatrixColorFilterVertexShader,
                    ColorMatrixColorFilterFragmentShader>;
using LinearToSrgbFilterPipeline =
    RenderPipelineT<LinearToSrgbFilterVertexShader,
                    LinearToSrgbFilterFragmentShader>;
using SrgbToLinearFilterPipeline =
    RenderPipelineT<SrgbToLinearFilterVertexShader,
                    SrgbToLinearFilterFragmentShader>;
using GlyphAtlasPipeline =
    RenderPipelineT<GlyphAtlasVertexShader, GlyphAtlasFragmentShader>;
using GlyphAtlasSdfPipeline =
    RenderPipelineT<GlyphAtlasSdfVertexShader, GlyphAtlasSdfFragmentShader>;
// Instead of requiring new shaders for clips, the solid fill stages are used
// to redirect writing to the stencil instead of color attachments.
using ClipPipeline =
    RenderPipelineT<SolidFillVertexShader, SolidFillFragmentShader>;

using GeometryColorPipeline =
    RenderPipelineT<PositionColorVertexShader, VerticesFragmentShader>;
using YUVToRGBFilterPipeline =
    RenderPipelineT<YuvToRgbFilterVertexShader, YuvToRgbFilterFragmentShader>;

// Advanced blends
using BlendColorPipeline = RenderPipelineT<AdvancedBlendVertexShader,
                                           AdvancedBlendColorFragmentShader>;
using BlendColorBurnPipeline =
    RenderPipelineT<AdvancedBlendVertexShader,
                    AdvancedBlendColorburnFragmentShader>;
using BlendColorDodgePipeline =
    RenderPipelineT<AdvancedBlendVertexShader,
                    AdvancedBlendColordodgeFragmentShader>;
using BlendDarkenPipeline = RenderPipelineT<AdvancedBlendVertexShader,
                                            AdvancedBlendDarkenFragmentShader>;
using BlendDifferencePipeline =
    RenderPipelineT<AdvancedBlendVertexShader,
                    AdvancedBlendDifferenceFragmentShader>;
using BlendExclusionPipeline =
    RenderPipelineT<AdvancedBlendVertexShader,
                    AdvancedBlendExclusionFragmentShader>;
using BlendHardLightPipeline =
    RenderPipelineT<AdvancedBlendVertexShader,
                    AdvancedBlendHardlightFragmentShader>;
using BlendHuePipeline =
    RenderPipelineT<AdvancedBlendVertexShader, AdvancedBlendHueFragmentShader>;
using BlendLightenPipeline =
    RenderPipelineT<AdvancedBlendVertexShader,
                    AdvancedBlendLightenFragmentShader>;
using BlendLuminosityPipeline =
    RenderPipelineT<AdvancedBlendVertexShader,
                    AdvancedBlendLuminosityFragmentShader>;
using BlendMultiplyPipeline =
    RenderPipelineT<AdvancedBlendVertexShader,
                    AdvancedBlendMultiplyFragmentShader>;
using BlendOverlayPipeline =
    RenderPipelineT<AdvancedBlendVertexShader,
                    AdvancedBlendOverlayFragmentShader>;
using BlendSaturationPipeline =
    RenderPipelineT<AdvancedBlendVertexShader,
                    AdvancedBlendSaturationFragmentShader>;
using BlendScreenPipeline = RenderPipelineT<AdvancedBlendVertexShader,
                                            AdvancedBlendScreenFragmentShader>;
using BlendSoftLightPipeline =
    RenderPipelineT<AdvancedBlendVertexShader,
                    AdvancedBlendSoftlightFragmentShader>;
// Framebuffer Advanced Blends
using FramebufferBlendColorPipeline =
    RenderPipelineT<FramebufferBlendVertexShader,
                    FramebufferBlendColorFragmentShader>;
using FramebufferBlendColorBurnPipeline =
    RenderPipelineT<FramebufferBlendVertexShader,
                    FramebufferBlendColorburnFragmentShader>;
using FramebufferBlendColorDodgePipeline =
    RenderPipelineT<FramebufferBlendVertexShader,
                    FramebufferBlendColordodgeFragmentShader>;
using FramebufferBlendDarkenPipeline =
    RenderPipelineT<FramebufferBlendVertexShader,
                    FramebufferBlendDarkenFragmentShader>;
using FramebufferBlendDifferencePipeline =
    RenderPipelineT<FramebufferBlendVertexShader,
                    FramebufferBlendDifferenceFragmentShader>;
using FramebufferBlendExclusionPipeline =
    RenderPipelineT<FramebufferBlendVertexShader,
                    FramebufferBlendExclusionFragmentShader>;
using FramebufferBlendHardLightPipeline =
    RenderPipelineT<FramebufferBlendVertexShader,
                    FramebufferBlendHardlightFragmentShader>;
using FramebufferBlendHuePipeline =
    RenderPipelineT<FramebufferBlendVertexShader,
                    FramebufferBlendHueFragmentShader>;
using FramebufferBlendLightenPipeline =
    RenderPipelineT<FramebufferBlendVertexShader,
                    FramebufferBlendLightenFragmentShader>;
using FramebufferBlendLuminosityPipeline =
    RenderPipelineT<FramebufferBlendVertexShader,
                    FramebufferBlendLuminosityFragmentShader>;
using FramebufferBlendMultiplyPipeline =
    RenderPipelineT<FramebufferBlendVertexShader,
                    FramebufferBlendMultiplyFragmentShader>;
using FramebufferBlendOverlayPipeline =
    RenderPipelineT<FramebufferBlendVertexShader,
                    FramebufferBlendOverlayFragmentShader>;
using FramebufferBlendSaturationPipeline =
    RenderPipelineT<FramebufferBlendVertexShader,
                    FramebufferBlendSaturationFragmentShader>;
using FramebufferBlendScreenPipeline =
    RenderPipelineT<FramebufferBlendVertexShader,
                    FramebufferBlendScreenFragmentShader>;
using FramebufferBlendSoftLightPipeline =
    RenderPipelineT<FramebufferBlendVertexShader,
                    FramebufferBlendSoftlightFragmentShader>;

/// Pipeline state configuration.
///
/// Each unique combination of these options requires a different pipeline state
/// object to be built. This struct is used as a key for the per-pipeline
/// variant cache.
///
/// When adding fields to this key, reliant features should take care to limit
/// the combinatorical explosion of variations. A sufficiently complicated
/// Flutter application may easily require building hundreds of PSOs in total,
/// but they shouldn't require e.g. 10s of thousands.
struct ContentContextOptions {
  SampleCount sample_count = SampleCount::kCount1;
  BlendMode blend_mode = BlendMode::kSourceOver;
  CompareFunction stencil_compare = CompareFunction::kEqual;
  StencilOperation stencil_operation = StencilOperation::kKeep;
  PrimitiveType primitive_type = PrimitiveType::kTriangle;
  std::optional<PixelFormat> color_attachment_pixel_format;
  bool has_stencil_attachment = true;
  bool wireframe = false;

  struct Hash {
    constexpr std::size_t operator()(const ContentContextOptions& o) const {
      return fml::HashCombine(o.sample_count, o.blend_mode, o.stencil_compare,
                              o.stencil_operation, o.primitive_type,
                              o.color_attachment_pixel_format,
                              o.has_stencil_attachment, o.wireframe);
    }
  };

  struct Equal {
    constexpr bool operator()(const ContentContextOptions& lhs,
                              const ContentContextOptions& rhs) const {
      return lhs.sample_count == rhs.sample_count &&
             lhs.blend_mode == rhs.blend_mode &&
             lhs.stencil_compare == rhs.stencil_compare &&
             lhs.stencil_operation == rhs.stencil_operation &&
             lhs.primitive_type == rhs.primitive_type &&
             lhs.color_attachment_pixel_format ==
                 rhs.color_attachment_pixel_format &&
             lhs.has_stencil_attachment == rhs.has_stencil_attachment &&
             lhs.wireframe == rhs.wireframe;
    }
  };

  void ApplyToPipelineDescriptor(PipelineDescriptor& desc) const;
};

class Tessellator;

class ContentContext {
 public:
  explicit ContentContext(std::shared_ptr<Context> context);

  ~ContentContext();

  bool IsValid() const;

  std::shared_ptr<scene::SceneContext> GetSceneContext() const;

  std::shared_ptr<Tessellator> GetTessellator() const;

  std::shared_ptr<Pipeline<PipelineDescriptor>> GetLinearGradientFillPipeline(
      ContentContextOptions opts) const {
    return GetPipeline(linear_gradient_fill_pipelines_, opts);
  }

  std::shared_ptr<Pipeline<PipelineDescriptor>>
  GetLinearGradientSSBOFillPipeline(ContentContextOptions opts) const {
    FML_DCHECK(GetDeviceCapabilities().SupportsSSBO());
    return GetPipeline(linear_gradient_ssbo_fill_pipelines_, opts);
  }

  std::shared_ptr<Pipeline<PipelineDescriptor>>
  GetRadialGradientSSBOFillPipeline(ContentContextOptions opts) const {
    FML_DCHECK(GetDeviceCapabilities().SupportsSSBO());
    return GetPipeline(radial_gradient_ssbo_fill_pipelines_, opts);
  }

  std::shared_ptr<Pipeline<PipelineDescriptor>>
  GetConicalGradientSSBOFillPipeline(ContentContextOptions opts) const {
    FML_DCHECK(GetDeviceCapabilities().SupportsSSBO());
    return GetPipeline(conical_gradient_ssbo_fill_pipelines_, opts);
  }

  std::shared_ptr<Pipeline<PipelineDescriptor>>
  GetSweepGradientSSBOFillPipeline(ContentContextOptions opts) const {
    FML_DCHECK(GetDeviceCapabilities().SupportsSSBO());
    return GetPipeline(sweep_gradient_ssbo_fill_pipelines_, opts);
  }

  std::shared_ptr<Pipeline<PipelineDescriptor>> GetRadialGradientFillPipeline(
      ContentContextOptions opts) const {
    return GetPipeline(radial_gradient_fill_pipelines_, opts);
  }

  std::shared_ptr<Pipeline<PipelineDescriptor>> GetConicalGradientFillPipeline(
      ContentContextOptions opts) const {
    return GetPipeline(conical_gradient_fill_pipelines_, opts);
  }

  std::shared_ptr<Pipeline<PipelineDescriptor>> GetRRectBlurPipeline(
      ContentContextOptions opts) const {
    return GetPipeline(rrect_blur_pipelines_, opts);
  }

  std::shared_ptr<Pipeline<PipelineDescriptor>> GetSweepGradientFillPipeline(
      ContentContextOptions opts) const {
    return GetPipeline(sweep_gradient_fill_pipelines_, opts);
  }

  std::shared_ptr<Pipeline<PipelineDescriptor>> GetSolidFillPipeline(
      ContentContextOptions opts) const {
    return GetPipeline(solid_fill_pipelines_, opts);
  }

  std::shared_ptr<Pipeline<PipelineDescriptor>> GetBlendPipeline(
      ContentContextOptions opts) const {
    return GetPipeline(texture_blend_pipelines_, opts);
  }

  std::shared_ptr<Pipeline<PipelineDescriptor>> GetTexturePipeline(
      ContentContextOptions opts) const {
    return GetPipeline(texture_pipelines_, opts);
  }

  std::shared_ptr<Pipeline<PipelineDescriptor>> GetPositionUVPipeline(
      ContentContextOptions opts) const {
    return GetPipeline(position_uv_pipelines_, opts);
  }

  std::shared_ptr<Pipeline<PipelineDescriptor>> GetTiledTexturePipeline(
      ContentContextOptions opts) const {
    return GetPipeline(tiled_texture_pipelines_, opts);
  }

  std::shared_ptr<Pipeline<PipelineDescriptor>> GetGaussianBlurPipeline(
      ContentContextOptions opts) const {
    return GetPipeline(gaussian_blur_pipelines_, opts);
  }

  std::shared_ptr<Pipeline<PipelineDescriptor>> GetGaussianBlurDecalPipeline(
      ContentContextOptions opts) const {
    return GetPipeline(gaussian_blur_decal_pipelines_, opts);
  }

  std::shared_ptr<Pipeline<PipelineDescriptor>> GetBorderMaskBlurPipeline(
      ContentContextOptions opts) const {
    return GetPipeline(border_mask_blur_pipelines_, opts);
  }

  std::shared_ptr<Pipeline<PipelineDescriptor>> GetMorphologyFilterPipeline(
      ContentContextOptions opts) const {
    return GetPipeline(morphology_filter_pipelines_, opts);
  }

  std::shared_ptr<Pipeline<PipelineDescriptor>>
  GetColorMatrixColorFilterPipeline(ContentContextOptions opts) const {
    return GetPipeline(color_matrix_color_filter_pipelines_, opts);
  }

  std::shared_ptr<Pipeline<PipelineDescriptor>> GetLinearToSrgbFilterPipeline(
      ContentContextOptions opts) const {
    return GetPipeline(linear_to_srgb_filter_pipelines_, opts);
  }

  std::shared_ptr<Pipeline<PipelineDescriptor>> GetSrgbToLinearFilterPipeline(
      ContentContextOptions opts) const {
    return GetPipeline(srgb_to_linear_filter_pipelines_, opts);
  }

  std::shared_ptr<Pipeline<PipelineDescriptor>> GetClipPipeline(
      ContentContextOptions opts) const {
    return GetPipeline(clip_pipelines_, opts);
  }

  std::shared_ptr<Pipeline<PipelineDescriptor>> GetGlyphAtlasPipeline(
      ContentContextOptions opts) const {
    return GetPipeline(glyph_atlas_pipelines_, opts);
  }

  std::shared_ptr<Pipeline<PipelineDescriptor>> GetGlyphAtlasSdfPipeline(
      ContentContextOptions opts) const {
    return GetPipeline(glyph_atlas_sdf_pipelines_, opts);
  }

  std::shared_ptr<Pipeline<PipelineDescriptor>> GetGeometryColorPipeline(
      ContentContextOptions opts) const {
    return GetPipeline(geometry_color_pipelines_, opts);
  }

  std::shared_ptr<Pipeline<PipelineDescriptor>> GetYUVToRGBFilterPipeline(
      ContentContextOptions opts) const {
    return GetPipeline(yuv_to_rgb_filter_pipelines_, opts);
  }

  // Advanced blends.

  std::shared_ptr<Pipeline<PipelineDescriptor>> GetBlendColorPipeline(
      ContentContextOptions opts) const {
    return GetPipeline(blend_color_pipelines_, opts);
  }

  std::shared_ptr<Pipeline<PipelineDescriptor>> GetBlendColorBurnPipeline(
      ContentContextOptions opts) const {
    return GetPipeline(blend_colorburn_pipelines_, opts);
  }

  std::shared_ptr<Pipeline<PipelineDescriptor>> GetBlendColorDodgePipeline(
      ContentContextOptions opts) const {
    return GetPipeline(blend_colordodge_pipelines_, opts);
  }

  std::shared_ptr<Pipeline<PipelineDescriptor>> GetBlendDarkenPipeline(
      ContentContextOptions opts) const {
    return GetPipeline(blend_darken_pipelines_, opts);
  }

  std::shared_ptr<Pipeline<PipelineDescriptor>> GetBlendDifferencePipeline(
      ContentContextOptions opts) const {
    return GetPipeline(blend_difference_pipelines_, opts);
  }

  std::shared_ptr<Pipeline<PipelineDescriptor>> GetBlendExclusionPipeline(
      ContentContextOptions opts) const {
    return GetPipeline(blend_exclusion_pipelines_, opts);
  }

  std::shared_ptr<Pipeline<PipelineDescriptor>> GetBlendHardLightPipeline(
      ContentContextOptions opts) const {
    return GetPipeline(blend_hardlight_pipelines_, opts);
  }

  std::shared_ptr<Pipeline<PipelineDescriptor>> GetBlendHuePipeline(
      ContentContextOptions opts) const {
    return GetPipeline(blend_hue_pipelines_, opts);
  }

  std::shared_ptr<Pipeline<PipelineDescriptor>> GetBlendLightenPipeline(
      ContentContextOptions opts) const {
    return GetPipeline(blend_lighten_pipelines_, opts);
  }

  std::shared_ptr<Pipeline<PipelineDescriptor>> GetBlendLuminosityPipeline(
      ContentContextOptions opts) const {
    return GetPipeline(blend_luminosity_pipelines_, opts);
  }

  std::shared_ptr<Pipeline<PipelineDescriptor>> GetBlendMultiplyPipeline(
      ContentContextOptions opts) const {
    return GetPipeline(blend_multiply_pipelines_, opts);
  }

  std::shared_ptr<Pipeline<PipelineDescriptor>> GetBlendOverlayPipeline(
      ContentContextOptions opts) const {
    return GetPipeline(blend_overlay_pipelines_, opts);
  }

  std::shared_ptr<Pipeline<PipelineDescriptor>> GetBlendSaturationPipeline(
      ContentContextOptions opts) const {
    return GetPipeline(blend_saturation_pipelines_, opts);
  }

  std::shared_ptr<Pipeline<PipelineDescriptor>> GetBlendScreenPipeline(
      ContentContextOptions opts) const {
    return GetPipeline(blend_screen_pipelines_, opts);
  }

  std::shared_ptr<Pipeline<PipelineDescriptor>> GetBlendSoftLightPipeline(
      ContentContextOptions opts) const {
    return GetPipeline(blend_softlight_pipelines_, opts);
  }

  // Framebuffer Advanced Blends
  std::shared_ptr<Pipeline<PipelineDescriptor>>
  GetFramebufferBlendColorPipeline(ContentContextOptions opts) const {
    FML_DCHECK(GetDeviceCapabilities().SupportsFramebufferFetch());
    return GetPipeline(framebuffer_blend_color_pipelines_, opts);
  }

  std::shared_ptr<Pipeline<PipelineDescriptor>>
  GetFramebufferBlendColorBurnPipeline(ContentContextOptions opts) const {
    FML_DCHECK(GetDeviceCapabilities().SupportsFramebufferFetch());
    return GetPipeline(framebuffer_blend_colorburn_pipelines_, opts);
  }

  std::shared_ptr<Pipeline<PipelineDescriptor>>
  GetFramebufferBlendColorDodgePipeline(ContentContextOptions opts) const {
    FML_DCHECK(GetDeviceCapabilities().SupportsFramebufferFetch());
    return GetPipeline(framebuffer_blend_colordodge_pipelines_, opts);
  }

  std::shared_ptr<Pipeline<PipelineDescriptor>>
  GetFramebufferBlendDarkenPipeline(ContentContextOptions opts) const {
    FML_DCHECK(GetDeviceCapabilities().SupportsFramebufferFetch());
    return GetPipeline(framebuffer_blend_darken_pipelines_, opts);
  }

  std::shared_ptr<Pipeline<PipelineDescriptor>>
  GetFramebufferBlendDifferencePipeline(ContentContextOptions opts) const {
    FML_DCHECK(GetDeviceCapabilities().SupportsFramebufferFetch());
    return GetPipeline(framebuffer_blend_difference_pipelines_, opts);
  }

  std::shared_ptr<Pipeline<PipelineDescriptor>>
  GetFramebufferBlendExclusionPipeline(ContentContextOptions opts) const {
    FML_DCHECK(GetDeviceCapabilities().SupportsFramebufferFetch());
    return GetPipeline(framebuffer_blend_exclusion_pipelines_, opts);
  }

  std::shared_ptr<Pipeline<PipelineDescriptor>>
  GetFramebufferBlendHardLightPipeline(ContentContextOptions opts) const {
    FML_DCHECK(GetDeviceCapabilities().SupportsFramebufferFetch());
    return GetPipeline(framebuffer_blend_hardlight_pipelines_, opts);
  }

  std::shared_ptr<Pipeline<PipelineDescriptor>> GetFramebufferBlendHuePipeline(
      ContentContextOptions opts) const {
    FML_DCHECK(GetDeviceCapabilities().SupportsFramebufferFetch());
    return GetPipeline(framebuffer_blend_hue_pipelines_, opts);
  }

  std::shared_ptr<Pipeline<PipelineDescriptor>>
  GetFramebufferBlendLightenPipeline(ContentContextOptions opts) const {
    FML_DCHECK(GetDeviceCapabilities().SupportsFramebufferFetch());
    return GetPipeline(framebuffer_blend_lighten_pipelines_, opts);
  }

  std::shared_ptr<Pipeline<PipelineDescriptor>>
  GetFramebufferBlendLuminosityPipeline(ContentContextOptions opts) const {
    FML_DCHECK(GetDeviceCapabilities().SupportsFramebufferFetch());
    return GetPipeline(framebuffer_blend_luminosity_pipelines_, opts);
  }

  std::shared_ptr<Pipeline<PipelineDescriptor>>
  GetFramebufferBlendMultiplyPipeline(ContentContextOptions opts) const {
    FML_DCHECK(GetDeviceCapabilities().SupportsFramebufferFetch());
    return GetPipeline(framebuffer_blend_multiply_pipelines_, opts);
  }

  std::shared_ptr<Pipeline<PipelineDescriptor>>
  GetFramebufferBlendOverlayPipeline(ContentContextOptions opts) const {
    FML_DCHECK(GetDeviceCapabilities().SupportsFramebufferFetch());
    return GetPipeline(framebuffer_blend_overlay_pipelines_, opts);
  }

  std::shared_ptr<Pipeline<PipelineDescriptor>>
  GetFramebufferBlendSaturationPipeline(ContentContextOptions opts) const {
    FML_DCHECK(GetDeviceCapabilities().SupportsFramebufferFetch());
    return GetPipeline(framebuffer_blend_saturation_pipelines_, opts);
  }

  std::shared_ptr<Pipeline<PipelineDescriptor>>
  GetFramebufferBlendScreenPipeline(ContentContextOptions opts) const {
    FML_DCHECK(GetDeviceCapabilities().SupportsFramebufferFetch());
    return GetPipeline(framebuffer_blend_screen_pipelines_, opts);
  }

  std::shared_ptr<Pipeline<PipelineDescriptor>>
  GetFramebufferBlendSoftLightPipeline(ContentContextOptions opts) const {
    FML_DCHECK(GetDeviceCapabilities().SupportsFramebufferFetch());
    return GetPipeline(framebuffer_blend_softlight_pipelines_, opts);
  }

  std::shared_ptr<Context> GetContext() const;

  std::shared_ptr<GlyphAtlasContext> GetGlyphAtlasContext() const;

  const IDeviceCapabilities& GetDeviceCapabilities() const;

  void SetWireframe(bool wireframe);

  using SubpassCallback =
      std::function<bool(const ContentContext&, RenderPass&)>;

  /// @brief  Creates a new texture of size `texture_size` and calls
  ///         `subpass_callback` with a `RenderPass` for drawing to the texture.
  std::shared_ptr<Texture> MakeSubpass(const std::string& label,
                                       ISize texture_size,
                                       const SubpassCallback& subpass_callback,
                                       bool msaa_enabled = true) const;

 private:
  std::shared_ptr<Context> context_;

  template <class T>
  using Variants = std::unordered_map<ContentContextOptions,
                                      std::unique_ptr<T>,
                                      ContentContextOptions::Hash,
                                      ContentContextOptions::Equal>;

  // These are mutable because while the prototypes are created eagerly, any
  // variants requested from that are lazily created and cached in the variants
  // map.
  mutable Variants<SolidFillPipeline> solid_fill_pipelines_;
  mutable Variants<LinearGradientFillPipeline> linear_gradient_fill_pipelines_;
  mutable Variants<RadialGradientFillPipeline> radial_gradient_fill_pipelines_;
  mutable Variants<ConicalGradientFillPipeline>
      conical_gradient_fill_pipelines_;
  mutable Variants<SweepGradientFillPipeline> sweep_gradient_fill_pipelines_;
  mutable Variants<LinearGradientSSBOFillPipeline>
      linear_gradient_ssbo_fill_pipelines_;
  mutable Variants<RadialGradientSSBOFillPipeline>
      radial_gradient_ssbo_fill_pipelines_;
  mutable Variants<ConicalGradientSSBOFillPipeline>
      conical_gradient_ssbo_fill_pipelines_;
  mutable Variants<SweepGradientSSBOFillPipeline>
      sweep_gradient_ssbo_fill_pipelines_;
  mutable Variants<RRectBlurPipeline> rrect_blur_pipelines_;
  mutable Variants<BlendPipeline> texture_blend_pipelines_;
  mutable Variants<TexturePipeline> texture_pipelines_;
  mutable Variants<PositionUVPipeline> position_uv_pipelines_;
  mutable Variants<TiledTexturePipeline> tiled_texture_pipelines_;
  mutable Variants<GaussianBlurPipeline> gaussian_blur_pipelines_;
  mutable Variants<GaussianBlurDecalPipeline> gaussian_blur_decal_pipelines_;
  mutable Variants<BorderMaskBlurPipeline> border_mask_blur_pipelines_;
  mutable Variants<MorphologyFilterPipeline> morphology_filter_pipelines_;
  mutable Variants<ColorMatrixColorFilterPipeline>
      color_matrix_color_filter_pipelines_;
  mutable Variants<LinearToSrgbFilterPipeline> linear_to_srgb_filter_pipelines_;
  mutable Variants<SrgbToLinearFilterPipeline> srgb_to_linear_filter_pipelines_;
  mutable Variants<ClipPipeline> clip_pipelines_;
  mutable Variants<GlyphAtlasPipeline> glyph_atlas_pipelines_;
  mutable Variants<GlyphAtlasSdfPipeline> glyph_atlas_sdf_pipelines_;
  mutable Variants<GeometryColorPipeline> geometry_color_pipelines_;
  mutable Variants<YUVToRGBFilterPipeline> yuv_to_rgb_filter_pipelines_;
  // Advanced blends.
  mutable Variants<BlendColorPipeline> blend_color_pipelines_;
  mutable Variants<BlendColorBurnPipeline> blend_colorburn_pipelines_;
  mutable Variants<BlendColorDodgePipeline> blend_colordodge_pipelines_;
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
  // Framebuffer Advanced blends.
  mutable Variants<FramebufferBlendColorPipeline>
      framebuffer_blend_color_pipelines_;
  mutable Variants<FramebufferBlendColorBurnPipeline>
      framebuffer_blend_colorburn_pipelines_;
  mutable Variants<FramebufferBlendColorDodgePipeline>
      framebuffer_blend_colordodge_pipelines_;
  mutable Variants<FramebufferBlendDarkenPipeline>
      framebuffer_blend_darken_pipelines_;
  mutable Variants<FramebufferBlendDifferencePipeline>
      framebuffer_blend_difference_pipelines_;
  mutable Variants<FramebufferBlendExclusionPipeline>
      framebuffer_blend_exclusion_pipelines_;
  mutable Variants<FramebufferBlendHardLightPipeline>
      framebuffer_blend_hardlight_pipelines_;
  mutable Variants<FramebufferBlendHuePipeline>
      framebuffer_blend_hue_pipelines_;
  mutable Variants<FramebufferBlendLightenPipeline>
      framebuffer_blend_lighten_pipelines_;
  mutable Variants<FramebufferBlendLuminosityPipeline>
      framebuffer_blend_luminosity_pipelines_;
  mutable Variants<FramebufferBlendMultiplyPipeline>
      framebuffer_blend_multiply_pipelines_;
  mutable Variants<FramebufferBlendOverlayPipeline>
      framebuffer_blend_overlay_pipelines_;
  mutable Variants<FramebufferBlendSaturationPipeline>
      framebuffer_blend_saturation_pipelines_;
  mutable Variants<FramebufferBlendScreenPipeline>
      framebuffer_blend_screen_pipelines_;
  mutable Variants<FramebufferBlendSoftLightPipeline>
      framebuffer_blend_softlight_pipelines_;

  template <class TypedPipeline>
  std::shared_ptr<Pipeline<PipelineDescriptor>> GetPipeline(
      Variants<TypedPipeline>& container,
      ContentContextOptions opts) const {
    if (!IsValid()) {
      return nullptr;
    }

    if (wireframe_) {
      opts.wireframe = true;
    }

    if (auto found = container.find(opts); found != container.end()) {
      return found->second->WaitAndGet();
    }

    auto prototype = container.find({});

    // The prototype must always be initialized in the constructor.
    FML_CHECK(prototype != container.end());

    auto variant_future = prototype->second->WaitAndGet()->CreateVariant(
        [&opts, variants_count = container.size()](PipelineDescriptor& desc) {
          opts.ApplyToPipelineDescriptor(desc);
          desc.SetLabel(
              SPrintF("%s V#%zu", desc.GetLabel().c_str(), variants_count));
        });
    auto variant = std::make_unique<TypedPipeline>(std::move(variant_future));
    auto variant_pipeline = variant->WaitAndGet();
    container[opts] = std::move(variant);
    return variant_pipeline;
  }

  bool is_valid_ = false;
  std::shared_ptr<Tessellator> tessellator_;
  std::shared_ptr<GlyphAtlasContext> glyph_atlas_context_;
  std::shared_ptr<scene::SceneContext> scene_context_;
  bool wireframe_ = false;

  FML_DISALLOW_COPY_AND_ASSIGN(ContentContext);
};

}  // namespace impeller
