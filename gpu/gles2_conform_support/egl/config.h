// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef GPU_GLES2_CONFORM_TEST_CONFIG_H_
#define GPU_GLES2_CONFORM_TEST_CONFIG_H_

#include <EGL/egl.h>

#include "base/basictypes.h"

namespace egl {

class Config {
 public:
  Config();
  ~Config();

  bool GetAttrib(EGLint attribute, EGLint* value) const;

 private:
  // Total color component bits in the color buffer.
  EGLint buffer_size_;
  // Bits of Red in the color buffer.
  EGLint red_size_;
  // Bits of Green in the color buffer.
  EGLint green_size_;
  // Bits of Blue in the color buffer.
  EGLint blue_size_;
  // Bits of Luminance in the color buffer.
  EGLint luminance_size_;
  // Bits of Alpha in the color buffer.
  EGLint alpha_size_;
  // Bits of Alpha Mask in the mask buffer.
  EGLint alpha_mask_size_;
  // True if bindable to RGB textures.
  EGLBoolean bind_to_texture_rgb_;
  // True if bindable to RGBA textures.
  EGLBoolean bind_to_texture_rgba_;
  // Color buffer type.
  EGLenum color_buffer_type_;
  // Any caveats for the configuration.
  EGLenum config_caveat_;
  // Unique EGLConfig identifier.
  EGLint config_id_;
  // Whether contexts created with this config are conformant.
  EGLint conformant_;
  // Bits of Z in the depth buffer.
  EGLint depth_size_;
  // Frame buffer level.
  EGLint level_;
  // Maximum width of pbuffer.
  EGLint max_pbuffer_width_;
  // Maximum height of pbuffer.
  EGLint max_pbuffer_height_;
  // Maximum size of pbuffer.
  EGLint max_pbuffer_pixels_;
  // Minimum swap interval.
  EGLint min_swap_interval_;
  // Maximum swap interval.
  EGLint max_swap_interval_;
  // True if native rendering APIs can render to surface.
  EGLBoolean native_renderable_;
  // Handle of corresponding native visual.
  EGLint native_visual_id_;
  // Native visual type of the associated visual.
  EGLint native_visual_type_;
  // Which client rendering APIs are supported.
  EGLint renderable_type_;
  // Number of multisample buffers.
  EGLint sample_buffers_;
  // Number of samples per pixel.
  EGLint samples_;
  // Bits of Stencil in the stencil buffer.
  EGLint stencil_size_;
  // Which types of EGL surfaces are supported.
  EGLint surface_type_;
  // Type of transparency supported
  EGLenum transparent_type_;
  // Transparent red value
  EGLint transparent_red_value_;
  // Transparent green value
  EGLint transparent_green_value_;
  // Transparent blue value
  EGLint transparent_blue_value_;

  DISALLOW_COPY_AND_ASSIGN(Config);
};

}  // namespace egl

#endif  // GPU_GLES2_CONFORM_TEST_CONFIG_H_
