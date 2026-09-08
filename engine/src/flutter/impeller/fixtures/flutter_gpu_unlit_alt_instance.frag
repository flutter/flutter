// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Exercises the GL uniform block instance-name canonicalization landed for
// flutter/flutter#186393: the instance variable name (`params`) does not
// normalize to the block name (`ColorParams`) under
// `BufferBindingsGLES`'s case- and underscore-insensitive match. Without
// canonicalization, every member of this block silently binds to GL
// location -1 on the OpenGL ES backend and the shader reads zeros.

in vec4 v_color;
out vec4 frag_color;

uniform ColorParams {
  vec4 base_color;
}
params;

void main() {
  frag_color = params.base_color * v_color;
}
