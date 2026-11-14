// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.embedding.engine.mutatorsstack;

import static android.view.View.OnFocusChangeListener;
import static junit.framework.TestCase.*;
import static org.mockito.Mockito.*;

import android.content.Context;
import android.graphics.Matrix;
import android.view.Gravity;
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
  public void onTouchEvent_delegatesToGestureTrackerAndRequestsUnbufferedOnMove() {
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

    // Matching gestureId sets flutterWonGesture.
    view.onFlutterWonGesture(100);
    assertTrue(view.getFlutterWonGesture());

    // Subsequent move event triggers unbuffered dispatch.
    final MotionEvent moveEvent =
        MotionEvent.obtain(100, 101, MotionEvent.ACTION_MOVE, 10.0f, 10.0f, 0);
    view.onTouchEvent(moveEvent);
    assertEquals(moveEvent, lastRequestedEvent[0]);
    assertFalse(view.getFlutterWonGesture());
  }

  /** Adds {@code view} to a laid out parent at the given position and size. */
  private FrameLayout layOutInParent(
      FlutterMutatorView view, FlutterMutatorsStack mutatorsStack, int left, int top) {
    final FrameLayout parent = new FrameLayout(ctx);
    parent.addView(view);
    view.readyToDisplay(mutatorsStack, left, top, 10, 10);
    parent.measure(
        View.MeasureSpec.makeMeasureSpec(100, View.MeasureSpec.EXACTLY),
        View.MeasureSpec.makeMeasureSpec(100, View.MeasureSpec.EXACTLY));
    parent.layout(0, 0, 100, 100);
    return parent;
  }

  @Test
  public void readyToDisplay_movesViewWithoutRequestingLayoutWhenSizeUnchanged() {
    final int[] scrollChangedCalls = new int[1];
    final int[] invalidateCalls = new int[1];
    final FlutterMutatorView view =
        new FlutterMutatorView(ctx) {
          @Override
          protected void onScrollChanged(int l, int t, int oldl, int oldt) {
            super.onScrollChanged(l, t, oldl, oldt);
            scrollChangedCalls[0]++;
          }

          @Override
          public void invalidate() {
            super.invalidate();
            invalidateCalls[0]++;
          }
        };
    final FlutterMutatorsStack mutatorsStack = new FlutterMutatorsStack();
    final FrameLayout parent = layOutInParent(view, mutatorsStack, 1, 2);
    assertEquals(1, view.getLeft());
    assertEquals(2, view.getTop());
    assertFalse(view.isLayoutRequested());
    invalidateCalls[0] = 0;

    view.readyToDisplay(mutatorsStack, 30, 40, 10, 10);

    // The view is moved and invalidated immediately, without a layout pass, and scroll listeners
    // are notified.
    assertFalse(view.isLayoutRequested());
    assertFalse(parent.isLayoutRequested());
    assertEquals(30, view.getLeft());
    assertEquals(40, view.getTop());
    assertEquals(40, view.getRight());
    assertEquals(50, view.getBottom());
    assertEquals(1, scrollChangedCalls[0]);
    assertEquals(1, invalidateCalls[0]);

    // Setting the same offset again does not fire onScrollChanged, but still invalidates so
    // mutator stack changes (e.g. clip or opacity) are redrawn.
    view.readyToDisplay(mutatorsStack, 30, 40, 10, 10);
    assertEquals(1, scrollChangedCalls[0]);
    assertEquals(2, invalidateCalls[0]);

    // The layout params are kept in sync, so a later layout pass keeps the position.
    final FrameLayout.LayoutParams params = (FrameLayout.LayoutParams) view.getLayoutParams();
    assertEquals(30, params.leftMargin);
    assertEquals(40, params.topMargin);
    parent.requestLayout();
    parent.measure(
        View.MeasureSpec.makeMeasureSpec(100, View.MeasureSpec.EXACTLY),
        View.MeasureSpec.makeMeasureSpec(100, View.MeasureSpec.EXACTLY));
    parent.layout(0, 0, 100, 100);
    assertEquals(30, view.getLeft());
    assertEquals(40, view.getTop());

    // Changing size still requests layout.
    view.readyToDisplay(mutatorsStack, 30, 40, 20, 20);
    assertTrue(view.isLayoutRequested());
  }

  @Test
  public void readyToDisplay_beforeLayout_onlyUpdatesLayoutParams() {
    final FlutterMutatorView view = new FlutterMutatorView(ctx);
    final FlutterMutatorsStack mutatorsStack = new FlutterMutatorsStack();
    view.setLayoutParams(new FrameLayout.LayoutParams(10, 10));

    view.readyToDisplay(mutatorsStack, 30, 40, 10, 10);

    final FrameLayout.LayoutParams params = (FrameLayout.LayoutParams) view.getLayoutParams();
    assertEquals(30, params.leftMargin);
    assertEquals(40, params.topMargin);
    assertEquals(Gravity.LEFT | Gravity.TOP, params.gravity);
    assertEquals(0, view.getLeft());
    assertEquals(0, view.getTop());
  }

  @Test
  public void readyToDisplay_whileLayoutRequested_stillMovesImmediately() {
    final FlutterMutatorView view = new FlutterMutatorView(ctx);
    final FlutterMutatorsStack mutatorsStack = new FlutterMutatorsStack();
    layOutInParent(view, mutatorsStack, 1, 2);
    view.requestLayout();
    assertTrue(view.isLayoutRequested());

    view.readyToDisplay(mutatorsStack, 30, 40, 10, 10);

    assertEquals(30, view.getLeft());
    assertEquals(40, view.getTop());
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
