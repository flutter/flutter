// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_CORE_RUNTIME_TYPES_H_
#define FLUTTER_IMPELLER_CORE_RUNTIME_TYPES_H_

#include <cstddef>
#include <optional>
#include <string>

namespace impeller {

enum class RuntimeStageBackend {
  kSkSL,
  kMetal,
  kOpenGLES,
  kVulkan,
};

enum RuntimeUniformType {
  kBoolean,
  kSignedByte,
  kUnsignedByte,
  kSignedShort,
  kUnsignedShort,
  kSignedInt,
  kUnsignedInt,
  kSignedInt64,
  kUnsignedInt64,
  kHalfFloat,
  kFloat,
  kDouble,
  kSampledImage,
};

enum class RuntimeShaderStage {
  kVertex,
  kFragment,
  kCompute,
};

struct RuntimeUniformDimensions {
  size_t rows = 0;
  size_t cols = 0;
};

struct RuntimeUniformDescription {
  std::string name;
  size_t location = 0u;
  RuntimeUniformType type = RuntimeUniformType::kFloat;
  RuntimeUniformDimensions dimensions;
  size_t bit_width;
  std::optional<size_t> array_elements;

  /// @brief  Computes the total number of bytes that this uniform requires.
  size_t GetSize() const;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_CORE_RUNTIME_TYPES_H_
