// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/device_capabilities.h"

namespace impeller {

IDeviceCapabilities::IDeviceCapabilities(bool threading_restrictions,
                                         bool offscreen_msaa,
                                         bool supports_ssbo,
                                         PixelFormat default_color_format,
                                         PixelFormat default_stencil_format)
    : threading_restrictions_(threading_restrictions),
      offscreen_msaa_(offscreen_msaa),
      supports_ssbo_(supports_ssbo),
      default_color_format_(default_color_format),
      default_stencil_format_(default_stencil_format) {}

IDeviceCapabilities::~IDeviceCapabilities() = default;

bool IDeviceCapabilities::HasThreadingRestrictions() const {
  return threading_restrictions_;
}

bool IDeviceCapabilities::SupportsOffscreenMSAA() const {
  return offscreen_msaa_;
}

bool IDeviceCapabilities::SupportsSSBO() const {
  return supports_ssbo_;
}

PixelFormat IDeviceCapabilities::GetDefaultColorFormat() const {
  return default_color_format_;
}

PixelFormat IDeviceCapabilities::GetDefaultStencilFormat() const {
  return default_stencil_format_;
}

DeviceCapabilitiesBuilder::DeviceCapabilitiesBuilder() = default;

DeviceCapabilitiesBuilder::~DeviceCapabilitiesBuilder() = default;

DeviceCapabilitiesBuilder&
DeviceCapabilitiesBuilder::SetHasThreadingRestrictions(bool value) {
  threading_restrictions_ = value;
  return *this;
}

DeviceCapabilitiesBuilder& DeviceCapabilitiesBuilder::SetSupportsOffscreenMSAA(
    bool value) {
  offscreen_msaa_ = value;
  return *this;
}

DeviceCapabilitiesBuilder& DeviceCapabilitiesBuilder::SetSupportsSSBO(
    bool value) {
  supports_ssbo_ = value;
  return *this;
}

DeviceCapabilitiesBuilder& DeviceCapabilitiesBuilder::SetDefaultColorFormat(
    PixelFormat value) {
  default_color_format_ = value;
  return *this;
}

DeviceCapabilitiesBuilder& DeviceCapabilitiesBuilder::SetDefaultStencilFormat(
    PixelFormat value) {
  default_stencil_format_ = value;
  return *this;
}

std::unique_ptr<IDeviceCapabilities> DeviceCapabilitiesBuilder::Build() {
  FML_CHECK(default_color_format_.has_value())
      << "Default color format not set";
  FML_CHECK(default_stencil_format_.has_value())
      << "Default stencil format not set";

  IDeviceCapabilities* capabilities = new IDeviceCapabilities(
      threading_restrictions_, offscreen_msaa_, supports_ssbo_,
      *default_color_format_, *default_stencil_format_);
  return std::unique_ptr<IDeviceCapabilities>(capabilities);
}

}  // namespace impeller
