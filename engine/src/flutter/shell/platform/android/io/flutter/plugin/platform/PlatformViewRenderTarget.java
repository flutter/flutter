// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugin.platform;

import android.graphics.Canvas;
import android.view.Surface;

/**
 * A PlatformViewRenderTarget interface allows an Android Platform View to be rendered into an
 * offscreen buffer (usually a texture is involved) that the engine can compose into the
 * FlutterView.
 */
public interface PlatformViewRenderTarget {
  // Called when the render target should be resized.
  public void resize(int width, int height);

  // Returns the currently specified width.
  public int getWidth();

  // Returns the currently specified height.
  public int getHeight();

  // Forwards call to Surface returned by getSurface.
  // NOTE: If this returns null the RenderTarget is "full" and has no room for a
  // new frame.
  Canvas lockHardwareCanvas();

  // Forwards call to Surface returned by getSurface.
  // NOTE: Must be called if lockHardwareCanvas returns a non-null Canvas.
  void unlockCanvasAndPost(Canvas canvas);

  // The id of this render target.
  public long getId();

  // Releases backing resources.
  public void release();

  // Returns true in the case that backing resource have been released.
  public boolean isReleased();

  // Returns the Surface to be rendered on to.
  public Surface getSurface();
}
