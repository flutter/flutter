// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <cstddef>
#include <string_view>
#include <vector>

#include "flutter/fml/hash_combine.h"
#include "impeller/geometry/matrix.h"

namespace impeller {

enum class ShaderStage {
  kUnknown,
  kVertex,
  kFragment,
  kTessellationControl,
  kTessellationEvaluation,
  kCompute,
};

enum class ShaderType {
  kUnknown,
  kVoid,
  kBoolean,
  kSignedByte,
  kUnsignedByte,
  kSignedShort,
  kUnsignedShort,
  kSignedInt,
  kUnsignedInt,
  kSignedInt64,
  kUnsignedInt64,
  kAtomicCounter,
  kHalfFloat,
  kFloat,
  kDouble,
  kStruct,
  kImage,
  kSampledImage,
  kSampler,
};

struct ShaderStructMemberMetadata {
  ShaderType type;
  std::string name;
  size_t offset;
  size_t size;
};

struct ShaderMetadata {
  std::string name;
  std::vector<ShaderStructMemberMetadata> members;
};

struct ShaderUniformSlot {
  const char* name;
  size_t binding;
};

struct ShaderStageIOSlot {
  const char* name;
  size_t location;
  size_t set;
  size_t binding;
  ShaderType type;
  size_t bit_width;
  size_t vec_size;
  size_t columns;

  constexpr size_t GetHash() const {
    return fml::HashCombine(name, location, set, binding, type, bit_width,
                            vec_size, columns);
  }

  constexpr bool operator==(const ShaderStageIOSlot& other) const {
    return name == other.name &&            //
           location == other.location &&    //
           set == other.set &&              //
           binding == other.binding &&      //
           type == other.type &&            //
           bit_width == other.bit_width &&  //
           vec_size == other.vec_size &&    //
           columns == other.columns;
  }
};

struct SampledImageSlot {
  const char* name;
  size_t texture_index;
  size_t sampler_index;

  constexpr bool HasTexture() const { return texture_index < 32u; }

  constexpr bool HasSampler() const { return sampler_index < 32u; }
};

template <size_t Size>
struct Padding {
 private:
  uint8_t pad_[Size];
};

inline constexpr Vector4 ToVector(Color color) {
  return {color.red, color.green, color.blue, color.alpha};
}

}  // namespace impeller
