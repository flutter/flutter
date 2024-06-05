// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_CORE_SAMPLER_DESCRIPTOR_H_
#define FLUTTER_IMPELLER_CORE_SAMPLER_DESCRIPTOR_H_

#include "impeller/base/comparable.h"
#include "impeller/core/formats.h"

namespace impeller {

class Context;

struct SamplerDescriptor final : public Comparable<SamplerDescriptor> {
  MinMagFilter min_filter = MinMagFilter::kNearest;
  MinMagFilter mag_filter = MinMagFilter::kNearest;
  MipFilter mip_filter = MipFilter::kNearest;

  SamplerAddressMode width_address_mode = SamplerAddressMode::kClampToEdge;
  SamplerAddressMode height_address_mode = SamplerAddressMode::kClampToEdge;
  SamplerAddressMode depth_address_mode = SamplerAddressMode::kClampToEdge;

  std::string label = "NN Clamp Sampler";

  SamplerDescriptor();

  SamplerDescriptor(std::string label,
                    MinMagFilter min_filter,
                    MinMagFilter mag_filter,
                    MipFilter mip_filter);

  // Comparable<SamplerDescriptor>
  std::size_t GetHash() const override {
    return fml::HashCombine(min_filter, mag_filter, mip_filter,
                            width_address_mode, height_address_mode,
                            depth_address_mode);
  }

  // Comparable<SamplerDescriptor>
  bool IsEqual(const SamplerDescriptor& o) const override {
    return min_filter == o.min_filter && mag_filter == o.mag_filter &&
           mip_filter == o.mip_filter &&
           width_address_mode == o.width_address_mode &&
           height_address_mode == o.height_address_mode &&
           depth_address_mode == o.depth_address_mode;
  }
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_CORE_SAMPLER_DESCRIPTOR_H_
