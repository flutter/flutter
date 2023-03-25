// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "flutter/fml/file.h"
#include "flutter/fml/macros.h"
#include "impeller/base/thread.h"
#include "impeller/renderer/backend/vulkan/capabilities_vk.h"
#include "impeller/renderer/backend/vulkan/vk.h"

namespace impeller {

class PipelineCacheVK {
 public:
  explicit PipelineCacheVK(std::shared_ptr<const Capabilities> caps,
                           vk::Device device,
                           fml::UniqueFD cache_directory);

  ~PipelineCacheVK();

  bool IsValid() const;

  vk::UniquePipeline CreatePipeline(const vk::GraphicsPipelineCreateInfo& info);

  void PersistCacheToDisk() const;

 private:
  const std::shared_ptr<const Capabilities> caps_;
  const vk::Device device_;
  const fml::UniqueFD cache_directory_;
  mutable Mutex cache_mutex_;
  vk::UniquePipelineCache cache_ IPLR_GUARDED_BY(cache_mutex_);
  bool is_valid_ = false;

  std::shared_ptr<fml::Mapping> CopyPipelineCacheData() const;

  FML_DISALLOW_COPY_AND_ASSIGN(PipelineCacheVK);
};

}  // namespace impeller
