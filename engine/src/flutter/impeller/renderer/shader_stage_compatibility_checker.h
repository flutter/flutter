// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_RENDERER_SHADER_STAGE_COMPATIBILITY_CHECKER_H_
#define FLUTTER_IMPELLER_RENDERER_SHADER_STAGE_COMPATIBILITY_CHECKER_H_

#include <cstddef>

#include "impeller/core/shader_types.h"

namespace impeller {
/// This is a classed use to check that the input slots of fragment shaders
/// match the output slots of the vertex shaders.
/// If they don't match it will result in linker errors when creating the
/// pipeline.  It's not used at runtime.
template <typename VertexShaderT, typename FragmentShaderT>
class ShaderStageCompatibilityChecker {
 public:
  static constexpr bool CompileTimeStrEqual(const char* str1,
                                            const char* str2) {
    return *str1 == *str2 &&
           (*str1 == '\0' || CompileTimeStrEqual(str1 + 1, str2 + 1));
  }

  /// Returns `true` if the shader input slots for the fragment shader match the
  /// ones declared as outputs in the vertex shader.
  static constexpr bool Check() {
    constexpr size_t num_outputs = VertexShaderT::kAllShaderStageOutputs.size();
    constexpr size_t num_inputs = FragmentShaderT::kAllShaderStageInputs.size();

    if (num_inputs > num_outputs) {
      return false;
    }

    for (size_t i = 0; i < num_inputs; ++i) {
      const ShaderStageIOSlot* input_slot =
          FragmentShaderT::kAllShaderStageInputs[i];
      for (size_t j = 0; j < num_outputs; ++j) {
        const ShaderStageIOSlot* output_slot =
            VertexShaderT::kAllShaderStageOutputs[j];
        if (input_slot->location == output_slot->location) {
          if (!CompileTimeStrEqual(input_slot->name, output_slot->name) ||
              input_slot->set != output_slot->set ||
              input_slot->binding != output_slot->binding ||
              input_slot->type != output_slot->type ||
              input_slot->bit_width != output_slot->bit_width ||
              input_slot->vec_size != output_slot->vec_size ||
              input_slot->columns != output_slot->columns ||
              input_slot->offset != output_slot->offset) {
            return false;
          }
        }
      }
    }

    return true;
  }
};

// The following shaders don't define output slots.
// TODO(https://github.com/flutter/flutter/issues/146852): Make impellerc emit
// an empty array for output slots.
struct ClipVertexShader;
struct SolidFillVertexShader;

template <typename FragmentShaderT>
class ShaderStageCompatibilityChecker<ClipVertexShader, FragmentShaderT> {
 public:
  static constexpr bool Check() { return true; }
};
template <typename FragmentShaderT>
class ShaderStageCompatibilityChecker<SolidFillVertexShader, FragmentShaderT> {
 public:
  static constexpr bool Check() { return true; }
};
}  // namespace impeller
#endif  // FLUTTER_IMPELLER_RENDERER_SHADER_STAGE_COMPATIBILITY_CHECKER_H_
