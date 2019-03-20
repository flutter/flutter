// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.embedding.engine.renderer;

import android.annotation.TargetApi;
import android.graphics.Bitmap;
import android.graphics.SurfaceTexture;
import android.os.Build;
import android.os.Handler;
import android.support.annotation.NonNull;
import android.view.Surface;

import java.nio.ByteBuffer;
import java.util.concurrent.atomic.AtomicLong;

import io.flutter.embedding.android.FlutterView;
import io.flutter.embedding.engine.FlutterJNI;
import io.flutter.view.TextureRegistry;

/**
 * WARNING: THIS CLASS IS EXPERIMENTAL. DO NOT SHIP A DEPENDENCY ON THIS CODE.
 * IF YOU USE IT, WE WILL BREAK YOU.
 *
 * {@code FlutterRenderer} works in tandem with a provided {@link RenderSurface} to create an
 * interactive Flutter UI.
 *
 * {@code FlutterRenderer} manages textures for rendering, and forwards some Java calls to native Flutter
 * code via JNI. The corresponding {@link RenderSurface} is used as a delegate to carry out
 * certain actions on behalf of this {@code FlutterRenderer} within an Android view hierarchy.
 *
 * {@link FlutterView} is an implementation of a {@link RenderSurface}.
 */
@TargetApi(Build.VERSION_CODES.JELLY_BEAN)
public class FlutterRenderer implements TextureRegistry {

  private final FlutterJNI flutterJNI;
  private final AtomicLong nextTextureId = new AtomicLong(0L);
  private RenderSurface renderSurface;

  public FlutterRenderer(@NonNull FlutterJNI flutterJNI) {
    this.flutterJNI = flutterJNI;
  }

  public void attachToRenderSurface(@NonNull RenderSurface renderSurface) {
    // TODO(mattcarroll): determine desired behavior when attaching to an already attached renderer
    if (this.renderSurface != null) {
      detachFromRenderSurface();
    }

    this.renderSurface = renderSurface;
    this.renderSurface.attachToRenderer(this);
    this.flutterJNI.setRenderSurface(renderSurface);
  }

  public void detachFromRenderSurface() {
    // TODO(mattcarroll): determine desired behavior if we're asked to detach without first being attached
    if (this.renderSurface != null) {
      this.renderSurface.detachFromRenderer();
      this.renderSurface = null;
      surfaceDestroyed();
      this.flutterJNI.setRenderSurface(null);
    }
  }

  public void addOnFirstFrameRenderedListener(@NonNull OnFirstFrameRenderedListener listener) {
    flutterJNI.addOnFirstFrameRenderedListener(listener);
  }

  public void removeOnFirstFrameRenderedListener(@NonNull OnFirstFrameRenderedListener listener) {
    flutterJNI.removeOnFirstFrameRenderedListener(listener);
  }

  //------ START TextureRegistry IMPLEMENTATION -----
  // TODO(mattcarroll): detachFromGLContext requires API 16. Create solution for earlier APIs.
  @TargetApi(Build.VERSION_CODES.JELLY_BEAN)
  @Override
  public SurfaceTextureEntry createSurfaceTexture() {
    final SurfaceTexture surfaceTexture = new SurfaceTexture(0);
    surfaceTexture.detachFromGLContext();
    final SurfaceTextureRegistryEntry entry = new SurfaceTextureRegistryEntry(
        nextTextureId.getAndIncrement(),
        surfaceTexture
    );
    registerTexture(entry.id(), surfaceTexture);
    return entry;
  }

  final class SurfaceTextureRegistryEntry implements TextureRegistry.SurfaceTextureEntry {
    private final long id;
    private final SurfaceTexture surfaceTexture;
    private boolean released;

    SurfaceTextureRegistryEntry(long id, SurfaceTexture surfaceTexture) {
      this.id = id;
      this.surfaceTexture = surfaceTexture;

      if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
        // The callback relies on being executed on the UI thread (unsynchronised read of mNativeView
        // and also the engine code check for platform thread in Shell::OnPlatformViewMarkTextureFrameAvailable),
        // so we explicitly pass a Handler for the current thread.
        this.surfaceTexture.setOnFrameAvailableListener(onFrameListener, new Handler());
      } else {
        // Android documentation states that the listener can be called on an arbitrary thread.
        // But in practice, versions of Android that predate the newer API will call the listener
        // on the thread where the SurfaceTexture was constructed.
        this.surfaceTexture.setOnFrameAvailableListener(onFrameListener);
      }
    }

    private SurfaceTexture.OnFrameAvailableListener onFrameListener = new SurfaceTexture.OnFrameAvailableListener() {
      @Override
      public void onFrameAvailable(SurfaceTexture texture) {
        if (released) {
          // Even though we make sure to unregister the callback before releasing, as of Android O
          // SurfaceTexture has a data race when accessing the callback, so the callback may
          // still be called by a stale reference after released==true and mNativeView==null.
          return;
        }
        markTextureFrameAvailable(id);
      }
    };

    @Override
    public SurfaceTexture surfaceTexture() {
      return surfaceTexture;
    }

    @Override
    public long id() {
      return id;
    }

    @Override
    public void release() {
      if (released) {
        return;
      }
      surfaceTexture.release();
      unregisterTexture(id);
      released = true;
    }
  }
  //------ END TextureRegistry IMPLEMENTATION ----

  // TODO(mattcarroll): describe the native behavior that this invokes
  public void surfaceCreated(Surface surface) {
    flutterJNI.onSurfaceCreated(surface);
  }

  // TODO(mattcarroll): describe the native behavior that this invokes
  public void surfaceChanged(int width, int height) {
    flutterJNI.onSurfaceChanged(width, height);
  }

  // TODO(mattcarroll): describe the native behavior that this invokes
  public void surfaceDestroyed() {
    flutterJNI.onSurfaceDestroyed();
  }

  // TODO(mattcarroll): describe the native behavior that this invokes
  public void setViewportMetrics(@NonNull ViewportMetrics viewportMetrics) {
    flutterJNI.setViewportMetrics(
        viewportMetrics.devicePixelRatio,
        viewportMetrics.width,
        viewportMetrics.height,
        viewportMetrics.paddingTop,
        viewportMetrics.paddingRight,
        viewportMetrics.paddingBottom,
        viewportMetrics.paddingLeft,
        viewportMetrics.viewInsetTop,
        viewportMetrics.viewInsetRight,
        viewportMetrics.viewInsetBottom,
        viewportMetrics.viewInsetLeft
    );
  }

  // TODO(mattcarroll): describe the native behavior that this invokes
  public Bitmap getBitmap() {
    return flutterJNI.getBitmap();
  }

  // TODO(mattcarroll): describe the native behavior that this invokes
  public void dispatchPointerDataPacket(ByteBuffer buffer, int position) {
    flutterJNI.dispatchPointerDataPacket(buffer, position);
  }

  // TODO(mattcarroll): describe the native behavior that this invokes
  private void registerTexture(long textureId, SurfaceTexture surfaceTexture) {
    flutterJNI.registerTexture(textureId, surfaceTexture);
  }

  // TODO(mattcarroll): describe the native behavior that this invokes
  private void markTextureFrameAvailable(long textureId) {
    flutterJNI.markTextureFrameAvailable(textureId);
  }

  // TODO(mattcarroll): describe the native behavior that this invokes
  private void unregisterTexture(long textureId) {
    flutterJNI.unregisterTexture(textureId);
  }

  // TODO(mattcarroll): describe the native behavior that this invokes
  public boolean isSoftwareRenderingEnabled() {
    return FlutterJNI.nativeGetIsSoftwareRenderingEnabled();
  }

  // TODO(mattcarroll): describe the native behavior that this invokes
  public void setAccessibilityFeatures(int flags) {
    flutterJNI.setAccessibilityFeatures(flags);
  }

  // TODO(mattcarroll): describe the native behavior that this invokes
  public void setSemanticsEnabled(boolean enabled) {
    flutterJNI.setSemanticsEnabled(enabled);
  }

  // TODO(mattcarroll): describe the native behavior that this invokes
  public void dispatchSemanticsAction(int id,
                                      int action,
                                      ByteBuffer args,
                                      int argsPosition) {
    flutterJNI.dispatchSemanticsAction(
        id,
        action,
        args,
        argsPosition
    );
  }

  /**
   * Delegate used in conjunction with a {@link FlutterRenderer} to create an interactive Flutter
   * UI.
   *
   * A {@code RenderSurface} is responsible for carrying out behaviors that are needed by a
   * corresponding {@link FlutterRenderer}.
   *
   * A {@code RenderSurface} also receives callbacks for important events, e.g.,
   * {@link #onFirstFrameRendered()}.
   */
  public interface RenderSurface {
    /**
     * Invoked by the owner of this {@code RenderSurface} when it wants to begin rendering
     * a Flutter UI to this {@code RenderSurface}.
     *
     * The details of how rendering is handled is an implementation detail.
     */
    void attachToRenderer(@NonNull FlutterRenderer renderer);

    /**
     * Invoked by the owner of this {@code RenderSurface} when it no longer wants to render
     * a Flutter UI to this {@code RenderSurface}.
     *
     * This method will cease any on-going rendering from Flutter to this {@code RenderSurface}.
     */
    void detachFromRenderer();

    /**
     * The {@link FlutterRenderer} corresponding to this {@code RenderSurface} has painted its
     * first frame since being initialized.
     *
     * "Initialized" refers to Flutter engine initialization, not the first frame after attaching
     * to the {@link FlutterRenderer}. Therefore, the first frame may have already rendered by
     * the time a {@code RenderSurface} has called {@link #attachToRenderSurface(RenderSurface)}
     * on a {@link FlutterRenderer}. In such a situation, {@code #onFirstFrameRendered()} will
     * never be called.
     */
    void onFirstFrameRendered();
  }

  /**
   * Mutable data structure that holds all viewport metrics properties that Flutter cares about.
   *
   * All distance measurements, e.g., width, height, padding, viewInsets, are measured in device
   * pixels, not logical pixels.
   */
  public static final class ViewportMetrics {
    public float devicePixelRatio = 1.0f;
    public int width = 0;
    public int height = 0;
    public int paddingTop = 0;
    public int paddingRight = 0;
    public int paddingBottom = 0;
    public int paddingLeft = 0;
    public int viewInsetTop = 0;
    public int viewInsetRight = 0;
    public int viewInsetBottom = 0;
    public int viewInsetLeft = 0;
  }
}
