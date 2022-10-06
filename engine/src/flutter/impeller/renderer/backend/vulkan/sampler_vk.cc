// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/vulkan/sampler_vk.h"

namespace impeller {
SamplerVK::~SamplerVK() {}

vk::Sampler SamplerVK::GetSamplerVK() const {
  return sampler_.get();
}

SamplerVK::SamplerVK(SamplerDescriptor desc, vk::UniqueSampler sampler)
    : Sampler(std::move(desc)), sampler_(std::move(sampler)) {
  is_valid_ = true;
}

bool SamplerVK::IsValid() const {
  return is_valid_;
}

}  // namespace impeller
