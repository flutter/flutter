// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <unordered_map>

#include "flutter/fml/macros.h"
#include "impeller/base/comparable.h"
#include "impeller/renderer/formats.h"

namespace impeller {

class Sampler;
class Context;

struct SamplerDescriptor final : public Comparable<SamplerDescriptor> {
  MinMagFilter min_filter = MinMagFilter::kNearest;
  MinMagFilter mag_filter = MinMagFilter::kNearest;

  SamplerAddressMode width_address_mode = SamplerAddressMode::kClampToEdge;
  SamplerAddressMode height_address_mode = SamplerAddressMode::kClampToEdge;
  SamplerAddressMode depth_address_mode = SamplerAddressMode::kClampToEdge;

  std::string label = "NN Clamp Sampler";

  // Comparable<SamplerDescriptor>
  std::size_t GetHash() const override {
    return fml::HashCombine(min_filter, mag_filter, width_address_mode,
                            height_address_mode, depth_address_mode);
  }

  // Comparable<SamplerDescriptor>
  bool IsEqual(const SamplerDescriptor& o) const override {
    return min_filter == o.min_filter && mag_filter == o.mag_filter &&
           width_address_mode == o.width_address_mode &&
           height_address_mode == o.height_address_mode &&
           depth_address_mode == o.depth_address_mode;
  }
};

using SamplerMap = std::unordered_map<SamplerDescriptor,
                                      std::shared_ptr<const Sampler>,
                                      ComparableHash<SamplerDescriptor>,
                                      ComparableEqual<SamplerDescriptor>>;

}  // namespace impeller
