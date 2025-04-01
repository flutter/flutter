// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugin.platform;

public class OcclusionRect {
  public OcclusionRect(int x, int y, int width, int height) {
    this.x = x;
    this.y = y;
    this.width = width;
    this.height = height;
  }

  int GetX() {
    return x;
  }

  int GetY() {
    return y;
  }

  int GetWidth() {
    return width;
  }

  int GetHeight() {
    return height;
  }

  private final int x;
  private final int y;
  private final int width;
  private final int height;
}
