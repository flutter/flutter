// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <array>
#include <cstddef>
#include <string_view>

#include "impeller/geometry/matrix.h"

namespace impeller {

enum class ShaderStage {
  kUnknown,
  kVertex,
  kFragment,
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

template <class T>
struct ShaderUniformSlot {
  using Type = T;
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

}  // namespace impeller
