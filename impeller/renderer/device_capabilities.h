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

  PixelFormat GetDefaultColorFormat() const;

  PixelFormat GetDefaultStencilFormat() const;

 private:
  IDeviceCapabilities(bool threading_restrictions,
                      bool offscreen_msaa,
                      bool supports_ssbo,
                      PixelFormat default_color_format,
                      PixelFormat default_stencil_format);

  friend class DeviceCapabilitiesBuilder;

  bool threading_restrictions_ = false;
  bool offscreen_msaa_ = false;
  bool supports_ssbo_ = false;
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

  DeviceCapabilitiesBuilder& SetDefaultColorFormat(PixelFormat value);

  DeviceCapabilitiesBuilder& SetDefaultStencilFormat(PixelFormat value);

  std::unique_ptr<IDeviceCapabilities> Build();

 private:
  bool threading_restrictions_ = false;
  bool offscreen_msaa_ = false;
  bool supports_ssbo_ = false;
  std::optional<PixelFormat> default_color_format_ = std::nullopt;
  std::optional<PixelFormat> default_stencil_format_ = std::nullopt;

  FML_DISALLOW_COPY_AND_ASSIGN(DeviceCapabilitiesBuilder);
};

}  // namespace impeller
