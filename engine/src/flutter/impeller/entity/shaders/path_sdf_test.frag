// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

precision mediump float;

#include <impeller/color.glsl>
#include "sdf_utils.glsl"

#define MAX_SEGMENTS 16
#define ITERATIONS 2

uniform FragInfo {
  vec4 color;
  float stroke_width;
  float segment_count;
  float aa_pixels;
  float unused;
  vec4 segments[MAX_SEGMENTS * 3];
}
frag_info;

out vec4 frag_color;

highp in vec2 v_position;

// --- Common Math Helpers ---

float dot2(vec2 v) {
  return dot(v, v);
}

float cro(vec2 a, vec2 b) {
  return a.x * b.y - a.y * b.x;
}

float cos_acos_3(float x) {
  return cos(acos(clamp(x, -1.0, 1.0)) / 3.0);
}

// --- Line SDF ---

float sdSegment(in vec2 p, in vec2 a, in vec2 b, in float r) {
  vec2 ba = b - a;
  vec2 pa = p - a;
  float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
  return length(pa - h * ba) - r;
}

// --- Quadratic Bezier SDF ---

float sdBezier(in vec2 pos, in vec2 A, in vec2 B, in vec2 C, out vec2 outQ) {
  vec2 a = B - A;
  vec2 b = A - 2.0 * B + C;
  vec2 c = a * 2.0;
  vec2 d = A - pos;

  float kk = 1.0 / dot(b, b);
  float kx = kk * dot(a, b);
  float ky = kk * (2.0 * dot(a, a) + dot(d, b)) / 3.0;
  float kz = kk * dot(d, a);

  float res = 0.0;
  float sgn = 0.0;

  float p = ky - kx * kx;
  float q = kx * (2.0 * kx * kx - 3.0 * ky) + kz;
  float p3 = p * p * p;
  float q2 = q * q;
  float h = q2 + 4.0 * p3;

  if (h >= 0.0) {  // 1 root
    h = sqrt(h);
    h = (q < 0.0) ? h : -h;
    float x = (h - q) / 2.0;
    float v = sign(x) * pow(abs(x), 1.0 / 3.0);
    float t = v - p / v;

    t -= (t * (t * t + 3.0 * p) + q) / (3.0 * t * t + 3.0 * p);
    t = clamp(t - kx, 0.0, 1.0);
    vec2 w = d + (c + b * t) * t;
    outQ = w + pos;
    res = dot2(w);
    sgn = cro(c + 2.0 * b * t, w);
  } else {  // 3 roots
    float z = sqrt(-p);
    float m = cos_acos_3(q / (p * z * 2.0));
    float n = sqrt(1.0 - m * m);
    n *= sqrt(3.0);
    vec3 t = clamp(vec3(m + m, -n - m, n - m) * z - kx, 0.0, 1.0);
    vec2 qx = d + (c + b * t.x) * t.x;
    float dx = dot2(qx), sx = cro(a + b * t.x, qx);
    vec2 qy = d + (c + b * t.y) * t.y;
    float dy = dot2(qy), sy = cro(a + b * t.y, qy);
    if (dx < dy) {
      res = dx;
      sgn = sx;
      outQ = qx + pos;
    } else {
      res = dy;
      sgn = sy;
      outQ = qy + pos;
    }
  }

  return sqrt(res) * sign(sgn);
}

// --- Complex / Cardano Helpers for Cubic ---

vec2 cexp(vec2 c) {
  return exp(c.x) * vec2(cos(c.y), sin(c.y));
}

vec2 cln(vec2 c) {
  return vec2(log(dot(c, c)) * .5, atan(c.y, c.x));
}

vec2 cmul(vec2 a, vec2 b) {
  return vec2(a.x * b.x - a.y * b.y, a.x * b.y + a.y * b.x);
}

vec2 conj(vec2 c) {
  return vec2(c.x, -c.y);
}

vec2 cdiv(vec2 a, vec2 b) {
  return cmul(a, conj(b)) / dot(b, b);
}

vec2 csqrt(vec2 a) {
  float r = length(a);
  if ((a.y + a.x) - a.x == 0.0) {
    return a.x >= 0.0 ? vec2(sqrt(r), 0.0) : vec2(0.0, sqrt(r));
  }
  vec2 h = a / r + vec2(1.0, 0.0);
  return h * sqrt(r / dot(h, h));
}

vec2 ccbrt(vec2 a) {
  return cexp(cln(a) / 3.0);
}

void cubic_roots(vec2 a,
                 vec2 b,
                 vec2 c,
                 vec2 d,
                 out vec2 x0,
                 out vec2 x1,
                 out vec2 x2) {
  vec2 ac = cmul(a, c);
  vec2 bb = cmul(b, b);
  vec2 aa = cmul(a, a);
  vec2 d0 = bb - 3.0 * ac;
  vec2 d1 = 2.0 * cmul(b, bb) - 9.0 * cmul(ac, b) + 27.0 * cmul(aa, d);
  vec2 s = csqrt(cmul(d1, d1) - 4.0 * cmul(cmul(d0, d0), d0));
  vec2 opta = d1 - s;
  vec2 optb = d1 + s;
  vec2 opt = dot(opta, opta) < dot(optb, optb) ? optb : opta;
  vec2 cb = ccbrt(opt * 0.5);

  // Division safeguard
  cb = length(cb) > 1e-5 ? cb : vec2(1e-5, 0.0);

  x0 = cdiv(b + cb + cdiv(d0, cb), -3.0 * a);
  vec2 root = vec2(-0.5, 0.866025403784439);
  cb = cmul(cb, root);
  x1 = cdiv(b + cb + cdiv(d0, cb), -3.0 * a);
  cb = cmul(cb, root);
  x2 = cdiv(b + cb + cdiv(d0, cb), -3.0 * a);
}

float newton_quintic(float a,
                     float b,
                     float c,
                     float d,
                     float e,
                     float f,
                     float x0) {
  float v = ((((a * x0 + b) * x0 + c) * x0 + d) * x0 + e) * x0 + f;
  float dv =
      (((5.0 * a * x0 + 4.0 * b) * x0 + 3.0 * c) * x0 + 2.0 * d) * x0 + e;
  float ddv = ((20.0 * a * x0 + 12.0 * b) * x0 + 6.0 * c) * x0 + 2.0 * d;

  // Handle potential flat areas / zero derivative
  dv = abs(dv) > 1e-5 ? dv : 1e-5 * sign(dv);
  ddv = abs(ddv) > 1e-5 ? ddv : 1e-5 * sign(ddv);

  float p = dv / ddv;
  float q = v / ddv * 2.0;
  float dx = p - sqrt(max(p * p - q, 0.0)) * sign(p);
  return x0 - dx;
}

float newton_bezier(float a,
                    float b,
                    float c,
                    float d,
                    float e,
                    float f,
                    float x0) {
  x0 = clamp(x0, 0.0, 1.0);
  for (int i = 0; i < ITERATIONS; i++) {
    x0 = clamp(newton_quintic(a, b, c, d, e, f, x0), 0.0, 1.0);
  }
  return x0;
}

// --- Cubic Bezier SDF ---

float sdCubicBezier(vec2 p, vec2 p0, vec2 p1, vec2 p2, vec2 p3) {
  vec2 A = -p0 + 3.0 * p1 - 3.0 * p2 + p3;
  vec2 B = 3.0 * p0 - 6.0 * p1 + 3.0 * p2;
  vec2 C = -3.0 * p0 + 3.0 * p1;
  vec2 D = p0;

  vec2 a_prime = 3.0 * A;
  vec2 b_prime = 2.0 * B;
  vec2 c_prime = C;

  vec2 x0, x1, x2;
  vec2 cardano_a = length(A) > 1e-5 ? A : vec2(1e-5, 0.0);
  cubic_roots(cardano_a, B, C, D - p, x0, x1, x2);

  float t0 = clamp(x0.x, 0.0, 1.0);
  float t1 = clamp(x1.x, 0.0, 1.0);
  float t2 = clamp(x2.x, 0.0, 1.0);

  vec2 D_minus_p = D - p;
  float coeff_a = dot(A, a_prime);
  float coeff_b = dot(A, b_prime) + dot(B, a_prime);
  float coeff_c = dot(A, c_prime) + dot(B, b_prime) + dot(C, a_prime);
  float coeff_d = dot(B, c_prime) + dot(C, b_prime) + dot(D_minus_p, a_prime);
  float coeff_e = dot(C, c_prime) + dot(D_minus_p, b_prime);
  float coeff_f = dot(D_minus_p, c_prime);

  t0 = newton_bezier(coeff_a, coeff_b, coeff_c, coeff_d, coeff_e, coeff_f, t0);
  t1 = newton_bezier(coeff_a, coeff_b, coeff_c, coeff_d, coeff_e, coeff_f, t1);
  t2 = newton_bezier(coeff_a, coeff_b, coeff_c, coeff_d, coeff_e, coeff_f, t2);

  float t3 = 0.0;
  float t4 = 1.0;

  vec2 pos0 = (((A * t0 + B) * t0 + C) * t0 + D);
  vec2 pos1 = (((A * t1 + B) * t1 + C) * t1 + D);
  vec2 pos2 = (((A * t2 + B) * t2 + C) * t2 + D);
  vec2 pos3 = p0;
  vec2 pos4 = p3;

  float d0 = length(pos0 - p);
  float d1 = length(pos1 - p);
  float d2 = length(pos2 - p);
  float d3 = length(pos3 - p);
  float d4 = length(pos4 - p);

  return min(min(min(d0, d1), min(d2, d3)), d4);
}

// --- Gradient Helpers ---

float pixelSize(float sdf) {
  vec2 gradient = vec2(dFdx(sdf), dFdy(sdf));
  return length(gradient);
}

// --- Main Entrypoint ---

void main() {
  float min_dist = 999999.0;
  int count = int(frag_info.segment_count);

  for (int i = 0; i < 16; ++i) {
    if (i >= count) {
      break;
    }

    int idx = 3 * i;
    vec2 p0 = frag_info.segments[idx + 0].xy;
    vec2 p1 = frag_info.segments[idx + 0].zw;
    vec2 p2 = frag_info.segments[idx + 1].xy;
    vec2 p3 = frag_info.segments[idx + 1].zw;
    float type = frag_info.segments[idx + 2].x;

    float dist = 999999.0;
    if (type < 0.5) {  // Line
      dist = abs(sdSegment(v_position, p0, p1, 0.0));
    } else if (type < 1.5) {  // Quad
      vec2 outQ;
      dist = abs(sdBezier(v_position, p0, p1, p2, outQ));
    } else {  // Cubic
      dist = abs(sdCubicBezier(v_position, p0, p1, p2, p3));
    }

    min_dist = min(min_dist, dist);
  }

  float dist_to_stroke = min_dist - frag_info.stroke_width * 0.5;
  float pixel_size = pixelSize(dist_to_stroke);
  float alpha = SDFAlpha(dist_to_stroke, pixel_size, frag_info.aa_pixels);

  vec4 final_color = vec4(frag_info.color.rgb, frag_info.color.a * alpha);
  frag_color = IPPremultiply(final_color);
}
