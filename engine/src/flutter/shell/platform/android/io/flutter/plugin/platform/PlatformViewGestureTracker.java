// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugin.platform;

import android.view.MotionEvent;
import android.view.View;
import androidx.annotation.NonNull;
import androidx.annotation.VisibleForTesting;

/**
 * Tracks gesture state for platform views and requests unbuffered motion event dispatch when
 * Flutter wins the gesture arena for an active gesture.
 */
public class PlatformViewGestureTracker {
  private boolean flutterWonGesture = false;
  private boolean isGestureActive = false;
  private long currentDownTime = -1;

  /** Callback interface for requesting unbuffered dispatch on a target {@link View}. */
  public interface UnbufferedRequester {
    void requestUnbuffered(@NonNull MotionEvent event);
  }

  /**
   * Informs the tracker that Flutter has won the gesture arena for the active touch sequence.
   *
   * <p>Subsequent {@link MotionEvent#ACTION_MOVE} events will request unbuffered dispatch on the
   * target view to minimize latency and prevent stutter for Flutter-driven gestures (e.g.,
   * scrolling).
   *
   * @param gestureId The identifier (downTime) of the gesture that Flutter won. Unbuffered dispatch
   *     is only enabled if this matches the currently active gesture's downTime.
   */
  public void onFlutterWonGesture(long gestureId) {
    if (isGestureActive && currentDownTime == gestureId) {
      flutterWonGesture = true;
    }
  }

  /**
   * Updates tracking state for the given {@link MotionEvent}.
   *
   * <p>If Flutter has won the gesture arena and the event is {@link MotionEvent#ACTION_MOVE}, this
   * invokes {@link View#requestUnbufferedDispatch(MotionEvent)} on the target view.
   *
   * @param event The motion event being processed.
   * @param targetView The view on which to request unbuffered dispatch.
   */
  public void onTouchEvent(@NonNull MotionEvent event, @NonNull View targetView) {
    onTouchEvent(event, targetView::requestUnbufferedDispatch);
  }

  /**
   * Updates tracking state for the given {@link MotionEvent} using a custom {@link
   * UnbufferedRequester}.
   *
   * @param event The motion event being processed.
   * @param requester The callback invoked to request unbuffered dispatch.
   */
  public void onTouchEvent(@NonNull MotionEvent event, @NonNull UnbufferedRequester requester) {
    switch (event.getActionMasked()) {
      case MotionEvent.ACTION_DOWN:
        isGestureActive = true;
        currentDownTime = event.getDownTime();
        flutterWonGesture = false;
        break;
      case MotionEvent.ACTION_MOVE:
        if (flutterWonGesture) {
          requester.requestUnbuffered(event);
          flutterWonGesture = false;
        }
        break;
      case MotionEvent.ACTION_UP:
      case MotionEvent.ACTION_CANCEL:
        isGestureActive = false;
        flutterWonGesture = false;
        currentDownTime = -1;
        break;
    }
  }

  @VisibleForTesting
  public boolean getFlutterWonGesture() {
    return flutterWonGesture;
  }

  @VisibleForTesting
  public boolean isGestureActive() {
    return isGestureActive;
  }

  @VisibleForTesting
  public long getCurrentDownTime() {
    return currentDownTime;
  }
}
