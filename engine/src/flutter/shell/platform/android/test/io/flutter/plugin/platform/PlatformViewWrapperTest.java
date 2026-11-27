// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugin.platform;

import static io.flutter.Build.API_LEVELS;
import static org.junit.Assert.*;
import static org.mockito.Mockito.*;
import static org.mockito.Mockito.spy;
import static org.robolectric.Shadows.shadowOf;

import android.annotation.TargetApi;
import android.content.Context;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Matrix;
import android.os.Looper;
import android.view.Gravity;
import android.view.MotionEvent;
import android.view.Surface;
import android.view.View;
import android.view.View.OnFocusChangeListener;
import android.view.ViewGroup;
import android.view.ViewTreeObserver;
import android.view.accessibility.AccessibilityEvent;
import android.widget.FrameLayout;
import androidx.test.core.app.ApplicationProvider;
import androidx.test.ext.junit.runners.AndroidJUnit4;
import io.flutter.embedding.android.AndroidTouchProcessor;
import io.flutter.embedding.engine.renderer.FlutterRenderer;
import java.util.List;
import org.junit.After;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InOrder;
import org.robolectric.annotation.Config;
import org.robolectric.annotation.Implementation;
import org.robolectric.annotation.Implements;

@TargetApi(API_LEVELS.API_31)
@RunWith(AndroidJUnit4.class)
public class PlatformViewWrapperTest {
  private final Context ctx = ApplicationProvider.getApplicationContext();

  @After
  public void tearDown() {
    FlutterRenderer.debugDisableSurfaceClear = false;
  }

  @Test
  public void invalidateChildInParent_callsInvalidate() {
    final PlatformViewWrapper wrapper = spy(new PlatformViewWrapper(ctx));

    // Mock Android framework calls.
    wrapper.invalidateChildInParent(null, null);

    // Verify.
    verify(wrapper, times(1)).invalidate();
  }

  @Test
  public void draw_withoutSurface() {
    final PlatformViewWrapper wrapper =
        new PlatformViewWrapper(ctx) {
          @Override
          public void onDraw(Canvas canvas) {
            canvas.drawColor(Color.RED);
          }
        };
    // Test.
    final Canvas canvas = mock(Canvas.class);
    wrapper.draw(canvas);

    // Verify.
    verify(canvas, times(1)).drawColor(Color.RED);
  }

  @Test
  public void draw_withoutValidSurface() {
    FlutterRenderer.debugDisableSurfaceClear = true;
    final Surface surface = mock(Surface.class);
    when(surface.isValid()).thenReturn(false);
    final PlatformViewRenderTarget renderTarget = mock(PlatformViewRenderTarget.class);
    when(renderTarget.getSurface()).thenReturn(surface);

    final PlatformViewWrapper wrapper = new PlatformViewWrapper(ctx, renderTarget);
    final Canvas canvas = mock(Canvas.class);
    wrapper.draw(canvas);

    verify(canvas, times(0)).drawColor(Color.TRANSPARENT, android.graphics.PorterDuff.Mode.CLEAR);
  }

  @Test
  public void draw_withValidSurface() {
    FlutterRenderer.debugDisableSurfaceClear = true;
    final Canvas canvas = mock(Canvas.class);
    final Surface surface = mock(Surface.class);
    when(surface.isValid()).thenReturn(true);
    final PlatformViewRenderTarget renderTarget = mock(PlatformViewRenderTarget.class);
    when(renderTarget.getSurface()).thenReturn(surface);
    when(surface.lockHardwareCanvas()).thenReturn(canvas);
    final PlatformViewWrapper wrapper = new PlatformViewWrapper(ctx, renderTarget);

    wrapper.draw(canvas);

    verify(canvas, times(1)).drawColor(Color.TRANSPARENT, android.graphics.PorterDuff.Mode.CLEAR);
  }

  @Test
  public void draw_withValidSurface_postsFrameAfterCurrentTraversal() {
    FlutterRenderer.debugDisableSurfaceClear = true;
    final Canvas canvas = mock(Canvas.class);
    final Surface surface = mock(Surface.class);
    when(surface.isValid()).thenReturn(true);
    final PlatformViewRenderTarget renderTarget = mock(PlatformViewRenderTarget.class);
    when(renderTarget.getSurface()).thenReturn(surface);
    when(surface.lockHardwareCanvas()).thenReturn(canvas);
    final PlatformViewWrapper wrapper = new PlatformViewWrapper(ctx, renderTarget);

    wrapper.draw(canvas);

    // The frame is recorded synchronously, but posted to the render target only after the
    // current traversal.
    verify(surface, times(1)).lockHardwareCanvas();
    verify(surface, never()).unlockCanvasAndPost(any());
    verify(renderTarget, never()).scheduleFrame();

    shadowOf(Looper.getMainLooper()).idle();

    final InOrder inOrder = inOrder(surface, renderTarget);
    inOrder.verify(surface).unlockCanvasAndPost(canvas);
    inOrder.verify(renderTarget).scheduleFrame();
  }

  @Test
  public void draw_twiceInOneTraversal_postsPreviousFrameBeforeLockingAgain() {
    FlutterRenderer.debugDisableSurfaceClear = true;
    final Canvas canvas = mock(Canvas.class);
    final Surface surface = mock(Surface.class);
    when(surface.isValid()).thenReturn(true);
    final PlatformViewRenderTarget renderTarget = mock(PlatformViewRenderTarget.class);
    when(renderTarget.getSurface()).thenReturn(surface);
    when(surface.lockHardwareCanvas()).thenReturn(canvas);
    final PlatformViewWrapper wrapper = new PlatformViewWrapper(ctx, renderTarget);

    wrapper.draw(canvas);
    wrapper.draw(canvas);

    verify(surface, times(2)).lockHardwareCanvas();
    verify(surface, times(1)).unlockCanvasAndPost(canvas);

    shadowOf(Looper.getMainLooper()).idle();

    verify(surface, times(2)).unlockCanvasAndPost(canvas);
    verify(renderTarget, times(2)).scheduleFrame();
  }

  @Test
  public void resizeRenderTarget_postsPendingFrameBeforeResizing() {
    FlutterRenderer.debugDisableSurfaceClear = true;
    final Canvas canvas = mock(Canvas.class);
    final Surface surface = mock(Surface.class);
    when(surface.isValid()).thenReturn(true);
    final PlatformViewRenderTarget renderTarget = mock(PlatformViewRenderTarget.class);
    when(renderTarget.getSurface()).thenReturn(surface);
    when(surface.lockHardwareCanvas()).thenReturn(canvas);
    final PlatformViewWrapper wrapper = new PlatformViewWrapper(ctx, renderTarget);

    wrapper.draw(canvas);
    wrapper.resizeRenderTarget(200, 300);

    final InOrder inOrder = inOrder(surface, renderTarget);
    inOrder.verify(surface).unlockCanvasAndPost(canvas);
    inOrder.verify(renderTarget).scheduleFrame();
    inOrder.verify(renderTarget).resize(200, 300);

    shadowOf(Looper.getMainLooper()).idle();
    verify(surface, times(1)).unlockCanvasAndPost(canvas);
    verify(renderTarget, times(1)).scheduleFrame();
  }

  @Test
  public void release_postsPendingFrame() {
    FlutterRenderer.debugDisableSurfaceClear = true;
    final Canvas canvas = mock(Canvas.class);
    final Surface surface = mock(Surface.class);
    when(surface.isValid()).thenReturn(true);
    final PlatformViewRenderTarget renderTarget = mock(PlatformViewRenderTarget.class);
    when(renderTarget.getSurface()).thenReturn(surface);
    when(surface.lockHardwareCanvas()).thenReturn(canvas);
    final PlatformViewWrapper wrapper = new PlatformViewWrapper(ctx, renderTarget);

    wrapper.draw(canvas);
    wrapper.release();

    final InOrder inOrder = inOrder(surface, renderTarget);
    inOrder.verify(surface).unlockCanvasAndPost(canvas);
    inOrder.verify(renderTarget).release();
    verify(renderTarget, never()).scheduleFrame();

    // Nothing is posted again after release.
    shadowOf(Looper.getMainLooper()).idle();
    verify(surface, times(1)).unlockCanvasAndPost(canvas);
  }

  @Test
  public void postPendingFrame_whenUnlockThrows_doesNotScheduleFrame() {
    FlutterRenderer.debugDisableSurfaceClear = true;
    final Canvas canvas = mock(Canvas.class);
    final Surface surface = mock(Surface.class);
    when(surface.isValid()).thenReturn(true);
    final PlatformViewRenderTarget renderTarget = mock(PlatformViewRenderTarget.class);
    when(renderTarget.getSurface()).thenReturn(surface);
    when(surface.lockHardwareCanvas()).thenReturn(canvas);
    doThrow(new IllegalStateException("Surface released"))
        .when(surface)
        .unlockCanvasAndPost(canvas);
    final PlatformViewWrapper wrapper = new PlatformViewWrapper(ctx, renderTarget);

    wrapper.draw(canvas);
    shadowOf(Looper.getMainLooper()).idle();

    verify(surface, times(1)).unlockCanvasAndPost(canvas);
    verify(renderTarget, never()).scheduleFrame();
  }

  @Test
  public void onWindowVisibilityChanged_withPendingFrame_flushesPendingFrameAndResumesCleanly() {
    FlutterRenderer.debugDisableSurfaceClear = true;
    final Canvas canvas1 = mock(Canvas.class);
    final Canvas canvas2 = mock(Canvas.class);
    final Surface surface = mock(Surface.class);
    when(surface.isValid()).thenReturn(true);
    final PlatformViewRenderTarget renderTarget = mock(PlatformViewRenderTarget.class);
    when(renderTarget.getSurface()).thenReturn(surface);
    when(surface.lockHardwareCanvas()).thenReturn(canvas1, canvas2);
    final PlatformViewWrapper wrapper = new PlatformViewWrapper(ctx, renderTarget);

    wrapper.draw(canvas1);
    verify(surface, never()).unlockCanvasAndPost(any());

    // Backgrounding with a pending frame immediately unlocks and posts so no surface stays locked.
    wrapper.onWindowVisibilityChanged(View.GONE);
    verify(surface, times(1)).unlockCanvasAndPost(canvas1);
    verify(renderTarget, times(1)).scheduleFrame();

    // Idling the main looper does not re-post the already-flushed frame.
    shadowOf(Looper.getMainLooper()).idle();
    verify(surface, times(1)).unlockCanvasAndPost(canvas1);
    verify(renderTarget, times(1)).scheduleFrame();

    // Resuming and drawing a new frame before release unlocks cleanly without stale callbacks.
    wrapper.onWindowVisibilityChanged(View.VISIBLE);
    wrapper.draw(canvas2);
    wrapper.release();

    verify(surface, times(1)).unlockCanvasAndPost(canvas2);
    verify(renderTarget, times(1)).release();
    shadowOf(Looper.getMainLooper()).idle();
    verify(surface, times(1)).unlockCanvasAndPost(canvas2);
    verify(renderTarget, times(1)).scheduleFrame();
  }

  @Test
  public void draw_twoWrappersInSingleTraversal_postsBothFramesAfterTraversal() {
    FlutterRenderer.debugDisableSurfaceClear = true;
    final Canvas canvas1 = mock(Canvas.class);
    final Surface surface1 = mock(Surface.class);
    when(surface1.isValid()).thenReturn(true);
    when(surface1.lockHardwareCanvas()).thenReturn(canvas1);
    final PlatformViewRenderTarget renderTarget1 = mock(PlatformViewRenderTarget.class);
    when(renderTarget1.getSurface()).thenReturn(surface1);

    final Canvas canvas2 = mock(Canvas.class);
    final Surface surface2 = mock(Surface.class);
    when(surface2.isValid()).thenReturn(true);
    when(surface2.lockHardwareCanvas()).thenReturn(canvas2);
    final PlatformViewRenderTarget renderTarget2 = mock(PlatformViewRenderTarget.class);
    when(renderTarget2.getSurface()).thenReturn(surface2);

    final PlatformViewWrapper wrapper1 = new PlatformViewWrapper(ctx, renderTarget1);
    final PlatformViewWrapper wrapper2 = new PlatformViewWrapper(ctx, renderTarget2);

    wrapper1.draw(canvas1);
    wrapper2.draw(canvas2);

    verify(surface1, never()).unlockCanvasAndPost(any());
    verify(surface2, never()).unlockCanvasAndPost(any());

    shadowOf(Looper.getMainLooper()).idle();

    verify(surface1, times(1)).unlockCanvasAndPost(canvas1);
    verify(renderTarget1, times(1)).scheduleFrame();
    verify(surface2, times(1)).unlockCanvasAndPost(canvas2);
    verify(renderTarget2, times(1)).scheduleFrame();

    wrapper1.release();
    wrapper2.release();
    shadowOf(Looper.getMainLooper()).idle();
    verify(surface1, times(1)).unlockCanvasAndPost(canvas1);
    verify(surface2, times(1)).unlockCanvasAndPost(canvas2);
  }

  @Test
  public void focusChangeListener_hasFocus() {
    final ViewTreeObserver viewTreeObserver = mock(ViewTreeObserver.class);
    when(viewTreeObserver.isAlive()).thenReturn(true);

    final PlatformViewWrapper view =
        new PlatformViewWrapper(ctx) {
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

    final PlatformViewWrapper view =
        new PlatformViewWrapper(ctx) {
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
    final PlatformViewWrapper view =
        new PlatformViewWrapper(ctx) {
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

    final PlatformViewWrapper view =
        new PlatformViewWrapper(ctx) {
          @Override
          public ViewTreeObserver getViewTreeObserver() {
            return viewTreeObserver;
          }
        };

    assertNull(view.getActiveFocusListener());

    view.setOnDescendantFocusChangeListener(mock(OnFocusChangeListener.class));
    assertNotNull(view.getActiveFocusListener());

    final ViewTreeObserver.OnGlobalFocusChangeListener activeFocusListener =
        view.getActiveFocusListener();

    view.setOnDescendantFocusChangeListener(mock(OnFocusChangeListener.class));
    assertNotNull(view.getActiveFocusListener());

    verify(viewTreeObserver, times(1)).removeOnGlobalFocusChangeListener(activeFocusListener);
  }

  @Test
  public void unsetOnDescendantFocusChangeListener_removesActiveListener() {
    final ViewTreeObserver viewTreeObserver = mock(ViewTreeObserver.class);
    when(viewTreeObserver.isAlive()).thenReturn(true);

    final PlatformViewWrapper view =
        new PlatformViewWrapper(ctx) {
          @Override
          public ViewTreeObserver getViewTreeObserver() {
            return viewTreeObserver;
          }
        };

    assertNull(view.getActiveFocusListener());

    view.setOnDescendantFocusChangeListener(mock(OnFocusChangeListener.class));
    assertNotNull(view.getActiveFocusListener());

    final ViewTreeObserver.OnGlobalFocusChangeListener activeFocusListener =
        view.getActiveFocusListener();

    view.unsetOnDescendantFocusChangeListener();
    assertNull(view.getActiveFocusListener());

    view.unsetOnDescendantFocusChangeListener();
    verify(viewTreeObserver, times(1)).removeOnGlobalFocusChangeListener(activeFocusListener);
  }

  @Test
  @Config(
      shadows = {
        ShadowFrameLayout.class,
        ShadowViewGroup.class,
      })
  public void ignoreAccessibilityEvents() {
    final PlatformViewWrapper wrapperView = new PlatformViewWrapper(ctx);

    final View embeddedView = mock(View.class);
    wrapperView.addView(embeddedView);

    when(embeddedView.getImportantForAccessibility())
        .thenReturn(View.IMPORTANT_FOR_ACCESSIBILITY_NO_HIDE_DESCENDANTS);
    final boolean eventSent =
        wrapperView.requestSendAccessibilityEvent(embeddedView, mock(AccessibilityEvent.class));
    assertFalse(eventSent);
  }

  @Test
  @Config(
      shadows = {
        ShadowFrameLayout.class,
        ShadowViewGroup.class,
      })
  public void sendAccessibilityEvents() {
    final PlatformViewWrapper wrapperView = new PlatformViewWrapper(ctx);

    final View embeddedView = mock(View.class);
    wrapperView.addView(embeddedView);

    when(embeddedView.getImportantForAccessibility())
        .thenReturn(View.IMPORTANT_FOR_ACCESSIBILITY_YES);
    boolean eventSent =
        wrapperView.requestSendAccessibilityEvent(embeddedView, mock(AccessibilityEvent.class));
    assertTrue(eventSent);

    when(embeddedView.getImportantForAccessibility())
        .thenReturn(View.IMPORTANT_FOR_ACCESSIBILITY_AUTO);
    eventSent =
        wrapperView.requestSendAccessibilityEvent(embeddedView, mock(AccessibilityEvent.class));
    assertTrue(eventSent);
  }

  @Test
  public void onTouchEvent_delegatesToGestureTrackerAndRequestsUnbufferedOnMove() {
    final AndroidTouchProcessor touchProcessor = mock(AndroidTouchProcessor.class);
    final MotionEvent[] lastRequestedEvent = new MotionEvent[1];
    final PlatformViewWrapper view =
        new PlatformViewWrapper(ctx) {
          @Override
          void requestUnbuffered(MotionEvent event) {
            lastRequestedEvent[0] = event;
          }
        };
    view.setTouchProcessor(touchProcessor);

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

  /** Adds {@code wrapper} to a laid out parent at the given position. */
  private FrameLayout layOutInParent(PlatformViewWrapper wrapper, int left, int top) {
    final FrameLayout.LayoutParams params =
        new FrameLayout.LayoutParams(10, 10, Gravity.LEFT | Gravity.TOP);
    params.leftMargin = left;
    params.topMargin = top;
    wrapper.setLayoutParams(params);
    final FrameLayout parent = new FrameLayout(ctx);
    parent.addView(wrapper);
    parent.measure(
        View.MeasureSpec.makeMeasureSpec(100, View.MeasureSpec.EXACTLY),
        View.MeasureSpec.makeMeasureSpec(100, View.MeasureSpec.EXACTLY));
    parent.layout(0, 0, 100, 100);
    return parent;
  }

  @Test
  public void setOffset_movesViewWithoutRequestingLayout() {
    final int[] scrollChangedCalls = new int[1];
    final PlatformViewWrapper wrapper =
        new PlatformViewWrapper(ctx) {
          @Override
          protected void onScrollChanged(int l, int t, int oldl, int oldt) {
            super.onScrollChanged(l, t, oldl, oldt);
            scrollChangedCalls[0]++;
          }
        };
    final FrameLayout parent = layOutInParent(wrapper, 1, 2);
    assertEquals(1, wrapper.getLeft());
    assertEquals(2, wrapper.getTop());
    assertFalse(wrapper.isLayoutRequested());

    wrapper.setOffset(30, 40);

    // The view is moved immediately, without a layout pass, and scroll listeners are notified.
    assertFalse(wrapper.isLayoutRequested());
    assertFalse(parent.isLayoutRequested());
    assertEquals(30, wrapper.getLeft());
    assertEquals(40, wrapper.getTop());
    assertEquals(40, wrapper.getRight());
    assertEquals(50, wrapper.getBottom());
    assertEquals(1, scrollChangedCalls[0]);

    // Setting the same offset again is a no-op.
    wrapper.setOffset(30, 40);
    assertEquals(1, scrollChangedCalls[0]);

    // The layout params are kept in sync, so a later layout pass keeps the position.
    final FrameLayout.LayoutParams params = (FrameLayout.LayoutParams) wrapper.getLayoutParams();
    assertEquals(30, params.leftMargin);
    assertEquals(40, params.topMargin);
    parent.requestLayout();
    parent.measure(
        View.MeasureSpec.makeMeasureSpec(100, View.MeasureSpec.EXACTLY),
        View.MeasureSpec.makeMeasureSpec(100, View.MeasureSpec.EXACTLY));
    parent.layout(0, 0, 100, 100);
    assertEquals(30, wrapper.getLeft());
    assertEquals(40, wrapper.getTop());
  }

  @Test
  public void setOffset_beforeLayout_onlyUpdatesLayoutParams() {
    final PlatformViewWrapper wrapper = new PlatformViewWrapper(ctx);
    wrapper.setLayoutParams(new FrameLayout.LayoutParams(10, 10));

    wrapper.setOffset(30, 40);

    final FrameLayout.LayoutParams params = (FrameLayout.LayoutParams) wrapper.getLayoutParams();
    assertEquals(30, params.leftMargin);
    assertEquals(40, params.topMargin);
    assertEquals(Gravity.LEFT | Gravity.TOP, params.gravity);
    assertEquals(0, wrapper.getLeft());
    assertEquals(0, wrapper.getTop());
  }

  @Test
  public void setOffset_whileLayoutRequested_stillMovesImmediately() {
    final PlatformViewWrapper wrapper = new PlatformViewWrapper(ctx);
    layOutInParent(wrapper, 1, 2);
    wrapper.requestLayout();
    assertTrue(wrapper.isLayoutRequested());

    wrapper.setOffset(30, 40);

    assertEquals(30, wrapper.getLeft());
    assertEquals(40, wrapper.getTop());
  }

  @Test
  public void onTouchEvent_translatesByCurrentPosition() {
    final AndroidTouchProcessor touchProcessor = mock(AndroidTouchProcessor.class);
    final PlatformViewWrapper wrapper = new PlatformViewWrapper(ctx);
    wrapper.setTouchProcessor(touchProcessor);
    layOutInParent(wrapper, 5, 6);
    final ArgumentCaptor<Matrix> matrixCaptor = ArgumentCaptor.forClass(Matrix.class);

    final MotionEvent downEvent =
        MotionEvent.obtain(100, 100, MotionEvent.ACTION_DOWN, 1.0f, 1.0f, 0);
    wrapper.onTouchEvent(downEvent);

    // The view moves (e.g. the list scrolls) in the middle of the gesture.
    wrapper.setOffset(15, 26);
    final MotionEvent moveEvent =
        MotionEvent.obtain(100, 101, MotionEvent.ACTION_MOVE, 2.0f, 2.0f, 0);
    wrapper.onTouchEvent(moveEvent);

    verify(touchProcessor, times(2)).onTouchEvent(any(MotionEvent.class), matrixCaptor.capture());
    final List<Matrix> matrices = matrixCaptor.getAllValues();
    final float[] values = new float[9];
    matrices.get(0).getValues(values);
    assertEquals(5f, values[Matrix.MTRANS_X], 0f);
    assertEquals(6f, values[Matrix.MTRANS_Y], 0f);
    matrices.get(1).getValues(values);
    assertEquals(15f, values[Matrix.MTRANS_X], 0f);
    assertEquals(26f, values[Matrix.MTRANS_Y], 0f);
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
