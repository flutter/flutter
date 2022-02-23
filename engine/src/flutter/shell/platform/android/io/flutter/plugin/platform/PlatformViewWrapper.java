// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugin.platform;

import android.annotation.SuppressLint;
import android.annotation.TargetApi;
import android.content.Context;
import android.graphics.BlendMode;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Matrix;
import android.graphics.Rect;
import android.graphics.SurfaceTexture;
import android.os.Build;
import android.view.MotionEvent;
import android.view.Surface;
import android.view.View;
import android.view.ViewParent;
import android.view.ViewTreeObserver;
import android.widget.FrameLayout;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.annotation.VisibleForTesting;
import io.flutter.Log;
import io.flutter.embedding.android.AndroidTouchProcessor;
import io.flutter.util.ViewUtils;

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

  public PlatformViewWrapper(@NonNull Context context) {
    super(context);
    setWillNotDraw(false);
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
      if (Build.VERSION.SDK_INT >= 29) {
        canvas.drawColor(Color.TRANSPARENT, BlendMode.CLEAR);
      } else {
        canvas.drawColor(Color.TRANSPARENT);
      }
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
    if (surface == null || !surface.isValid()) {
      Log.e(TAG, "Invalid surface. The platform view cannot be displayed.");
      return;
    }
    if (tx == null || tx.isReleased()) {
      Log.e(TAG, "Invalid texture. The platform view cannot be displayed.");
      return;
    }
    // Override the canvas that this subtree of views will use to draw.
    final Canvas surfaceCanvas = surface.lockHardwareCanvas();
    try {
      // Clear the current pixels in the canvas.
      // This helps when a WebView renders an HTML document with transparent background.
      if (Build.VERSION.SDK_INT >= 29) {
        surfaceCanvas.drawColor(Color.TRANSPARENT, BlendMode.CLEAR);
      } else {
        surfaceCanvas.drawColor(Color.TRANSPARENT);
      }
      super.draw(surfaceCanvas);
    } finally {
      surface.unlockCanvasAndPost(surfaceCanvas);
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
