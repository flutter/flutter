// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <memory>

#include "flutter/fml/macros.h"
#include "impeller/renderer/formats.h"

namespace impeller {

class IDeviceCapabilities {
 public:
  ~IDeviceCapabilities();

  bool HasThreadingRestrictions() const;

  bool SupportsOffscreenMSAA() const;

  bool SupportsSSBO() const;

  bool SupportsTextureToTextureBlits() const;

  bool SupportsFramebufferFetch() const;

  PixelFormat GetDefaultColorFormat() const;

  PixelFormat GetDefaultStencilFormat() const;

 private:
  IDeviceCapabilities(bool has_threading_restrictions,
                      bool supports_offscreen_msaa,
                      bool supports_ssbo,
                      bool supports_texture_to_texture_blits,
                      bool supports_framebuffer_fetch,
                      PixelFormat default_color_format,
                      PixelFormat default_stencil_format);

  friend class DeviceCapabilitiesBuilder;

  bool has_threading_restrictions_ = false;
  bool supports_offscreen_msaa_ = false;
  bool supports_ssbo_ = false;
  bool supports_texture_to_texture_blits_ = false;
  bool supports_framebuffer_fetch_ = false;
  PixelFormat default_color_format_;
  PixelFormat default_stencil_format_;

  FML_DISALLOW_COPY_AND_ASSIGN(IDeviceCapabilities);
};

class DeviceCapabilitiesBuilder {
 public:
  DeviceCapabilitiesBuilder();

  ~DeviceCapabilitiesBuilder();

  DeviceCapabilitiesBuilder& SetHasThreadingRestrictions(bool value);

  DeviceCapabilitiesBuilder& SetSupportsOffscreenMSAA(bool value);

  DeviceCapabilitiesBuilder& SetSupportsSSBO(bool value);

  DeviceCapabilitiesBuilder& SetSupportsTextureToTextureBlits(bool value);

  DeviceCapabilitiesBuilder& SetSupportsFramebufferFetch(bool value);

  DeviceCapabilitiesBuilder& SetDefaultColorFormat(PixelFormat value);

  DeviceCapabilitiesBuilder& SetDefaultStencilFormat(PixelFormat value);

  std::unique_ptr<IDeviceCapabilities> Build();

 private:
  bool has_threading_restrictions_ = false;
  bool supports_offscreen_msaa_ = false;
  bool supports_ssbo_ = false;
  bool supports_texture_to_texture_blits_ = false;
  bool supports_framebuffer_fetch_ = false;
  std::optional<PixelFormat> default_color_format_ = std::nullopt;
  std::optional<PixelFormat> default_stencil_format_ = std::nullopt;

  FML_DISALLOW_COPY_AND_ASSIGN(DeviceCapabilitiesBuilder);
};

}  // namespace impeller
