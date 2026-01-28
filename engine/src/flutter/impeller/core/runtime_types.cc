// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/core/runtime_types.h"

namespace impeller {

size_t RuntimeUniformDescription::GetDartSize() const {
  size_t size = 0;
  if (!padding_layout.empty()) {
    for (impeller::RuntimePaddingType byte_type : padding_layout) {
      if (byte_type == RuntimePaddingType::kFloat) {
        size += sizeof(float);
      }
    }
  } else {
    size = dimensions.rows * dimensions.cols * bit_width / 8u;
  }
  if (array_elements.value_or(0) > 0) {
    // Covered by check on the line above.
    // NOLINTNEXTLINE(bugprone-unchecked-optional-access)
    size *= array_elements.value();
  }
  return size;
}

size_t RuntimeUniformDescription::GetGPUSize() const {
  size_t size = 0;
  if (padding_layout.empty()) {
    size = dimensions.rows * dimensions.cols * bit_width / 8u;
  } else {
    size = sizeof(float) * padding_layout.size();
  }
  if (array_elements.value_or(0) > 0) {
    // Covered by check on the line above.
    // NOLINTNEXTLINE(bugprone-unchecked-optional-access)
    size *= array_elements.value();
  }
  return size;
}

}  // namespace impeller
