// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <map>
#include <set>
#include <string>
#include <vector>

#include "flutter/fml/macros.h"
#include "impeller/base/backend_cast.h"
#include "impeller/renderer/backend/vulkan/vk.h"
#include "impeller/renderer/capabilities.h"

namespace impeller {

class ContextVK;

//------------------------------------------------------------------------------
/// @brief      The Vulkan layers and extensions wrangler.
///
class CapabilitiesVK final : public Capabilities,
                             public BackendCast<CapabilitiesVK, Capabilities> {
 public:
  explicit CapabilitiesVK(bool enable_validations);

  ~CapabilitiesVK();

  bool IsValid() const;

  bool AreValidationsEnabled() const;

  std::optional<std::vector<std::string>> GetRequiredLayers() const;

  std::optional<std::vector<std::string>> GetRequiredInstanceExtensions() const;

  std::optional<std::vector<std::string>> GetRequiredDeviceExtensions(
      const vk::PhysicalDevice& physical_device) const;

  std::optional<vk::PhysicalDeviceFeatures> GetRequiredDeviceFeatures(
      const vk::PhysicalDevice& physical_device) const;

  [[nodiscard]] bool SetDevice(const vk::PhysicalDevice& physical_device);

  const vk::PhysicalDeviceProperties& GetPhysicalDeviceProperties() const;

  // |Capabilities|
  bool HasThreadingRestrictions() const override;

  // |Capabilities|
  bool SupportsOffscreenMSAA() const override;

  // |Capabilities|
  bool SupportsSSBO() const override;

  // |Capabilities|
  bool SupportsTextureToTextureBlits() const override;

  // |Capabilities|
  bool SupportsFramebufferFetch() const override;

  // |Capabilities|
  bool SupportsCompute() const override;

  // |Capabilities|
  bool SupportsComputeSubgroups() const override;

  // |Capabilities|
  bool SupportsReadFromResolve() const override;

  // |Capabilities|
  PixelFormat GetDefaultColorFormat() const override;

  // |Capabilities|
  PixelFormat GetDefaultStencilFormat() const override;

 private:
  const bool enable_validations_;
  std::map<std::string, std::set<std::string>> exts_;
  PixelFormat color_format_ = PixelFormat::kUnknown;
  PixelFormat depth_stencil_format_ = PixelFormat::kUnknown;
  vk::PhysicalDeviceProperties device_properties_;
  bool is_valid_ = false;

  bool HasExtension(const std::string& ext) const;

  bool HasLayer(const std::string& layer) const;

  FML_DISALLOW_COPY_AND_ASSIGN(CapabilitiesVK);
};

}  // namespace impeller
