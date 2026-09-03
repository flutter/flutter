// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

precision mediump float;

#include <impeller/color.glsl>
#include <impeller/constants.glsl>
#include <impeller/types.glsl>

#include "rse_sdf.glsl"
#include "sdf_functions.glsl"
#include "sdf_utils.glsl"

uniform FragInfo {
  // FragInfo fields are sorted by size (vec4 -> vec2 -> float) to optimize
  // uniform register usage.

  // ===========================================================================
  // vec4 fields
  // ===========================================================================

  /// The RGBA color of the shape.
  vec4 color;
  /// Corner radii for rounded rects (top-left, top-right, bottom-left,
  /// bottom-right), or the circular cap radii for rounded superellipses in
  /// radii.xy (top octant in x, right octant in y).
  vec4 radii;

  // ===========================================================================
  // vec2 fields
  // ===========================================================================

  // --- General Shape Geometry ---
  /// The center position of the shape in local coordinates.
  vec2 center;
  /// The half-dimensions of the shape (half-width, half-height).
  vec2 size;
  /// The size of a device pixel in local coordinates.
  vec2 pixel_size;

  // --- Superellipse Parameters ---
  /// The exponent degree (n_x, n_y) of the superellipse curvature.
  vec2 superellipse_degree;
  /// The angular span of the corner circular arc transitions for rounded
  /// superellipses.
  vec2 angle_span;
  /// The center of the corner transition circle for the top octant of a
  /// rounded superellipse.
  vec2 circle_center_top;
  /// The center of the corner transition circle for the right octant of a
  /// rounded superellipse.
  vec2 circle_center_right;

  // ===========================================================================
  // float fields
  // ===========================================================================

  // --- General Configuration ---
  /// The shape type:
  ///   0: Circle
  ///   1: Rect
  ///   2: Oval
  ///   3: RoundRect
  ///   4: Rounded Superellipse (must have uniform circular corner radii)
  float type;
  /// The width in device pixels over which to apply antialiasing.
  float aa_pixels;

  // --- Stroke Parameters ---
  /// Whether the shape is stroked (1.0) or filled (0.0).
  float stroked;
  /// The width of the stroke.
  float stroke_width;
  /// The join style for the stroke:
  ///   0: Miter
  ///   1: Bevel
  ///   2: Round
  float stroke_join;
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

// Calculates signed distance to an oval (ellipse with semi-axes `ab`) and
// computes its outward surface normal vector at the closest boundary point.
//
// The ellipse boundary is parameterized by angle w as (a * cos(w), b * sin(w)).
// The tangent vector is (-a * sin(w), b * cos(w)), so the outward normal
// is orthogonal: (b * cos(w), a * sin(w)).
float distanceFromOval(vec2 p, vec2 ab, out vec2 normal) {
  vec2 p_abs = abs(p);
  vec2 q = ab * (p_abs - ab);
  float w = (q.x < q.y) ? 1.570796327 : 0.0;
  vec2 cs;
  for (int i = 0; i < 5; i++) {
    cs = vec2(cos(w), sin(w));
    vec2 u = ab * vec2(cs.x, cs.y);
    vec2 v = ab * vec2(-cs.y, cs.x);
    w = w + dot(p_abs - u, v) / (dot(p_abs - u, u) + dot(v, v));
  }
  cs = vec2(cos(w), sin(w));
  float d = length(p_abs - ab * cs);

  vec2 s = vec2(p.x >= 0.0 ? 1.0 : -1.0, p.y >= 0.0 ? 1.0 : -1.0);
  normal = s * normalize(vec2(ab.y * cs.x, ab.x * cs.y));

  return (dot(p_abs / ab, p_abs / ab) > 1.0) ? d : -d;
}

float distanceFromRoundedRect(in vec2 p, in vec2 b, in vec4 r) {
  r.xy = (p.x > 0.0) ? r.xy : r.zw;
  r.x = (p.y > 0.0) ? r.x : r.y;
  vec2 q = abs(p) - b + r.x;
  return min(max(q.x, q.y), 0.0) + length(max(q, 0.0)) - r.x;
}

float distanceFromChamferRect(vec2 p, vec2 half_size, float chamfer_size) {
  p = abs(p);
  float d1 = max(p.x - half_size.x, p.y - half_size.y);
  float d2 =
      (p.x + p.y - half_size.x - half_size.y + chamfer_size) * kHalfSqrtTwo;
  return max(d1, d2);
}

float distanceFromRoundedSuperellipse(vec2 p,
                                      vec2 degree,
                                      vec2 size,
                                      vec2 radii,
                                      vec2 angle_span,
                                      vec2 circle_center_top,
                                      vec2 circle_center_right) {
  // Do work in the first quadrant to simply things.
  p = abs(p);

  // Transition line offset dividing top and right octants.
  float c = size.x - size.y;

  // Declare all RSE params for a single octant.
  float se_degree, span, radius, axis_length;
  vec2 circle_center;

  // 'p' in the coordinate system of the octant.
  vec2 p_oct;

  // We split the quadrant along the diagonal of the transition (p.y + c ==
  // p.x). This allows us to grab the correct set of parameters for the
  // "top" and "right" halves of the corner.
  if (p.y + c > p.x) {
    p_oct = p + vec2(0.0, c);
    se_degree = degree.x;
    span = angle_span.x;
    radius = radii.x;
    circle_center = circle_center_top;
    axis_length = size.x;
  } else {
    // For the 'right' octant, we flip the point and shift it according to
    // the CPU's OctantContains/Flip logic.
    p_oct = p.yx - vec2(0.0, c);
    se_degree = degree.y;
    span = angle_span.y;
    radius = radii.y;
    circle_center = circle_center_right;
    axis_length = size.y;
  }

  return distanceFromRSEOctant(p_oct, circle_center, radius, span, axis_length,
                               se_degree);
}

// Calculates pixel size for rectangles using frag_info.pixel_size.
float rectPixelSize(vec2 p) {
  // Get pixel size in the direction perpendicular to the closest edge of the
  // rectangle: frag_info.pixel_size.x when closer to a vertical edge, and
  // frag_info.pixel_size.y when closer to a horizontal edge.
  vec2 distance = abs(abs(p) - frag_info.size);
  return (distance.x < distance.y) ? frag_info.pixel_size.x
                                   : frag_info.pixel_size.y;
}

// Calculates pixel size for rounded rectangles using frag_info.pixel_size.
float roundRectPixelSize(vec2 p) {
  // Select the corner radius for the quadrant of p.
  vec4 r = frag_info.radii;
  r.xy = (p.x > 0.0) ? r.xy : r.zw;
  float radius = (p.y > 0.0) ? r.x : r.y;

  // Vector from corner circle center to abs(p).
  vec2 corner_center = frag_info.size - radius;
  vec2 q = abs(p) - corner_center;

  float pixel_size;
  // If in the rounded corner arc, blend X and Y pixel sizes along the normal.
  if (q.x > 0.0 && q.y > 0.0) {
    pixel_size = length(normalize(q) * frag_info.pixel_size);
  } else {
    // Otherwise, we are closer to a straight edge. Get pixel size in the
    // direction perpendicular to the closer edge.
    pixel_size = (q.x > q.y) ? frag_info.pixel_size.x : frag_info.pixel_size.y;
  }
  return pixel_size;
}

// Calculates the effective pixel size in local coordinates along a given
// surface normal vector.
//
// For affine transforms, the size of a screen pixel in local coordinates is
// constant across the quad and precomputed on the CPU in
// `frag_info.pixel_size`. Projecting the unit normal onto these local-space
// pixel dimensions scales the antialiasing width appropriately along the
// gradient direction (handling both uniform scaling and non-uniform
// stretching).
float directionalPixelSize(vec2 normal) {
  return length(normal * frag_info.pixel_size);
}

// Calculates pixel size from the SDF gradient using screen-space derivatives.
// Used for shapes like Oval and Rounded Superellipse where the surface normal
// varies along complex curves and cannot be cheaply derived analytically.
float pixelSize(float sdf) {
  vec2 gradient = vec2(dFdx(sdf), dFdy(sdf));
  return length(gradient);
}

// Evaluates the SDF for the shape selected by frag_info.type.
// Returns vec2(sdf, pixel_size).
vec2 filledSDF(vec2 p) {
  float sdf;
  float pixel_size;
  if (frag_info.type < 0.5) {  // Circle
    sdf = distanceFromCircle(p, frag_info.size.x);
    pixel_size = (length(p) > 0.0) ? directionalPixelSize(normalize(p))
                                   : frag_info.pixel_size.x;
  } else if (frag_info.type < 1.5) {  // Rect
    sdf = distanceFromRect(p, frag_info.size);
    // Rect has its own separate logic for calculating pixel size.
    pixel_size = rectPixelSize(p);
  } else if (frag_info.type < 2.5) {  // Oval
    vec2 normal;
    sdf = distanceFromOval(p, frag_info.size, normal);
    pixel_size = directionalPixelSize(normal);
  } else if (frag_info.type < 3.5) {  // Rounded Rect
    sdf = distanceFromRoundedRect(p, frag_info.size, frag_info.radii);
    // RoundRect has its own separate logic for calculating pixel size.
    pixel_size = roundRectPixelSize(p);
  } else {  // Symmetric Rounded Superellipse
    sdf = distanceFromRoundedSuperellipse(
        p, frag_info.superellipse_degree, frag_info.size, frag_info.radii.xy,
        frag_info.angle_span, frag_info.circle_center_top,
        frag_info.circle_center_right);
    pixel_size = pixelSize(sdf);
  }
  return vec2(sdf, pixel_size);
}

// Evaluates the stroked SDF for the shape selected by frag_info.type.
// Returns vec2(sdf, pixel_size).
vec2 strokedSDF(vec2 p) {
  vec2 base_sdf_and_pixel_size = filledSDF(p);
  float base_sdf = base_sdf_and_pixel_size.x;
  float base_pixel_size = base_sdf_and_pixel_size.y;

  float half_stroke = max(frag_info.stroke_width, base_pixel_size) * 0.5;

  float sdf;
  float pixel_size;
  if (frag_info.type >= 0.5 && frag_info.type < 1.5 &&
      frag_info.stroke_join < 0.5) {
    // Rect with Miter join
    float outer = distanceFromRect(p, frag_info.size + half_stroke);
    float inner = base_sdf + half_stroke;
    sdf = max(outer, -inner);
    pixel_size = rectPixelSize(p);
  } else if (frag_info.type >= 0.5 && frag_info.type < 1.5 &&
             frag_info.stroke_join >= 0.5 && frag_info.stroke_join < 1.5) {
    // Rect with Bevel join
    float outer =
        distanceFromChamferRect(p, frag_info.size + half_stroke, half_stroke);
    float inner = base_sdf + half_stroke;
    sdf = max(outer, -inner);
    // For a 45-degree bevel join, the unit normal is (1/sqrt(2), 1/sqrt(2)).
    // The directional pixel size along this normal simplifies to:
    //   length(vec2(1/sqrt(2), 1/sqrt(2)) * frag_info.pixel_size)
    //   = length(frag_info.pixel_size) * (1.0 / sqrt(2.0)).
    pixel_size = length(frag_info.pixel_size) * kHalfSqrtTwo;
  } else {
    // All other shapes
    vec2 sdf_and_pixel_size =
        SDFStroke(base_sdf, base_pixel_size, frag_info.stroke_width);
    sdf = sdf_and_pixel_size.x;
    pixel_size = sdf_and_pixel_size.y;
  }
  return vec2(sdf, pixel_size);
}

// Converts linear coverage alpha to perceptual alpha.
float gammaCorrectedAlpha(float alpha, vec3 foreground_rgb) {
  // Gamma corrected alpha used for dark colors.
  // Fast approximation for `1.0 - pow(1.0 - alpha, 1.0 / 2.2)`.
  float alpha_dark = 1.0 - sqrt(1.0 - alpha);

  // Gamma corrected alpha used for light colors.
  // Fast approximation for `pow(alpha, 1.0 / 2.2)`.
  float alpha_light = sqrt(alpha);

  // Interpolate between the dark and light gamma corrected alphas based on the
  // foreground luma.
  float luma = dot(foreground_rgb, vec3(0.2126, 0.7152, 0.0722));
  return mix(alpha_dark, alpha_light, luma);
}

void main() {
  vec2 p = v_position - frag_info.center;

  vec2 sdf_and_pixel_size =
      (frag_info.stroked < 0.5) ? filledSDF(p) : strokedSDF(p);
  float sdf = sdf_and_pixel_size.x;
  float pixel_size = sdf_and_pixel_size.y;

  float alpha = SDFAlpha(sdf, pixel_size, frag_info.aa_pixels);
  // Clamp alpha in case floating point precision errors cause it to be outside
  // [0.0, 1.0].
  alpha = clamp(alpha, 0.0, 1.0);
  alpha = gammaCorrectedAlpha(alpha, frag_info.color.rgb);

  frag_color = vec4(frag_info.color.rgb, frag_info.color.a * alpha);
  frag_color = IPPremultiply(frag_color);
}
