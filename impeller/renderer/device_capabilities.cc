// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/device_capabilities.h"

namespace impeller {

IDeviceCapabilities::IDeviceCapabilities(bool has_threading_restrictions,
                                         bool supports_offscreen_msaa,
                                         bool supports_ssbo,
                                         bool supports_texture_to_texture_blits,
                                         bool supports_framebuffer_fetch,
                                         PixelFormat default_color_format,
                                         PixelFormat default_stencil_format)
    : has_threading_restrictions_(has_threading_restrictions),
      supports_offscreen_msaa_(supports_offscreen_msaa),
      supports_ssbo_(supports_ssbo),
      supports_texture_to_texture_blits_(supports_texture_to_texture_blits),
      supports_framebuffer_fetch_(supports_framebuffer_fetch),
      default_color_format_(default_color_format),
      default_stencil_format_(default_stencil_format) {}

IDeviceCapabilities::~IDeviceCapabilities() = default;

bool IDeviceCapabilities::HasThreadingRestrictions() const {
  return has_threading_restrictions_;
}

bool IDeviceCapabilities::SupportsOffscreenMSAA() const {
  return supports_offscreen_msaa_;
}

bool IDeviceCapabilities::SupportsSSBO() const {
  return supports_ssbo_;
}

bool IDeviceCapabilities::SupportsTextureToTextureBlits() const {
  return supports_texture_to_texture_blits_;
}

bool IDeviceCapabilities::SupportsFramebufferFetch() const {
  return supports_framebuffer_fetch_;
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
  has_threading_restrictions_ = value;
  return *this;
}

DeviceCapabilitiesBuilder& DeviceCapabilitiesBuilder::SetSupportsOffscreenMSAA(
    bool value) {
  supports_offscreen_msaa_ = value;
  return *this;
}

DeviceCapabilitiesBuilder& DeviceCapabilitiesBuilder::SetSupportsSSBO(
    bool value) {
  supports_ssbo_ = value;
  return *this;
}

DeviceCapabilitiesBuilder&
DeviceCapabilitiesBuilder::SetSupportsTextureToTextureBlits(bool value) {
  supports_texture_to_texture_blits_ = value;
  return *this;
}

DeviceCapabilitiesBuilder&
DeviceCapabilitiesBuilder::SetSupportsFramebufferFetch(bool value) {
  supports_framebuffer_fetch_ = value;
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

  IDeviceCapabilities* capabilities = new IDeviceCapabilities(  //
      has_threading_restrictions_,                              //
      supports_offscreen_msaa_,                                 //
      supports_ssbo_,                                           //
      supports_texture_to_texture_blits_,                       //
      supports_framebuffer_fetch_,                              //
      *default_color_format_,                                   //
      *default_stencil_format_                                  //
  );
  return std::unique_ptr<IDeviceCapabilities>(capabilities);
}

}  // namespace impeller
