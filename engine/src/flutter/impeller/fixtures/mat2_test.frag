// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

layout(std140) uniform Params {
  mat2 uMat2;
}
uParams;

out vec4 frag_color;

void main() {
  frag_color = vec4(uParams.uMat2[0], uParams.uMat2[1]);
}
