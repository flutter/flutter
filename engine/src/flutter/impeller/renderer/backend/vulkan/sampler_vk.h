// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_RENDERER_BACKEND_VULKAN_SAMPLER_VK_H_
#define FLUTTER_IMPELLER_RENDERER_BACKEND_VULKAN_SAMPLER_VK_H_

#include "flutter/fml/macros.h"
#include "impeller/base/backend_cast.h"
#include "impeller/core/sampler.h"
#include "impeller/renderer/backend/vulkan/shared_object_vk.h"
#include "impeller/renderer/backend/vulkan/vk.h"

namespace impeller {

class SamplerLibraryVK;

class SamplerVK final : public Sampler, public BackendCast<SamplerVK, Sampler> {
 public:
  SamplerVK(SamplerDescriptor desc, vk::UniqueSampler sampler);

  // |Sampler|
  ~SamplerVK() override;

  vk::Sampler GetSampler() const;

 private:
  friend SamplerLibraryVK;

  std::shared_ptr<SharedObjectVKT<vk::Sampler>> sampler_;
  bool is_valid_ = false;

  SamplerVK(const SamplerVK&) = delete;

  SamplerVK& operator=(const SamplerVK&) = delete;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_RENDERER_BACKEND_VULKAN_SAMPLER_VK_H_
