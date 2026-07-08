// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

precision mediump float;

#include <impeller/color.glsl>
#include <impeller/gaussian.glsl>
#include <impeller/types.glsl>

#include "sdf_functions.glsl"
#include "sdf_utils.glsl"

uniform FragInfo {
  vec4 color;
  vec2 center;
  vec2 size;
  float shape_type;
  float filter_type;
  float filter_scale;
  float stroke_width;
  float stroke_join;
  float stroked;
  vec2 superellipse_degree;
  vec2 superellipse_semi_axis;
  vec2 angle_span;
  float octant_offset_c;
  vec2 circle_center_top;
  vec2 circle_center_right;
  vec2 superellipse_scale;
  vec4 radii;
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

float distanceFromOval(vec2 p, vec2 ab) {
  p = abs(p);
  vec2 q = ab * (p - ab);
  float w = (q.x < q.y) ? 1.570796327 : 0.0;
  for (int i = 0; i < 5; i++) {
    vec2 cs = vec2(cos(w), sin(w));
    vec2 u = ab * vec2(cs.x, cs.y);
    vec2 v = ab * vec2(-cs.y, cs.x);
    w = w + dot(p - u, v) / (dot(p - u, u) + dot(v, v));
  }
  float d = length(p - ab * vec2(cos(w), sin(w)));
  return (dot(p / ab, p / ab) > 1.0) ? d : -d;
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
      (p.x + p.y - half_size.x - half_size.y + chamfer_size) * 0.70710678;
  return max(d1, d2);
}

float distanceFromRoundedSuperellipse(vec2 p,
                                      vec2 degree,
                                      vec2 se_a,
                                      vec2 radii,
                                      vec2 angle_span,
                                      vec2 circle_center_top,
                                      vec2 circle_center_right,
                                      float c,
                                      vec2 scale) {
  // Do work in the first quadrant to simply things.
  p = abs(p);
  // Map p in to a square.
  vec2 p_norm = p / scale;

  // Declare all RSE params for a single octant.
  float se_degree, span, radius, axis_length;
  vec2 circle_center;

  // 'p' in the coordinate system of the octant.
  vec2 p_oct;

  // We split the quadrant along the diagonal of the transition (p_norm.y + c ==
  // p_norm.x). This allows us to grab the correct set of parameters for the
  // "top" and "right" halves of the corner.
  if (p_norm.y + c > p_norm.x) {
    p_oct = p_norm + vec2(0.0, c);
    se_degree = degree.x;
    span = angle_span.x;
    radius = radii.x;
    circle_center = circle_center_top;
    axis_length = se_a.x;
  } else {
    // For the 'right' octant, we flip the point and shift it according to
    // the CPU's OctantContains/Flip logic.
    p_oct = p_norm.yx - vec2(0.0, c);
    se_degree = degree.y;
    span = angle_span.y;
    radius = radii.y;
    circle_center = circle_center_right;
    axis_length = se_a.y;
  }

  // Move the point to the corner circle's coordinate system.
  vec2 p_rel = p_oct - circle_center;

  // Grab the angle offset of the point.
  float theta = atan(p_rel.y, p_rel.x);

  // The angular distance between the point and the 45 degree midline.
  float d_theta = theta - PI_OVER_FOUR;
  d_theta = mod(d_theta + PI, TWO_PI) - PI;

  // If the point is within the span of the corner circle's arc,
  // use a circle SDF.
  // This works because the normals of the circular and superelliptical sections
  // agree at the transition angle, the total RSE curve is continuous and
  // the closest point on a continuous curve to a point lies along the normal.
  if (abs(d_theta) < abs(span)) {
    return distanceFromCircle(p_rel, radius);
  }
  return sdSuperellipse(p_oct / axis_length, se_degree) * axis_length;
}

float pixelSize(float sdf) {
  vec2 gradient = vec2(dFdx(sdf), dFdy(sdf));
  return length(gradient);
}

vec2 filledSDF(vec2 p) {
  float sdf;
  if (frag_info.shape_type < 0.5) {  // Circle
    sdf = distanceFromCircle(p, frag_info.size.x);
  } else if (frag_info.shape_type < 1.5) {  // Rect
    sdf = distanceFromRect(p, frag_info.size);
  } else if (frag_info.shape_type < 2.5) {  // Oval
    sdf = distanceFromOval(p, frag_info.size);
  } else if (frag_info.shape_type < 3.5) {  // Rounded Rect
    sdf = distanceFromRoundedRect(p, frag_info.size, frag_info.radii);
  } else {  // Symmetric Rounded Superellipse
    sdf = distanceFromRoundedSuperellipse(
        p, frag_info.superellipse_degree, frag_info.superellipse_semi_axis,
        frag_info.radii.xy, frag_info.angle_span, frag_info.circle_center_top,
        frag_info.circle_center_right, frag_info.octant_offset_c,
        frag_info.superellipse_scale);
  }
  return vec2(sdf, pixelSize(sdf));
}

vec2 strokedSDF(vec2 p) {
  vec2 base_sdf_and_pixel_size = filledSDF(p);
  float base_sdf = base_sdf_and_pixel_size.x;
  float base_pixel_size = base_sdf_and_pixel_size.y;

  float half_stroke = max(frag_info.stroke_width, base_pixel_size) * 0.5;

  // Some cases need special handling because their stroked SDFs have a
  // different shape from their base SDFs.
  if (frag_info.shape_type >= 0.5 && frag_info.shape_type < 1.5) {  // Rect
    // Rect has slightly different outer shape depending on the join type
    if (frag_info.stroke_join < 0.5) {  // Miter
      float outer = distanceFromRect(p, frag_info.size + half_stroke);
      float inner = base_sdf + half_stroke;
      float sdf = max(outer, -inner);
      return vec2(sdf, pixelSize(sdf));
    } else if (frag_info.stroke_join < 1.5) {  // Bevel
      float outer =
          distanceFromChamferRect(p, frag_info.size + half_stroke, half_stroke);
      float inner = base_sdf + half_stroke;
      float sdf = max(outer, -inner);
      return vec2(sdf, pixelSize(sdf));
    }
  }

  return SDFStroke(base_sdf, base_pixel_size, frag_info.stroke_width);
}

float getAlpha(vec2 sdf_and_pixel_size) {
  highp float sdf = sdf_and_pixel_size.x;
  highp float pixel_size = sdf_and_pixel_size.y;

  if (frag_info.filter_type < 0.5) {
    // Antialiasing case. The filter_scale is the size of the AA pixel blends
    // at the edge of the shape and the SDFAlpha function uses a smoothstep
    // function to filter the coverage across those blended pixels.
    return SDFAlpha(sdf, pixel_size, frag_info.filter_scale);
  }

  // Else we are processing a shadow.
  // Shadows. Fade from alpha 1 to 0 across the edge of the SDF at a distance
  // of -shadow_radius on the inside of the shape where the shadow is most
  // opaque (maximum umbra) to a distance of +shadow_radius on the outside
  // of the shape where the shadow fades to transparent.
  //
  // The total distance over which the shadow fades from maximum umbra to
  // transparency is (shadow_radius * 2.0)
  //
  // The scale changes +/-shadow_radius to +/-0.5, we then invert that scaled
  // number (we want higher values on the inside) and offset by 0.5 to get
  // a gaussian coefficient from 1 (inside/umbra) to 0 (outside/transparent).
  if (frag_info.filter_type > 10.0) {
    float shadow_scale;
    if (frag_info.filter_type < 1.5) {
      // Device scale shadow.
      shadow_scale = 0.5 / (frag_info.filter_scale * pixel_size);
    } else {
      // Local space shadow.
      shadow_scale = 0.5 / frag_info.filter_scale;
    }
    float gaussian_t = clamp(0.5 - sdf * shadow_scale, 0.0, 1.0);
    return IPHalfFractionToFastGaussianCDF(gaussian_t);
  }
  highp float shadow_size;
  if (frag_info.filter_type < 1.5) {
    // Device scale shadow.
    shadow_size = frag_info.filter_scale * pixel_size;
  } else {
    // Local space shadow.
    shadow_size = frag_info.filter_scale;
  }
  float gaussian_t = 1.0 - smoothstep(-shadow_size, shadow_size, sdf);
  return gaussian_t;
}

#undef SDF_VISUALIZATION

#ifdef SDF_VISUALIZATION
vec4 SampleSDFVisualization(vec2 sdf_and_pixel_size) {
  float d = sdf_and_pixel_size.x;
  float px = sdf_and_pixel_size.y;

  // The following constants are tuned for a coordinate system where 1.0
  // represents 100 pixels.
  float d_norm = d / 100.0;
  float px_norm = px / 100.0;

  vec3 col = (d > 0.0) ? vec3(0.9, 0.6, 0.3) : vec3(0.65, 0.85, 1.0);
  col *= 1.0 - exp2(-12.0 * abs(d_norm));
  col *= 0.8 + 0.2 * cos(120.0 * d_norm);
  col =
      mix(col, vec3(1.0), smoothstep(1.5 * px_norm, 0.0, abs(d_norm) - 0.002));

  return vec4(col, 1.0);
}
#endif  // SDF_VISUALIZATION

void main() {
  vec2 p = v_position - frag_info.center;

  vec2 sdf_and_pixel_size =
      (frag_info.stroked < 0.5) ? filledSDF(p) : strokedSDF(p);

#ifdef SDF_VISUALIZATION
  if (frag_info.filter_type > 2.5) {
    frag_color = SampleSDFVisualization(sdf_and_pixel_size);
    return;
  }
#endif  // SDF_VISUALIZATION

  float alpha = getAlpha(sdf_and_pixel_size);

  frag_color = vec4(frag_info.color.rgb, frag_info.color.a * alpha);
  frag_color = IPPremultiply(frag_color);
}
