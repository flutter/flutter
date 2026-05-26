// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SDF_UTILS_GLSL_
#define SDF_UTILS_GLSL_

// Applies anti-aliasing to an SDF value.
//
// Fade from alpha 1 to 0 across the edge of the SDF (where it
// goes from negative to positive). Fade through distance of half
// (pixel_size * aa_pixels) in each direction.
float SDFAlpha(float sdf, float pixel_size, float aa_pixels) {
  float fade_size = pixel_size * aa_pixels * 0.5;
  return 1.0 - smoothstep(-fade_size, fade_size, sdf);
}

// Converts a filled SDF into a stroked SDF.
//
// This is the generic annular conversion for most shapes.
// Some shapes (like Rect with Miter/Bevel joins) require special handling.
vec2 SDFStroke(float base_sdf, float base_pixel_size, float stroke_width) {
  // Stroke width is clamped to be at least the base sdf's pixel size.
  float half_stroke = max(stroke_width, base_pixel_size) * 0.5;

  // The stroked SDF is defined by the +/- half_stroke isolines of the base SDF.
  float sdf = abs(base_sdf) - half_stroke;

  // For these shapes, the stroked pixel size is the same as the base pixel
  // size. This is because the stroked SDF's gradient has the same magnitudes as
  // the base SDF's gradient (except for a discontinuity at the center of the
  // stroke, which does not affect the final render).
  return vec2(sdf, base_pixel_size);
}

#endif