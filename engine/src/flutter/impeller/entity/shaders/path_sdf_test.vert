// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <impeller/types.glsl>

uniform FrameInfo {
  mat4 mvp;
  mat4 local_to_device;
}
frame_info;

in vec2 position;

out vec2 v_device_pos;

void main() {
  gl_Position = frame_info.mvp * vec4(position, 0.0, 1.0);
  v_device_pos = (frame_info.local_to_device * vec4(position, 0.0, 1.0)).xy;
}
