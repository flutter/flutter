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
import androidx.annotation.Nullable;
import androidx.annotation.RequiresApi;
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
 *
 * <p>Content that Flutter paints over the scrollable content (for example, a floating action
 * button) is part of every captured image, as it would be for a native view drawn over a scrolling
 * view. Apps can opt out of scrolling screenshots with {@link View#setScrollCaptureHint(int)}{@code
 * (View.SCROLL_CAPTURE_HINT_EXCLUDE)} on the {@link FlutterView}.
 */
@RequiresApi(API_LEVELS.API_31)
class FlutterScrollCaptureCallback implements ScrollCaptureCallback {
  private static final String TAG = "FlutterScrollCapture";

  /** Captures the frame most recently rendered by Flutter. */
  interface FrameCapturer {
    /**
     * Returns the last frame that Flutter rendered, which has the size of the {@link FlutterView},
     * or {@code null} if it is not available. The caller recycles the returned bitmap.
     */
    @Nullable
    Bitmap captureFrame();
  }

  /** The state of a capture session, which is no longer current once the session has ended. */
  private static final class Session {
    /** Whether the framework is capturing the same content that was found by the search. */
    boolean isUsable = false;
  }

  @NonNull private final View view;
  @NonNull private final ScrollCaptureChannel channel;
  @NonNull private final FrameCapturer frameCapturer;

  @Nullable private Session currentSession;

  FlutterScrollCaptureCallback(
      @NonNull View view,
      @NonNull ScrollCaptureChannel channel,
      @NonNull FrameCapturer frameCapturer) {
    this.view = view;
    this.channel = channel;
    this.frameCapturer = frameCapturer;
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
    final Session captureSession = new Session();
    currentSession = captureSession;
    channel.start(
        bounds -> {
          if (signal.isCanceled() || captureSession != currentSession) {
            return;
          }
          // If the content has moved or changed since the search, the images would not match the
          // scroll bounds, so the first image request fails, which ends the session.
          captureSession.isUsable = session.getScrollBounds().equals(clipToView(bounds));
          onReady.run();
        });
  }

  @Override
  public void onScrollCaptureImageRequest(
      @NonNull ScrollCaptureSession session,
      @NonNull CancellationSignal signal,
      @NonNull Rect captureArea,
      @NonNull Consumer<Rect> onComplete) {
    final Session captureSession = currentSession;
    if (captureSession == null || !captureSession.isUsable) {
      onComplete.accept(new Rect());
      return;
    }
    channel.scrollTo(
        captureArea.top,
        captureArea.bottom,
        scrollDelta -> {
          if (signal.isCanceled() || captureSession != currentSession) {
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
          // The framework replies once the frame showing the requested area has been submitted
          // for rasterization, and the engine rasterizes frames in order before taking the
          // screenshot, so the captured frame shows the requested area.
          if (drawToSurface(session.getSurface(), source)) {
            onComplete.accept(availableArea);
          } else {
            onComplete.accept(new Rect());
          }
        });
  }

  @Override
  public void onScrollCaptureEnd(@NonNull Runnable onReady) {
    if (currentSession == null) {
      onReady.run();
      return;
    }
    currentSession = null;
    channel.end(onReady);
  }

  /**
   * Ends the current capture session, if any, for example because the {@link FlutterView} is
   * detached from its engine. Pending requests of the session are ignored.
   */
  void dispose() {
    if (currentSession != null) {
      currentSession = null;
      channel.end(() -> {});
    }
  }

  /**
   * Draws the part of the last rendered frame within {@code source}, in the coordinates of the
   * view, at the origin of {@code surface}.
   */
  private boolean drawToSurface(@NonNull Surface surface, @NonNull Rect source) {
    final Bitmap frame = frameCapturer.captureFrame();
    if (frame == null) {
      return false;
    }
    try {
      if (frame.getWidth() != view.getWidth() || frame.getHeight() != view.getHeight()) {
        // The frame does not correspond to the current size of the view.
        return false;
      }
      final Canvas canvas = surface.lockHardwareCanvas();
      try {
        canvas.drawColor(Color.TRANSPARENT, PorterDuff.Mode.CLEAR);
        canvas.drawBitmap(frame, source, new Rect(0, 0, source.width(), source.height()), null);
      } finally {
        surface.unlockCanvasAndPost(canvas);
      }
      return true;
    } catch (IllegalStateException | IllegalArgumentException e) {
      // The session's surface has been released, or could not be drawn to.
      Log.w(TAG, "Unable to draw scroll capture image: " + e);
      return false;
    } finally {
      frame.recycle();
    }
  }

  @NonNull
  private Rect clipToView(@Nullable Rect bounds) {
    if (bounds == null || !bounds.intersect(0, 0, view.getWidth(), view.getHeight())) {
      return new Rect();
    }
    return bounds;
  }
}
