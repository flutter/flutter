// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/converters/native_viewport/surface_configuration_type_converters.h"

namespace mojo {

// static
gfx::SurfaceConfiguration
TypeConverter<gfx::SurfaceConfiguration, SurfaceConfigurationPtr>::Convert(
    const SurfaceConfigurationPtr& input) {
  auto output = gfx::SurfaceConfiguration();
  output.red_bits = input->red_bits;
  output.green_bits = input->green_bits;
  output.blue_bits = input->blue_bits;
  output.alpha_bits = input->alpha_bits;
  output.depth_bits = input->depth_bits;
  output.stencil_bits = input->stencil_bits;
  return output;
}

}  // namespace mojo