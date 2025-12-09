// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef RUNTIME_EFFECT_GLSL_
#define RUNTIME_EFFECT_GLSL_

#if defined(IMPELLER_GRAPHICS_BACKEND)

// Note: The GLES backend uses name matching for attribute locations. This name
// must match the name of the attribute output in:
// impeller/entity/shaders/runtime_effect.vert
in vec2 _fragCoord;
vec2 FlutterFragCoord() {
  return _fragCoord;
}

in vec2 v_tex_coord_0;
in vec2 v_tex_coord_1;
in vec2 v_tex_coord_2;
in vec2 v_tex_coord_3;

vec2 FlutterGetInputTextureCoordinates(int index) {
  if (index == 0) {
    return v_tex_coord_0;
  }
  if (index == 1) {
    return v_tex_coord_1;
  }
  if (index == 2) {
    return v_tex_coord_2;
  }
  if (index == 3) {
    return v_tex_coord_3;
  }
  return vec2(0.0);
}

#elif defined(SKIA_GRAPHICS_BACKEND)

vec2 FlutterFragCoord() {
  return gl_FragCoord.xy;
}

vec2 FlutterGetInputTextureCoordinates(int index) {
  return vec2(0.0);
}

#else
#error "Runtime effect builtins are not supported for this graphics backend."
#endif

#endif
