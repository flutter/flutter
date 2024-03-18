// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_ENTITY_CONTENTS_CONTENT_CONTEXT_H_
#define FLUTTER_IMPELLER_ENTITY_CONTENTS_CONTENT_CONTEXT_H_

#include <initializer_list>
#include <memory>
#include <optional>
#include <unordered_map>

#include "flutter/fml/build_config.h"
#include "flutter/fml/logging.h"
#include "flutter/fml/status_or.h"
#include "impeller/base/validation.h"
#include "impeller/core/formats.h"
#include "impeller/core/host_buffer.h"
#include "impeller/entity/entity.h"
#include "impeller/renderer/capabilities.h"
#include "impeller/renderer/command_buffer.h"
#include "impeller/renderer/pipeline.h"
#include "impeller/renderer/pipeline_descriptor.h"
#include "impeller/renderer/render_target.h"
#include "impeller/typographer/typographer_context.h"

#ifdef IMPELLER_DEBUG
#include "impeller/entity/checkerboard.frag.h"
#include "impeller/entity/checkerboard.vert.h"
#endif  // IMPELLER_DEBUG

#include "impeller/entity/blend.frag.h"
#include "impeller/entity/blend.vert.h"
#include "impeller/entity/border_mask_blur.frag.h"
#include "impeller/entity/border_mask_blur.vert.h"
#include "impeller/entity/clip.frag.h"
#include "impeller/entity/clip.vert.h"
#include "impeller/entity/color_matrix_color_filter.frag.h"
#include "impeller/entity/color_matrix_color_filter.vert.h"
#include "impeller/entity/conical_gradient_fill.frag.h"
#include "impeller/entity/glyph_atlas.frag.h"
#include "impeller/entity/glyph_atlas.vert.h"
#include "impeller/entity/glyph_atlas_color.frag.h"
#include "impeller/entity/gradient_fill.vert.h"
#include "impeller/entity/linear_gradient_fill.frag.h"
#include "impeller/entity/linear_to_srgb_filter.frag.h"
#include "impeller/entity/linear_to_srgb_filter.vert.h"
#include "impeller/entity/morphology_filter.frag.h"
#include "impeller/entity/morphology_filter.vert.h"
#include "impeller/entity/points.comp.h"
#include "impeller/entity/porter_duff_blend.frag.h"
#include "impeller/entity/porter_duff_blend.vert.h"
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
#include "impeller/entity/texture_fill_strict_src.frag.h"
#include "impeller/entity/tiled_texture_fill.frag.h"
#include "impeller/entity/uv.comp.h"
#include "impeller/entity/vertices.frag.h"
#include "impeller/entity/yuv_to_rgb_filter.frag.h"
#include "impeller/entity/yuv_to_rgb_filter.vert.h"

#include "impeller/entity/gaussian_blur.vert.h"
#include "impeller/entity/gaussian_blur_noalpha_decal.frag.h"
#include "impeller/entity/gaussian_blur_noalpha_nodecal.frag.h"
#include "impeller/entity/kernel_decal.frag.h"
#include "impeller/entity/kernel_nodecal.frag.h"

#include "impeller/entity/position_color.vert.h"

#include "impeller/typographer/glyph_atlas.h"

#include "impeller/entity/conical_gradient_ssbo_fill.frag.h"
#include "impeller/entity/linear_gradient_ssbo_fill.frag.h"
#include "impeller/entity/radial_gradient_ssbo_fill.frag.h"
#include "impeller/entity/sweep_gradient_ssbo_fill.frag.h"

#include "impeller/entity/advanced_blend.frag.h"
#include "impeller/entity/advanced_blend.vert.h"

#include "impeller/entity/framebuffer_blend.frag.h"
#include "impeller/entity/framebuffer_blend.vert.h"

#ifdef IMPELLER_ENABLE_OPENGLES
#include "impeller/entity/texture_fill_external.frag.h"
#include "impeller/entity/tiled_texture_fill_external.frag.h"
#endif  // IMPELLER_ENABLE_OPENGLES

#if IMPELLER_ENABLE_3D
#include "impeller/scene/scene_context.h"  // nogncheck
#endif

namespace impeller {

#ifdef IMPELLER_DEBUG
using CheckerboardPipeline =
    RenderPipelineT<CheckerboardVertexShader, CheckerboardFragmentShader>;
#endif  // IMPELLER_DEBUG

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
using RRectBlurPipeline =
    RenderPipelineT<RrectBlurVertexShader, RrectBlurFragmentShader>;
using BlendPipeline = RenderPipelineT<BlendVertexShader, BlendFragmentShader>;
using TexturePipeline =
    RenderPipelineT<TextureFillVertexShader, TextureFillFragmentShader>;
using TextureStrictSrcPipeline =
    RenderPipelineT<TextureFillVertexShader,
                    TextureFillStrictSrcFragmentShader>;
using PositionUVPipeline =
    RenderPipelineT<TextureFillVertexShader, TiledTextureFillFragmentShader>;
using TiledTexturePipeline =
    RenderPipelineT<TextureFillVertexShader, TiledTextureFillFragmentShader>;
using GaussianBlurDecalPipeline =
    RenderPipelineT<GaussianBlurVertexShader,
                    GaussianBlurNoalphaDecalFragmentShader>;
using GaussianBlurPipeline =
    RenderPipelineT<GaussianBlurVertexShader,
                    GaussianBlurNoalphaNodecalFragmentShader>;
using KernelDecalPipeline =
    RenderPipelineT<GaussianBlurVertexShader, KernelDecalFragmentShader>;
using KernelPipeline =
    RenderPipelineT<GaussianBlurVertexShader, KernelNodecalFragmentShader>;
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
using GlyphAtlasColorPipeline =
    RenderPipelineT<GlyphAtlasVertexShader, GlyphAtlasColorFragmentShader>;
using PorterDuffBlendPipeline =
    RenderPipelineT<PorterDuffBlendVertexShader, PorterDuffBlendFragmentShader>;
// Instead of requiring new shaders for clips, the solid fill stages are used
// to redirect writing to the stencil instead of color attachments.
using ClipPipeline = RenderPipelineT<ClipVertexShader, ClipFragmentShader>;

using GeometryColorPipeline =
    RenderPipelineT<PositionColorVertexShader, VerticesFragmentShader>;
using YUVToRGBFilterPipeline =
    RenderPipelineT<YuvToRgbFilterVertexShader, YuvToRgbFilterFragmentShader>;

// Advanced blends
using BlendColorPipeline =
    RenderPipelineT<AdvancedBlendVertexShader, AdvancedBlendFragmentShader>;
using BlendColorBurnPipeline =
    RenderPipelineT<AdvancedBlendVertexShader, AdvancedBlendFragmentShader>;
using BlendColorDodgePipeline =
    RenderPipelineT<AdvancedBlendVertexShader, AdvancedBlendFragmentShader>;
using BlendDarkenPipeline =
    RenderPipelineT<AdvancedBlendVertexShader, AdvancedBlendFragmentShader>;
using BlendDifferencePipeline =
    RenderPipelineT<AdvancedBlendVertexShader, AdvancedBlendFragmentShader>;
using BlendExclusionPipeline =
    RenderPipelineT<AdvancedBlendVertexShader, AdvancedBlendFragmentShader>;
using BlendHardLightPipeline =
    RenderPipelineT<AdvancedBlendVertexShader, AdvancedBlendFragmentShader>;
using BlendHuePipeline =
    RenderPipelineT<AdvancedBlendVertexShader, AdvancedBlendFragmentShader>;
using BlendLightenPipeline =
    RenderPipelineT<AdvancedBlendVertexShader, AdvancedBlendFragmentShader>;
using BlendLuminosityPipeline =
    RenderPipelineT<AdvancedBlendVertexShader, AdvancedBlendFragmentShader>;
using BlendMultiplyPipeline =
    RenderPipelineT<AdvancedBlendVertexShader, AdvancedBlendFragmentShader>;
using BlendOverlayPipeline =
    RenderPipelineT<AdvancedBlendVertexShader, AdvancedBlendFragmentShader>;
using BlendSaturationPipeline =
    RenderPipelineT<AdvancedBlendVertexShader, AdvancedBlendFragmentShader>;
using BlendScreenPipeline =
    RenderPipelineT<AdvancedBlendVertexShader, AdvancedBlendFragmentShader>;
using BlendSoftLightPipeline =
    RenderPipelineT<AdvancedBlendVertexShader, AdvancedBlendFragmentShader>;
// Framebuffer Advanced Blends
using FramebufferBlendColorPipeline =
    RenderPipelineT<FramebufferBlendVertexShader,
                    FramebufferBlendFragmentShader>;
using FramebufferBlendColorBurnPipeline =
    RenderPipelineT<FramebufferBlendVertexShader,
                    FramebufferBlendFragmentShader>;
using FramebufferBlendColorDodgePipeline =
    RenderPipelineT<FramebufferBlendVertexShader,
                    FramebufferBlendFragmentShader>;
using FramebufferBlendDarkenPipeline =
    RenderPipelineT<FramebufferBlendVertexShader,
                    FramebufferBlendFragmentShader>;
using FramebufferBlendDifferencePipeline =
    RenderPipelineT<FramebufferBlendVertexShader,
                    FramebufferBlendFragmentShader>;
using FramebufferBlendExclusionPipeline =
    RenderPipelineT<FramebufferBlendVertexShader,
                    FramebufferBlendFragmentShader>;
using FramebufferBlendHardLightPipeline =
    RenderPipelineT<FramebufferBlendVertexShader,
                    FramebufferBlendFragmentShader>;
using FramebufferBlendHuePipeline =
    RenderPipelineT<FramebufferBlendVertexShader,
                    FramebufferBlendFragmentShader>;
using FramebufferBlendLightenPipeline =
    RenderPipelineT<FramebufferBlendVertexShader,
                    FramebufferBlendFragmentShader>;
using FramebufferBlendLuminosityPipeline =
    RenderPipelineT<FramebufferBlendVertexShader,
                    FramebufferBlendFragmentShader>;
using FramebufferBlendMultiplyPipeline =
    RenderPipelineT<FramebufferBlendVertexShader,
                    FramebufferBlendFragmentShader>;
using FramebufferBlendOverlayPipeline =
    RenderPipelineT<FramebufferBlendVertexShader,
                    FramebufferBlendFragmentShader>;
using FramebufferBlendSaturationPipeline =
    RenderPipelineT<FramebufferBlendVertexShader,
                    FramebufferBlendFragmentShader>;
using FramebufferBlendScreenPipeline =
    RenderPipelineT<FramebufferBlendVertexShader,
                    FramebufferBlendFragmentShader>;
using FramebufferBlendSoftLightPipeline =
    RenderPipelineT<FramebufferBlendVertexShader,
                    FramebufferBlendFragmentShader>;

/// Geometry Pipelines
using PointsComputeShaderPipeline = ComputePipelineBuilder<PointsComputeShader>;
using UvComputeShaderPipeline = ComputePipelineBuilder<UvComputeShader>;

#ifdef IMPELLER_ENABLE_OPENGLES
using TextureExternalPipeline =
    RenderPipelineT<TextureFillVertexShader, TextureFillExternalFragmentShader>;

using TiledTextureExternalPipeline =
    RenderPipelineT<TextureFillVertexShader,
                    TiledTextureFillExternalFragmentShader>;
#endif  // IMPELLER_ENABLE_OPENGLES

// A struct used to isolate command buffer storage from the content
// context options to preserve const-ness.
struct PendingCommandBuffers {
  std::vector<std::shared_ptr<CommandBuffer>> command_buffers;
};

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
  enum class StencilMode : uint8_t {
    /// Turn the stencil test off. Used when drawing without stencil-then-cover.
    kIgnore,

    // Operations used for stencil-then-cover

    /// Draw the stencil for the NonZero fill path rule.
    ///
    /// The stencil ref should always be 0 on commands using this mode.
    kStencilNonZeroFill,
    /// Draw the stencil for the EvenOdd fill path rule.
    ///
    /// The stencil ref should always be 0 on commands using this mode.
    kStencilEvenOddFill,
    /// Used for draw calls which fill in the stenciled area. Intended to be
    /// used after `kStencilNonZeroFill` or `kStencilEvenOddFill` is used to set
    /// up the stencil buffer. Also cleans up the stencil buffer by resetting
    /// everything to zero.
    ///
    /// The stencil ref should always be 0 on commands using this mode.
    kCoverCompare,
    /// The opposite of `kCoverCompare`. Used for draw calls which fill in the
    /// non-stenciled area (intersection clips). Intended to be used after
    /// `kStencilNonZeroFill` or `kStencilEvenOddFill` is used to set up the
    /// stencil buffer. Also cleans up the stencil buffer by resetting
    /// everything to zero.
    ///
    /// The stencil ref should always be 0 on commands using this mode.
    kCoverCompareInverted,

    // Operations to control the legacy clip implementation, which forms a
    // heightmap on the stencil buffer.

    /// Slice the clip heightmap to a new maximum height.
    kLegacyClipRestore,
    /// Increment the stencil heightmap.
    kLegacyClipIncrement,
    /// Decrement the stencil heightmap (used for difference clipping only).
    kLegacyClipDecrement,
    /// Used for applying clips to all non-clip draw calls.
    kLegacyClipCompare,
  };

  SampleCount sample_count = SampleCount::kCount1;
  BlendMode blend_mode = BlendMode::kSourceOver;
  CompareFunction depth_compare = CompareFunction::kAlways;
  StencilMode stencil_mode =
      ContentContextOptions::StencilMode::kLegacyClipCompare;
  PrimitiveType primitive_type = PrimitiveType::kTriangle;
  PixelFormat color_attachment_pixel_format = PixelFormat::kUnknown;
  bool has_depth_stencil_attachments = true;
  bool depth_write_enabled = false;
  bool wireframe = false;
  bool is_for_rrect_blur_clear = false;

  struct Hash {
    constexpr uint64_t operator()(const ContentContextOptions& o) const {
      static_assert(sizeof(o.sample_count) == 1);
      static_assert(sizeof(o.blend_mode) == 1);
      static_assert(sizeof(o.sample_count) == 1);
      static_assert(sizeof(o.depth_compare) == 1);
      static_assert(sizeof(o.stencil_mode) == 1);
      static_assert(sizeof(o.primitive_type) == 1);
      static_assert(sizeof(o.color_attachment_pixel_format) == 1);

      return (o.is_for_rrect_blur_clear ? 1llu : 0llu) << 0 |
             (o.wireframe ? 1llu : 0llu) << 1 |
             (o.has_depth_stencil_attachments ? 1llu : 0llu) << 2 |
             (o.depth_write_enabled ? 1llu : 0llu) << 3 |
             // enums
             static_cast<uint64_t>(o.color_attachment_pixel_format) << 8 |
             static_cast<uint64_t>(o.primitive_type) << 16 |
             static_cast<uint64_t>(o.stencil_mode) << 24 |
             static_cast<uint64_t>(o.depth_compare) << 32 |
             static_cast<uint64_t>(o.blend_mode) << 40 |
             static_cast<uint64_t>(o.sample_count) << 48;
    }
  };

  struct Equal {
    constexpr bool operator()(const ContentContextOptions& lhs,
                              const ContentContextOptions& rhs) const {
      return lhs.sample_count == rhs.sample_count &&
             lhs.blend_mode == rhs.blend_mode &&
             lhs.depth_write_enabled == rhs.depth_write_enabled &&
             lhs.depth_compare == rhs.depth_compare &&
             lhs.stencil_mode == rhs.stencil_mode &&
             lhs.primitive_type == rhs.primitive_type &&
             lhs.color_attachment_pixel_format ==
                 rhs.color_attachment_pixel_format &&
             lhs.has_depth_stencil_attachments ==
                 rhs.has_depth_stencil_attachments &&
             lhs.wireframe == rhs.wireframe &&
             lhs.is_for_rrect_blur_clear == rhs.is_for_rrect_blur_clear;
    }
  };

  void ApplyToPipelineDescriptor(PipelineDescriptor& desc) const;
};

class Tessellator;
class RenderTargetCache;

class ContentContext {
 public:
  explicit ContentContext(
      std::shared_ptr<Context> context,
      std::shared_ptr<TypographerContext> typographer_context,
      std::shared_ptr<RenderTargetAllocator> render_target_allocator = nullptr);

  ~ContentContext();

  bool IsValid() const;

  /// This setting does two things:
  /// 1. Enables clipping with the depth buffer, freeing up the stencil buffer.
  ///    See also: https://github.com/flutter/flutter/issues/138460
  /// 2. Switches the generic tessellation fallback to use stencil-then-cover.
  ///    See also: https://github.com/flutter/flutter/issues/123671
  ///
  // TODO(bdero): Remove this setting once StC is fully de-risked
  //              https://github.com/flutter/flutter/issues/123671
  static constexpr bool kEnableStencilThenCover = true;

#if IMPELLER_ENABLE_3D
  std::shared_ptr<scene::SceneContext> GetSceneContext() const;
#endif  // IMPELLER_ENABLE_3D

  std::shared_ptr<Tessellator> GetTessellator() const;

#ifdef IMPELLER_DEBUG
  std::shared_ptr<Pipeline<PipelineDescriptor>> GetCheckerboardPipeline(
      ContentContextOptions opts) const {
    return GetPipeline(checkerboard_pipelines_, opts);
  }
#endif  // IMPELLER_DEBUG

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

  std::shared_ptr<Pipeline<PipelineDescriptor>> GetTextureStrictSrcPipeline(
      ContentContextOptions opts) const {
    return GetPipeline(texture_strict_src_pipelines_, opts);
  }

#ifdef IMPELLER_ENABLE_OPENGLES
  std::shared_ptr<Pipeline<PipelineDescriptor>> GetTextureExternalPipeline(
      ContentContextOptions opts) const {
    FML_DCHECK(GetContext()->GetBackendType() ==
               Context::BackendType::kOpenGLES);
    return GetPipeline(texture_external_pipelines_, opts);
  }

  std::shared_ptr<Pipeline<PipelineDescriptor>> GetTiledTextureExternalPipeline(
      ContentContextOptions opts) const {
    FML_DCHECK(GetContext()->GetBackendType() ==
               Context::BackendType::kOpenGLES);
    return GetPipeline(tiled_texture_external_pipelines_, opts);
  }
#endif  // IMPELLER_ENABLE_OPENGLES

  std::shared_ptr<Pipeline<PipelineDescriptor>> GetPositionUVPipeline(
      ContentContextOptions opts) const {
    return GetPipeline(position_uv_pipelines_, opts);
  }

  std::shared_ptr<Pipeline<PipelineDescriptor>> GetTiledTexturePipeline(
      ContentContextOptions opts) const {
    return GetPipeline(tiled_texture_pipelines_, opts);
  }

  std::shared_ptr<Pipeline<PipelineDescriptor>> GetGaussianBlurDecalPipeline(
      ContentContextOptions opts) const {
    return GetPipeline(gaussian_blur_noalpha_decal_pipelines_, opts);
  }

  std::shared_ptr<Pipeline<PipelineDescriptor>> GetGaussianBlurPipeline(
      ContentContextOptions opts) const {
    return GetPipeline(gaussian_blur_noalpha_nodecal_pipelines_, opts);
  }

  std::shared_ptr<Pipeline<PipelineDescriptor>> GetKernelDecalPipeline(
      ContentContextOptions opts) const {
    return GetPipeline(kernel_decal_pipelines_, opts);
  }

  std::shared_ptr<Pipeline<PipelineDescriptor>> GetKernelPipeline(
      ContentContextOptions opts) const {
    return GetPipeline(kernel_nodecal_pipelines_, opts);
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

  std::shared_ptr<Pipeline<PipelineDescriptor>> GetGlyphAtlasColorPipeline(
      ContentContextOptions opts) const {
    return GetPipeline(glyph_atlas_color_pipelines_, opts);
  }

  std::shared_ptr<Pipeline<PipelineDescriptor>> GetGeometryColorPipeline(
      ContentContextOptions opts) const {
    return GetPipeline(geometry_color_pipelines_, opts);
  }

  std::shared_ptr<Pipeline<PipelineDescriptor>> GetYUVToRGBFilterPipeline(
      ContentContextOptions opts) const {
    return GetPipeline(yuv_to_rgb_filter_pipelines_, opts);
  }

  std::shared_ptr<Pipeline<PipelineDescriptor>> GetPorterDuffBlendPipeline(
      ContentContextOptions opts) const {
    return GetPipeline(porter_duff_blend_pipelines_, opts);
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

  std::shared_ptr<Pipeline<ComputePipelineDescriptor>> GetPointComputePipeline()
      const {
    FML_DCHECK(GetDeviceCapabilities().SupportsCompute());
    return point_field_compute_pipelines_;
  }

  std::shared_ptr<Pipeline<ComputePipelineDescriptor>> GetUvComputePipeline()
      const {
    FML_DCHECK(GetDeviceCapabilities().SupportsCompute());
    return uv_compute_pipelines_;
  }

  std::shared_ptr<Context> GetContext() const;

  const Capabilities& GetDeviceCapabilities() const;

  void SetWireframe(bool wireframe);

  using SubpassCallback =
      std::function<bool(const ContentContext&, RenderPass&)>;

  /// @brief  Creates a new texture of size `texture_size` and calls
  ///         `subpass_callback` with a `RenderPass` for drawing to the texture.
  fml::StatusOr<RenderTarget> MakeSubpass(
      const std::string& label,
      ISize texture_size,
      const SubpassCallback& subpass_callback,
      bool msaa_enabled = true,
      bool depth_stencil_enabled = false,
      int32_t mip_count = 1) const;

  /// Makes a subpass that will render to `subpass_target`.
  fml::StatusOr<RenderTarget> MakeSubpass(
      const std::string& label,
      const RenderTarget& subpass_target,
      const SubpassCallback& subpass_callback) const;

  const std::shared_ptr<LazyGlyphAtlas>& GetLazyGlyphAtlas() const {
    return lazy_glyph_atlas_;
  }

  const std::shared_ptr<RenderTargetAllocator>& GetRenderTargetCache() const {
    return render_target_cache_;
  }

  /// RuntimeEffect pipelines must be obtained via this method to avoid
  /// re-creating them every frame.
  ///
  /// The unique_entrypoint_name comes from RuntimeEffect::GetEntrypoint.
  /// Impellerc generates a unique entrypoint name for runtime effect shaders
  /// based on the input file name and shader stage.
  ///
  /// The create_callback is synchronously invoked exactly once if a cached
  /// pipeline is not found.
  std::shared_ptr<Pipeline<PipelineDescriptor>> GetCachedRuntimeEffectPipeline(
      const std::string& unique_entrypoint_name,
      const ContentContextOptions& options,
      const std::function<std::shared_ptr<Pipeline<PipelineDescriptor>>()>&
          create_callback) const;

  /// Used by hot reload/hot restart to clear a cached pipeline from
  /// GetCachedRuntimeEffectPipeline.
  void ClearCachedRuntimeEffectPipeline(
      const std::string& unique_entrypoint_name) const;

  /// @brief Retrieve the currnent host buffer for transient storage.
  ///
  /// This is only safe to use from the raster threads. Other threads should
  /// allocate their own device buffers.
  HostBuffer& GetTransientsBuffer() const { return *host_buffer_; }

 private:
  std::shared_ptr<Context> context_;
  std::shared_ptr<LazyGlyphAtlas> lazy_glyph_atlas_;

  /// Run backend specific additional setup and create common shader variants.
  ///
  /// This bootstrap is intended to improve the performance of several
  /// first frame benchmarks that are tracked in the flutter device lab.
  /// The workload includes initializing commonly used but not default
  /// shader variants, as well as forcing driver initialization.
  void InitializeCommonlyUsedShadersIfNeeded() const;

  struct RuntimeEffectPipelineKey {
    std::string unique_entrypoint_name;
    ContentContextOptions options;

    struct Hash {
      std::size_t operator()(const RuntimeEffectPipelineKey& key) const {
        return fml::HashCombine(key.unique_entrypoint_name,
                                ContentContextOptions::Hash{}(key.options));
      }
    };

    struct Equal {
      constexpr bool operator()(const RuntimeEffectPipelineKey& lhs,
                                const RuntimeEffectPipelineKey& rhs) const {
        return lhs.unique_entrypoint_name == rhs.unique_entrypoint_name &&
               ContentContextOptions::Equal{}(lhs.options, rhs.options);
      }
    };
  };

  mutable std::unordered_map<RuntimeEffectPipelineKey,
                             std::shared_ptr<Pipeline<PipelineDescriptor>>,
                             RuntimeEffectPipelineKey::Hash,
                             RuntimeEffectPipelineKey::Equal>
      runtime_effect_pipelines_;

  template <class PipelineT>
  class Variants {
   public:
    Variants() = default;

    void Set(const ContentContextOptions& options,
             std::unique_ptr<PipelineT> pipeline) {
      pipelines_[options] = std::move(pipeline);
    }

    void SetDefault(const ContentContextOptions& options,
                    std::unique_ptr<PipelineT> pipeline) {
      default_options_ = options;
      Set(options, std::move(pipeline));
    }

    void CreateDefault(const Context& context,
                       const ContentContextOptions& options,
                       const std::initializer_list<Scalar>& constants = {}) {
      auto desc =
          PipelineT::Builder::MakeDefaultPipelineDescriptor(context, constants);
      if (!desc.has_value()) {
        VALIDATION_LOG << "Failed to create default pipeline.";
        return;
      }
      options.ApplyToPipelineDescriptor(*desc);
      SetDefault(options, std::make_unique<PipelineT>(context, desc));
    }

    PipelineT* Get(const ContentContextOptions& options) const {
      if (auto found = pipelines_.find(options); found != pipelines_.end()) {
        return found->second.get();
      }
      return nullptr;
    }

    PipelineT* GetDefault() const {
      if (!default_options_.has_value()) {
        return nullptr;
      }
      return Get(default_options_.value());
    }

    size_t GetPipelineCount() const { return pipelines_.size(); }

   private:
    std::optional<ContentContextOptions> default_options_;
    std::unordered_map<ContentContextOptions,
                       std::unique_ptr<PipelineT>,
                       ContentContextOptions::Hash,
                       ContentContextOptions::Equal>
        pipelines_;

    Variants(const Variants&) = delete;

    Variants& operator=(const Variants&) = delete;
  };

  // These are mutable because while the prototypes are created eagerly, any
  // variants requested from that are lazily created and cached in the variants
  // map.

#ifdef IMPELLER_DEBUG
  mutable Variants<CheckerboardPipeline> checkerboard_pipelines_;
#endif  // IMPELLER_DEBUG

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
  mutable Variants<TextureStrictSrcPipeline> texture_strict_src_pipelines_;
#ifdef IMPELLER_ENABLE_OPENGLES
  mutable Variants<TextureExternalPipeline> texture_external_pipelines_;
  mutable Variants<TiledTextureExternalPipeline>
      tiled_texture_external_pipelines_;
#endif  // IMPELLER_ENABLE_OPENGLES
  mutable Variants<PositionUVPipeline> position_uv_pipelines_;
  mutable Variants<TiledTexturePipeline> tiled_texture_pipelines_;
  mutable Variants<GaussianBlurDecalPipeline>
      gaussian_blur_noalpha_decal_pipelines_;
  mutable Variants<GaussianBlurPipeline>
      gaussian_blur_noalpha_nodecal_pipelines_;
  mutable Variants<KernelDecalPipeline> kernel_decal_pipelines_;
  mutable Variants<KernelPipeline> kernel_nodecal_pipelines_;
  mutable Variants<BorderMaskBlurPipeline> border_mask_blur_pipelines_;
  mutable Variants<MorphologyFilterPipeline> morphology_filter_pipelines_;
  mutable Variants<ColorMatrixColorFilterPipeline>
      color_matrix_color_filter_pipelines_;
  mutable Variants<LinearToSrgbFilterPipeline> linear_to_srgb_filter_pipelines_;
  mutable Variants<SrgbToLinearFilterPipeline> srgb_to_linear_filter_pipelines_;
  mutable Variants<ClipPipeline> clip_pipelines_;
  mutable Variants<GlyphAtlasPipeline> glyph_atlas_pipelines_;
  mutable Variants<GlyphAtlasColorPipeline> glyph_atlas_color_pipelines_;
  mutable Variants<GeometryColorPipeline> geometry_color_pipelines_;
  mutable Variants<YUVToRGBFilterPipeline> yuv_to_rgb_filter_pipelines_;
  mutable Variants<PorterDuffBlendPipeline> porter_duff_blend_pipelines_;
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
  mutable std::shared_ptr<Pipeline<ComputePipelineDescriptor>>
      point_field_compute_pipelines_;
  mutable std::shared_ptr<Pipeline<ComputePipelineDescriptor>>
      uv_compute_pipelines_;

  template <class TypedPipeline>
  std::shared_ptr<Pipeline<PipelineDescriptor>> GetPipeline(
      Variants<TypedPipeline>& container,
      ContentContextOptions opts) const {
    TypedPipeline* pipeline = CreateIfNeeded(container, opts);
    if (!pipeline) {
      return nullptr;
    }
    return pipeline->WaitAndGet();
  }

  template <class TypedPipeline>
  TypedPipeline* CreateIfNeeded(Variants<TypedPipeline>& container,
                                ContentContextOptions opts) const {
    if (!IsValid()) {
      return nullptr;
    }

    if (wireframe_) {
      opts.wireframe = true;
    }

    if (TypedPipeline* found = container.Get(opts)) {
      return found;
    }

    TypedPipeline* prototype = container.GetDefault();

    // The prototype must always be initialized in the constructor.
    FML_CHECK(prototype != nullptr);

    std::shared_ptr<Pipeline<PipelineDescriptor>> pipeline =
        prototype->WaitAndGet();
    if (!pipeline) {
      return nullptr;
    }

    auto variant_future = pipeline->CreateVariant(
        [&opts, variants_count =
                    container.GetPipelineCount()](PipelineDescriptor& desc) {
          opts.ApplyToPipelineDescriptor(desc);
          desc.SetLabel(
              SPrintF("%s V#%zu", desc.GetLabel().c_str(), variants_count));
        });
    std::unique_ptr<TypedPipeline> variant =
        std::make_unique<TypedPipeline>(std::move(variant_future));
    container.Set(opts, std::move(variant));
    return container.Get(opts);
  }

  bool is_valid_ = false;
  std::shared_ptr<Tessellator> tessellator_;
#if IMPELLER_ENABLE_3D
  std::shared_ptr<scene::SceneContext> scene_context_;
#endif  // IMPELLER_ENABLE_3D
  std::shared_ptr<RenderTargetAllocator> render_target_cache_;
  std::shared_ptr<HostBuffer> host_buffer_;
  std::unique_ptr<PendingCommandBuffers> pending_command_buffers_;
  bool wireframe_ = false;

  ContentContext(const ContentContext&) = delete;

  ContentContext& operator=(const ContentContext&) = delete;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_ENTITY_CONTENTS_CONTENT_CONTEXT_H_
