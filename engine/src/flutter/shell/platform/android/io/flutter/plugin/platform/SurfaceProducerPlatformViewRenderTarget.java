package io.flutter.plugin.platform;

import android.annotation.TargetApi;
import android.graphics.Canvas;
import android.view.Surface;
import io.flutter.view.TextureRegistry.SurfaceProducer;

@TargetApi(29)
public class SurfaceProducerPlatformViewRenderTarget implements PlatformViewRenderTarget {
  private static final String TAG = "SurfaceProducerRenderTarget";
  private SurfaceProducer producer;

  public SurfaceProducerPlatformViewRenderTarget(SurfaceProducer producer) {
    this.producer = producer;
  }

  // Called when the render target should be resized.
  public void resize(int width, int height) {
    this.producer.setSize(width, height);
  }

  // Returns the currently specified width.
  public int getWidth() {
    return this.producer.getWidth();
  }

  // Returns the currently specified height.
  public int getHeight() {
    return this.producer.getHeight();
  }

  // Forwards call to Surface returned by getSurface.
  // NOTE: If this returns null the RenderTarget is "full" and has no room for a
  // new frame.
  public Canvas lockHardwareCanvas() {
    Surface surface = this.producer.getSurface();
    return surface.lockHardwareCanvas();
  }

  // Forwards call to Surface returned by getSurface.
  // NOTE: Must be called if lockHardwareCanvas returns a non-null Canvas.
  public void unlockCanvasAndPost(Canvas canvas) {
    Surface surface = this.producer.getSurface();
    surface.unlockCanvasAndPost(canvas);
  }

  // The id of this render target.
  public long getId() {
    return this.producer.id();
  }

  // Releases backing resources.
  public void release() {
    this.producer.release();
    this.producer = null;
  }

  // Returns true in the case that backing resource have been released.
  public boolean isReleased() {
    return this.producer == null;
  }

  // Returns the Surface to be rendered on to.
  public Surface getSurface() {
    return this.producer.getSurface();
  }
}
