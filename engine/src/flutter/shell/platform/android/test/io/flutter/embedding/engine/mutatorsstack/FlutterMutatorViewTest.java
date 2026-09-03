// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.embedding.engine.mutatorsstack;

import static android.view.View.OnFocusChangeListener;
import static junit.framework.TestCase.*;
import static org.mockito.Mockito.*;

import android.content.Context;
import android.graphics.Matrix;
import android.view.MotionEvent;
import android.view.View;
import android.view.ViewGroup;
import android.view.ViewTreeObserver;
import android.view.accessibility.AccessibilityEvent;
import android.widget.FrameLayout;
import androidx.test.core.app.ApplicationProvider;
import androidx.test.ext.junit.runners.AndroidJUnit4;
import io.flutter.embedding.android.AndroidTouchProcessor;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.mockito.ArgumentCaptor;
import org.robolectric.annotation.Config;
import org.robolectric.annotation.Implementation;
import org.robolectric.annotation.Implements;

@RunWith(AndroidJUnit4.class)
public class FlutterMutatorViewTest {
  private final Context ctx = ApplicationProvider.getApplicationContext();

  @Test
  public void canDragViews() {
    final AndroidTouchProcessor touchProcessor = mock(AndroidTouchProcessor.class);
    final FlutterMutatorView view = new FlutterMutatorView(ctx, 1.0f, touchProcessor);
    final FlutterMutatorsStack mutatorStack = mock(FlutterMutatorsStack.class);

    assertTrue(view.onInterceptTouchEvent(mock(MotionEvent.class)));

    {
      view.readyToDisplay(mutatorStack, /*left=*/ 1, /*top=*/ 2, /*width=*/ 0, /*height=*/ 0);
      view.layout(1, 2, 1, 2);
      view.onTouchEvent(MotionEvent.obtain(0, 0, MotionEvent.ACTION_DOWN, 0.0f, 0.0f, 0));
      final ArgumentCaptor<Matrix> matrixCaptor = ArgumentCaptor.forClass(Matrix.class);
      verify(touchProcessor).onTouchEvent(any(), matrixCaptor.capture());

      final Matrix screenMatrix = new Matrix();
      screenMatrix.postTranslate(1, 2);
      assertEquals(matrixCaptor.getValue(), screenMatrix);
    }

    reset(touchProcessor);

    {
      view.readyToDisplay(mutatorStack, /*left=*/ 3, /*top=*/ 4, /*width=*/ 0, /*height=*/ 0);
      view.layout(3, 4, 3, 4);
      view.onTouchEvent(MotionEvent.obtain(0, 0, MotionEvent.ACTION_MOVE, 0.0f, 0.0f, 0));
      final ArgumentCaptor<Matrix> matrixCaptor = ArgumentCaptor.forClass(Matrix.class);
      verify(touchProcessor).onTouchEvent(any(), matrixCaptor.capture());

      final Matrix screenMatrix = new Matrix();
      screenMatrix.postTranslate(3, 4);
      assertEquals(matrixCaptor.getValue(), screenMatrix);
    }

    reset(touchProcessor);

    {
      view.readyToDisplay(mutatorStack, /*left=*/ 5, /*top=*/ 6, /*width=*/ 0, /*height=*/ 0);
      view.layout(5, 6, 5, 6);
      view.onTouchEvent(MotionEvent.obtain(0, 0, MotionEvent.ACTION_MOVE, 0.0f, 0.0f, 0));
      final ArgumentCaptor<Matrix> matrixCaptor = ArgumentCaptor.forClass(Matrix.class);
      verify(touchProcessor).onTouchEvent(any(), matrixCaptor.capture());

      final Matrix screenMatrix = new Matrix();
      screenMatrix.postTranslate(5, 6);
      assertEquals(matrixCaptor.getValue(), screenMatrix);
    }

    reset(touchProcessor);

    {
      view.readyToDisplay(mutatorStack, /*left=*/ 7, /*top=*/ 8, /*width=*/ 0, /*height=*/ 0);
      view.layout(7, 8, 7, 8);
      view.onTouchEvent(MotionEvent.obtain(0, 0, MotionEvent.ACTION_DOWN, 0.0f, 0.0f, 0));
      final ArgumentCaptor<Matrix> matrixCaptor = ArgumentCaptor.forClass(Matrix.class);
      verify(touchProcessor).onTouchEvent(any(), matrixCaptor.capture());

      final Matrix screenMatrix = new Matrix();
      screenMatrix.postTranslate(7, 8);
      assertEquals(matrixCaptor.getValue(), screenMatrix);
    }
  }

  @Test
  public void focusChangeListener_hasFocus() {
    final ViewTreeObserver viewTreeObserver = mock(ViewTreeObserver.class);
    when(viewTreeObserver.isAlive()).thenReturn(true);

    final FlutterMutatorView view =
        new FlutterMutatorView(ctx) {
          @Override
          public ViewTreeObserver getViewTreeObserver() {
            return viewTreeObserver;
          }

          @Override
          public boolean hasFocus() {
            return true;
          }
        };

    final OnFocusChangeListener focusListener = mock(OnFocusChangeListener.class);
    view.setOnDescendantFocusChangeListener(focusListener);

    final ArgumentCaptor<ViewTreeObserver.OnGlobalFocusChangeListener> focusListenerCaptor =
        ArgumentCaptor.forClass(ViewTreeObserver.OnGlobalFocusChangeListener.class);
    verify(viewTreeObserver).addOnGlobalFocusChangeListener(focusListenerCaptor.capture());

    focusListenerCaptor.getValue().onGlobalFocusChanged(null, null);
    verify(focusListener).onFocusChange(view, true);
  }

  @Test
  public void focusChangeListener_doesNotHaveFocus() {
    final ViewTreeObserver viewTreeObserver = mock(ViewTreeObserver.class);
    when(viewTreeObserver.isAlive()).thenReturn(true);

    final FlutterMutatorView view =
        new FlutterMutatorView(ctx) {
          @Override
          public ViewTreeObserver getViewTreeObserver() {
            return viewTreeObserver;
          }

          @Override
          public boolean hasFocus() {
            return false;
          }
        };

    final OnFocusChangeListener focusListener = mock(OnFocusChangeListener.class);
    view.setOnDescendantFocusChangeListener(focusListener);

    final ArgumentCaptor<ViewTreeObserver.OnGlobalFocusChangeListener> focusListenerCaptor =
        ArgumentCaptor.forClass(ViewTreeObserver.OnGlobalFocusChangeListener.class);
    verify(viewTreeObserver).addOnGlobalFocusChangeListener(focusListenerCaptor.capture());

    focusListenerCaptor.getValue().onGlobalFocusChanged(null, null);
    verify(focusListener).onFocusChange(view, false);
  }

  @Test
  public void focusChangeListener_viewTreeObserverIsAliveFalseDoesNotThrow() {
    final FlutterMutatorView view =
        new FlutterMutatorView(ctx) {
          @Override
          public ViewTreeObserver getViewTreeObserver() {
            final ViewTreeObserver viewTreeObserver = mock(ViewTreeObserver.class);
            when(viewTreeObserver.isAlive()).thenReturn(false);
            return viewTreeObserver;
          }
        };
    view.setOnDescendantFocusChangeListener(mock(OnFocusChangeListener.class));
  }

  @Test
  public void setOnDescendantFocusChangeListener_keepsSingleListener() {
    final ViewTreeObserver viewTreeObserver = mock(ViewTreeObserver.class);
    when(viewTreeObserver.isAlive()).thenReturn(true);

    final FlutterMutatorView view =
        new FlutterMutatorView(ctx) {
          @Override
          public ViewTreeObserver getViewTreeObserver() {
            return viewTreeObserver;
          }
        };

    assertNull(view.activeFocusListener);

    view.setOnDescendantFocusChangeListener(mock(OnFocusChangeListener.class));
    assertNotNull(view.activeFocusListener);

    final ViewTreeObserver.OnGlobalFocusChangeListener activeFocusListener =
        view.activeFocusListener;

    view.setOnDescendantFocusChangeListener(mock(OnFocusChangeListener.class));
    assertNotNull(view.activeFocusListener);

    verify(viewTreeObserver, times(1)).removeOnGlobalFocusChangeListener(activeFocusListener);
  }

  @Test
  public void unsetOnDescendantFocusChangeListener_removesActiveListener() {
    final ViewTreeObserver viewTreeObserver = mock(ViewTreeObserver.class);
    when(viewTreeObserver.isAlive()).thenReturn(true);

    final FlutterMutatorView view =
        new FlutterMutatorView(ctx) {
          @Override
          public ViewTreeObserver getViewTreeObserver() {
            return viewTreeObserver;
          }
        };

    assertNull(view.activeFocusListener);

    view.setOnDescendantFocusChangeListener(mock(OnFocusChangeListener.class));
    assertNotNull(view.activeFocusListener);

    final ViewTreeObserver.OnGlobalFocusChangeListener activeFocusListener =
        view.activeFocusListener;

    view.unsetOnDescendantFocusChangeListener();
    assertNull(view.activeFocusListener);

    view.unsetOnDescendantFocusChangeListener();
    verify(viewTreeObserver, times(1)).removeOnGlobalFocusChangeListener(activeFocusListener);
  }

  @Test
  @Config(
      shadows = {
        ShadowViewGroup.class,
      })
  public void ignoreAccessibilityEvents() {
    final FlutterMutatorView wrapperView = new FlutterMutatorView(ctx);

    final View embeddedView = mock(View.class);
    wrapperView.addView(embeddedView);

    when(embeddedView.getImportantForAccessibility())
        .thenReturn(View.IMPORTANT_FOR_ACCESSIBILITY_NO_HIDE_DESCENDANTS);
    final boolean eventSent =
        wrapperView.requestSendAccessibilityEvent(embeddedView, mock(AccessibilityEvent.class));
    assertFalse(eventSent);
  }

  @Test
  public void requestsUnbufferedDispatchOnMoveOnly_afterFlutterWonGesture() {
    final AndroidTouchProcessor touchProcessor = mock(AndroidTouchProcessor.class);
    final MotionEvent[] lastRequestedEvent = new MotionEvent[1];
    final FlutterMutatorView view =
        new FlutterMutatorView(ctx, 1.0f, touchProcessor) {
          @Override
          void requestUnbuffered(MotionEvent event) {
            lastRequestedEvent[0] = event;
          }
        };

    // Before Flutter wins the arena: touches are buffered.
    final MotionEvent downEvent =
        MotionEvent.obtain(100, 100, MotionEvent.ACTION_DOWN, 0.0f, 0.0f, 0);
    view.onTouchEvent(downEvent);
    assertTrue(view.isGestureActive());
    assertEquals(100, view.getCurrentDownTime());
    assertNull(lastRequestedEvent[0]);

    final MotionEvent moveEvent1 =
        MotionEvent.obtain(100, 101, MotionEvent.ACTION_MOVE, 0.0f, 0.0f, 0);
    view.onTouchEvent(moveEvent1);
    assertNull(lastRequestedEvent[0]);

    // Mismatched gestureId does not set flutterWonGesture.
    view.onFlutterWonGesture(50);
    assertFalse(view.getFlutterWonGesture());

    // Matching gestureId sets flutterWonGesture.
    view.onFlutterWonGesture(100);
    assertTrue(view.getFlutterWonGesture());

    // Subsequent move events are unbuffered.
    final MotionEvent moveEvent2 =
        MotionEvent.obtain(100, 102, MotionEvent.ACTION_MOVE, 10.0f, 10.0f, 0);
    view.onTouchEvent(moveEvent2);
    assertEquals(moveEvent2, lastRequestedEvent[0]);
    assertFalse(view.getFlutterWonGesture());

    lastRequestedEvent[0] = null;

    // Subsequent move in the same gesture does not redundantly request unbuffered dispatch.
    final MotionEvent moveEvent3 =
        MotionEvent.obtain(100, 103, MotionEvent.ACTION_MOVE, 11.0f, 11.0f, 0);
    view.onTouchEvent(moveEvent3);
    assertNull(lastRequestedEvent[0]);

    // Up event terminates gesture.
    final MotionEvent upEvent =
        MotionEvent.obtain(100, 104, MotionEvent.ACTION_UP, 11.0f, 11.0f, 0);
    view.onTouchEvent(upEvent);
    assertFalse(view.isGestureActive());
    assertNull(lastRequestedEvent[0]);
    assertFalse(view.getFlutterWonGesture());

    // Subsequent late onFlutterWonGesture after UP is ignored.
    view.onFlutterWonGesture(100);
    assertFalse(view.getFlutterWonGesture());

    // Subsequent gesture starts buffered again.
    final MotionEvent moveEvent4 =
        MotionEvent.obtain(200, 201, MotionEvent.ACTION_MOVE, 12.0f, 12.0f, 0);
    view.onTouchEvent(moveEvent4);
    assertNull(lastRequestedEvent[0]);
  }

  @Test
  public void resetsFlutterWonGestureOnCancelAndDown() {
    final AndroidTouchProcessor touchProcessor = mock(AndroidTouchProcessor.class);
    final FlutterMutatorView view = new FlutterMutatorView(ctx, 1.0f, touchProcessor);

    // Before any gesture is active, onFlutterWonGesture is ignored.
    view.onFlutterWonGesture(100);
    assertFalse(view.getFlutterWonGesture());

    // Gesture 1 starts.
    final MotionEvent downEvent1 =
        MotionEvent.obtain(100, 100, MotionEvent.ACTION_DOWN, 0.0f, 0.0f, 0);
    view.onTouchEvent(downEvent1);
    assertTrue(view.isGestureActive());
    assertEquals(100, view.getCurrentDownTime());

    view.onFlutterWonGesture(100);
    assertTrue(view.getFlutterWonGesture());

    // CANCEL resets flutterWonGesture and marks gesture inactive.
    final MotionEvent cancelEvent =
        MotionEvent.obtain(100, 101, MotionEvent.ACTION_CANCEL, 0.0f, 0.0f, 0);
    view.onTouchEvent(cancelEvent);
    assertFalse(view.getFlutterWonGesture());
    assertFalse(view.isGestureActive());

    // Delayed onFlutterWonGesture for Gesture 1 is ignored because gesture is inactive.
    view.onFlutterWonGesture(100);
    assertFalse(view.getFlutterWonGesture());

    // Gesture 2 starts with downTime 200.
    final MotionEvent downEvent2 =
        MotionEvent.obtain(200, 200, MotionEvent.ACTION_DOWN, 0.0f, 0.0f, 0);
    view.onTouchEvent(downEvent2);
    assertTrue(view.isGestureActive());
    assertEquals(200, view.getCurrentDownTime());
    assertFalse(view.getFlutterWonGesture());

    // Late onFlutterWonGesture from Gesture 1 arriving during Gesture 2 is rejected.
    view.onFlutterWonGesture(100);
    assertFalse(view.getFlutterWonGesture());

    // Matching onFlutterWonGesture for Gesture 2 is accepted.
    view.onFlutterWonGesture(200);
    assertTrue(view.getFlutterWonGesture());
  }

  @Implements(ViewGroup.class)
  public static class ShadowViewGroup extends org.robolectric.shadows.ShadowViewGroup {
    @Implementation
    protected boolean requestSendAccessibilityEvent(View child, AccessibilityEvent event) {
      return true;
    }
  }

  @Implements(FrameLayout.class)
  public static class ShadowFrameLayout
      extends io.flutter.plugin.platform.PlatformViewWrapperTest.ShadowViewGroup {}
}
