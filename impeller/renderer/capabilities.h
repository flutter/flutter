// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <memory>

#include "flutter/fml/macros.h"
#include "impeller/core/formats.h"

namespace impeller {

class Capabilities {
 public:
  virtual ~Capabilities();

  virtual bool HasThreadingRestrictions() const = 0;

  virtual bool SupportsOffscreenMSAA() const = 0;

  virtual bool SupportsSSBO() const = 0;

  virtual bool SupportsBufferToTextureBlits() const = 0;

  virtual bool SupportsTextureToTextureBlits() const = 0;

  virtual bool SupportsFramebufferFetch() const = 0;

  virtual bool SupportsCompute() const = 0;

  virtual bool SupportsComputeSubgroups() const = 0;

  virtual bool SupportsReadFromOnscreenTexture() const = 0;

  virtual bool SupportsReadFromResolve() const = 0;

  virtual bool SupportsDecalTileMode() const = 0;

  virtual bool SupportsMemorylessTextures() const = 0;

  virtual bool SupportsPipelinesWithNoColorAttachments() const = 0;

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

  CapabilitiesBuilder& SetSupportsBufferToTextureBlits(bool value);

  CapabilitiesBuilder& SetSupportsTextureToTextureBlits(bool value);

  CapabilitiesBuilder& SetSupportsFramebufferFetch(bool value);

  CapabilitiesBuilder& SetSupportsCompute(bool value);

  CapabilitiesBuilder& SetSupportsComputeSubgroups(bool value);

  CapabilitiesBuilder& SetSupportsReadFromOnscreenTexture(bool value);

  CapabilitiesBuilder& SetSupportsReadFromResolve(bool value);

  CapabilitiesBuilder& SetDefaultColorFormat(PixelFormat value);

  CapabilitiesBuilder& SetDefaultStencilFormat(PixelFormat value);

  CapabilitiesBuilder& SetSupportsDecalTileMode(bool value);

  CapabilitiesBuilder& SetSupportsMemorylessTextures(bool value);

  CapabilitiesBuilder& SetSupportsPipelinesWithNoColorAttachments(bool value);

  std::unique_ptr<Capabilities> Build();

 private:
  bool has_threading_restrictions_ = false;
  bool supports_offscreen_msaa_ = false;
  bool supports_ssbo_ = false;
  bool supports_buffer_to_texture_blits_ = false;
  bool supports_texture_to_texture_blits_ = false;
  bool supports_framebuffer_fetch_ = false;
  bool supports_compute_ = false;
  bool supports_compute_subgroups_ = false;
  bool supports_read_from_onscreen_texture_ = false;
  bool supports_read_from_resolve_ = false;
  bool supports_decal_tile_mode_ = false;
  bool supports_memoryless_textures_ = false;
  bool supports_pipelines_with_no_color_attachments_ = false;
  std::optional<PixelFormat> default_color_format_ = std::nullopt;
  std::optional<PixelFormat> default_stencil_format_ = std::nullopt;

  FML_DISALLOW_COPY_AND_ASSIGN(CapabilitiesBuilder);
};

}  // namespace impeller
