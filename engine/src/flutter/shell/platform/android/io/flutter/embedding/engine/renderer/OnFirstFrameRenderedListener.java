// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.embedding.engine.renderer;

/**
 * Listener invoked after Flutter paints its first frame since being initialized.
 *
 * WARNING: THIS CLASS IS EXPERIMENTAL. DO NOT SHIP A DEPENDENCY ON THIS CODE.
 * IF YOU USE IT, WE WILL BREAK YOU.
 */
public interface OnFirstFrameRenderedListener {
  /**
   * A {@link FlutterRenderer} has painted its first frame since being initialized.
   *
   * This method will not be invoked if this listener is added after the first frame is rendered.
   */
  void onFirstFrameRendered();
}
