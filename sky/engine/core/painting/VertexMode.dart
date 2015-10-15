// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of dart_ui;

/// Defines how a list of points is interpreted when drawing a set of triangles. See Skia or OpenGL documentation for more details.
enum VertexMode {
  triangles,
  triangleStrip,
  triangleFan,
}
