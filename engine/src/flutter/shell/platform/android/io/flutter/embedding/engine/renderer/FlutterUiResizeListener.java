// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.embedding.engine.renderer;

/** Listener invoked when Flutter resizes the surface frame based on the content size. */
public interface FlutterUiResizeListener {
  /** Flutter has resized the display based on content size */
  void resizeEngineView(int width, int height);
}
