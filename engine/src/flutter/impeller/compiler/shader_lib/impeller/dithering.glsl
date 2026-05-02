// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef DITHERING_GLSL_
#define DITHERING_GLSL_

#include <impeller/types.glsl>

/// The dithering rate, which is 1.0 / 64.0, or 0.015625.
const float kDitherRate = 1.0 / 64.0;

/// Pre-folded coefficients for the Bayer 8x8 dither offset.
const float kBayerScale = (2.0 / 128.0) * kDitherRate;    // == 1/4096
const float kBayerOffset = (63.0 / 128.0) * kDitherRate;  // == 63/8192

/// Returns the closest color to the input color using 8x8 ordered dithering.
///
/// Ordered dithering divides the output into a grid of cells, and then assigns
/// a different threshold to each cell. The threshold is used to determine if
/// the color should be rounded up (white) or down (black).
//
/// This technique was chosen mostly because Skia also uses it:
/// https://github.com/google/skia/blob/f9de059517a6f58951510fc7af0cba21e13dd1a8/src/opts/SkRasterPipeline_opts.h#L1717
///
/// See also:
/// - https://en.wikipedia.org/wiki/Ordered_dithering
/// - https://surma.dev/things/ditherpunk/
/// - https://shader-tutorial.dev/advanced/color-banding-dithering/
vec4 IPOrderedDither8x8(vec4 color, vec2 dest) {
  // Get the x and y coordinates of the pixel in the 8x8 grid.
  uint x = uint(dest.x) % 8;
  uint y = uint(dest.y);
  y ^= x;

  // Get the dither value from the matrix.
  uint m = (y & 1) << 5 |  //
           (x & 1) << 4 |  //
           (y & 2) << 2 |  //
           (x & 2) << 1 |  //
           (y & 4) >> 1 |  //
           (x & 4) >> 2;   //

  // Single mad per channel: dither offset is in [-kBayerOffset, +kBayerOffset]
  // (~ ±0.0077), comfortably less than 0.5 / 64 so exact 0 and 1 round-trip
  // through the 8-bit framebuffer unchanged.
  color.rgb += float(m) * kBayerScale - kBayerOffset;

  return color;
}

/// Half-precision variant of IPOrderedDither8x8.
f16vec4 IPHalfOrderedDither8x8(f16vec4 color, vec2 dest) {
  uint x = uint(dest.x) % 8;
  uint y = uint(dest.y);
  y ^= x;

  uint m = (y & 1) << 5 |  //
           (x & 1) << 4 |  //
           (y & 2) << 2 |  //
           (x & 2) << 1 |  //
           (y & 4) >> 1 |  //
           (x & 4) >> 2;   //

  float16_t dither = float16_t(float(m) * kBayerScale - kBayerOffset);
  color.rgb += dither;

  return color;
}

#endif
