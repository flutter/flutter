// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// FLUTTER_NOLINT: https://github.com/flutter/flutter/issues/123467

#include "impeller/renderer/backend/vulkan/pipeline_cache_vk.h"

#include <sstream>

#include "flutter/fml/mapping.h"

namespace impeller {

static constexpr const char* kPipelineCacheFileName =
    "flutter.impeller.vkcache";

static bool VerifyExistingCache(const fml::Mapping& mapping,
                                const CapabilitiesVK& caps) {
  return true;
}

static std::shared_ptr<fml::Mapping> DecorateCacheWithMetadata(
    std::shared_ptr<fml::Mapping> data) {
  return data;
}

static std::unique_ptr<fml::Mapping> RemoveMetadataFromCache(
    std::unique_ptr<fml::Mapping> data) {
  return data;
}

static std::unique_ptr<fml::Mapping> OpenCacheFile(
    const fml::UniqueFD& base_directory,
    const std::string& cache_file_name,
    const CapabilitiesVK& caps) {
  if (!base_directory.is_valid()) {
    return nullptr;
  }
  std::unique_ptr<fml::Mapping> mapping =
      fml::FileMapping::CreateReadOnly(base_directory, cache_file_name);
  if (!mapping) {
    return nullptr;
  }
  if (!VerifyExistingCache(*mapping, caps)) {
    return nullptr;
  }
  mapping = RemoveMetadataFromCache(std::move(mapping));
  if (!mapping) {
    return nullptr;
  }
  return mapping;
}

PipelineCacheVK::PipelineCacheVK(std::shared_ptr<const Capabilities> caps,
                                 std::shared_ptr<DeviceHolder> device_holder,
                                 fml::UniqueFD cache_directory)
    : caps_(std::move(caps)),
      device_holder_(device_holder),
      cache_directory_(std::move(cache_directory)) {
  if (!caps_ || !device_holder->GetDevice()) {
    return;
  }

  const auto& vk_caps = CapabilitiesVK::Cast(*caps_);

  auto existing_cache_data =
      OpenCacheFile(cache_directory_, kPipelineCacheFileName, vk_caps);

  vk::PipelineCacheCreateInfo cache_info;

  // TODO(csg): VK_PIPELINE_CACHE_CREATE_EXTERNALLY_SYNCHRONIZED_BIT is behind
  // an extension. Check it and set it. If not, the implementation is doing
  // unnecessary synchronization.
  // cache_info.flags =
  // vk::PipelineCacheCreateFlagBits::eExternallySynchronized;

  if (existing_cache_data) {
    cache_info.initialDataSize = existing_cache_data->GetSize();
    cache_info.pInitialData = existing_cache_data->GetMapping();
  }

  auto [result, existing_cache] =
      device_holder->GetDevice().createPipelineCacheUnique(cache_info);

  if (result == vk::Result::eSuccess) {
    cache_ = std::move(existing_cache);
  } else {
    // Even though we perform consistency checks because we don't trust the
    // driver, the driver may have additional information that may cause it to
    // reject the cache too.
    FML_LOG(INFO) << "Existing pipeline cache was invalid: "
                  << vk::to_string(result) << ". Starting with a fresh cache.";
    cache_info.pInitialData = nullptr;
    cache_info.initialDataSize = 0u;
    auto [result2, new_cache] =
        device_holder->GetDevice().createPipelineCacheUnique(cache_info);
    if (result2 == vk::Result::eSuccess) {
      cache_ = std::move(new_cache);
    } else {
      VALIDATION_LOG << "Could not create new pipeline cache: "
                     << vk::to_string(result2);
    }
  }

  is_valid_ = !!cache_;
}

PipelineCacheVK::~PipelineCacheVK() {
  std::shared_ptr<DeviceHolder> device_holder = device_holder_.lock();
  if (device_holder) {
    cache_.reset();
  } else {
    cache_.release();
  }
}

bool PipelineCacheVK::IsValid() const {
  return is_valid_;
}

vk::UniquePipeline PipelineCacheVK::CreatePipeline(
    const vk::GraphicsPipelineCreateInfo& info) {
  std::shared_ptr<DeviceHolder> strong_device = device_holder_.lock();
  if (!strong_device) {
    return {};
  }

  Lock lock(cache_mutex_);
  auto [result, pipeline] =
      strong_device->GetDevice().createGraphicsPipelineUnique(*cache_, info);
  if (result != vk::Result::eSuccess) {
    VALIDATION_LOG << "Could not create graphics pipeline: "
                   << vk::to_string(result);
  }
  return std::move(pipeline);
}

vk::UniquePipeline PipelineCacheVK::CreatePipeline(
    const vk::ComputePipelineCreateInfo& info) {
  std::shared_ptr<DeviceHolder> strong_device = device_holder_.lock();
  if (!strong_device) {
    return {};
  }

  Lock lock(cache_mutex_);
  auto [result, pipeline] =
      strong_device->GetDevice().createComputePipelineUnique(*cache_, info);
  if (result != vk::Result::eSuccess) {
    VALIDATION_LOG << "Could not create compute pipeline: "
                   << vk::to_string(result);
  }
  return std::move(pipeline);
}

std::shared_ptr<fml::Mapping> PipelineCacheVK::CopyPipelineCacheData() const {
  std::shared_ptr<DeviceHolder> strong_device = device_holder_.lock();
  if (!strong_device) {
    return nullptr;
  }

  if (!IsValid()) {
    return nullptr;
  }
  Lock lock(cache_mutex_);
  auto [result, data] =
      strong_device->GetDevice().getPipelineCacheData(*cache_);
  if (result != vk::Result::eSuccess) {
    VALIDATION_LOG << "Could not get pipeline cache data to persist.";
    return nullptr;
  }
  auto shared_data = std::make_shared<std::vector<uint8_t>>();
  std::swap(*shared_data, data);
  return std::make_shared<fml::NonOwnedMapping>(
      shared_data->data(), shared_data->size(), [shared_data](auto, auto) {});
}

void PipelineCacheVK::PersistCacheToDisk() const {
  if (!cache_directory_.is_valid()) {
    return;
  }
  auto data = CopyPipelineCacheData();
  if (!data) {
    VALIDATION_LOG << "Could not copy pipeline cache data.";
    return;
  }
  data = DecorateCacheWithMetadata(std::move(data));
  if (!data) {
    VALIDATION_LOG
        << "Could not decorate pipeline cache with additional metadata.";
    return;
  }
  if (!fml::WriteAtomically(cache_directory_, kPipelineCacheFileName, *data)) {
    VALIDATION_LOG << "Could not persist pipeline cache to disk.";
    return;
  }
}

}  // namespace impeller
