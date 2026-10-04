// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

uniform FrameInfo {
  mat4 mvp;
}
frame_info;

// Per-vertex geometry. Sourced from a binding that advances once per vertex.
in vec2 vertex_position;

// Per-instance data. Sourced from a binding that advances once per instance.
// Using instance-rate vertex attributes rather than gl_InstanceIndex keeps
// this shader portable down to OpenGL ES 2.0, which has no instance-ID
// builtin.
in vec2 instance_offset;
in vec4 instance_color;

out vec4 v_color;

void main() {
  gl_Position =
      frame_info.mvp * vec4(vertex_position + instance_offset, 0.0, 1.0);
  v_color = instance_color;
}
