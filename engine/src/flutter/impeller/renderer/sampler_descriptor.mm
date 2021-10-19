// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/sampler_descriptor.h"

#include "impeller/renderer/formats_metal.h"
#include "impeller/renderer/sampler.h"

namespace impeller {

SamplerLibrary::SamplerLibrary(id<MTLDevice> device) : device_(device) {}

SamplerLibrary::~SamplerLibrary() = default;

std::shared_ptr<const Sampler> SamplerLibrary::GetSampler(
    SamplerDescriptor descriptor) {
  auto found = samplers_.find(descriptor);
  if (found != samplers_.end()) {
    return found->second;
  }
  if (!device_) {
    return nullptr;
  }
  auto desc = [[MTLSamplerDescriptor alloc] init];
  desc.minFilter = ToMTLSamplerMinMagFilter(descriptor.min_filter);
  desc.magFilter = ToMTLSamplerMinMagFilter(descriptor.mag_filter);
  desc.sAddressMode = MTLSamplerAddressMode(descriptor.width_address_mode);
  desc.rAddressMode = MTLSamplerAddressMode(descriptor.depth_address_mode);
  desc.tAddressMode = MTLSamplerAddressMode(descriptor.height_address_mode);
  auto mtl_sampler = [device_ newSamplerStateWithDescriptor:desc];
  if (!mtl_sampler) {
    return nullptr;
  }
  auto sampler = std::shared_ptr<Sampler>(new Sampler(mtl_sampler));
  if (!sampler->IsValid()) {
    return nullptr;
  }
  samplers_[descriptor] = sampler;
  return sampler;
}

}  // namespace impeller
