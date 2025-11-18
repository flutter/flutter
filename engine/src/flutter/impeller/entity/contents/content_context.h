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
#include "impeller/entity/contents/text_shadow_cache.h"
#include "impeller/geometry/color.h"
#include "impeller/renderer/capabilities.h"
#include "impeller/renderer/command_buffer.h"
#include "impeller/renderer/pipeline.h"
#include "impeller/renderer/pipeline_descriptor.h"
#include "impeller/renderer/render_target.h"
#include "impeller/typographer/lazy_glyph_atlas.h"
#include "impeller/typographer/typographer_context.h"

namespace impeller {
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
           (0) << 1 |  // // Unused, previously wireframe.
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
  PipelineRef GetCirclePipeline(ContentContextOptions opts) const;
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
  PipelineRef GetDrawVerticesUberPipeline(BlendMode blend_mode, ContentContextOptions opts) const;
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
  PipelineRef GetLinePipeline(ContentContextOptions opts) const;
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
  PipelineRef GetRSuperellipseBlurPipeline(ContentContextOptions opts) const;
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
#if !defined(FML_OS_EMSCRIPTEN)
  PipelineRef GetTiledTextureExternalPipeline(ContentContextOptions opts) const;
  PipelineRef GetTiledTextureUvExternalPipeline(ContentContextOptions opts) const;
#endif
  PipelineRef GetDownsampleTextureGlesPipeline(ContentContextOptions opts) const;
#endif  // IMPELLER_ENABLE_OPENGLES
  // clang-format on

  // An empty 1x1 texture for binding drawVertices/drawAtlas or other cases
  // that don't always have a texture (due to blending).
  std::shared_ptr<Texture> GetEmptyTexture() const;

  std::shared_ptr<Context> GetContext() const;

  const Capabilities& GetDeviceCapabilities() const;

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

  /// @brief Retrieve the current host buffer for transient storage of indexes
  ///        used for indexed draws.
  ///
  /// This may or may not return the same value as `GetTransientsDataBuffer`
  /// depending on the backend.
  ///
  /// This is only safe to use from the raster threads. Other threads should
  /// allocate their own device buffers.
  HostBuffer& GetTransientsIndexesBuffer() const {
    return *indexes_host_buffer_;
  }

  /// @brief Retrieve the current host buffer for transient storage of other
  ///        non-index data.
  ///
  /// This is only safe to use from the raster threads. Other threads should
  /// allocate their own device buffers.
  HostBuffer& GetTransientsDataBuffer() const { return *data_host_buffer_; }

  /// @brief Resets the transients buffers held onto by the content context.
  void ResetTransientsBuffers();

  TextShadowCache& GetTextShadowCache() const { return *text_shadow_cache_; }

 protected:
  // Visible for testing.
  void SetTransientsIndexesBuffer(std::shared_ptr<HostBuffer> host_buffer) {
    indexes_host_buffer_ = std::move(host_buffer);
  }

  // Visible for testing.
  void SetTransientsDataBuffer(std::shared_ptr<HostBuffer> host_buffer) {
    data_host_buffer_ = std::move(host_buffer);
  }

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
      inline bool operator()(const RuntimeEffectPipelineKey& lhs,
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

  struct Pipelines;
  std::unique_ptr<Pipelines> pipelines_;

  bool is_valid_ = false;
  std::shared_ptr<Tessellator> tessellator_;
  std::shared_ptr<RenderTargetAllocator> render_target_cache_;
  std::shared_ptr<HostBuffer> data_host_buffer_;
  std::shared_ptr<HostBuffer> indexes_host_buffer_;
  std::shared_ptr<Texture> empty_texture_;
  std::unique_ptr<TextShadowCache> text_shadow_cache_;

  ContentContext(const ContentContext&) = delete;

  ContentContext& operator=(const ContentContext&) = delete;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_ENTITY_CONTENTS_CONTENT_CONTEXT_H_
