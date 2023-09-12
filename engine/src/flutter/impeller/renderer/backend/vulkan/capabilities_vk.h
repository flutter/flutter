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

enum class OptionalDeviceExtensionVK : uint32_t {
  // https://registry.khronos.org/vulkan/specs/1.3-extensions/man/html/VK_EXT_pipeline_creation_feedback.html
  kEXTPipelineCreationFeedback,
  kLast,
};

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

  bool HasOptionalDeviceExtension(OptionalDeviceExtensionVK extension) const;

  std::optional<std::vector<std::string>> GetEnabledLayers() const;

  std::optional<std::vector<std::string>> GetEnabledInstanceExtensions() const;

  std::optional<std::vector<std::string>> GetEnabledDeviceExtensions(
      const vk::PhysicalDevice& physical_device) const;

  std::optional<vk::PhysicalDeviceFeatures> GetEnabledDeviceFeatures(
      const vk::PhysicalDevice& physical_device) const;

  [[nodiscard]] bool SetPhysicalDevice(
      const vk::PhysicalDevice& physical_device);

  const vk::PhysicalDeviceProperties& GetPhysicalDeviceProperties() const;

  void SetOffscreenFormat(PixelFormat pixel_format) const;

  // |Capabilities|
  bool SupportsOffscreenMSAA() const override;

  // |Capabilities|
  bool SupportsSSBO() const override;

  // |Capabilities|
  bool SupportsBufferToTextureBlits() const override;

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
  bool SupportsReadFromOnscreenTexture() const override;

  // |Capabilities|
  bool SupportsDecalSamplerAddressMode() const override;

  // |Capabilities|
  bool SupportsDeviceTransientTextures() const override;

  // |Capabilities|
  PixelFormat GetDefaultColorFormat() const override;

  // |Capabilities|
  PixelFormat GetDefaultStencilFormat() const override;

  // |Capabilities|
  PixelFormat GetDefaultDepthStencilFormat() const override;

 private:
  bool validations_enabled_ = false;
  std::map<std::string, std::set<std::string>> exts_;
  std::set<OptionalDeviceExtensionVK> optional_device_extensions_;
  mutable PixelFormat default_color_format_ = PixelFormat::kUnknown;
  PixelFormat default_stencil_format_ = PixelFormat::kUnknown;
  PixelFormat default_depth_stencil_format_ = PixelFormat::kUnknown;
  vk::PhysicalDeviceProperties device_properties_;
  bool supports_compute_subgroups_ = false;
  bool supports_device_transient_textures_ = false;
  bool is_valid_ = false;

  bool HasExtension(const std::string& ext) const;

  bool HasLayer(const std::string& layer) const;

  FML_DISALLOW_COPY_AND_ASSIGN(CapabilitiesVK);
};

}  // namespace impeller
