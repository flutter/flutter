// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

precision mediump float;

#include <impeller/color.glsl>
#include <impeller/types.glsl>

uniform FragInfo {
  vec4 color;
  vec2 center;
  vec2 size;
  float stroke_width;
  float stroke_join;
  float aa_pixels;
  float stroked;
  float type;
}
frag_info;

out vec4 frag_color;

highp in vec2 v_position;

float distanceFromCircle(vec2 p, float radius) {
  return length(p) - radius;
}

float distanceFromRect(vec2 p, vec2 b) {
  vec2 d = abs(p) - b;
  return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
}

float distanceFromChamferRect(vec2 p, vec2 b, float chamfer) {
  vec2 d = abs(p) - b;

  d = (d.y > d.x) ? d.yx : d.xy;
  d.y += chamfer;

  const float k = 1.0 - sqrt(2.0);
  if (d.y < 0.0 && d.y + d.x * k < 0.0) {
    return d.x;
  }

  if (d.x < d.y) {
    return (d.x + d.y) * sqrt(0.5);
  }

  return length(d);
}

float filledSDF(vec2 p) {
  if (frag_info.type < 0.5) {  // Circle
    return distanceFromCircle(p, frag_info.size.x);
  } else {  // Rect
    return distanceFromRect(p, frag_info.size);
  }
}

float strokedSDF(vec2 p) {
  float half_stroke = max(frag_info.stroke_width, 0.0) * 0.5;
  float outer;
  float inner;

  if (frag_info.type < 0.5) {  // Circle
    outer = distanceFromCircle(p, frag_info.size.x + half_stroke);
    inner = distanceFromCircle(p, frag_info.size.x - half_stroke);
  } else {                              // Rect
    if (frag_info.stroke_join < 0.5) {  // Miter
      // Rectangle expanded by half_stroke
      outer = distanceFromRect(p, frag_info.size + half_stroke);
    } else if (frag_info.stroke_join < 1.5) {  // Bevel
      // Rectangle expanded by half_stroke, with half_stroke chamfer
      outer =
          distanceFromChamferRect(p, frag_info.size + half_stroke, half_stroke);
    } else {  // Round
      // Rectangle sdf expanded by half_stroke, to give a half_stroke radius
      // https://www.shadertoy.com/view/NfXSDr
      outer = distanceFromRect(p, frag_info.size) - half_stroke;
    }
    inner = distanceFromRect(p, frag_info.size - half_stroke);
  }

  return max(outer, -inner);
}

void main() {
  vec2 p = v_position - frag_info.center;

  float dist = (frag_info.stroked < 0.5) ? filledSDF(p) : strokedSDF(p);

  // Gradient vector of the SDF at point p. Points in the direction of steepest
  // increase away from SDF's shape. At the edges of the shape, this is
  // perpendicular to the edge.
  //
  // The x and y magnitudes of the gradient are determined by the dFdx and dFdy
  // of the SDF value. dFdx and dFdy return the change of a value in the x and y
  // direction per screen-space unit (physical pixel). So this gradient
  // is the change in the SDF, at point p, in local space units per pixel.
  vec2 gradient = vec2(dFdx(dist), dFdy(dist));

  // The length of the gradient vector is how fast the SDF changes per
  // screen-space pixel distance. This is equal to the width of a pixel when
  // measuring in the direction of the gradient vector.
  //
  // In local space, the SDF always increases by 1 in the gradient's direction
  // per unit distance. That's the definition of an SDF: it is the distance to
  // the closest point of the shape. But in terms of screen-space, the SDF may
  // increase by a different amount than 1 per unit distance (in screen-space
  // units, i.e. physical pixels), due to scales/skews/rotations.
  //
  // As an example, if the SDF is a plain unscaled/unskewed circle centered at
  // the origin, the gradient is vec2(1.0, 0.0) for points along the positive x
  // axis: For every one pixel we move along the positive x axis, the SDF value
  // increases by 1.0. Now consider a the same circle with a transformation that
  // scales it by 2 along the x axis. In screen-space the circle is stretched to
  // be twice as wide as the original circle in the postive and negative x
  // diretion. The gradient for this will be vec2(0.5, 0.0) along the positive x
  // axis, because now for every physical pixel we move along the this axis, the
  // stretched SDF increases by only 0.5.
  float pixel_size = length(gradient);

  // Anti-aliasing. Fade from alpha 1 to 0 across the edge of the SDF (where it
  // goes from negative to positive). Fade through distance of half
  // (pixel_size * aa_pixels) in each direction.
  float fade_size = pixel_size * frag_info.aa_pixels * 0.5;
  float alpha = 1.0 - smoothstep(-fade_size, fade_size, dist);

  frag_color = vec4(frag_info.color.rgb, frag_info.color.a * alpha);
  frag_color = IPPremultiply(frag_color);
}
