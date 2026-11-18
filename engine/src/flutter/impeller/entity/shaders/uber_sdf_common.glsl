// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Shared body of the UberSDF shaders, included by `uber_sdf.frag` and
// `uber_sdf_ssbo.frag`. Each entrypoint supplies only `getGradientColor()`.
//
// Precision
// =========
//
// The default precision is mediump, which many mobile GPUs execute as fp16:
// 11 significant bits, a largest finite value of 65504 (so squaring anything
// above ~256 overflows), and subnormal values below ~6e-5 that some GPUs flush
// to zero. Some drivers (Mali on GLES) also store mediump uniforms in 16 bits,
// rounding them before the shader runs, even if the code that reads them is
// highp. Metal does not use fp16 for this shader, so the macOS goldens do not
// catch violations of these rules.
//
// Making everything highp costs uniform registers on Mali, so the shader
// follows these rules instead:
//
//  1. A value is highp from where it is read until the last subtraction that
//     can cancel it. Near an edge, a distance is a small difference of large
//     local coordinates. For a fill, the last subtraction is the edge
//     distance; for a stroke, it is the subtraction of the half stroke width.
//  2. A uniform is highp if it is a position or a length at the scale of the
//     shape.
//  3. An iterative solver may run in mediump only if it corrects itself
//     (Newton's method does, bisection does not), and then needs a final step
//     in highp.
//  4. The gradient parameter `t` is highp until it has been tiled.
//
// Colors, enums, ratios, per-pixel sizes and the antialiasing math stay
// mediump.

precision mediump float;

// See rule 3 above and `sdSuperellipse` in sdf_functions.glsl.
#define SD_SUPERELLIPSE_PRECISION highp

#include <impeller/color.glsl>
#include <impeller/constants.glsl>
#include <impeller/texture.glsl>
#include <impeller/types.glsl>

#include "rse_sdf.glsl"
#include "sdf_functions.glsl"
#include "sdf_utils.glsl"

/// The width in device pixels over which to apply antialiasing.
///
/// Must match `UberSDFParameters::kAntialiasPixels`, which pads the drawn
/// geometry to make room for it.
const float aa_pixels = 1.0;

uniform FragInfo {
  // FragInfo fields are sorted by size (vec4 -> vec2 -> float) to optimize
  // uniform register usage.

  // ===========================================================================
  // vec4 fields
  // ===========================================================================

  /// The RGBA color of the shape (or paint opacity in color.a for gradients).
  vec4 color;
  /// Corner radii for rounded rects (top-left, top-right, bottom-left,
  /// bottom-right).
  ///
  /// For rounded superellipses:
  ///   xy: The circular cap radii (top octant in x, right octant in y).
  ///   zw: The cosines of the angular spans of the corner circular arc
  ///       transitions (top octant in z, right octant in w). These share the
  ///       radii's slot to save uniform registers.
  highp vec4 radii;

  // ===========================================================================
  // vec2 fields
  // ===========================================================================

  // --- General Shape Geometry ---
  /// The half-dimensions of the shape (half-width, half-height).
  highp vec2 size;
  /// The size of a device pixel in local coordinates.
  vec2 pixel_size;

  // --- Gradient Parameters ---
  /// The linear gradient's delta vector (end - start) in local coordinates.
  /// Unused (0) for radial gradients.
  highp vec2 gradient_delta;

  // --- Superellipse Parameters ---
  /// The exponent degree (n_x, n_y) of the superellipse curvature.
  vec2 superellipse_degree;
  /// The center of the corner transition circle for the top octant of a
  /// rounded superellipse.
  highp vec2 circle_center_top;
  /// The center of the corner transition circle for the right octant of a
  /// rounded superellipse.
  highp vec2 circle_center_right;

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
  /// The type of color source:
  ///   0: Solid color
  ///   1: Linear gradient
  ///   2: Radial gradient
  float color_source_type;

  // --- Stroke Parameters ---
  /// Whether the shape is stroked (1.0) or filled (0.0).
  float stroked;
  /// The width of the stroke.
  highp float stroke_width;
  /// The join style for the stroke:
  ///   0: Miter
  ///   1: Bevel
  ///   2: Round
  float stroke_join;

  // --- Gradient Parameters ---
  /// The tile mode for gradient sampling:
  ///   0: Clamp
  ///   1: Repeat
  ///   2: Mirror
  ///   3: Decal
  float tile_mode;
  /// Inverse gradient length:
  ///   - Linear gradient: 1.0 / dot(delta, delta)
  ///   - Radial gradient: 1.0 / radius
  highp float inv_gradient_length;

  // --- Variant-Specific Gradient Parameters ---
  // Exactly one of these is used by any given entrypoint; the other is unset.

  /// Half the size of a single gradient texel in normalized texture
  /// coordinates along the gradient ramp (x axis).
  ///
  /// Only used by the gradient ramp texture variant.
  float half_texel;
  /// The number of gradient stops in the color data storage buffer.
  ///
  /// Only used by the storage buffer variant.
  float colors_length;
}
frag_info;

out vec4 frag_color;

// The fragment position in local coordinates, relative to the shape's center
// (see `uber_sdf.vert`).
highp in vec2 v_position;

// The fragment position in local coordinates, relative to the gradient's
// origin (see `uber_sdf.vert`).
highp in vec2 v_gradient_position;

// Looks up the gradient color at gradient position `t`.
//
// `t` is untiled, so implementations apply frag_info.tile_mode themselves.
// Returns an unpremultiplied color, ignoring frag_info.color.a, which the
// calling getColor() applies below.
vec4 getGradientColor(highp float t);

// Gets the color to use at v_position based on frag_info properties.
vec4 getColor() {
  vec4 color;
  if (frag_info.color_source_type < 0.5) {
    // Solid color
    color = frag_info.color;
  } else {
    // Same expressions as IPComputeLinearGradientT and
    // IPComputeRadialGradientT (which take mediump parameters), with the
    // subtraction of the gradient's origin already done in the vertex shader.
    // These are highp: the products overflow mediump for gradients longer than
    // ~256 units.
    highp vec2 gradient_position = v_gradient_position;
    highp float t;
    if (frag_info.color_source_type < 1.5) {
      // Linear gradient
      t = dot(gradient_position, frag_info.gradient_delta) *
          frag_info.inv_gradient_length;
    } else {
      // Radial gradient
      t = length(gradient_position) * frag_info.inv_gradient_length;
    }
    vec4 gradient_color = getGradientColor(t);
    color = vec4(gradient_color.rgb, gradient_color.a * frag_info.color.a);
  }
  return color;
}

// The distance functions below take highp positions and sizes and return
// highp distances (rule 1 above).

highp float distanceFromCircle(highp vec2 p, highp float radius) {
  return length(p) - radius;
}

highp float distanceFromRect(highp vec2 p, highp vec2 b) {
  highp vec2 d = abs(p) - b;
  return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
}

highp float distanceFromOval(highp vec2 position, highp vec2 semi_axes) {
  position = abs(position);

  // Find the angle `w` of the closest point on the ellipse with Newton's
  // method. The iteration is scale invariant, so the first steps run in
  // mediump on coordinates normalized by the larger semi-axis, where their
  // intermediate products can't overflow.
  highp float scale = 1.0 / max(semi_axes.x, semi_axes.y);
  highp vec2 p_normalized = position * scale;
  highp vec2 ab_normalized = semi_axes * scale;
  vec2 p = p_normalized;
  vec2 ab = ab_normalized;
  vec2 q = ab * (p - ab);
  float w = (q.x < q.y) ? 1.570796327 : 0.0;
  for (int i = 0; i < 4; i++) {
    vec2 cs = vec2(cos(w), sin(w));
    vec2 u = ab * vec2(cs.x, cs.y);
    vec2 v = ab * vec2(-cs.y, cs.x);
    w = w + dot(p - u, v) / (dot(p - u, u) + dot(v, v));
  }

  // A final Newton step in highp refines the angle to full precision.
  highp float hw = w;
  highp vec2 hcs = vec2(cos(hw), sin(hw));
  highp vec2 hu = ab_normalized * hcs;
  highp vec2 hv = ab_normalized * vec2(-hcs.y, hcs.x);
  hw = hw +
       dot(p_normalized - hu, hv) / (dot(p_normalized - hu, hu) + dot(hv, hv));

  // Near the edge, both the distance and the inside test are small differences
  // of large values, so they are computed in highp as well. The inside test is
  // (x/a)^2 + (y/b)^2 > 1 without the divisions.
  highp float d = length(position - semi_axes * vec2(cos(hw), sin(hw)));
  highp vec2 scaled_position = position * semi_axes.yx;
  highp float axes_product = semi_axes.x * semi_axes.y;
  return (dot(scaled_position, scaled_position) > axes_product * axes_product)
             ? d
             : -d;
}

highp float distanceFromRoundedRect(in highp vec2 p,
                                    in highp vec2 b,
                                    in highp vec4 r) {
  r.xy = (p.x > 0.0) ? r.xy : r.zw;
  r.x = (p.y > 0.0) ? r.x : r.y;
  highp vec2 q = abs(p) - b + r.x;
  return min(max(q.x, q.y), 0.0) + length(max(q, 0.0)) - r.x;
}

highp float distanceFromChamferRect(highp vec2 p,
                                    highp vec2 half_size,
                                    highp float chamfer_size) {
  p = abs(p);
  highp float d1 = max(p.x - half_size.x, p.y - half_size.y);
  highp float d2 =
      (p.x + p.y - half_size.x - half_size.y + chamfer_size) * kHalfSqrtTwo;
  return max(d1, d2);
}

highp float distanceFromRoundedSuperellipse(highp vec2 p,
                                            vec2 degree,
                                            highp vec2 size,
                                            highp vec2 radii,
                                            vec2 cos_angle_span,
                                            highp vec2 circle_center_top,
                                            highp vec2 circle_center_right) {
  // Do work in the first quadrant to simply things.
  p = abs(p);

  // Transition line offset dividing top and right octants.
  highp float c = size.x - size.y;

  // Declare all RSE params for a single octant.
  float se_degree, cos_span;
  highp float radius, axis_length;
  highp vec2 circle_center;

  // 'p' in the coordinate system of the octant.
  highp vec2 p_oct;

  // We split the quadrant along the diagonal of the transition (p.y + c ==
  // p.x). This allows us to grab the correct set of parameters for the
  // "top" and "right" halves of the corner.
  if (p.y + c > p.x) {
    p_oct = p + vec2(0.0, c);
    se_degree = degree.x;
    cos_span = cos_angle_span.x;
    radius = radii.x;
    circle_center = circle_center_top;
    axis_length = size.x;
  } else {
    // For the 'right' octant, we flip the point and shift it according to
    // the CPU's OctantContains/Flip logic.
    p_oct = p.yx - vec2(0.0, c);
    se_degree = degree.y;
    cos_span = cos_angle_span.y;
    radius = radii.y;
    circle_center = circle_center_right;
    axis_length = size.y;
  }

  return distanceFromRSEOctantCos(p_oct, circle_center, radius, cos_span,
                                  axis_length, se_degree);
}

// Calculates pixel size for rectangles using frag_info.pixel_size.
float rectPixelSize(highp vec2 p) {
  // Get pixel size in the direction perpendicular to the closest edge of the
  // rectangle: frag_info.pixel_size.x when closer to a vertical edge, and
  // frag_info.pixel_size.y when closer to a horizontal edge.
  highp vec2 distance = abs(abs(p) - frag_info.size);
  return (distance.x < distance.y) ? frag_info.pixel_size.x
                                   : frag_info.pixel_size.y;
}

// Special case pixel size calculation for rounded rectangles, similar to
// `rectPixelSize` for regular rectangles.
float roundRectPixelSize(highp vec2 p) {
  // The change in local coordinates per horizontal device pixel (device_dx)
  // and vertical device pixel (device_dy).
  vec2 device_dx = dFdx(v_position);
  vec2 device_dy = dFdy(v_position);
  // The size of a device pixel in terms of local coordinates.
  vec2 device_pixel_size = vec2(length(vec2(device_dx.x, device_dy.x)),
                                length(vec2(device_dx.y, device_dy.y)));

  // Select the corner radius for the quadrant of p.
  highp vec4 r = frag_info.radii;
  r.xy = (p.x > 0.0) ? r.xy : r.zw;
  highp float radius = (p.y > 0.0) ? r.x : r.y;

  // Vector from corner circle center to abs(p).
  highp vec2 corner_center = frag_info.size - radius;
  highp vec2 q = abs(p) - corner_center;

  float pixel_size;
  // If in the rounded corner arc, blend X and Y pixel sizes along the normal.
  if (q.x > 0.0 && q.y > 0.0) {
    pixel_size = length(normalize(q) * device_pixel_size);
  } else {
    // Otherwise, we are closer to a straight edge. Get pixel size in the
    // direction perpendicular to the closer edge.
    pixel_size = (q.x > q.y) ? device_pixel_size.x : device_pixel_size.y;
  }
  return pixel_size;
}

float pixelSize(highp float sdf) {
  vec2 gradient = vec2(dFdx(sdf), dFdy(sdf));
  return length(gradient);
}

// Evaluates the SDF for the shape selected by frag_info.type.
// Returns vec2(sdf, pixel_size).
highp vec2 filledSDF(highp vec2 p) {
  highp float sdf;
  float pixel_size;
  // frag_info.type holds a small integer. Round before converting so that a
  // value stored or converted slightly below it can't truncate to the wrong
  // shape.
  int type = int(round(frag_info.type));
  if (type == 0) {  // Circle
    sdf = distanceFromCircle(p, frag_info.size.x);
    pixel_size = pixelSize(sdf);
  } else if (type == 1) {  // Rect
    sdf = distanceFromRect(p, frag_info.size);
    // Rect has its own separate logic for calculating pixel size.
    pixel_size = rectPixelSize(p);
  } else if (type == 2) {  // Oval
    sdf = distanceFromOval(p, frag_info.size);
    pixel_size = pixelSize(sdf);
  } else if (type == 3) {  // Rounded Rect
    sdf = distanceFromRoundedRect(p, frag_info.size, frag_info.radii);
    // RoundRect has its own separate logic for calculating pixel size.
    pixel_size = roundRectPixelSize(p);
  } else {  // Symmetric Rounded Superellipse
    sdf = distanceFromRoundedSuperellipse(
        p, frag_info.superellipse_degree, frag_info.size, frag_info.radii.xy,
        frag_info.radii.zw, frag_info.circle_center_top,
        frag_info.circle_center_right);
    pixel_size = pixelSize(sdf);
  }
  return vec2(sdf, pixel_size);
}

// Evaluates the stroked SDF for the shape selected by frag_info.type.
// Returns vec2(sdf, pixel_size).
highp vec2 strokedSDF(highp vec2 p) {
  highp vec2 base_sdf_and_pixel_size = filledSDF(p);
  highp float base_sdf = base_sdf_and_pixel_size.x;
  float pixel_size = base_sdf_and_pixel_size.y;

  // Stroke width is clamped to be at least the base sdf's pixel size.
  highp float half_stroke = max(frag_info.stroke_width, pixel_size) * 0.5;

  highp float sdf;
  // frag_info.type and frag_info.stroke_join hold small integers (see
  // filledSDF() for why they are rounded).
  int type = int(round(frag_info.type));
  int join = int(round(frag_info.stroke_join));
  if (type == 1 && join == 0) {
    // Rect with Miter join
    highp float outer = distanceFromRect(p, frag_info.size + half_stroke);
    highp float inner = base_sdf + half_stroke;
    sdf = max(outer, -inner);
  } else if (type == 1 && join == 1) {
    // Rect with Bevel join
    highp float outer =
        distanceFromChamferRect(p, frag_info.size + half_stroke, half_stroke);
    highp float inner = base_sdf + half_stroke;
    sdf = max(outer, -inner);
  } else {
    // All other shapes: the stroked SDF is defined by the +/- half_stroke
    // isolines of the base SDF. This is SDFStroke() from sdf_utils.glsl, but
    // without converting the base distance to mediump first.
    sdf = abs(base_sdf) - half_stroke;
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
  vec4 color = getColor();

  highp vec2 p = v_position;

  highp vec2 sdf_and_pixel_size =
      (frag_info.stroked < 0.5) ? filledSDF(p) : strokedSDF(p);
  // From here on only the antialiasing band around zero matters, so mediump is
  // enough.
  float sdf = sdf_and_pixel_size.x;
  float pixel_size = sdf_and_pixel_size.y;

  float alpha = SDFAlpha(sdf, pixel_size, aa_pixels);
  // Clamp alpha in case floating point precision errors cause it to be outside
  // [0.0, 1.0].
  alpha = clamp(alpha, 0.0, 1.0);
  if (alpha < 1.0) {
    alpha = gammaCorrectedAlpha(alpha, color.rgb);
  }

  frag_color = vec4(color.rgb, color.a * alpha);
  frag_color = IPPremultiply(frag_color);
}
