// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/capabilities.h"

namespace impeller {

Capabilities::Capabilities() = default;

Capabilities::~Capabilities() = default;

class StandardCapabilities final : public Capabilities {
 public:
  // |Capabilities|
  ~StandardCapabilities() override = default;

  // |Capabilities|
  bool SupportsOffscreenMSAA() const override {
    return supports_offscreen_msaa_;
  }

  // |Capabilities|
  bool SupportsImplicitResolvingMSAA() const override { return false; }

  // |Capabilities|
  bool SupportsSSBO() const override { return supports_ssbo_; }

  // |Capabilities|
  bool SupportsBufferToTextureBlits() const override {
    return supports_buffer_to_texture_blits_;
  }

  // |Capabilities|
  bool SupportsTextureToTextureBlits() const override {
    return supports_texture_to_texture_blits_;
  }

  // |Capabilities|
  bool SupportsFramebufferFetch() const override {
    return supports_framebuffer_fetch_;
  }

  // |Capabilities|
  bool SupportsCompute() const override { return supports_compute_; }

  // |Capabilities|
  bool SupportsComputeSubgroups() const override {
    return supports_compute_subgroups_;
  }

  // |Capabilities|
  bool SupportsReadFromOnscreenTexture() const override {
    return supports_read_from_onscreen_texture_;
  }

  // |Capabilities|
  bool SupportsReadFromResolve() const override {
    return supports_read_from_resolve_;
  }

  // |Capabilities|
  bool SupportsDecalSamplerAddressMode() const override {
    return supports_decal_sampler_address_mode_;
  }

  // |Capabilities|
  PixelFormat GetDefaultColorFormat() const override {
    return default_color_format_;
  }

  // |Capabilities|
  PixelFormat GetDefaultStencilFormat() const override {
    return default_stencil_format_;
  }

  // |Capabilities|
  PixelFormat GetDefaultDepthStencilFormat() const override {
    return default_depth_stencil_format_;
  }

  bool SupportsDeviceTransientTextures() const override {
    return supports_device_transient_textures_;
  }

 private:
  StandardCapabilities(bool supports_offscreen_msaa,
                       bool supports_ssbo,
                       bool supports_buffer_to_texture_blits,
                       bool supports_texture_to_texture_blits,
                       bool supports_framebuffer_fetch,
                       bool supports_compute,
                       bool supports_compute_subgroups,
                       bool supports_read_from_onscreen_texture,
                       bool supports_read_from_resolve,
                       bool supports_decal_sampler_address_mode,
                       bool supports_device_transient_textures,
                       PixelFormat default_color_format,
                       PixelFormat default_stencil_format,
                       PixelFormat default_depth_stencil_format)
      : supports_offscreen_msaa_(supports_offscreen_msaa),
        supports_ssbo_(supports_ssbo),
        supports_buffer_to_texture_blits_(supports_buffer_to_texture_blits),
        supports_texture_to_texture_blits_(supports_texture_to_texture_blits),
        supports_framebuffer_fetch_(supports_framebuffer_fetch),
        supports_compute_(supports_compute),
        supports_compute_subgroups_(supports_compute_subgroups),
        supports_read_from_onscreen_texture_(
            supports_read_from_onscreen_texture),
        supports_read_from_resolve_(supports_read_from_resolve),
        supports_decal_sampler_address_mode_(
            supports_decal_sampler_address_mode),
        supports_device_transient_textures_(supports_device_transient_textures),
        default_color_format_(default_color_format),
        default_stencil_format_(default_stencil_format),
        default_depth_stencil_format_(default_depth_stencil_format) {}

  friend class CapabilitiesBuilder;

  bool supports_offscreen_msaa_ = false;
  bool supports_ssbo_ = false;
  bool supports_buffer_to_texture_blits_ = false;
  bool supports_texture_to_texture_blits_ = false;
  bool supports_framebuffer_fetch_ = false;
  bool supports_compute_ = false;
  bool supports_compute_subgroups_ = false;
  bool supports_read_from_onscreen_texture_ = false;
  bool supports_read_from_resolve_ = false;
  bool supports_decal_sampler_address_mode_ = false;
  bool supports_device_transient_textures_ = false;
  PixelFormat default_color_format_ = PixelFormat::kUnknown;
  PixelFormat default_stencil_format_ = PixelFormat::kUnknown;
  PixelFormat default_depth_stencil_format_ = PixelFormat::kUnknown;

  StandardCapabilities(const StandardCapabilities&) = delete;

  StandardCapabilities& operator=(const StandardCapabilities&) = delete;
};

CapabilitiesBuilder::CapabilitiesBuilder() = default;

CapabilitiesBuilder::~CapabilitiesBuilder() = default;

CapabilitiesBuilder& CapabilitiesBuilder::SetSupportsOffscreenMSAA(bool value) {
  supports_offscreen_msaa_ = value;
  return *this;
}

CapabilitiesBuilder& CapabilitiesBuilder::SetSupportsSSBO(bool value) {
  supports_ssbo_ = value;
  return *this;
}

CapabilitiesBuilder& CapabilitiesBuilder::SetSupportsBufferToTextureBlits(
    bool value) {
  supports_buffer_to_texture_blits_ = value;
  return *this;
}

CapabilitiesBuilder& CapabilitiesBuilder::SetSupportsTextureToTextureBlits(
    bool value) {
  supports_texture_to_texture_blits_ = value;
  return *this;
}

CapabilitiesBuilder& CapabilitiesBuilder::SetSupportsFramebufferFetch(
    bool value) {
  supports_framebuffer_fetch_ = value;
  return *this;
}

CapabilitiesBuilder& CapabilitiesBuilder::SetSupportsCompute(bool value) {
  supports_compute_ = value;
  return *this;
}

CapabilitiesBuilder& CapabilitiesBuilder::SetSupportsComputeSubgroups(
    bool value) {
  supports_compute_subgroups_ = value;
  return *this;
}

CapabilitiesBuilder& CapabilitiesBuilder::SetSupportsReadFromOnscreenTexture(
    bool read_from_onscreen_texture) {
  supports_read_from_onscreen_texture_ = read_from_onscreen_texture;
  return *this;
}

CapabilitiesBuilder& CapabilitiesBuilder::SetSupportsReadFromResolve(
    bool read_from_resolve) {
  supports_read_from_resolve_ = read_from_resolve;
  return *this;
}

CapabilitiesBuilder& CapabilitiesBuilder::SetDefaultColorFormat(
    PixelFormat value) {
  default_color_format_ = value;
  return *this;
}

CapabilitiesBuilder& CapabilitiesBuilder::SetDefaultStencilFormat(
    PixelFormat value) {
  default_stencil_format_ = value;
  return *this;
}

CapabilitiesBuilder& CapabilitiesBuilder::SetDefaultDepthStencilFormat(
    PixelFormat value) {
  default_depth_stencil_format_ = value;
  return *this;
}

CapabilitiesBuilder& CapabilitiesBuilder::SetSupportsDecalSamplerAddressMode(
    bool value) {
  supports_decal_sampler_address_mode_ = value;
  return *this;
}

CapabilitiesBuilder& CapabilitiesBuilder::SetSupportsDeviceTransientTextures(
    bool value) {
  supports_device_transient_textures_ = value;
  return *this;
}

std::unique_ptr<Capabilities> CapabilitiesBuilder::Build() {
  return std::unique_ptr<StandardCapabilities>(new StandardCapabilities(  //
      supports_offscreen_msaa_,                                           //
      supports_ssbo_,                                                     //
      supports_buffer_to_texture_blits_,                                  //
      supports_texture_to_texture_blits_,                                 //
      supports_framebuffer_fetch_,                                        //
      supports_compute_,                                                  //
      supports_compute_subgroups_,                                        //
      supports_read_from_onscreen_texture_,                               //
      supports_read_from_resolve_,                                        //
      supports_decal_sampler_address_mode_,                               //
      supports_device_transient_textures_,                                //
      default_color_format_.value_or(PixelFormat::kUnknown),              //
      default_stencil_format_.value_or(PixelFormat::kUnknown),            //
      default_depth_stencil_format_.value_or(PixelFormat::kUnknown)       //
      ));
}

}  // namespace impeller
