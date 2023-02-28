// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/vulkan/sampler_vk.h"

namespace impeller {

SamplerVK::SamplerVK(SamplerDescriptor desc, vk::UniqueSampler sampler)
    : Sampler(std::move(desc)),
      sampler_(MakeSharedVK<vk::Sampler>(std::move(sampler))) {
  is_valid_ = true;
}

SamplerVK::~SamplerVK() = default;

vk::Sampler SamplerVK::GetSamplerVK() const {
  return *sampler_;
}

const std::shared_ptr<SharedObjectVKT<vk::Sampler>>&
SamplerVK::GetSharedSampler() const {
  return sampler_;
}

bool SamplerVK::IsValid() const {
  return is_valid_;
}

}  // namespace impeller
