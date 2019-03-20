// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.embedding.android;

import android.content.Context;
import android.support.annotation.NonNull;
import android.support.annotation.Nullable;
import android.util.AttributeSet;
import android.util.Log;
import android.view.SurfaceHolder;
import android.view.SurfaceView;

import io.flutter.embedding.engine.renderer.FlutterRenderer;

/**
 * Paints a Flutter UI on a {@link android.view.Surface}.
 *
 * To begin rendering a Flutter UI, the owner of this {@code FlutterSurfaceView} must invoke
 * {@link #attachToRenderer(FlutterRenderer)} with the desired {@link FlutterRenderer}.
 *
 * To stop rendering a Flutter UI, the owner of this {@code FlutterSurfaceView} must invoke
 * {@link #detachFromRenderer()}.
 *
 * A {@code FlutterSurfaceView} is intended for situations where a developer needs to render
 * a Flutter UI, but does not require any keyboard input, gesture input, accessibility
 * integrations or any other interactivity beyond rendering. If standard interactivity is
 * desired, consider using a {@link FlutterView} which provides all of these behaviors and
 * utilizes a {@code FlutterSurfaceView} internally.
 */
public class FlutterSurfaceView extends SurfaceView implements FlutterRenderer.RenderSurface {
  private static final String TAG = "FlutterSurfaceView";

  private boolean isSurfaceAvailableForRendering = false;
  private boolean isAttachedToFlutterRenderer = false;
  @Nullable
  private FlutterRenderer flutterRenderer;

  // Connects the {@code Surface} beneath this {@code SurfaceView} with Flutter's native code.
  // Callbacks are received by this Object and then those messages are forwarded to our
  // FlutterRenderer, and then on to the JNI bridge over to native Flutter code.
  private final SurfaceHolder.Callback surfaceCallback = new SurfaceHolder.Callback() {
    @Override
    public void surfaceCreated(SurfaceHolder holder) {
      Log.d(TAG, "SurfaceHolder.Callback.surfaceCreated()");
      isSurfaceAvailableForRendering = true;

      if (isAttachedToFlutterRenderer) {
        Log.d(TAG, "Already attached to renderer. Notifying of surface creation.");
        connectSurfaceToRenderer();
      }
    }

    @Override
    public void surfaceChanged(SurfaceHolder holder, int format, int width, int height) {
      Log.d(TAG, "SurfaceHolder.Callback.surfaceChanged()");
      if (isAttachedToFlutterRenderer) {
        changeSurfaceSize(width, height);
      }
    }

    @Override
    public void surfaceDestroyed(SurfaceHolder holder) {
      Log.d(TAG, "SurfaceHolder.Callback.surfaceDestroyed()");
      isSurfaceAvailableForRendering = false;

      if (isAttachedToFlutterRenderer) {
        disconnectSurfaceFromRenderer();
      }
    }
  };

  /**
   * Constructs a {@code FlutterSurfaceView} programmatically, without any XML attributes.
   */
  public FlutterSurfaceView(Context context) {
    this(context, null);
  }

  /**
   * Constructs a {@code FlutterSurfaceView} in an XML-inflation-compliant manner.
   */
  public FlutterSurfaceView(Context context, AttributeSet attrs) {
    super(context, attrs);
    init();
  }

  private void init() {
    // Grab a reference to our underlying Surface and register callbacks with that Surface so we
    // can monitor changes and forward those changes on to native Flutter code.
    getHolder().addCallback(surfaceCallback);
  }

  /**
   * Invoked by the owner of this {@code FlutterSurfaceView} when it wants to begin rendering
   * a Flutter UI to this {@code FlutterSurfaceView}.
   *
   * If an Android {@link android.view.Surface} is available, this method will give that
   * {@link android.view.Surface} to the given {@link FlutterRenderer} to begin rendering
   * Flutter's UI to this {@code FlutterSurfaceView}.
   *
   * If no Android {@link android.view.Surface} is available yet, this {@code FlutterSurfaceView}
   * will wait until a {@link android.view.Surface} becomes available and then give that
   * {@link android.view.Surface} to the given {@link FlutterRenderer} to begin rendering
   * Flutter's UI to this {@code FlutterSurfaceView}.
   */
  public void attachToRenderer(@NonNull FlutterRenderer flutterRenderer) {
    Log.d(TAG, "attachToRenderer");
    if (this.flutterRenderer != null) {
      this.flutterRenderer.detachFromRenderSurface();
    }

    this.flutterRenderer = flutterRenderer;
    isAttachedToFlutterRenderer = true;

    // If we're already attached to an Android window then we're now attached to both a renderer
    // and the Android window. We can begin rendering now.
    if (isSurfaceAvailableForRendering) {
      Log.d(TAG, "Surface is available for rendering. Connecting.");
      connectSurfaceToRenderer();
    }
  }

  /**
   * Invoked by the owner of this {@code FlutterSurfaceView} when it no longer wants to render
   * a Flutter UI to this {@code FlutterSurfaceView}.
   *
   * This method will cease any on-going rendering from Flutter to this {@code FlutterSurfaceView}.
   */
  public void detachFromRenderer() {
    if (flutterRenderer != null) {
      // If we're attached to an Android window then we were rendering a Flutter UI. Now that
      // this FlutterSurfaceView is detached from the FlutterRenderer, we need to stop rendering.
      if (getWindowToken() != null) {
        disconnectSurfaceFromRenderer();
      }

      flutterRenderer = null;
      isAttachedToFlutterRenderer = false;
    } else {
      Log.w(TAG, "detachFromRenderer() invoked when no FlutterRenderer was attached.");
    }
  }

  // FlutterRenderer and getSurfaceTexture() must both be non-null.
  private void connectSurfaceToRenderer() {
    if (flutterRenderer == null || getHolder() == null) {
      throw new IllegalStateException("connectSurfaceToRenderer() should only be called when flutterRenderer and getHolder() are non-null.");
    }

    flutterRenderer.surfaceCreated(getHolder().getSurface());
  }

  // FlutterRenderer must be non-null.
  private void changeSurfaceSize(int width, int height) {
    if (flutterRenderer == null) {
      throw new IllegalStateException("changeSurfaceSize() should only be called when flutterRenderer is non-null.");
    }

    flutterRenderer.surfaceChanged(width, height);
  }

  // FlutterRenderer must be non-null.
  private void disconnectSurfaceFromRenderer() {
    if (flutterRenderer == null) {
      throw new IllegalStateException("disconnectSurfaceFromRenderer() should only be called when flutterRenderer is non-null.");
    }

    flutterRenderer.surfaceDestroyed();
  }

  @Override
  public void onFirstFrameRendered() {
    // TODO(mattcarroll): decide where this method should live and what it needs to do.
    Log.d(TAG, "onFirstFrameRendered()");
  }
}
