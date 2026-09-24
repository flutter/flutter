// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugin.platform;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertNull;
import static org.junit.Assert.assertTrue;

import android.view.MotionEvent;
import androidx.test.ext.junit.runners.AndroidJUnit4;
import org.junit.Test;
import org.junit.runner.RunWith;

@RunWith(AndroidJUnit4.class)
public class PlatformViewGestureTrackerTest {

  @Test
  public void requestsUnbufferedDispatchOnMoveOnly_afterFlutterWonGesture() {
    final PlatformViewGestureTracker tracker = new PlatformViewGestureTracker();
    final MotionEvent[] lastRequestedEvent = new MotionEvent[1];
    final PlatformViewGestureTracker.UnbufferedRequester requester =
        event -> lastRequestedEvent[0] = event;

    // Before Flutter wins the arena: touches are buffered.
    final MotionEvent downEvent =
        MotionEvent.obtain(100, 100, MotionEvent.ACTION_DOWN, 0.0f, 0.0f, 0);
    tracker.onTouchEvent(downEvent, requester);
    assertTrue(tracker.isGestureActive());
    assertEquals(100, tracker.getCurrentDownTime());
    assertNull(lastRequestedEvent[0]);

    final MotionEvent moveEvent1 =
        MotionEvent.obtain(100, 101, MotionEvent.ACTION_MOVE, 0.0f, 0.0f, 0);
    tracker.onTouchEvent(moveEvent1, requester);
    assertNull(lastRequestedEvent[0]);

    // Mismatched gestureId does not set flutterWonGesture.
    tracker.onFlutterWonGesture(50);
    assertFalse(tracker.getFlutterWonGesture());

    // Matching gestureId sets flutterWonGesture.
    tracker.onFlutterWonGesture(100);
    assertTrue(tracker.getFlutterWonGesture());

    // Subsequent move events are unbuffered.
    final MotionEvent moveEvent2 =
        MotionEvent.obtain(100, 102, MotionEvent.ACTION_MOVE, 10.0f, 10.0f, 0);
    tracker.onTouchEvent(moveEvent2, requester);
    assertEquals(moveEvent2, lastRequestedEvent[0]);
    assertFalse(tracker.getFlutterWonGesture());

    lastRequestedEvent[0] = null;

    // Subsequent move in the same gesture does not redundantly request unbuffered dispatch.
    final MotionEvent moveEvent3 =
        MotionEvent.obtain(100, 103, MotionEvent.ACTION_MOVE, 11.0f, 11.0f, 0);
    tracker.onTouchEvent(moveEvent3, requester);
    assertNull(lastRequestedEvent[0]);

    // Up event terminates gesture.
    final MotionEvent upEvent =
        MotionEvent.obtain(100, 104, MotionEvent.ACTION_UP, 11.0f, 11.0f, 0);
    tracker.onTouchEvent(upEvent, requester);
    assertFalse(tracker.isGestureActive());
    assertNull(lastRequestedEvent[0]);
    assertFalse(tracker.getFlutterWonGesture());

    // Subsequent late onFlutterWonGesture after UP is ignored.
    tracker.onFlutterWonGesture(100);
    assertFalse(tracker.getFlutterWonGesture());

    // Subsequent gesture starts buffered again.
    final MotionEvent moveEvent4 =
        MotionEvent.obtain(200, 201, MotionEvent.ACTION_MOVE, 12.0f, 12.0f, 0);
    tracker.onTouchEvent(moveEvent4, requester);
    assertNull(lastRequestedEvent[0]);
  }

  @Test
  public void resetsFlutterWonGestureOnCancelAndDown() {
    final PlatformViewGestureTracker tracker = new PlatformViewGestureTracker();
    final MotionEvent[] lastRequestedEvent = new MotionEvent[1];
    final PlatformViewGestureTracker.UnbufferedRequester requester =
        event -> lastRequestedEvent[0] = event;

    // Before any gesture is active, onFlutterWonGesture is ignored.
    tracker.onFlutterWonGesture(100);
    assertFalse(tracker.getFlutterWonGesture());

    // Gesture 1 starts.
    final MotionEvent downEvent1 =
        MotionEvent.obtain(100, 100, MotionEvent.ACTION_DOWN, 0.0f, 0.0f, 0);
    tracker.onTouchEvent(downEvent1, requester);
    assertTrue(tracker.isGestureActive());
    assertEquals(100, tracker.getCurrentDownTime());

    tracker.onFlutterWonGesture(100);
    assertTrue(tracker.getFlutterWonGesture());

    // CANCEL resets flutterWonGesture and marks gesture inactive.
    final MotionEvent cancelEvent =
        MotionEvent.obtain(100, 101, MotionEvent.ACTION_CANCEL, 0.0f, 0.0f, 0);
    tracker.onTouchEvent(cancelEvent, requester);
    assertFalse(tracker.getFlutterWonGesture());
    assertFalse(tracker.isGestureActive());

    // Delayed onFlutterWonGesture for Gesture 1 is ignored because gesture is inactive.
    tracker.onFlutterWonGesture(100);
    assertFalse(tracker.getFlutterWonGesture());

    // Gesture 2 starts with downTime 200.
    final MotionEvent downEvent2 =
        MotionEvent.obtain(200, 200, MotionEvent.ACTION_DOWN, 0.0f, 0.0f, 0);
    tracker.onTouchEvent(downEvent2, requester);
    assertTrue(tracker.isGestureActive());
    assertEquals(200, tracker.getCurrentDownTime());
    assertFalse(tracker.getFlutterWonGesture());

    // Late onFlutterWonGesture from Gesture 1 arriving during Gesture 2 is rejected.
    tracker.onFlutterWonGesture(100);
    assertFalse(tracker.getFlutterWonGesture());

    // Matching onFlutterWonGesture for Gesture 2 is accepted.
    tracker.onFlutterWonGesture(200);
    assertTrue(tracker.getFlutterWonGesture());
  }

  @Test
  public void gestureIdZero_ignoredWhenGestureActive() {
    final PlatformViewGestureTracker tracker = new PlatformViewGestureTracker();
    final MotionEvent[] lastRequestedEvent = new MotionEvent[1];
    final PlatformViewGestureTracker.UnbufferedRequester requester =
        event -> lastRequestedEvent[0] = event;

    // Gesture starts with downTime 100.
    final MotionEvent downEvent =
        MotionEvent.obtain(100, 100, MotionEvent.ACTION_DOWN, 0.0f, 0.0f, 0);
    tracker.onTouchEvent(downEvent, requester);

    // gestureId 0 does not match downTime 100 and is ignored (fails safe to buffered dispatch).
    tracker.onFlutterWonGesture(0);
    assertFalse(tracker.getFlutterWonGesture());

    final MotionEvent moveEvent =
        MotionEvent.obtain(100, 101, MotionEvent.ACTION_MOVE, 0.0f, 0.0f, 0);
    tracker.onTouchEvent(moveEvent, requester);
    assertNull(lastRequestedEvent[0]);
  }
}
