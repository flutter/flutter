// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This shader draws lines using the technique from GPU Gems 2, Chapter 22:
// "Fast Prefiltered Lines." Instead of relying on hardware multisample
// anti-aliasing (MSAA), this approach analytically determines pixel coverage.
//
// The LineContents expands the line's geometry into a padded bounding box. For
// each vertex, four implicit edge equations are computed, representing the
// normalized distances from the borders. The fragment shader uses these
// distances to look up the coverage percentage from a precomputed 1D curve
// texture, resulting in fast, high-quality, and artifact-free anti-aliasing.
//
// For information on the implementation of this shader, see the design doc:
// https://docs.google.com/document/d/19I6ToHCMlSgSava-niFWzMLGJEAd-rYiBQEGOMu8IJg/edit?tab=t.0#heading=h.icnmwum4oznc
//
// See also:
// - //impeller/entity/shaders/line.vert
// - //impeller/entity/contents/line_contents.cc

precision mediump float;

#include <impeller/color.glsl>
#include <impeller/types.glsl>

uniform FragInfo {
  vec4 color;
  float cap_type;  // 0.0 for butt/square, 1.0 for round
}
frag_info;

// A 1D texture that encodes the coverage percentage (or anti-aliasing profile)
// across the edge of the line. This acts as a prefiltered lookup table.
uniform sampler2D curve;

highp in vec2 v_position;
// These should be `flat` but that doesn't work in our glsl compiler. It
// shouldn't make any visual difference.
//
// Equations for the four edges defining the line segment's padded bounding box.
// Evaluated as dot(pos, v_eN), these give the normalized distance from the
// respective edge. A distance <= 0.0 is completely outside the padded geometry.
// The distances evaluate to 1.0 exactly at the geometric center of the line.
//
// v_e0 and v_e2: Distances from the two parallel side edges defining the
//                line segment's bounds (along its thickness).
// v_e1 and v_e3: Distances from the two perpendicular cap edges defining the
//                start and end bounds of the line segment.
highp in vec3 v_e0;
highp in vec3 v_e1;
highp in vec3 v_e2;
highp in vec3 v_e3;

out vec4 frag_color;

float lookup(float x) {
  return texture(curve, vec2(x, 0)).r;
}

float CalculateLine() {
  vec3 pos = vec3(v_position.xy, 1.0);
  vec4 d = vec4(dot(pos, v_e0), dot(pos, v_e1), dot(pos, v_e2), dot(pos, v_e3));

  if (any(lessThan(d, vec4(0.0)))) {
    return 0.0;
  }

  if (frag_info.cap_type == 1.0) {
    if (min(d.y, d.w) < 1.0) {
      float R = distance(vec2(min(d.x, d.z), min(d.y, d.w)), vec2(1.0));
      return lookup(clamp(1.0 - R, 0.0, 1.0));
    } else {
      return lookup(min(d.x, d.z));
    }
  } else {
    return lookup(min(d.x, d.z)) * lookup(min(d.y, d.w));
  }
}

void main() {
  float line = CalculateLine();
  frag_color = vec4(frag_info.color.xyz, line);
  //////////////////////////////////////////////////////////////////////////////
  // This is a nice way to visually debug this shader:
  // frag_color =
  //   vec4(mix(vec3(1, 0,0), frag_info.color.xyz, line), 1.0);
  //////////////////////////////////////////////////////////////////////////////
  frag_color = IPPremultiply(frag_color);
}
