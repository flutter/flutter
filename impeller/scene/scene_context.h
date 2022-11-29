// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "impeller/renderer/context.h"
#include "impeller/renderer/pipeline_descriptor.h"
#include "impeller/scene/shaders/geometry.vert.h"
#include "impeller/scene/shaders/unlit.frag.h"

namespace impeller {
namespace scene {

using UnlitPipeline =
    RenderPipelineT<GeometryVertexShader, UnlitFragmentShader>;

struct SceneContextOptions {
  SampleCount sample_count = SampleCount::kCount1;
  PrimitiveType primitive_type = PrimitiveType::kTriangle;

  struct Hash {
    constexpr std::size_t operator()(const SceneContextOptions& o) const {
      return fml::HashCombine(o.sample_count, o.primitive_type);
    }
  };

  struct Equal {
    constexpr bool operator()(const SceneContextOptions& lhs,
                              const SceneContextOptions& rhs) const {
      return lhs.sample_count == rhs.sample_count &&
             lhs.primitive_type == rhs.primitive_type;
    }
  };

  void ApplyToPipelineDescriptor(PipelineDescriptor& desc) const;
};

class SceneContext {
 public:
  explicit SceneContext(std::shared_ptr<Context> context);

  ~SceneContext();

  bool IsValid() const;

  std::shared_ptr<Context> GetContext() const;

  std::shared_ptr<Pipeline<PipelineDescriptor>> GetUnlitPipeline(
      SceneContextOptions opts) const {
    return GetPipeline(unlit_pipeline_, opts);
  }

 private:
  std::shared_ptr<Context> context_;

  template <class T>
  using Variants = std::unordered_map<SceneContextOptions,
                                      std::unique_ptr<T>,
                                      SceneContextOptions::Hash,
                                      SceneContextOptions::Equal>;

  mutable Variants<UnlitPipeline> unlit_pipeline_;

  template <class TypedPipeline>
  std::shared_ptr<Pipeline<PipelineDescriptor>> GetPipeline(
      Variants<TypedPipeline>& container,
      SceneContextOptions opts) const {
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

  FML_DISALLOW_COPY_AND_ASSIGN(SceneContext);
};

}  // namespace scene
}  // namespace impeller
