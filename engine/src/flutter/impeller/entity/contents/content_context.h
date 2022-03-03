// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <memory>
#include <unordered_map>

#include "flutter/fml/hash_combine.h"
#include "flutter/fml/macros.h"
#include "flutter/impeller/entity/glyph_atlas.frag.h"
#include "flutter/impeller/entity/glyph_atlas.vert.h"
#include "flutter/impeller/entity/gradient_fill.frag.h"
#include "flutter/impeller/entity/gradient_fill.vert.h"
#include "flutter/impeller/entity/solid_fill.frag.h"
#include "flutter/impeller/entity/solid_fill.vert.h"
#include "flutter/impeller/entity/solid_stroke.frag.h"
#include "flutter/impeller/entity/solid_stroke.vert.h"
#include "flutter/impeller/entity/texture_fill.frag.h"
#include "flutter/impeller/entity/texture_fill.vert.h"

namespace impeller {

using GradientFillPipeline =
    PipelineT<GradientFillVertexShader, GradientFillFragmentShader>;
using SolidFillPipeline =
    PipelineT<SolidFillVertexShader, SolidFillFragmentShader>;
using TexturePipeline =
    PipelineT<TextureFillVertexShader, TextureFillFragmentShader>;
using SolidStrokePipeline =
    PipelineT<SolidStrokeVertexShader, SolidStrokeFragmentShader>;
using GlyphAtlasPipeline =
    PipelineT<GlyphAtlasVertexShader, GlyphAtlasFragmentShader>;
// Instead of requiring new shaders for clips,  the solid fill stages are used
// to redirect writing to the stencil instead of color attachments.
using ClipPipeline = PipelineT<SolidFillVertexShader, SolidFillFragmentShader>;

struct ContentContextOptions {
  SampleCount sample_count = SampleCount::kCount1;

  struct Hash {
    constexpr std::size_t operator()(const ContentContextOptions& o) const {
      return fml::HashCombine(o.sample_count);
    }
  };

  struct Equal {
    constexpr bool operator()(const ContentContextOptions& lhs,
                              const ContentContextOptions& rhs) const {
      return lhs.sample_count == rhs.sample_count;
    }
  };
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

  std::shared_ptr<Pipeline> GetTexturePipeline(
      ContentContextOptions opts) const {
    return GetPipeline(texture_pipelines_, opts);
  }

  std::shared_ptr<Pipeline> GetSolidStrokePipeline(
      ContentContextOptions opts) const {
    return GetPipeline(solid_stroke_pipelines_, opts);
  }

  std::shared_ptr<Pipeline> GetClipPipeline(ContentContextOptions opts) const {
    return GetPipeline(clip_pipelines_, opts);
  }

  std::shared_ptr<Pipeline> GetClipRestorePipeline(
      ContentContextOptions opts) const {
    return GetPipeline(clip_restoration_pipelines_, opts);
  }

  std::shared_ptr<Pipeline> GetGlyphAtlasPipeline(
      ContentContextOptions opts) const {
    return GetPipeline(glyph_atlas_pipelines_, opts);
  }

  std::shared_ptr<Context> GetContext() const;

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
  mutable Variants<TexturePipeline> texture_pipelines_;
  mutable Variants<SolidStrokePipeline> solid_stroke_pipelines_;
  mutable Variants<ClipPipeline> clip_pipelines_;
  mutable Variants<ClipPipeline> clip_restoration_pipelines_;
  mutable Variants<GlyphAtlasPipeline> glyph_atlas_pipelines_;

  static void ApplyOptionsToDescriptor(PipelineDescriptor& desc,
                                       const ContentContextOptions& options) {
    desc.SetSampleCount(options.sample_count);
  }

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
          ApplyOptionsToDescriptor(desc, opts);
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
