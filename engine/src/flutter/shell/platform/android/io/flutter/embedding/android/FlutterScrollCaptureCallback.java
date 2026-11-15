// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.embedding.android;

import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.PorterDuff;
import android.graphics.Rect;
import android.os.CancellationSignal;
import android.view.ScrollCaptureCallback;
import android.view.ScrollCaptureSession;
import android.view.Surface;
import android.view.View;
import androidx.annotation.NonNull;
import androidx.annotation.RequiresApi;
import androidx.annotation.VisibleForTesting;
import io.flutter.Build.API_LEVELS;
import io.flutter.Log;
import io.flutter.embedding.engine.systemchannels.ScrollCaptureChannel;
import java.util.function.Consumer;

/**
 * A {@link ScrollCaptureCallback} that lets Android's scrolling screenshots ("Capture more")
 * capture the primary vertically scrollable content of a {@link FlutterView}.
 *
 * <p>Android can only detect scrollable content in native {@link View}s by default. Flutter renders
 * its whole UI into a single surface, so this callback asks the framework over the {@link
 * ScrollCaptureChannel} where the scrollable content is, scrolls it on request, and copies the
 * rendered pixels into the capture session.
 */
@RequiresApi(API_LEVELS.API_31)
class FlutterScrollCaptureCallback implements ScrollCaptureCallback {
  private static final String TAG = "FlutterScrollCapture";

  /**
   * The time to wait after the framework has produced a frame before copying its pixels, to give
   * the raster thread time to present it.
   *
   * <p>This matches the default delay Android uses when capturing native scrolling views.
   */
  @VisibleForTesting static final long POST_SCROLL_DELAY_MILLIS = 60L;

  /** Copies the pixels currently rendered by Flutter. */
  interface PixelCopier {
    /**
     * Copies the pixels in {@code source}, in the coordinates of the {@link FlutterView}, into
     * {@code destination}, which has the same size as {@code source}, and then calls {@code onDone}
     * on the main thread with whether the copy succeeded.
     */
    void copyPixels(
        @NonNull Rect source, @NonNull Bitmap destination, @NonNull Consumer<Boolean> onDone);
  }

  @NonNull private final View view;
  @NonNull private final ScrollCaptureChannel channel;
  @NonNull private final PixelCopier pixelCopier;

  private boolean sessionStarted = false;

  FlutterScrollCaptureCallback(
      @NonNull View view, @NonNull ScrollCaptureChannel channel, @NonNull PixelCopier pixelCopier) {
    this.view = view;
    this.channel = channel;
    this.pixelCopier = pixelCopier;
  }

  @Override
  public void onScrollCaptureSearch(
      @NonNull CancellationSignal signal, @NonNull Consumer<Rect> onReady) {
    if (!view.isShown()) {
      onReady.accept(new Rect());
      return;
    }
    channel.search(
        bounds -> {
          if (signal.isCanceled()) {
            return;
          }
          onReady.accept(clipToView(bounds));
        });
  }

  @Override
  public void onScrollCaptureStart(
      @NonNull ScrollCaptureSession session,
      @NonNull CancellationSignal signal,
      @NonNull Runnable onReady) {
    sessionStarted = true;
    // If the framework cannot find the scrollable content anymore, the first image request will
    // fail, which ends the session.
    channel.start(
        bounds -> {
          if (signal.isCanceled()) {
            return;
          }
          onReady.run();
        });
  }

  @Override
  public void onScrollCaptureImageRequest(
      @NonNull ScrollCaptureSession session,
      @NonNull CancellationSignal signal,
      @NonNull Rect captureArea,
      @NonNull Consumer<Rect> onComplete) {
    channel.scrollTo(
        captureArea.top,
        captureArea.bottom,
        scrollDelta -> {
          if (signal.isCanceled()) {
            return;
          }
          if (scrollDelta == null) {
            onComplete.accept(new Rect());
            return;
          }
          final Rect scrollBounds = session.getScrollBounds();
          // The part of the scroll bounds that is currently visible, relative to the scroll
          // bounds at the start of the session.
          final Rect visibleArea =
              new Rect(0, scrollDelta, scrollBounds.width(), scrollDelta + scrollBounds.height());
          final Rect availableArea = new Rect(captureArea);
          if (!availableArea.intersect(visibleArea)) {
            // The requested area is beyond the end of the content.
            onComplete.accept(new Rect());
            return;
          }
          // The same area in the coordinates of the view.
          final Rect source = new Rect(availableArea);
          source.offset(scrollBounds.left, scrollBounds.top - scrollDelta);
          view.postDelayed(
              () -> capture(session, signal, source, availableArea, onComplete),
              POST_SCROLL_DELAY_MILLIS);
        });
  }

  @Override
  public void onScrollCaptureEnd(@NonNull Runnable onReady) {
    if (!sessionStarted) {
      onReady.run();
      return;
    }
    sessionStarted = false;
    channel.end(onReady);
  }

  private void capture(
      @NonNull ScrollCaptureSession session,
      @NonNull CancellationSignal signal,
      @NonNull Rect source,
      @NonNull Rect availableArea,
      @NonNull Consumer<Rect> onComplete) {
    if (signal.isCanceled()) {
      return;
    }
    final Bitmap bitmap =
        Bitmap.createBitmap(source.width(), source.height(), Bitmap.Config.ARGB_8888);
    pixelCopier.copyPixels(
        source,
        bitmap,
        success -> {
          if (signal.isCanceled()) {
            return;
          }
          if (success && drawToSurface(session.getSurface(), bitmap)) {
            onComplete.accept(availableArea);
          } else {
            onComplete.accept(new Rect());
          }
        });
  }

  private static boolean drawToSurface(@NonNull Surface surface, @NonNull Bitmap bitmap) {
    try {
      final Canvas canvas = surface.lockHardwareCanvas();
      try {
        canvas.drawColor(Color.TRANSPARENT, PorterDuff.Mode.CLEAR);
        canvas.drawBitmap(bitmap, 0, 0, null);
      } finally {
        surface.unlockCanvasAndPost(canvas);
      }
      return true;
    } catch (IllegalStateException | IllegalArgumentException e) {
      // The session's surface has been released.
      Log.w(TAG, "Unable to draw scroll capture image: " + e);
      return false;
    }
  }

  @NonNull
  private Rect clipToView(Rect bounds) {
    if (bounds == null || !bounds.intersect(0, 0, view.getWidth(), view.getHeight())) {
      return new Rect();
    }
    return bounds;
  }
}
