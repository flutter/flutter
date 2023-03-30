// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "flutter/fml/macros.h"
#include "impeller/base/backend_cast.h"
#include "impeller/renderer/backend/vulkan/shared_object_vk.h"
#include "impeller/renderer/backend/vulkan/vk.h"
#include "impeller/renderer/sampler.h"
#include "vulkan/vulkan_handles.hpp"

namespace impeller {

class SamplerLibraryVK;

class SamplerVK final : public Sampler, public BackendCast<SamplerVK, Sampler> {
 public:
  SamplerVK(SamplerDescriptor desc, vk::UniqueSampler sampler);

  // |Sampler|
  ~SamplerVK() override;

  vk::Sampler GetSampler() const;

  const std::shared_ptr<SharedObjectVKT<vk::Sampler>>& GetSharedSampler() const;

 private:
  friend SamplerLibraryVK;

  std::shared_ptr<SharedObjectVKT<vk::Sampler>> sampler_;
  bool is_valid_ = false;

  // |Sampler|
  bool IsValid() const override;

  FML_DISALLOW_COPY_AND_ASSIGN(SamplerVK);
};

}  // namespace impeller
