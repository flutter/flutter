// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
#version 450
// Cover the full target. The dynamic scissor clips each backing store.
void main() {
  vec2 corner = vec2((gl_VertexIndex << 1) & 2, gl_VertexIndex & 2);
  gl_Position = vec4(corner * 2.0 - 1.0, 0.0, 1.0);
}
