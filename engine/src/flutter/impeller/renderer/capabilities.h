// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <memory>

#include "flutter/fml/macros.h"
#include "impeller/renderer/formats.h"

namespace impeller {

class Capabilities {
 public:
  virtual ~Capabilities();

  virtual bool HasThreadingRestrictions() const = 0;

  virtual bool SupportsOffscreenMSAA() const = 0;

  virtual bool SupportsSSBO() const = 0;

  virtual bool SupportsTextureToTextureBlits() const = 0;

  virtual bool SupportsFramebufferFetch() const = 0;

  virtual bool SupportsCompute() const = 0;

  virtual bool SupportsComputeSubgroups() const = 0;

  virtual PixelFormat GetDefaultColorFormat() const = 0;

  virtual PixelFormat GetDefaultStencilFormat() const = 0;

 protected:
  Capabilities();

  FML_DISALLOW_COPY_AND_ASSIGN(Capabilities);
};

class CapabilitiesBuilder {
 public:
  CapabilitiesBuilder();

  ~CapabilitiesBuilder();

  CapabilitiesBuilder& SetHasThreadingRestrictions(bool value);

  CapabilitiesBuilder& SetSupportsOffscreenMSAA(bool value);

  CapabilitiesBuilder& SetSupportsSSBO(bool value);

  CapabilitiesBuilder& SetSupportsTextureToTextureBlits(bool value);

  CapabilitiesBuilder& SetSupportsFramebufferFetch(bool value);

  CapabilitiesBuilder& SetSupportsCompute(bool compute, bool subgroups);

  CapabilitiesBuilder& SetDefaultColorFormat(PixelFormat value);

  CapabilitiesBuilder& SetDefaultStencilFormat(PixelFormat value);

  std::unique_ptr<Capabilities> Build();

 private:
  bool has_threading_restrictions_ = false;
  bool supports_offscreen_msaa_ = false;
  bool supports_ssbo_ = false;
  bool supports_texture_to_texture_blits_ = false;
  bool supports_framebuffer_fetch_ = false;
  bool supports_compute_ = false;
  bool supports_compute_subgroups_ = false;
  std::optional<PixelFormat> default_color_format_ = std::nullopt;
  std::optional<PixelFormat> default_stencil_format_ = std::nullopt;

  FML_DISALLOW_COPY_AND_ASSIGN(CapabilitiesBuilder);
};

}  // namespace impeller
