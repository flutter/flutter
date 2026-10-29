// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_RENDERER_BACKEND_VULKAN_SAMPLER_LIBRARY_VK_H_
#define FLUTTER_IMPELLER_RENDERER_BACKEND_VULKAN_SAMPLER_LIBRARY_VK_H_

#include "impeller/base/backend_cast.h"
#include "impeller/base/thread.h"
#include "impeller/core/sampler.h"
#include "impeller/core/sampler_descriptor.h"
#include "impeller/renderer/backend/vulkan/device_holder_vk.h"
#include "impeller/renderer/sampler_library.h"

namespace impeller {

class SamplerLibraryVK final
    : public SamplerLibrary,
      public BackendCast<SamplerLibraryVK, SamplerLibrary> {
 public:
  // |SamplerLibrary|
  ~SamplerLibraryVK() override;

  SamplerLibraryVK(const std::weak_ptr<DeviceHolderVK>& device_holder,
                   uint32_t max_sampler_anisotropy);

 private:
  friend class ContextVK;

  std::weak_ptr<DeviceHolderVK> device_holder_;
  Mutex samplers_mutex_;
  std::vector<std::pair<uint64_t, std::shared_ptr<const Sampler>>> samplers_
      IPLR_GUARDED_BY(samplers_mutex_);
  uint32_t max_sampler_anisotropy_ = 1;

  // |SamplerLibrary|
  raw_ptr<const Sampler> GetSampler(
      const SamplerDescriptor& descriptor) override;

  /// @brief Find the cached sampler for `key`, or a null `raw_ptr` if there
  ///        is none.
  ///
  ///        The result outlives `samplers_mutex_`: `samplers_` holds each
  ///        sampler by shared_ptr and never removes one, so it stays valid
  ///        for the lifetime of this library.
  raw_ptr<const Sampler> FindSampler(uint64_t key) const
      IPLR_REQUIRES(samplers_mutex_);

  SamplerLibraryVK(const SamplerLibraryVK&) = delete;

  SamplerLibraryVK& operator=(const SamplerLibraryVK&) = delete;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_RENDERER_BACKEND_VULKAN_SAMPLER_LIBRARY_VK_H_
