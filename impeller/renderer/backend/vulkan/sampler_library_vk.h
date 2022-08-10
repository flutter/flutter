// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "flutter/fml/macros.h"
#include "impeller/base/backend_cast.h"
#include "impeller/base/comparable.h"
#include "impeller/renderer/backend/vulkan/vk.h"
#include "impeller/renderer/sampler_descriptor.h"
#include "impeller/renderer/sampler_library.h"

namespace impeller {

class SamplerLibraryVK final
    : public SamplerLibrary,
      public BackendCast<SamplerLibraryVK, SamplerLibrary> {
 public:
  // |SamplerLibrary|
  ~SamplerLibraryVK() override;

 private:
  friend class ContextVK;

  vk::Device device_;
  SamplerMap samplers_;

  explicit SamplerLibraryVK(vk::Device device);

  // |SamplerLibrary|
  std::shared_ptr<const Sampler> GetSampler(
      SamplerDescriptor descriptor) override;

  FML_DISALLOW_COPY_AND_ASSIGN(SamplerLibraryVK);
};

}  // namespace impeller
