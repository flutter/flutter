// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/metal/sampler_library_mtl.h"

#include "impeller/renderer/backend/metal/formats_mtl.h"
#include "impeller/renderer/backend/metal/sampler_mtl.h"

namespace impeller {

SamplerLibraryMTL::SamplerLibraryMTL(id<MTLDevice> device) : device_(device) {}

SamplerLibraryMTL::~SamplerLibraryMTL() = default;

static const std::unique_ptr<const Sampler> kNullSampler = nullptr;

const std::unique_ptr<const Sampler>& SamplerLibraryMTL::GetSampler(
    SamplerDescriptor descriptor) {
  auto found = samplers_.find(descriptor);
  if (found != samplers_.end()) {
    return found->second;
  }
  if (!device_) {
    return kNullSampler;
  }
  auto desc = [[MTLSamplerDescriptor alloc] init];
  desc.minFilter = ToMTLSamplerMinMagFilter(descriptor.min_filter);
  desc.magFilter = ToMTLSamplerMinMagFilter(descriptor.mag_filter);
  desc.mipFilter = ToMTLSamplerMipFilter(descriptor.mip_filter);
  desc.sAddressMode = ToMTLSamplerAddressMode(descriptor.width_address_mode);
  desc.tAddressMode = ToMTLSamplerAddressMode(descriptor.height_address_mode);
  desc.rAddressMode = ToMTLSamplerAddressMode(descriptor.depth_address_mode);
  if (@available(iOS 14.0, macos 10.12, *)) {
    desc.borderColor = MTLSamplerBorderColorTransparentBlack;
  }
  if (!descriptor.label.empty()) {
    desc.label = @(descriptor.label.c_str());
  }

  auto mtl_sampler = [device_ newSamplerStateWithDescriptor:desc];
  if (!mtl_sampler) {
    return kNullSampler;
  }
  auto sampler =
      std::unique_ptr<SamplerMTL>(new SamplerMTL(descriptor, mtl_sampler));

  return (samplers_[descriptor] = std::move(sampler));
}

}  // namespace impeller
