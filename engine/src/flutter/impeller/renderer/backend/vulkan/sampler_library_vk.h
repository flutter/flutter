// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_RENDERER_BACKEND_VULKAN_SAMPLER_LIBRARY_VK_H_
#define FLUTTER_IMPELLER_RENDERER_BACKEND_VULKAN_SAMPLER_LIBRARY_VK_H_

#include "impeller/base/backend_cast.h"
#include "impeller/core/sampler.h"
#include "impeller/core/sampler_descriptor.h"
#include "impeller/renderer/backend/vulkan/device_holder_vk.h"
#include "impeller/renderer/backend/vulkan/workarounds_vk.h"
#include "impeller/renderer/sampler_library.h"

namespace impeller {

class SamplerVK;

class SamplerLibraryVK final
    : public SamplerLibrary,
      public BackendCast<SamplerLibraryVK, SamplerLibrary> {
 public:
  // |SamplerLibrary|
  ~SamplerLibraryVK() override;

  SamplerLibraryVK(const std::weak_ptr<DeviceHolderVK>& device_holder,
                   uint32_t max_sampler_anisotropy);

  void ApplyWorkarounds(const WorkaroundsVK& workarounds);

 private:
  friend class ContextVK;

  std::weak_ptr<DeviceHolderVK> device_holder_;
  std::vector<std::pair<uint64_t, std::shared_ptr<SamplerVK>>> samplers_;
  uint32_t max_sampler_anisotropy_ = 1;
  bool mips_disabled_workaround_ = false;

  // |SamplerLibrary|
  raw_ptr<const Sampler> GetSampler(
      const SamplerDescriptor& descriptor) override;

  /// Give the sampler a base-mip-clamped copy that passes substitute when they
  /// bind a texture whose mip levels came from the broken generation path.
  void AttachBaseMipClampedVariant(SamplerVK& sampler);

  SamplerLibraryVK(const SamplerLibraryVK&) = delete;

  SamplerLibraryVK& operator=(const SamplerLibraryVK&) = delete;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_RENDERER_BACKEND_VULKAN_SAMPLER_LIBRARY_VK_H_
