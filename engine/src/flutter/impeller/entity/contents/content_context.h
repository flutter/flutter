// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <memory>
#include <unordered_map>

#include "flutter/fml/hash_combine.h"
#include "flutter/fml/macros.h"
#include "fml/logging.h"
#include "impeller/base/validation.h"
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
#include "impeller/entity/blend.frag.h"
#include "impeller/entity/blend.vert.h"
#include "impeller/entity/border_mask_blur.frag.h"
#include "impeller/entity/border_mask_blur.vert.h"
#include "impeller/entity/entity.h"
#include "impeller/entity/gaussian_blur.frag.h"
#include "impeller/entity/gaussian_blur.vert.h"
#include "impeller/entity/glyph_atlas.frag.h"
#include "impeller/entity/glyph_atlas.vert.h"
#include "impeller/entity/gradient_fill.frag.h"
#include "impeller/entity/gradient_fill.vert.h"
#include "impeller/entity/solid_fill.frag.h"
#include "impeller/entity/solid_fill.vert.h"
#include "impeller/entity/solid_stroke.frag.h"
#include "impeller/entity/solid_stroke.vert.h"
#include "impeller/entity/texture_fill.frag.h"
#include "impeller/entity/texture_fill.vert.h"
#include "impeller/entity/vertices.frag.h"
#include "impeller/entity/vertices.vert.h"
#include "impeller/renderer/formats.h"

namespace impeller {

using GradientFillPipeline =
    PipelineT<GradientFillVertexShader, GradientFillFragmentShader>;
using SolidFillPipeline =
    PipelineT<SolidFillVertexShader, SolidFillFragmentShader>;
using BlendPipeline = PipelineT<BlendVertexShader, BlendFragmentShader>;
using BlendColorPipeline =
    PipelineT<AdvancedBlendVertexShader, AdvancedBlendColorFragmentShader>;
using BlendColorBurnPipeline =
    PipelineT<AdvancedBlendVertexShader, AdvancedBlendColorburnFragmentShader>;
using BlendColorDodgePipeline =
    PipelineT<AdvancedBlendVertexShader, AdvancedBlendColordodgeFragmentShader>;
using BlendDarkenPipeline =
    PipelineT<AdvancedBlendVertexShader, AdvancedBlendDarkenFragmentShader>;
using BlendDifferencePipeline =
    PipelineT<AdvancedBlendVertexShader, AdvancedBlendDifferenceFragmentShader>;
using BlendExclusionPipeline =
    PipelineT<AdvancedBlendVertexShader, AdvancedBlendExclusionFragmentShader>;
using BlendHardLightPipeline =
    PipelineT<AdvancedBlendVertexShader, AdvancedBlendHardlightFragmentShader>;
using BlendHuePipeline =
    PipelineT<AdvancedBlendVertexShader, AdvancedBlendHueFragmentShader>;
using BlendLightenPipeline =
    PipelineT<AdvancedBlendVertexShader, AdvancedBlendLightenFragmentShader>;
using BlendLuminosityPipeline =
    PipelineT<AdvancedBlendVertexShader, AdvancedBlendLuminosityFragmentShader>;
using BlendMultiplyPipeline =
    PipelineT<AdvancedBlendVertexShader, AdvancedBlendMultiplyFragmentShader>;
using BlendOverlayPipeline =
    PipelineT<AdvancedBlendVertexShader, AdvancedBlendOverlayFragmentShader>;
using BlendSaturationPipeline =
    PipelineT<AdvancedBlendVertexShader, AdvancedBlendSaturationFragmentShader>;
using BlendScreenPipeline =
    PipelineT<AdvancedBlendVertexShader, AdvancedBlendScreenFragmentShader>;
using BlendSoftLightPipeline =
    PipelineT<AdvancedBlendVertexShader, AdvancedBlendSoftlightFragmentShader>;
using TexturePipeline =
    PipelineT<TextureFillVertexShader, TextureFillFragmentShader>;
using GaussianBlurPipeline =
    PipelineT<GaussianBlurVertexShader, GaussianBlurFragmentShader>;
using BorderMaskBlurPipeline =
    PipelineT<BorderMaskBlurVertexShader, BorderMaskBlurFragmentShader>;
using SolidStrokePipeline =
    PipelineT<SolidStrokeVertexShader, SolidStrokeFragmentShader>;
using GlyphAtlasPipeline =
    PipelineT<GlyphAtlasVertexShader, GlyphAtlasFragmentShader>;
using VerticesPipeline =
    PipelineT<VerticesVertexShader, VerticesFragmentShader>;
// Instead of requiring new shaders for clips, the solid fill stages are used
// to redirect writing to the stencil instead of color attachments.
using ClipPipeline = PipelineT<SolidFillVertexShader, SolidFillFragmentShader>;

struct ContentContextOptions {
  SampleCount sample_count = SampleCount::kCount1;
  Entity::BlendMode blend_mode = Entity::BlendMode::kSourceOver;
  CompareFunction stencil_compare = CompareFunction::kEqual;
  StencilOperation stencil_operation = StencilOperation::kKeep;

  struct Hash {
    constexpr std::size_t operator()(const ContentContextOptions& o) const {
      return fml::HashCombine(o.sample_count, o.blend_mode, o.stencil_compare,
                              o.stencil_operation);
    }
  };

  struct Equal {
    constexpr bool operator()(const ContentContextOptions& lhs,
                              const ContentContextOptions& rhs) const {
      return lhs.sample_count == rhs.sample_count &&
             lhs.blend_mode == rhs.blend_mode &&
             lhs.stencil_compare == rhs.stencil_compare &&
             lhs.stencil_operation == rhs.stencil_operation;
    }
  };

  void ApplyToPipelineDescriptor(PipelineDescriptor& desc) const;
};

class ContentContext {
 public:
  ContentContext(std::shared_ptr<Context> context);

  ~ContentContext();

  bool IsValid() const;

  std::shared_ptr<Pipeline> GetGradientFillPipeline(
      ContentContextOptions opts) const {
    return GetPipeline(gradient_fill_pipelines_, opts);
  }

  std::shared_ptr<Pipeline> GetSolidFillPipeline(
      ContentContextOptions opts) const {
    return GetPipeline(solid_fill_pipelines_, opts);
  }

  std::shared_ptr<Pipeline> GetBlendPipeline(ContentContextOptions opts) const {
    return GetPipeline(texture_blend_pipelines_, opts);
  }

  std::shared_ptr<Pipeline> GetTexturePipeline(
      ContentContextOptions opts) const {
    return GetPipeline(texture_pipelines_, opts);
  }

  std::shared_ptr<Pipeline> GetGaussianBlurPipeline(
      ContentContextOptions opts) const {
    return GetPipeline(gaussian_blur_pipelines_, opts);
  }

  std::shared_ptr<Pipeline> GetBorderMaskBlurPipeline(
      ContentContextOptions opts) const {
    return GetPipeline(border_mask_blur_pipelines_, opts);
  }

  std::shared_ptr<Pipeline> GetSolidStrokePipeline(
      ContentContextOptions opts) const {
    return GetPipeline(solid_stroke_pipelines_, opts);
  }

  std::shared_ptr<Pipeline> GetClipPipeline(ContentContextOptions opts) const {
    return GetPipeline(clip_pipelines_, opts);
  }

  std::shared_ptr<Pipeline> GetGlyphAtlasPipeline(
      ContentContextOptions opts) const {
    return GetPipeline(glyph_atlas_pipelines_, opts);
  }

  std::shared_ptr<Pipeline> GetVerticesPipeline(
      ContentContextOptions opts) const {
    return GetPipeline(vertices_pipelines_, opts);
  }

  // Advanced blends.

  std::shared_ptr<Pipeline> GetBlendColorPipeline(
      ContentContextOptions opts) const {
    return GetPipeline(blend_color_pipelines_, opts);
  }

  std::shared_ptr<Pipeline> GetBlendColorBurnPipeline(
      ContentContextOptions opts) const {
    return GetPipeline(blend_colorburn_pipelines_, opts);
  }

  std::shared_ptr<Pipeline> GetBlendColorDodgePipeline(
      ContentContextOptions opts) const {
    return GetPipeline(blend_colordodge_pipelines_, opts);
  }

  std::shared_ptr<Pipeline> GetBlendDarkenPipeline(
      ContentContextOptions opts) const {
    return GetPipeline(blend_darken_pipelines_, opts);
  }

  std::shared_ptr<Pipeline> GetBlendDifferencePipeline(
      ContentContextOptions opts) const {
    return GetPipeline(blend_difference_pipelines_, opts);
  }

  std::shared_ptr<Pipeline> GetBlendExclusionPipeline(
      ContentContextOptions opts) const {
    return GetPipeline(blend_exclusion_pipelines_, opts);
  }

  std::shared_ptr<Pipeline> GetBlendHardLightPipeline(
      ContentContextOptions opts) const {
    return GetPipeline(blend_hardlight_pipelines_, opts);
  }

  std::shared_ptr<Pipeline> GetBlendHuePipeline(
      ContentContextOptions opts) const {
    return GetPipeline(blend_hue_pipelines_, opts);
  }

  std::shared_ptr<Pipeline> GetBlendLightenPipeline(
      ContentContextOptions opts) const {
    return GetPipeline(blend_lighten_pipelines_, opts);
  }

  std::shared_ptr<Pipeline> GetBlendLuminosityPipeline(
      ContentContextOptions opts) const {
    return GetPipeline(blend_luminosity_pipelines_, opts);
  }

  std::shared_ptr<Pipeline> GetBlendMultiplyPipeline(
      ContentContextOptions opts) const {
    return GetPipeline(blend_multiply_pipelines_, opts);
  }

  std::shared_ptr<Pipeline> GetBlendOverlayPipeline(
      ContentContextOptions opts) const {
    return GetPipeline(blend_overlay_pipelines_, opts);
  }

  std::shared_ptr<Pipeline> GetBlendSaturationPipeline(
      ContentContextOptions opts) const {
    return GetPipeline(blend_saturation_pipelines_, opts);
  }

  std::shared_ptr<Pipeline> GetBlendScreenPipeline(
      ContentContextOptions opts) const {
    return GetPipeline(blend_screen_pipelines_, opts);
  }

  std::shared_ptr<Pipeline> GetBlendSoftLightPipeline(
      ContentContextOptions opts) const {
    return GetPipeline(blend_softlight_pipelines_, opts);
  }

  std::shared_ptr<Context> GetContext() const;

  using SubpassCallback =
      std::function<bool(const ContentContext&, RenderPass&)>;

  /// @brief  Creates a new texture of size `texture_size` and calls
  ///         `subpass_callback` with a `RenderPass` for drawing to the texture.
  std::shared_ptr<Texture> MakeSubpass(ISize texture_size,
                                       SubpassCallback subpass_callback) const;

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
  mutable Variants<GradientFillPipeline> gradient_fill_pipelines_;
  mutable Variants<SolidFillPipeline> solid_fill_pipelines_;
  mutable Variants<BlendPipeline> texture_blend_pipelines_;
  mutable Variants<TexturePipeline> texture_pipelines_;
  mutable Variants<GaussianBlurPipeline> gaussian_blur_pipelines_;
  mutable Variants<BorderMaskBlurPipeline> border_mask_blur_pipelines_;
  mutable Variants<SolidStrokePipeline> solid_stroke_pipelines_;
  mutable Variants<ClipPipeline> clip_pipelines_;
  mutable Variants<GlyphAtlasPipeline> glyph_atlas_pipelines_;
  mutable Variants<VerticesPipeline> vertices_pipelines_;
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

  template <class TypedPipeline>
  std::shared_ptr<Pipeline> GetPipeline(Variants<TypedPipeline>& container,
                                        ContentContextOptions opts) const {
    if (!IsValid()) {
      return nullptr;
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

  FML_DISALLOW_COPY_AND_ASSIGN(ContentContext);
};

}  // namespace impeller
