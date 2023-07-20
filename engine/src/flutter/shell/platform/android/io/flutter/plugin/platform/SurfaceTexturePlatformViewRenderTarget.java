package io.flutter.plugin.platform;

import static android.content.ComponentCallbacks2.TRIM_MEMORY_COMPLETE;

import android.annotation.TargetApi;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.PorterDuff;
import android.graphics.SurfaceTexture;
import android.os.Build;
import android.view.Surface;
import io.flutter.Log;
import io.flutter.view.TextureRegistry;
import io.flutter.view.TextureRegistry.SurfaceTextureEntry;
import java.util.concurrent.atomic.AtomicLong;

@TargetApi(26)
public class SurfaceTexturePlatformViewRenderTarget implements PlatformViewRenderTarget {
  private static final String TAG = "SurfaceTexturePlatformViewRenderTarget";

  private final AtomicLong pendingFramesCount = new AtomicLong(0L);

  private void onFrameProduced() {
    if (Build.VERSION.SDK_INT == 29) {
      pendingFramesCount.incrementAndGet();
    }
  }

  private final SurfaceTextureEntry surfaceTextureEntry;

  private SurfaceTexture surfaceTexture;
  private Surface surface;
  private int bufferWidth = 0;
  private int bufferHeight = 0;

  private final TextureRegistry.OnFrameConsumedListener frameConsumedListener =
      new TextureRegistry.OnFrameConsumedListener() {
        @Override
        public void onFrameConsumed() {
          if (Build.VERSION.SDK_INT == 29) {
            pendingFramesCount.decrementAndGet();
          }
        }
      };

  private boolean shouldRecreateSurfaceForLowMemory = false;
  private final TextureRegistry.OnTrimMemoryListener trimMemoryListener =
      new TextureRegistry.OnTrimMemoryListener() {
        @Override
        public void onTrimMemory(int level) {
          // When a memory pressure warning is received and the level equal {@code
          // ComponentCallbacks2.TRIM_MEMORY_COMPLETE}, the Android system releases the
          // underlying
          // surface. If we continue to use the surface (e.g., call lockHardwareCanvas), a
          // crash
          // occurs, and we found that this crash appeared on Android10 and above.
          // See https://github.com/flutter/flutter/issues/103870 for more details.
          //
          // Here our workaround is to recreate the surface before using it.
          if (level == TRIM_MEMORY_COMPLETE && Build.VERSION.SDK_INT >= 29) {
            shouldRecreateSurfaceForLowMemory = true;
          }
        }
      };

  private void recreateSurfaceIfNeeded() {
    if (!shouldRecreateSurfaceForLowMemory) {
      return;
    }
    if (surface != null) {
      surface.release();
      surface = null;
    }
    surface = createSurface();
    shouldRecreateSurfaceForLowMemory = false;
  }

  protected Surface createSurface() {
    return new Surface(surfaceTexture);
  }

  private void init() {
    if (bufferWidth > 0 && bufferHeight > 0) {
      surfaceTexture.setDefaultBufferSize(bufferWidth, bufferHeight);
    }
    if (surface != null) {
      surface.release();
      surface = null;
    }
    surface = createSurface();

    // Fill the entire canvas with a transparent color.
    // As a result, the background color of the platform view container is displayed
    // to the user until the platform view draws its first frame.
    final Canvas canvas = lockHardwareCanvas();
    try {
      canvas.drawColor(Color.TRANSPARENT, PorterDuff.Mode.CLEAR);
    } finally {
      unlockCanvasAndPost(canvas);
    }
  }

  /** Implementation of PlatformViewRenderTarget */
  public SurfaceTexturePlatformViewRenderTarget(SurfaceTextureEntry surfaceTextureEntry) {
    if (Build.VERSION.SDK_INT < 23) {
      throw new UnsupportedOperationException(
          "Platform views cannot be displayed below API level 23"
              + "You can prevent this issue by setting `minSdkVersion: 23` in build.gradle.");
    }
    this.surfaceTextureEntry = surfaceTextureEntry;
    this.surfaceTexture = surfaceTextureEntry.surfaceTexture();
    surfaceTextureEntry.setOnFrameConsumedListener(frameConsumedListener);
    surfaceTextureEntry.setOnTrimMemoryListener(trimMemoryListener);
    init();
  }

  public Canvas lockHardwareCanvas() {
    recreateSurfaceIfNeeded();

    // We've observed on Android Q that we have to wait for the consumer of {@link
    // SurfaceTexture}
    // to consume the last image before continuing to draw, otherwise subsequent
    // calls to
    // {@code dequeueBuffer} to request a free buffer from the {@link BufferQueue}
    // will fail.
    // See https://github.com/flutter/flutter/issues/98722
    if (Build.VERSION.SDK_INT == 29 && pendingFramesCount.get() > 0L) {
      return null;
    }
    if (surfaceTexture == null || surfaceTexture.isReleased()) {
      Log.e(TAG, "Invalid RenderTarget: null or already released SurfaceTexture");
      return null;
    }
    onFrameProduced();
    return surface.lockHardwareCanvas();
  }

  public void unlockCanvasAndPost(Canvas canvas) {
    surface.unlockCanvasAndPost(canvas);
  }

  public void resize(int width, int height) {
    bufferWidth = width;
    bufferHeight = height;
    if (surfaceTexture != null) {
      surfaceTexture.setDefaultBufferSize(bufferWidth, bufferHeight);
    }
  }

  public int getWidth() {
    return bufferWidth;
  }

  public int getHeight() {
    return bufferHeight;
  }

  public long getId() {
    return this.surfaceTextureEntry.id();
  }

  public boolean isReleased() {
    return surfaceTexture == null;
  }

  public void release() {
    // Don't release the texture.
    surfaceTexture = null;
    if (surface != null) {
      surface.release();
      surface = null;
    }
  }

  public Surface getSurface() {
    recreateSurfaceIfNeeded();
    return surface;
  }
}
