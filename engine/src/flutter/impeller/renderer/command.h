// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <map>
#include <memory>
#include <string>

#include "flutter/fml/logging.h"
#include "flutter/fml/macros.h"
#include "impeller/renderer/buffer_view.h"
#include "impeller/renderer/formats.h"
#include "impeller/renderer/pipeline.h"
#include "impeller/renderer/sampler.h"
#include "impeller/renderer/shader_types.h"
#include "impeller/renderer/texture.h"
#include "impeller/renderer/vertex_buffer.h"

namespace impeller {

struct Bindings {
  std::map<size_t, BufferView> buffers;
  std::map<size_t, std::shared_ptr<const Texture>> textures;
  std::map<size_t, std::shared_ptr<const Sampler>> samplers;
};

struct Command {
  std::shared_ptr<Pipeline> pipeline;
  Bindings vertex_bindings;
  Bindings fragment_bindings;
  BufferView index_buffer;
  size_t index_count = 0u;
  std::string label;
  PrimitiveType primitive_type = PrimitiveType::kTriangle;
  WindingOrder winding = WindingOrder::kClockwise;

  bool BindVertices(const VertexBuffer& buffer);

  template <class T>
  bool BindResource(ShaderStage stage,
                    const ShaderUniformSlot<T> slot,
                    BufferView view) {
    return BindResource(stage, slot.binding, std::move(view));
  }

  bool BindResource(ShaderStage stage, size_t binding, BufferView view);

  bool BindResource(ShaderStage stage,
                    const SampledImageSlot& slot,
                    std::shared_ptr<const Texture> texture);

  bool BindResource(ShaderStage stage,
                    const SampledImageSlot& slot,
                    std::shared_ptr<const Sampler> sampler);

  bool BindResource(ShaderStage stage,
                    const SampledImageSlot& slot,
                    std::shared_ptr<const Texture> texture,
                    std::shared_ptr<const Sampler> sampler);

  constexpr operator bool() const { return pipeline && pipeline->IsValid(); }
};

}  // namespace impeller
