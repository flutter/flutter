// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "flutter/fml/file.h"
#include "flutter/fml/macros.h"
#include "impeller/base/thread.h"
#include "impeller/renderer/backend/vulkan/capabilities_vk.h"
#include "impeller/renderer/backend/vulkan/device_holder.h"
#include "impeller/renderer/backend/vulkan/vk.h"

namespace impeller {

class PipelineCacheVK {
 public:
  // The [device] is passed in directly so that it can be used in the
  // constructor directly. The [device_holder] isn't guaranteed to be valid
  // at the time of executing `PipelineCacheVK` because of how `ContextVK` does
  // initialization.
  explicit PipelineCacheVK(std::shared_ptr<const Capabilities> caps,
                           std::shared_ptr<DeviceHolder> device_holder,
                           fml::UniqueFD cache_directory);

  ~PipelineCacheVK();

  bool IsValid() const;

  vk::UniquePipeline CreatePipeline(const vk::GraphicsPipelineCreateInfo& info);

  vk::UniquePipeline CreatePipeline(const vk::ComputePipelineCreateInfo& info);

  const CapabilitiesVK* GetCapabilities() const;

  void PersistCacheToDisk() const;

 private:
  const std::shared_ptr<const Capabilities> caps_;
  std::weak_ptr<DeviceHolder> device_holder_;
  const fml::UniqueFD cache_directory_;
  vk::UniquePipelineCache cache_;
  bool is_valid_ = false;

  std::shared_ptr<fml::Mapping> CopyPipelineCacheData() const;

  FML_DISALLOW_COPY_AND_ASSIGN(PipelineCacheVK);
};

}  // namespace impeller
