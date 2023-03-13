// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/vulkan/capabilities_vk.h"

#include "impeller/renderer/backend/vulkan/vk.h"

namespace impeller {

CapabilitiesVK::CapabilitiesVK() {
  for (const auto& ext : vk::enumerateInstanceExtensionProperties().value) {
    extensions_.insert(ext.extensionName);
  }

  for (const auto& layer : vk::enumerateInstanceLayerProperties().value) {
    layers_.insert(layer.layerName);
  }
}

CapabilitiesVK::~CapabilitiesVK() = default;

bool CapabilitiesVK::HasExtension(const std::string& extension) const {
  return extensions_.count(extension) == 1u;
}

bool CapabilitiesVK::HasLayer(const std::string& layer) const {
  return layers_.count(layer) == 1u;
}

bool CapabilitiesVK::HasLayerExtension(const std::string& layer,
                                       const std::string& extension) {
  for (const auto& ext :
       vk::enumerateInstanceExtensionProperties(layer).value) {
    if (std::string{ext.extensionName} == extension) {
      return true;
    }
  }
  return false;
}

}  // namespace impeller
