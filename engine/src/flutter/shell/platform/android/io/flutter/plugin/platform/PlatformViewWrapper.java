// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugin.platform;

import static android.content.ComponentCallbacks2.TRIM_MEMORY_COMPLETE;

import android.annotation.SuppressLint;
import android.annotation.TargetApi;
import android.content.Context;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Matrix;
import android.graphics.PorterDuff;
import android.graphics.Rect;
import android.graphics.SurfaceTexture;
import android.os.Build;
import android.view.MotionEvent;
import android.view.Surface;
import android.view.View;
import android.view.ViewParent;
import android.view.ViewTreeObserver;
import android.view.accessibility.AccessibilityEvent;
import android.widget.FrameLayout;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.annotation.VisibleForTesting;
import io.flutter.Log;
import io.flutter.embedding.android.AndroidTouchProcessor;
import io.flutter.util.ViewUtils;
import io.flutter.view.TextureRegistry;
import java.util.concurrent.atomic.AtomicLong;

/**
 * Wraps a platform view to intercept gestures and project this view onto a {@link SurfaceTexture}.
 *
 * <p>An Android platform view is composed by the engine using a {@code TextureLayer}. The view is
 * embeded to the Android view hierarchy like a normal view, but it's projected onto a {@link
 * SurfaceTexture}, so it can be efficiently composed by the engine.
 *
 * <p>Since the view is in the Android view hierarchy, keyboard and accessibility interactions
 * behave normally.
 */
@TargetApi(23)
class PlatformViewWrapper extends FrameLayout {
  private static final String TAG = "PlatformViewWrapper";

  private int prevLeft;
  private int prevTop;
  private int left;
  private int top;
  private int bufferWidth;
  private int bufferHeight;
  private SurfaceTexture tx;
  private Surface surface;
  private AndroidTouchProcessor touchProcessor;

  @Nullable @VisibleForTesting ViewTreeObserver.OnGlobalFocusChangeListener activeFocusListener;
  private final AtomicLong pendingFramesCount = new AtomicLong(0L);

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
          // ComponentCallbacks2.TRIM_MEMORY_COMPLETE}, the Android system releases the underlying
          // surface. If we continue to use the surface (e.g., call lockHardwareCanvas), a crash
          // occurs, and we found that this crash appeared on Android10 and above.
          // See https://github.com/flutter/flutter/issues/103870 for more details.
          //
          // Here our workaround is to recreate the surface before using it.
          if (level == TRIM_MEMORY_COMPLETE && Build.VERSION.SDK_INT >= 29) {
            shouldRecreateSurfaceForLowMemory = true;
          }
        }
      };

  private void onFrameProduced() {
    if (Build.VERSION.SDK_INT == 29) {
      pendingFramesCount.incrementAndGet();
    }
  }

  private void recreateSurfaceIfNeeded() {
    if (shouldRecreateSurfaceForLowMemory) {
      if (surface != null) {
        surface.release();
      }
      surface = createSurface(tx);
      shouldRecreateSurfaceForLowMemory = false;
    }
  }

  private boolean shouldDrawToSurfaceNow() {
    if (Build.VERSION.SDK_INT == 29) {
      return pendingFramesCount.get() <= 0L;
    }
    return true;
  }

  public PlatformViewWrapper(@NonNull Context context) {
    super(context);
    setWillNotDraw(false);
  }

  public PlatformViewWrapper(
      @NonNull Context context, @NonNull TextureRegistry.SurfaceTextureEntry textureEntry) {
    this(context);
    textureEntry.setOnFrameConsumedListener(frameConsumedListener);
    textureEntry.setOnTrimMemoryListener(trimMemoryListener);
    setTexture(textureEntry.surfaceTexture());
  }

  /**
   * Sets the touch processor that allows to intercept gestures.
   *
   * @param newTouchProcessor The touch processor.
   */
  public void setTouchProcessor(@Nullable AndroidTouchProcessor newTouchProcessor) {
    touchProcessor = newTouchProcessor;
  }

  /**
   * Sets the texture where the view is projected onto.
   *
   * <p>{@link PlatformViewWrapper} doesn't take ownership of the {@link SurfaceTexture}. As a
   * result, the caller is responsible for releasing the texture.
   *
   * <p>{@link io.flutter.view.TextureRegistry} is responsible for creating and registering textures
   * in the engine. Therefore, the engine is responsible for also releasing the texture.
   *
   * @param newTx The texture where the view is projected onto.
   */
  @SuppressLint("NewApi")
  public void setTexture(@Nullable SurfaceTexture newTx) {
    if (Build.VERSION.SDK_INT < 23) {
      Log.e(
          TAG,
          "Platform views cannot be displayed below API level 23. "
              + "You can prevent this issue by setting `minSdkVersion: 23` in build.gradle.");
      return;
    }

    tx = newTx;

    if (bufferWidth > 0 && bufferHeight > 0) {
      tx.setDefaultBufferSize(bufferWidth, bufferHeight);
    }

    if (surface != null) {
      surface.release();
    }
    surface = createSurface(newTx);

    // Fill the entire canvas with a transparent color.
    // As a result, the background color of the platform view container is displayed
    // to the user until the platform view draws its first frame.
    final Canvas canvas = surface.lockHardwareCanvas();
    try {
      canvas.drawColor(Color.TRANSPARENT, PorterDuff.Mode.CLEAR);
      onFrameProduced();
    } finally {
      surface.unlockCanvasAndPost(canvas);
    }
  }

  @NonNull
  @VisibleForTesting
  protected Surface createSurface(@NonNull SurfaceTexture tx) {
    return new Surface(tx);
  }

  /** Returns the texture where the view is projected. */
  @Nullable
  public SurfaceTexture getTexture() {
    return tx;
  }

  /**
   * Sets the layout parameters for this view.
   *
   * @param params The new parameters.
   */
  public void setLayoutParams(@NonNull FrameLayout.LayoutParams params) {
    super.setLayoutParams(params);

    left = params.leftMargin;
    top = params.topMargin;
  }

  /**
   * Sets the size of the image buffer.
   *
   * @param width The width of the screen buffer.
   * @param height The height of the screen buffer.
   */
  public void setBufferSize(int width, int height) {
    bufferWidth = width;
    bufferHeight = height;
    if (tx != null) {
      tx.setDefaultBufferSize(width, height);
    }
  }

  /** Returns the image buffer width. */
  public int getBufferWidth() {
    return bufferWidth;
  }

  /** Returns the image buffer height. */
  public int getBufferHeight() {
    return bufferHeight;
  }

  /** Releases the surface. */
  public void release() {
    // Don't release the texture.
    tx = null;
    if (surface != null) {
      surface.release();
      surface = null;
    }
  }

  @Override
  public boolean onInterceptTouchEvent(@NonNull MotionEvent event) {
    return true;
  }

  @Override
  public boolean requestSendAccessibilityEvent(View child, AccessibilityEvent event) {
    final View embeddedView = getChildAt(0);
    if (embeddedView != null
        && embeddedView.getImportantForAccessibility()
            == View.IMPORTANT_FOR_ACCESSIBILITY_NO_HIDE_DESCENDANTS) {
      return false;
    }
    // Forward the request only if the embedded view is in the Flutter accessibility tree.
    // The embedded view may be ignored when the framework doesn't populate a SemanticNode
    // for the current platform view.
    // See AccessibilityBridge for more.
    return super.requestSendAccessibilityEvent(child, event);
  }

  /** Used on Android O+, {@link invalidateChildInParent} used for previous versions. */
  @SuppressLint("NewApi")
  @Override
  public void onDescendantInvalidated(@NonNull View child, @NonNull View target) {
    super.onDescendantInvalidated(child, target);
    invalidate();
  }

  @Override
  public ViewParent invalidateChildInParent(int[] location, Rect dirty) {
    invalidate();
    return super.invalidateChildInParent(location, dirty);
  }

  @Override
  @SuppressLint("NewApi")
  public void draw(Canvas canvas) {
    if (surface == null) {
      super.draw(canvas);
      Log.e(TAG, "Platform view cannot be composed without a surface.");
      return;
    }
    if (!surface.isValid()) {
      Log.e(TAG, "Invalid surface. The platform view cannot be displayed.");
      return;
    }
    if (tx == null || tx.isReleased()) {
      Log.e(TAG, "Invalid texture. The platform view cannot be displayed.");
      return;
    }
    // We've observed on Android Q that we have to wait for the consumer of {@link SurfaceTexture}
    // to consume the last image before continuing to draw, otherwise subsequent calls to
    // {@code dequeueBuffer} to request a free buffer from the {@link BufferQueue} will fail.
    // See https://github.com/flutter/flutter/issues/98722
    if (!shouldDrawToSurfaceNow()) {
      // If there are still frames that are not consumed, we will draw them next time.
      invalidate();
    } else {
      // We try to recreate the surface before using it to avoid the crash:
      // https://github.com/flutter/flutter/issues/103870
      recreateSurfaceIfNeeded();

      // Override the canvas that this subtree of views will use to draw.
      final Canvas surfaceCanvas = surface.lockHardwareCanvas();
      try {
        // Clear the current pixels in the canvas.
        // This helps when a WebView renders an HTML document with transparent background.
        surfaceCanvas.drawColor(Color.TRANSPARENT, PorterDuff.Mode.CLEAR);
        super.draw(surfaceCanvas);
        onFrameProduced();
      } finally {
        surface.unlockCanvasAndPost(surfaceCanvas);
      }
    }
  }

  @Override
  @SuppressLint("ClickableViewAccessibility")
  public boolean onTouchEvent(@NonNull MotionEvent event) {
    if (touchProcessor == null) {
      return super.onTouchEvent(event);
    }
    final Matrix screenMatrix = new Matrix();
    switch (event.getAction()) {
      case MotionEvent.ACTION_DOWN:
        prevLeft = left;
        prevTop = top;
        screenMatrix.postTranslate(left, top);
        break;
      case MotionEvent.ACTION_MOVE:
        // While the view is dragged, use the left and top positions as
        // they were at the moment the touch event fired.
        screenMatrix.postTranslate(prevLeft, prevTop);
        prevLeft = left;
        prevTop = top;
        break;
      case MotionEvent.ACTION_UP:
      default:
        screenMatrix.postTranslate(left, top);
        break;
    }
    return touchProcessor.onTouchEvent(event, screenMatrix);
  }

  public void setOnDescendantFocusChangeListener(@NonNull OnFocusChangeListener userFocusListener) {
    unsetOnDescendantFocusChangeListener();
    final ViewTreeObserver observer = getViewTreeObserver();
    if (observer.isAlive() && activeFocusListener == null) {
      activeFocusListener =
          new ViewTreeObserver.OnGlobalFocusChangeListener() {
            @Override
            public void onGlobalFocusChanged(View oldFocus, View newFocus) {
              userFocusListener.onFocusChange(
                  PlatformViewWrapper.this, ViewUtils.childHasFocus(PlatformViewWrapper.this));
            }
          };
      observer.addOnGlobalFocusChangeListener(activeFocusListener);
    }
  }

  public void unsetOnDescendantFocusChangeListener() {
    final ViewTreeObserver observer = getViewTreeObserver();
    if (observer.isAlive() && activeFocusListener != null) {
      final ViewTreeObserver.OnGlobalFocusChangeListener currFocusListener = activeFocusListener;
      activeFocusListener = null;
      observer.removeOnGlobalFocusChangeListener(currFocusListener);
    }
  }
}
