// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

uniform FrameInfo {
  mat4 mvp;
  float enable_skinning;
  float joint_texture_size;
}
frame_info;

uniform sampler2D joints_texture;

// This attribute layout is expected to be identical to `SkinnedVertex` within
// `impeller/scene/importer/scene.fbs`.
in vec3 position;
in vec3 normal;
in vec4 tangent;
in vec2 texture_coords;
in vec4 color;
in vec4 joints;
in vec4 weights;

out vec3 v_position;
out mat3 v_tangent_space;
out vec2 v_texture_coords;
out vec4 v_color;

const int kMatrixTexelStride = 4;

mat4 GetJoint(float joint_index) {
  // The size of one texel in UV space. The joint texture should always be
  // square, so the answer is the same in both dimensions.
  float texel_size_uv = 1 / frame_info.joint_texture_size;

  // Each joint matrix takes up 4 pixels (16 floats), so we jump 4 pixels per
  // joint matrix.
  float matrix_start = joint_index * kMatrixTexelStride;

  // The texture space coordinates at the start of the matrix.
  float x = mod(matrix_start, frame_info.joint_texture_size);
  float y = floor(matrix_start / frame_info.joint_texture_size);

  // Nearest sample the middle of each the texel by adding `0.5 * texel_size_uv`
  // to both dimensions.
  y = (y + 0.5) * texel_size_uv;
  mat4 joint =
      mat4(texture(joints_texture, vec2((x + 0.5) * texel_size_uv, y)),
           texture(joints_texture, vec2((x + 1.5) * texel_size_uv, y)),
           texture(joints_texture, vec2((x + 2.5) * texel_size_uv, y)),
           texture(joints_texture, vec2((x + 3.5) * texel_size_uv, y)));

  return joint;
}

void main() {
  mat4 skin_matrix;
  if (frame_info.enable_skinning == 1) {
    skin_matrix =
        GetJoint(joints.x) * weights.x + GetJoint(joints.y) * weights.y +
        GetJoint(joints.z) * weights.z + GetJoint(joints.w) * weights.w;
  } else {
    skin_matrix = mat4(1);  // Identity matrix.
  }

  gl_Position = frame_info.mvp * skin_matrix * vec4(position, 1.0);
  v_position = gl_Position.xyz;

  vec3 lh_tangent = (skin_matrix * vec4(tangent.xyz * tangent.w, 0.0)).xyz;
  vec3 out_normal = (skin_matrix * vec4(normal, 0.0)).xyz;
  v_tangent_space = mat3(frame_info.mvp) *
                    mat3(lh_tangent, cross(out_normal, lh_tangent), out_normal);
  v_texture_coords = texture_coords;
  v_color = color;
}
