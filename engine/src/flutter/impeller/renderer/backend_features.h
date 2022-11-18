// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

namespace impeller {

/// @brief A struct for describing available backend features for runtime
/// selection.
struct BackendFeatures {
  bool ssbo_support;
};

/// @brief feature sets available on most but not all modern hardware.
constexpr BackendFeatures kModernBackendFeatures = {.ssbo_support = true};

/// @brief Lowest common denominator feature sets.
constexpr BackendFeatures kLegacyBackendFeatures = {.ssbo_support = false};

}  // namespace impeller
