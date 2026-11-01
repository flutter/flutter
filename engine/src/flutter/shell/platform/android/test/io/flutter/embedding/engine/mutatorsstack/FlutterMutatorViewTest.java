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

  @Test
  public void pushStretchEffect_storesFinalStretchEffect() {
    final FlutterMutatorsStack stack = new FlutterMutatorsStack();
    assertNull(stack.getFinalStretchEffect());

    stack.pushStretchEffect(0.15f, -0.25f, 0.7f, 10.0f, 20.0f, 310.0f, 620.0f);
    final FlutterMutatorsStack.FlutterStretchEffect stretch = stack.getFinalStretchEffect();
    assertNotNull(stretch);
    assertEquals(0.15f, stretch.getOverscrollX(), 1e-5f);
    assertEquals(-0.25f, stretch.getOverscrollY(), 1e-5f);
    assertEquals(0.7f, stretch.getInterpolationStrength(), 1e-5f);
    assertEquals(10.0f, stretch.getRect().left, 1e-5f);
    assertEquals(20.0f, stretch.getRect().top, 1e-5f);
    assertEquals(310.0f, stretch.getRect().right, 1e-5f);
    assertEquals(620.0f, stretch.getRect().bottom, 1e-5f);
  }

  @Test
  public void computeStretchedPosition_matchesOverscrollFormula() {
    // At overscroll = 0, position is unchanged.
    assertEquals(0.25f, FlutterMutatorView.computeStretchedPosition(0.25f, 0.0f, 0.7f), 1e-5f);

    // Positive overscroll pins the leading edge (0.0) and stretches interior points forward.
    assertEquals(0.0f, FlutterMutatorView.computeStretchedPosition(0.0f, 0.3f, 0.7f), 1e-5f);
    final float stretchedMid = FlutterMutatorView.computeStretchedPosition(0.5f, 0.3f, 0.7f);
    assertTrue(stretchedMid > 0.5f);

    // Negative overscroll pins the trailing edge (1.0) and pulls interior points backward.
    assertEquals(1.0f, FlutterMutatorView.computeStretchedPosition(1.0f, -0.3f, 0.7f), 1e-5f);
    final float pulledMid = FlutterMutatorView.computeStretchedPosition(0.5f, -0.3f, 0.7f);
    assertTrue(pulledMid < 0.5f);
  }

  @Test
  public void computeStretchedRect_leavesOutOfBoundsEdgesAtIdentity() {
    final FlutterMutatorsStack stack = new FlutterMutatorsStack();
    stack.pushStretchEffect(0.2f, 0.3f, 0.7f, 0.0f, 0.0f, 300.0f, 600.0f);
    final FlutterMutatorsStack.FlutterStretchEffect stretch = stack.getFinalStretchEffect();
    assertNotNull(stretch);

    // Left (-20) and top (-40) are outside [0, 300] x [0, 600] and must remain at identity,
    // while right (150 -> norm 0.5) and bottom (300 -> norm 0.5) are inside and stretched.
    final android.graphics.RectF rect =
        FlutterMutatorView.computeStretchedRect(-20, -40, 170, 340, stretch);
    assertEquals(-20.0f, rect.left, 1e-4f);
    assertEquals(-40.0f, rect.top, 1e-4f);
    assertEquals(
        FlutterMutatorView.computeStretchedPosition(0.5f, 0.2f, 0.7f) * 300.0f, rect.right, 1e-4f);
    assertEquals(
        FlutterMutatorView.computeStretchedPosition(0.5f, 0.3f, 0.7f) * 600.0f, rect.bottom, 1e-4f);
  }

  @Test
  @Config(sdk = 31)
  public void readyToDisplay_appliesMatrixTransformFallbackBelowApi33() {
    final AndroidTouchProcessor touchProcessor = mock(AndroidTouchProcessor.class);
    final FlutterMutatorView view = new FlutterMutatorView(ctx, 1.0f, touchProcessor);
    final FlutterMutatorsStack stack = new FlutterMutatorsStack();
    stack.pushStretchEffect(0.0f, 0.3f, 0.7f, 0.0f, 0.0f, 300.0f, 600.0f);

    view.readyToDisplay(stack, /*left=*/ 50, /*top=*/ 100, /*width=*/ 200, /*height=*/ 200);
    assertTrue(view.isUsingMatrixStretchFallback());
    final FrameLayout.LayoutParams layoutParams = (FrameLayout.LayoutParams) view.getLayoutParams();
    assertEquals(50, layoutParams.leftMargin);
    assertTrue(layoutParams.topMargin > 100);
    assertEquals(200, layoutParams.width);
    assertTrue(layoutParams.height > 200);

    // Verify dispatchDraw(Canvas) applies the non-identity fallback matrix when stretched on API <
    // 33.
    final android.graphics.Canvas canvas = mock(android.graphics.Canvas.class);
    view.dispatchDraw(canvas);
    final ArgumentCaptor<Matrix> matrixCaptor = ArgumentCaptor.forClass(Matrix.class);
    verify(canvas).concat(matrixCaptor.capture());
    assertFalse(matrixCaptor.getValue().isIdentity());
  }

  @Test
  @Config(sdk = 34)
  public void readyToDisplay_appliesMatrixTransformFallbackForSurfaceViewChild() {
    final AndroidTouchProcessor touchProcessor = mock(AndroidTouchProcessor.class);
    final FlutterMutatorView view = new FlutterMutatorView(ctx, 1.0f, touchProcessor);
    final android.view.SurfaceView surfaceView = new android.view.SurfaceView(ctx);
    view.addView(surfaceView);

    final FlutterMutatorsStack stack = new FlutterMutatorsStack();
    stack.pushStretchEffect(0.0f, 0.3f, 0.7f, 0.0f, 0.0f, 300.0f, 600.0f);

    surfaceView.setScaleX(1.25f);
    surfaceView.setScaleY(0.75f);
    surfaceView.setPivotX(12.0f);
    surfaceView.setPivotY(34.0f);

    view.readyToDisplay(stack, /*left=*/ 50, /*top=*/ 100, /*width=*/ 200, /*height=*/ 200);
    assertTrue(surfaceView.getScaleY() > 1.0f);

    // Restoring to idle restores the child's pre-existing scale and pivot.
    final FlutterMutatorsStack idleStack = new FlutterMutatorsStack();
    view.readyToDisplay(idleStack, /*left=*/ 50, /*top=*/ 100, /*width=*/ 200, /*height=*/ 200);
    assertEquals(1.25f, surfaceView.getScaleX(), 1e-5f);
    assertEquals(0.75f, surfaceView.getScaleY(), 1e-5f);
    assertEquals(12.0f, surfaceView.getPivotX(), 1e-5f);
    assertEquals(34.0f, surfaceView.getPivotY(), 1e-5f);
  }

  @Test
  @Config(sdk = 34)
  public void getOrCreateStretchShader_isIsolatedPerMutatorViewInstance() {
    final AndroidTouchProcessor touchProcessor = mock(AndroidTouchProcessor.class);
    final FlutterMutatorView view1 = new FlutterMutatorView(ctx, 1.0f, touchProcessor);
    final FlutterMutatorView view2 = new FlutterMutatorView(ctx, 1.0f, touchProcessor);
    assertNotNull(view1.getOrCreateStretchShader());
    assertNotNull(view2.getOrCreateStretchShader());
    assertNotSame(view1.getOrCreateStretchShader(), view2.getOrCreateStretchShader());
  }

  @Test
  @Config(sdk = 34)
  public void draw_clipsWhenContainerTransformedAndNotStretched() {
    final AndroidTouchProcessor touchProcessor = mock(AndroidTouchProcessor.class);
    final FlutterMutatorView view = new FlutterMutatorView(ctx, 1.0f, touchProcessor);
    final FlutterMutatorsStack stack = new FlutterMutatorsStack();
    final Matrix scaleMatrix = new Matrix();
    scaleMatrix.setScale(1.5f, 1.5f);
    final float[] scaleValues = new float[9];
    scaleMatrix.getValues(scaleValues);
    stack.pushTransform(scaleValues);
    stack.pushClipRect(0, 0, 200, 200);

    view.readyToDisplay(stack, /*left=*/ 0, /*top=*/ 0, /*width=*/ 200, /*height=*/ 200);
    final android.graphics.Canvas canvas = mock(android.graphics.Canvas.class);
    view.draw(canvas);
    verify(canvas, atLeastOnce()).clipPath(any());
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
