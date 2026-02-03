#version 320 es

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

precision highp float;

uniform vec4 color_rgba;

out vec4 fragColor;

void main() {
  fragColor = color_rgba;
}
