// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_ENTITY_CONTENTS_CONTENT_CONTEXT_H_
#define FLUTTER_IMPELLER_ENTITY_CONTENTS_CONTENT_CONTEXT_H_

#include <initializer_list>
#include <memory>
#include <optional>
#include <unordered_map>
#include <utility>

#include "flutter/fml/logging.h"
#include "flutter/fml/status_or.h"
#include "impeller/base/validation.h"
#include "impeller/core/formats.h"
#include "impeller/core/host_buffer.h"
#include "impeller/geometry/color.h"
#include "impeller/renderer/capabilities.h"
#include "impeller/renderer/command_buffer.h"
#include "impeller/renderer/pipeline.h"
#include "impeller/renderer/pipeline_descriptor.h"
#include "impeller/renderer/render_target.h"
#include "impeller/typographer/lazy_glyph_atlas.h"
#include "impeller/typographer/typographer_context.h"

#include "impeller/entity/border_mask_blur.frag.h"
#include "impeller/entity/clip.frag.h"
#include "impeller/entity/clip.vert.h"
#include "impeller/entity/color_matrix_color_filter.frag.h"
#include "impeller/entity/conical_gradient_fill_conical.frag.h"
#include "impeller/entity/conical_gradient_fill_radial.frag.h"
#include "impeller/entity/conical_gradient_fill_strip.frag.h"
#include "impeller/entity/conical_gradient_fill_strip_radial.frag.h"
#include "impeller/entity/fast_gradient.frag.h"
#include "impeller/entity/fast_gradient.vert.h"
#include "impeller/entity/filter_position.vert.h"
#include "impeller/entity/filter_position_uv.vert.h"
#include "impeller/entity/gaussian.frag.h"
#include "impeller/entity/glyph_atlas.frag.h"
#include "impeller/entity/glyph_atlas.vert.h"
#include "impeller/entity/gradient_fill.vert.h"
#include "impeller/entity/linear_gradient_fill.frag.h"
#include "impeller/entity/linear_to_srgb_filter.frag.h"
#include "impeller/entity/morphology_filter.frag.h"
#include "impeller/entity/porter_duff_blend.frag.h"
#include "impeller/entity/porter_duff_blend.vert.h"
#include "impeller/entity/radial_gradient_fill.frag.h"
#include "impeller/entity/rrect_blur.frag.h"
#include "impeller/entity/rrect_blur.vert.h"
#include "impeller/entity/solid_fill.frag.h"
#include "impeller/entity/solid_fill.vert.h"
#include "impeller/entity/srgb_to_linear_filter.frag.h"
#include "impeller/entity/sweep_gradient_fill.frag.h"
#include "impeller/entity/texture_downsample.frag.h"
#include "impeller/entity/texture_fill.frag.h"
#include "impeller/entity/texture_fill.vert.h"
#include "impeller/entity/texture_fill_strict_src.frag.h"
#include "impeller/entity/texture_uv_fill.vert.h"
#include "impeller/entity/tiled_texture_fill.frag.h"
#include "impeller/entity/yuv_to_rgb_filter.frag.h"

#include "impeller/entity/conical_gradient_uniform_fill_conical.frag.h"
#include "impeller/entity/conical_gradient_uniform_fill_radial.frag.h"
#include "impeller/entity/conical_gradient_uniform_fill_strip.frag.h"
#include "impeller/entity/conical_gradient_uniform_fill_strip_radial.frag.h"
#include "impeller/entity/linear_gradient_uniform_fill.frag.h"
#include "impeller/entity/radial_gradient_uniform_fill.frag.h"
#include "impeller/entity/sweep_gradient_uniform_fill.frag.h"

#include "impeller/entity/conical_gradient_ssbo_fill.frag.h"
#include "impeller/entity/linear_gradient_ssbo_fill.frag.h"
#include "impeller/entity/radial_gradient_ssbo_fill.frag.h"
#include "impeller/entity/sweep_gradient_ssbo_fill.frag.h"

#include "impeller/entity/advanced_blend.frag.h"
#include "impeller/entity/advanced_blend.vert.h"

#include "impeller/entity/framebuffer_blend.frag.h"
#include "impeller/entity/framebuffer_blend.vert.h"

#include "impeller/entity/vertices_uber.frag.h"

#ifdef IMPELLER_ENABLE_OPENGLES
#include "impeller/entity/texture_downsample_gles.frag.h"
#include "impeller/entity/tiled_texture_fill_external.frag.h"
#endif  // IMPELLER_ENABLE_OPENGLES

namespace impeller {

template <typename T>
using GradientPipelineHandle =
    RenderPipelineHandle<GradientFillVertexShader, T>;

using AdvancedBlendPipelineHandle =
    RenderPipelineHandle<AdvancedBlendVertexShader,
                         AdvancedBlendFragmentShader>;

using FramebufferBlendPipelineHandle =
    RenderPipelineHandle<FramebufferBlendVertexShader,
                         FramebufferBlendFragmentShader>;

// clang-format off
using BlendColorBurnPipeline = AdvancedBlendPipelineHandle;
using BlendColorDodgePipeline = AdvancedBlendPipelineHandle;
using BlendColorPipeline = AdvancedBlendPipelineHandle;
using BlendDarkenPipeline = AdvancedBlendPipelineHandle;
using BlendDifferencePipeline = AdvancedBlendPipelineHandle;
using BlendExclusionPipeline = AdvancedBlendPipelineHandle;
using BlendHardLightPipeline = AdvancedBlendPipelineHandle;
using BlendHuePipeline = AdvancedBlendPipelineHandle;
using BlendLightenPipeline = AdvancedBlendPipelineHandle;
using BlendLuminosityPipeline = AdvancedBlendPipelineHandle;
using BlendMultiplyPipeline = AdvancedBlendPipelineHandle;
using BlendOverlayPipeline = AdvancedBlendPipelineHandle;
using BlendSaturationPipeline = AdvancedBlendPipelineHandle;
using BlendScreenPipeline = AdvancedBlendPipelineHandle;
using BlendSoftLightPipeline = AdvancedBlendPipelineHandle;
using BorderMaskBlurPipeline = RenderPipelineHandle<FilterPositionUvVertexShader, BorderMaskBlurFragmentShader>;
using ClipPipeline = RenderPipelineHandle<ClipVertexShader, ClipFragmentShader>;
using ColorMatrixColorFilterPipeline = RenderPipelineHandle<FilterPositionVertexShader, ColorMatrixColorFilterFragmentShader>;
using ConicalGradientFillConicalPipeline = GradientPipelineHandle<ConicalGradientFillConicalFragmentShader>;
using ConicalGradientFillRadialPipeline = GradientPipelineHandle<ConicalGradientFillRadialFragmentShader>;
using ConicalGradientFillStripPipeline = GradientPipelineHandle<ConicalGradientFillStripFragmentShader>;
using ConicalGradientFillStripRadialPipeline = GradientPipelineHandle<ConicalGradientFillStripRadialFragmentShader>;
using ConicalGradientSSBOFillPipeline = GradientPipelineHandle<ConicalGradientSsboFillFragmentShader>;
using ConicalGradientUniformFillConicalPipeline = GradientPipelineHandle<ConicalGradientUniformFillConicalFragmentShader>;
using ConicalGradientUniformFillRadialPipeline = GradientPipelineHandle<ConicalGradientUniformFillRadialFragmentShader>;
using ConicalGradientUniformFillStripPipeline = GradientPipelineHandle<ConicalGradientUniformFillStripFragmentShader>;
using ConicalGradientUniformFillStripRadialPipeline = GradientPipelineHandle<ConicalGradientUniformFillStripRadialFragmentShader>;
using FastGradientPipeline = RenderPipelineHandle<FastGradientVertexShader, FastGradientFragmentShader>;
using FramebufferBlendColorBurnPipeline = FramebufferBlendPipelineHandle;
using FramebufferBlendColorDodgePipeline = FramebufferBlendPipelineHandle;
using FramebufferBlendColorPipeline = FramebufferBlendPipelineHandle;
using FramebufferBlendDarkenPipeline = FramebufferBlendPipelineHandle;
using FramebufferBlendDifferencePipeline = FramebufferBlendPipelineHandle;
using FramebufferBlendExclusionPipeline = FramebufferBlendPipelineHandle;
using FramebufferBlendHardLightPipeline = FramebufferBlendPipelineHandle;
using FramebufferBlendHuePipeline = FramebufferBlendPipelineHandle;
using FramebufferBlendLightenPipeline = FramebufferBlendPipelineHandle;
using FramebufferBlendLuminosityPipeline = FramebufferBlendPipelineHandle;
using FramebufferBlendMultiplyPipeline = FramebufferBlendPipelineHandle;
using FramebufferBlendOverlayPipeline = FramebufferBlendPipelineHandle;
using FramebufferBlendSaturationPipeline = FramebufferBlendPipelineHandle;
using FramebufferBlendScreenPipeline = FramebufferBlendPipelineHandle;
using FramebufferBlendSoftLightPipeline = FramebufferBlendPipelineHandle;
using GaussianBlurPipeline = RenderPipelineHandle<FilterPositionUvVertexShader, GaussianFragmentShader>;
using GlyphAtlasPipeline = RenderPipelineHandle<GlyphAtlasVertexShader, GlyphAtlasFragmentShader>;
using LinearGradientFillPipeline = GradientPipelineHandle<LinearGradientFillFragmentShader>;
using LinearGradientSSBOFillPipeline = GradientPipelineHandle<LinearGradientSsboFillFragmentShader>;
using LinearGradientUniformFillPipeline = GradientPipelineHandle<LinearGradientUniformFillFragmentShader>;
using LinearToSrgbFilterPipeline = RenderPipelineHandle<FilterPositionVertexShader, LinearToSrgbFilterFragmentShader>;
using MorphologyFilterPipeline = RenderPipelineHandle<FilterPositionUvVertexShader, MorphologyFilterFragmentShader>;
using PorterDuffBlendPipeline = RenderPipelineHandle<PorterDuffBlendVertexShader, PorterDuffBlendFragmentShader>;
using RadialGradientFillPipeline = GradientPipelineHandle<RadialGradientFillFragmentShader>;
using RadialGradientSSBOFillPipeline = GradientPipelineHandle<RadialGradientSsboFillFragmentShader>;
using RadialGradientUniformFillPipeline = GradientPipelineHandle<RadialGradientUniformFillFragmentShader>;
using RRectBlurPipeline = RenderPipelineHandle<RrectBlurVertexShader, RrectBlurFragmentShader>;
using SolidFillPipeline = RenderPipelineHandle<SolidFillVertexShader, SolidFillFragmentShader>;
using SrgbToLinearFilterPipeline = RenderPipelineHandle<FilterPositionVertexShader, SrgbToLinearFilterFragmentShader>;
using SweepGradientFillPipeline = GradientPipelineHandle<SweepGradientFillFragmentShader>;
using SweepGradientSSBOFillPipeline = GradientPipelineHandle<SweepGradientSsboFillFragmentShader>;
using SweepGradientUniformFillPipeline = GradientPipelineHandle<SweepGradientUniformFillFragmentShader>;
using TextureDownsamplePipeline = RenderPipelineHandle<TextureFillVertexShader, TextureDownsampleFragmentShader>;
using TexturePipeline = RenderPipelineHandle<TextureFillVertexShader, TextureFillFragmentShader>;
using TextureStrictSrcPipeline = RenderPipelineHandle<TextureFillVertexShader, TextureFillStrictSrcFragmentShader>;
using TiledTexturePipeline = RenderPipelineHandle<TextureUvFillVertexShader, TiledTextureFillFragmentShader>;
using VerticesUberShader = RenderPipelineHandle<PorterDuffBlendVertexShader, VerticesUberFragmentShader>;
using YUVToRGBFilterPipeline = RenderPipelineHandle<FilterPositionVertexShader, YuvToRgbFilterFragmentShader>;
// clang-format on

#ifdef IMPELLER_ENABLE_OPENGLES
using TiledTextureExternalPipeline =
    RenderPipelineHandle<TextureFillVertexShader,
                         TiledTextureFillExternalFragmentShader>;
using TiledTextureUvExternalPipeline =
    RenderPipelineHandle<TextureUvFillVertexShader,
                         TiledTextureFillExternalFragmentShader>;
using TextureDownsampleGlesPipeline =
    RenderPipelineHandle<TextureFillVertexShader,
                         TextureDownsampleGlesFragmentShader>;
#endif  // IMPELLER_ENABLE_OPENGLES

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
    /// Turn the stencil test off. Used when drawing without stencil-then-cover
    /// or overdraw prevention.
    kIgnore,

    // Operations used for stencil-then-cover.

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

    // Operations used for the "overdraw prevention" mechanism. This is used for
    // drawing strokes.

    /// For each fragment, increment the stencil value if it's currently zero.
    /// Discard fragments when the value is non-zero. This prevents
    /// self-overlapping strokes from drawing over themselves.
    ///
    /// Note that this is done for rendering correctness, not performance. If a
    /// stroke is drawn with a backdrop-reliant blend and self-intersects, then
    /// the intersected geometry will render incorrectly when overdrawn because
    /// we don't adjust the geometry prevent self-intersection.
    ///
    /// The stencil ref should always be 0 on commands using this mode.
    kOverdrawPreventionIncrement,
    /// Reset the stencil to a new maximum value specified by the ref (currently
    /// always 0).
    ///
    /// The stencil ref should always be 0 on commands using this mode.
    kOverdrawPreventionRestore,
  };

  SampleCount sample_count = SampleCount::kCount1;
  BlendMode blend_mode = BlendMode::kSrcOver;
  CompareFunction depth_compare = CompareFunction::kAlways;
  StencilMode stencil_mode = ContentContextOptions::StencilMode::kIgnore;
  PrimitiveType primitive_type = PrimitiveType::kTriangle;
  PixelFormat color_attachment_pixel_format = PixelFormat::kUnknown;
  bool has_depth_stencil_attachments = true;
  bool depth_write_enabled = false;
  bool wireframe = false;
  bool is_for_rrect_blur_clear = false;

  constexpr uint64_t ToKey() const {
    static_assert(sizeof(sample_count) == 1);
    static_assert(sizeof(blend_mode) == 1);
    static_assert(sizeof(sample_count) == 1);
    static_assert(sizeof(depth_compare) == 1);
    static_assert(sizeof(stencil_mode) == 1);
    static_assert(sizeof(primitive_type) == 1);
    static_assert(sizeof(color_attachment_pixel_format) == 1);

    return (is_for_rrect_blur_clear ? 1llu : 0llu) << 0 |
           (wireframe ? 1llu : 0llu) << 1 |
           (has_depth_stencil_attachments ? 1llu : 0llu) << 2 |
           (depth_write_enabled ? 1llu : 0llu) << 3 |
           // enums
           static_cast<uint64_t>(color_attachment_pixel_format) << 8 |
           static_cast<uint64_t>(primitive_type) << 16 |
           static_cast<uint64_t>(stencil_mode) << 24 |
           static_cast<uint64_t>(depth_compare) << 32 |
           static_cast<uint64_t>(blend_mode) << 40 |
           static_cast<uint64_t>(sample_count) << 48;
  }

  void ApplyToPipelineDescriptor(PipelineDescriptor& desc) const;
};

enum ConicalKind {
  kConical,
  kRadial,
  kStrip,
  kStripAndRadial,
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

  Tessellator& GetTessellator() const;

  // clang-format off
  PipelineRef GetBlendColorBurnPipeline(ContentContextOptions opts) const;
  PipelineRef GetBlendColorDodgePipeline(ContentContextOptions opts) const;
  PipelineRef GetBlendColorPipeline(ContentContextOptions opts) const;
  PipelineRef GetBlendDarkenPipeline(ContentContextOptions opts) const;
  PipelineRef GetBlendDifferencePipeline(ContentContextOptions opts) const;
  PipelineRef GetBlendExclusionPipeline(ContentContextOptions opts) const;
  PipelineRef GetBlendHardLightPipeline(ContentContextOptions opts) const;
  PipelineRef GetBlendHuePipeline(ContentContextOptions opts) const;
  PipelineRef GetBlendLightenPipeline(ContentContextOptions opts) const;
  PipelineRef GetBlendLuminosityPipeline(ContentContextOptions opts) const;
  PipelineRef GetBlendMultiplyPipeline(ContentContextOptions opts) const;
  PipelineRef GetBlendOverlayPipeline(ContentContextOptions opts) const;
  PipelineRef GetBlendSaturationPipeline(ContentContextOptions opts) const;
  PipelineRef GetBlendScreenPipeline(ContentContextOptions opts) const;
  PipelineRef GetBlendSoftLightPipeline(ContentContextOptions opts) const;
  PipelineRef GetBorderMaskBlurPipeline(ContentContextOptions opts) const;
  PipelineRef GetClearBlendPipeline(ContentContextOptions opts) const;
  PipelineRef GetClipPipeline(ContentContextOptions opts) const;
  PipelineRef GetColorMatrixColorFilterPipeline(ContentContextOptions opts) const;
  PipelineRef GetConicalGradientFillPipeline(ContentContextOptions opts, ConicalKind kind) const;
  PipelineRef GetConicalGradientSSBOFillPipeline(ContentContextOptions opts, ConicalKind kind) const;
  PipelineRef GetConicalGradientUniformFillPipeline(ContentContextOptions opts, ConicalKind kind) const;
  PipelineRef GetDestinationATopBlendPipeline(ContentContextOptions opts) const;
  PipelineRef GetDestinationBlendPipeline(ContentContextOptions opts) const;
  PipelineRef GetDestinationInBlendPipeline(ContentContextOptions opts) const;
  PipelineRef GetDestinationOutBlendPipeline(ContentContextOptions opts) const;
  PipelineRef GetDestinationOverBlendPipeline(ContentContextOptions opts) const;
  PipelineRef GetDownsamplePipeline(ContentContextOptions opts) const;
  PipelineRef GetDrawVerticesUberShader(ContentContextOptions opts) const;
  PipelineRef GetFastGradientPipeline(ContentContextOptions opts) const;
  PipelineRef GetFramebufferBlendColorBurnPipeline(ContentContextOptions opts) const;
  PipelineRef GetFramebufferBlendColorDodgePipeline(ContentContextOptions opts) const;
  PipelineRef GetFramebufferBlendColorPipeline( ContentContextOptions opts) const;
  PipelineRef GetFramebufferBlendDarkenPipeline(ContentContextOptions opts) const;
  PipelineRef GetFramebufferBlendDifferencePipeline(ContentContextOptions opts) const;
  PipelineRef GetFramebufferBlendExclusionPipeline(ContentContextOptions opts) const;
  PipelineRef GetFramebufferBlendHardLightPipeline(ContentContextOptions opts) const;
  PipelineRef GetFramebufferBlendHuePipeline(ContentContextOptions opts) const;
  PipelineRef GetFramebufferBlendLightenPipeline(ContentContextOptions opts) const;
  PipelineRef GetFramebufferBlendLuminosityPipeline(ContentContextOptions opts) const;
  PipelineRef GetFramebufferBlendMultiplyPipeline(ContentContextOptions opts) const;
  PipelineRef GetFramebufferBlendOverlayPipeline(ContentContextOptions opts) const;
  PipelineRef GetFramebufferBlendSaturationPipeline(ContentContextOptions opts) const;
  PipelineRef GetFramebufferBlendScreenPipeline(ContentContextOptions opts) const;
  PipelineRef GetFramebufferBlendSoftLightPipeline(ContentContextOptions opts) const;
  PipelineRef GetGaussianBlurPipeline(ContentContextOptions opts) const;
  PipelineRef GetGlyphAtlasPipeline(ContentContextOptions opts) const;
  PipelineRef GetLinearGradientFillPipeline(ContentContextOptions opts) const;
  PipelineRef GetLinearGradientSSBOFillPipeline(ContentContextOptions opts) const;
  PipelineRef GetLinearGradientUniformFillPipeline(ContentContextOptions opts) const;
  PipelineRef GetLinearToSrgbFilterPipeline(ContentContextOptions opts) const;
  PipelineRef GetModulateBlendPipeline(ContentContextOptions opts) const;
  PipelineRef GetMorphologyFilterPipeline(ContentContextOptions opts) const;
  PipelineRef GetPlusBlendPipeline(ContentContextOptions opts) const;
  PipelineRef GetPorterDuffPipeline(BlendMode mode, ContentContextOptions opts) const;
  PipelineRef GetRadialGradientFillPipeline(ContentContextOptions opts) const;
  PipelineRef GetRadialGradientSSBOFillPipeline(ContentContextOptions opts) const;
  PipelineRef GetRadialGradientUniformFillPipeline(ContentContextOptions opts) const;
  PipelineRef GetRRectBlurPipeline(ContentContextOptions opts) const;
  PipelineRef GetScreenBlendPipeline(ContentContextOptions opts) const;
  PipelineRef GetSolidFillPipeline(ContentContextOptions opts) const;
  PipelineRef GetSourceATopBlendPipeline(ContentContextOptions opts) const;
  PipelineRef GetSourceBlendPipeline(ContentContextOptions opts) const;
  PipelineRef GetSourceInBlendPipeline(ContentContextOptions opts) const;
  PipelineRef GetSourceOutBlendPipeline(ContentContextOptions opts) const;
  PipelineRef GetSourceOverBlendPipeline(ContentContextOptions opts) const;
  PipelineRef GetSrgbToLinearFilterPipeline(ContentContextOptions opts) const;
  PipelineRef GetSweepGradientFillPipeline(ContentContextOptions opts) const;
  PipelineRef GetSweepGradientSSBOFillPipeline( ContentContextOptions opts) const;
  PipelineRef GetSweepGradientUniformFillPipeline(ContentContextOptions opts) const;
  PipelineRef GetTexturePipeline(ContentContextOptions opts) const;
  PipelineRef GetTextureStrictSrcPipeline(ContentContextOptions opts) const;
  PipelineRef GetTiledTexturePipeline(ContentContextOptions opts) const;
  PipelineRef GetXorBlendPipeline(ContentContextOptions opts) const;
  PipelineRef GetYUVToRGBFilterPipeline(ContentContextOptions opts) const;
#ifdef IMPELLER_ENABLE_OPENGLES
  PipelineRef GetDownsampleTextureGlesPipeline(ContentContextOptions opts) const;
  PipelineRef GetTiledTextureExternalPipeline(ContentContextOptions opts) const;
  PipelineRef GetTiledTextureUvExternalPipeline(ContentContextOptions opts) const;
#endif  // IMPELLER_ENABLE_OPENGLES
  // clang-format on

  // An empty 1x1 texture for binding drawVertices/drawAtlas or other cases
  // that don't always have a texture (due to blending).
  std::shared_ptr<Texture> GetEmptyTexture() const;

  std::shared_ptr<Context> GetContext() const;

  const Capabilities& GetDeviceCapabilities() const;

  void SetWireframe(bool wireframe);

  using SubpassCallback =
      std::function<bool(const ContentContext&, RenderPass&)>;

  /// @brief  Creates a new texture of size `texture_size` and calls
  ///         `subpass_callback` with a `RenderPass` for drawing to the texture.
  fml::StatusOr<RenderTarget> MakeSubpass(
      std::string_view label,
      ISize texture_size,
      const std::shared_ptr<CommandBuffer>& command_buffer,
      const SubpassCallback& subpass_callback,
      bool msaa_enabled = true,
      bool depth_stencil_enabled = false,
      int32_t mip_count = 1) const;

  /// Makes a subpass that will render to `subpass_target`.
  fml::StatusOr<RenderTarget> MakeSubpass(
      std::string_view label,
      const RenderTarget& subpass_target,
      const std::shared_ptr<CommandBuffer>& command_buffer,
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
  PipelineRef GetCachedRuntimeEffectPipeline(
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
                                key.options.ToKey());
      }
    };

    struct Equal {
      constexpr bool operator()(const RuntimeEffectPipelineKey& lhs,
                                const RuntimeEffectPipelineKey& rhs) const {
        return lhs.unique_entrypoint_name == rhs.unique_entrypoint_name &&
               lhs.options.ToKey() == rhs.options.ToKey();
      }
    };
  };

  mutable std::unordered_map<RuntimeEffectPipelineKey,
                             std::shared_ptr<Pipeline<PipelineDescriptor>>,
                             RuntimeEffectPipelineKey::Hash,
                             RuntimeEffectPipelineKey::Equal>
      runtime_effect_pipelines_;

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
      SetDefault(
          default_options_.value(),
          std::make_unique<PipelineHandleT>(context, desc_, /*async=*/false));
      return Get(default_options_.value());
    }

    size_t GetPipelineCount() const { return pipelines_.size(); }

   private:
    std::optional<PipelineDescriptor> desc_;
    std::optional<ContentContextOptions> default_options_;
    std::vector<std::pair<uint64_t, std::unique_ptr<PipelineHandleT>>>
        pipelines_;

    Variants(const Variants&) = delete;

    Variants& operator=(const Variants&) = delete;
  };

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

  template <class TypedPipeline>
  PipelineRef GetPipeline(Variants<TypedPipeline>& container,
                          ContentContextOptions opts) const {
    TypedPipeline* pipeline = CreateIfNeeded(container, opts);
    if (!pipeline) {
      return raw_ptr<Pipeline<PipelineDescriptor>>();
    }
    return raw_ptr(pipeline->WaitAndGet());
  }

  template <class RenderPipelineHandleT>
  RenderPipelineHandleT* CreateIfNeeded(
      Variants<RenderPipelineHandleT>& container,
      ContentContextOptions opts) const {
    if (!IsValid()) {
      return nullptr;
    }

    if (wireframe_) {
      opts.wireframe = true;
    }

    if (RenderPipelineHandleT* found = container.Get(opts)) {
      return found;
    }

    RenderPipelineHandleT* default_handle = container.GetDefault(*GetContext());
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

  bool is_valid_ = false;
  std::shared_ptr<Tessellator> tessellator_;
  std::shared_ptr<RenderTargetAllocator> render_target_cache_;
  std::shared_ptr<HostBuffer> host_buffer_;
  std::shared_ptr<Texture> empty_texture_;
  bool wireframe_ = false;

  ContentContext(const ContentContext&) = delete;

  ContentContext& operator=(const ContentContext&) = delete;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_ENTITY_CONTENTS_CONTENT_CONTEXT_H_
