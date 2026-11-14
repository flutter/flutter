// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_COMPILER_GLSL_UNIFORMS_H_
#define FLUTTER_IMPELLER_COMPILER_GLSL_UNIFORMS_H_

#include <cstdint>

#include "spirv_glsl.hpp"

namespace impeller::compiler {

inline bool CanEmitPlainUniforms(const spirv_cross::CompilerGLSL& compiler,
                                 uint32_t vector_limit) {
  if (vector_limit == 0) {
    return false;
  }
  const auto resources = compiler.get_shader_resources();
  if (!resources.storage_buffers.empty() ||
      !resources.push_constant_buffers.empty() ||
      !resources.gl_plain_uniforms.empty() ||
      !resources.separate_images.empty() ||
      !resources.separate_samplers.empty()) {
    return false;
  }
  // Treat every scalar component as a separate vector, including padding.
  // This overestimates storage without depending on the driver's packing.
  // Include sampler uniforms in the same conservative bound.
  uint64_t vectors = resources.sampled_images.size();
  for (const auto& sampler : resources.sampled_images) {
    if (!compiler.get_type(sampler.type_id).array.empty()) {
      return false;
    }
  }
  for (const auto& ubo : resources.uniform_buffers) {
    if (!compiler.get_type(ubo.type_id).array.empty()) {
      return false;
    }
    const auto& block = compiler.get_type(ubo.base_type_id);
    for (size_t i = 0; i < block.member_types.size(); i++) {
      const auto& member = compiler.get_type(block.member_types[i]);
      // Keep layouts unsupported by BufferBindingsGLES's plain-uniform path,
      // including mat2/mat3 with std140 column padding, as uniform blocks.
      if (member.basetype != spirv_cross::SPIRType::Float ||
          member.width != 32 || member.array.size() > 1 ||
          compiler.has_member_decoration(block.self, i,
                                         spv::DecorationRowMajor) ||
          (member.columns > 1 &&
           (member.columns != 4 || member.vecsize != 4))) {
        return false;
      }
      if (!member.array.empty() &&
          (!member.array_size_literal[0] || member.array[0] == 0)) {
        return false;
      }
    }
    vectors += (compiler.get_declared_struct_size(block) + 3) / 4;
  }
  return vectors <= vector_limit;
}

}  // namespace impeller::compiler

#endif  // FLUTTER_IMPELLER_COMPILER_GLSL_UNIFORMS_H_
