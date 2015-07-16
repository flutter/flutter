// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_CONVERTERS_NATIVE_VIEWPORT_SURFACE_CONFIGURATION_TYPE_CONVERTERS_H_
#define MOJO_CONVERTERS_NATIVE_VIEWPORT_SURFACE_CONFIGURATION_TYPE_CONVERTERS_H_

#include "base/memory/scoped_ptr.h"
#include "mojo/services/native_viewport/public/interfaces/native_viewport.mojom.h"
#include "ui/gl/gl_surface.h"

namespace mojo {

// Types from native_viewport.mojom
template <>
struct TypeConverter<gfx::SurfaceConfiguration, SurfaceConfigurationPtr> {
  static gfx::SurfaceConfiguration Convert(
      const SurfaceConfigurationPtr& input);
};

}  // namespace mojo

#endif  // MOJO_CONVERTERS_NATIVE_VIEWPORT_SURFACE_CONFIGURATION_TYPE_CONVERTERS_H_
