// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.domokit.sky.shell;

import android.content.Context;
import android.view.GestureDetector;
import android.view.MotionEvent;

import org.chromium.mojom.sky.EventType;
import org.chromium.mojom.sky.GestureData;
import org.chromium.mojom.sky.InputEvent;

/**
 * Knows how to drive a GestureDetector to turn MotionEvents into Sky's
 * InputEvents.  Seems like this should not be needed.  That there must exist
 * some Android class to do most of this work for us?
 */
public class GestureProvider implements GestureDetector.OnGestureListener {
    private static final String TAG = "GestureProvider";

    /**
     * Callback interface
     */
    public interface OnGestureListener {
        void onGestureEvent(InputEvent e);
    }

    private OnGestureListener mListener;
    private GestureDetector mDetector;
    private boolean mScrolling;
    private boolean mFlinging;

    public GestureProvider(Context context, OnGestureListener listener) {
        mListener = listener;
        mDetector = new GestureDetector(context, this);
    }

    private InputEvent createGestureEvent(MotionEvent event) {
        int pointerIndex = event.getActionIndex();
        GestureData gestureData = new GestureData();
        gestureData.primaryPointer = event.getPointerId(pointerIndex);
        gestureData.x = event.getX(pointerIndex);
        gestureData.y = event.getY(pointerIndex);
        InputEvent inputEvent = new InputEvent();
        inputEvent.timeStamp = event.getEventTime();
        inputEvent.gestureData = gestureData;
        return inputEvent;
    }

    public void onTouchEvent(MotionEvent event) {
        // TODO(eseidel): I am not confident that these stops are correct.
        int maskedAction = event.getActionMasked();
        if (mScrolling && maskedAction == MotionEvent.ACTION_UP) {
            mScrolling = false;
            InputEvent inputEvent = createGestureEvent(event);
            inputEvent.type = EventType.GESTURE_SCROLL_END;
            mListener.onGestureEvent(inputEvent);
        }

        if (mFlinging && maskedAction == MotionEvent.ACTION_DOWN) {
            mFlinging = false;
            InputEvent inputEvent = createGestureEvent(event);
            inputEvent.type = EventType.GESTURE_FLING_CANCEL;
            mListener.onGestureEvent(inputEvent);
        }

        mDetector.onTouchEvent(event);
    }

    @Override
    public boolean onDown(MotionEvent event) {
        InputEvent inputEvent = createGestureEvent(event);
        inputEvent.type = EventType.GESTURE_TAP_DOWN;
        mListener.onGestureEvent(inputEvent);
        return true;
    }

    @Override
    public boolean onFling(MotionEvent e1, MotionEvent e2,
            float velocityX, float velocityY) {
        mFlinging = true;

        // Use the first event as a scroll start (for the target hit-test)
        InputEvent inputEvent = createGestureEvent(e1);
        inputEvent.gestureData.velocityX = velocityX;
        inputEvent.gestureData.velocityY = velocityY;
        inputEvent.type = EventType.GESTURE_FLING_START;

        mListener.onGestureEvent(inputEvent);
        return true;
    }

    @Override
    public void onLongPress(MotionEvent event) {
        InputEvent inputEvent = createGestureEvent(event);
        inputEvent.type = EventType.GESTURE_LONG_PRESS;
        mListener.onGestureEvent(inputEvent);
    }

    @Override
    public boolean onScroll(MotionEvent e1, MotionEvent e2, float distanceX,
            float distanceY) {
        // Use the first event as a scroll start (for the target hit-test)
        InputEvent inputEvent = createGestureEvent(e1);
        inputEvent.gestureData.dx = distanceX;
        inputEvent.gestureData.dy = -distanceY;

        // If we haven't started scrolling, send a scroll_begin.
        if (!mScrolling) {
            mScrolling = true;
            inputEvent.type = EventType.GESTURE_SCROLL_BEGIN;
            mListener.onGestureEvent(inputEvent);
        }

        inputEvent.type = EventType.GESTURE_SCROLL_UPDATE;
        mListener.onGestureEvent(inputEvent);
        return true;
    }

    @Override
    public void onShowPress(MotionEvent event) {
        InputEvent inputEvent = createGestureEvent(event);
        inputEvent.type = EventType.GESTURE_SHOW_PRESS;
        mListener.onGestureEvent(inputEvent);
    }

    @Override
    public boolean onSingleTapUp(MotionEvent event) {
        InputEvent inputEvent = createGestureEvent(event);
        inputEvent.type = EventType.GESTURE_TAP;
        mListener.onGestureEvent(inputEvent);
        return true;
    }
}