package io.flutter.plugin.platform;

import static android.view.View.OnFocusChangeListener;
import static org.junit.Assert.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

import android.annotation.TargetApi;
import android.content.Context;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.PorterDuff;
import android.graphics.SurfaceTexture;
import android.view.Surface;
import android.view.View;
import android.view.ViewGroup;
import android.view.ViewTreeObserver;
import android.view.accessibility.AccessibilityEvent;
import androidx.annotation.NonNull;
import androidx.test.core.app.ApplicationProvider;
import androidx.test.ext.junit.runners.AndroidJUnit4;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.mockito.ArgumentCaptor;
import org.robolectric.annotation.Config;
import org.robolectric.annotation.Implementation;
import org.robolectric.annotation.Implements;

@TargetApi(31)
@RunWith(AndroidJUnit4.class)
public class PlatformViewWrapperTest {
  private final Context ctx = ApplicationProvider.getApplicationContext();

  @Test
  public void invalidateChildInParent_callsInvalidate() {
    final PlatformViewWrapper wrapper = spy(new PlatformViewWrapper(ctx));

    // Mock Android framework calls.
    wrapper.invalidateChildInParent(null, null);

    // Verify.
    verify(wrapper, times(1)).invalidate();
  }

  @Test
  public void setTexture_writesToBuffer() {
    final Surface surface = mock(Surface.class);
    final PlatformViewWrapper wrapper =
        new PlatformViewWrapper(ctx) {
          @Override
          protected Surface createSurface(@NonNull SurfaceTexture tx) {
            return surface;
          }
        };

    final SurfaceTexture tx = mock(SurfaceTexture.class);
    when(tx.isReleased()).thenReturn(false);

    final Canvas canvas = mock(Canvas.class);
    when(surface.lockHardwareCanvas()).thenReturn(canvas);

    // Test.
    wrapper.setTexture(tx);

    // Verify.
    verify(surface, times(1)).lockHardwareCanvas();
    verify(surface, times(1)).unlockCanvasAndPost(canvas);
    verify(canvas, times(1)).drawColor(Color.TRANSPARENT, PorterDuff.Mode.CLEAR);
    verifyNoMoreInteractions(surface);
    verifyNoMoreInteractions(canvas);
  }

  @Test
  public void draw_writesToBuffer() {
    final Surface surface = mock(Surface.class);
    final PlatformViewWrapper wrapper =
        new PlatformViewWrapper(ctx) {
          @Override
          protected Surface createSurface(@NonNull SurfaceTexture tx) {
            return surface;
          }
        };

    wrapper.addView(
        new View(ctx) {
          @Override
          public void draw(Canvas canvas) {
            super.draw(canvas);
            canvas.drawColor(Color.RED);
          }
        });

    final int size = 100;
    wrapper.measure(size, size);
    wrapper.layout(0, 0, size, size);

    final SurfaceTexture tx = mock(SurfaceTexture.class);
    when(tx.isReleased()).thenReturn(false);

    when(surface.lockHardwareCanvas()).thenReturn(mock(Canvas.class));

    wrapper.setTexture(tx);

    reset(surface);

    final Canvas canvas = mock(Canvas.class);
    when(surface.lockHardwareCanvas()).thenReturn(canvas);
    when(surface.isValid()).thenReturn(true);

    // Test.
    wrapper.invalidate();
    wrapper.draw(new Canvas());

    // Verify.
    verify(canvas, times(1)).drawColor(Color.TRANSPARENT, PorterDuff.Mode.CLEAR);
    verify(surface, times(1)).isValid();
    verify(surface, times(1)).lockHardwareCanvas();
    verify(surface, times(1)).unlockCanvasAndPost(canvas);
    verifyNoMoreInteractions(surface);
    verifyNoMoreInteractions(canvas);
  }

  @Test
  @Config(
      shadows = {
        ShadowView.class,
      })
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
  public void release() {
    final Surface surface = mock(Surface.class);
    final PlatformViewWrapper wrapper =
        new PlatformViewWrapper(ctx) {
          @Override
          protected Surface createSurface(@NonNull SurfaceTexture tx) {
            return surface;
          }
        };

    final SurfaceTexture tx = mock(SurfaceTexture.class);
    when(tx.isReleased()).thenReturn(false);

    final Canvas canvas = mock(Canvas.class);
    when(surface.lockHardwareCanvas()).thenReturn(canvas);

    wrapper.setTexture(tx);
    reset(surface);
    reset(tx);

    // Test.
    wrapper.release();

    // Verify.
    verify(surface, times(1)).release();
    verifyNoMoreInteractions(surface);
    verifyNoMoreInteractions(tx);
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

    final PlatformViewWrapper view =
        new PlatformViewWrapper(ctx) {
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

  @Implements(View.class)
  public static class ShadowView {}

  @Implements(ViewGroup.class)
  public static class ShadowViewGroup extends org.robolectric.shadows.ShadowView {
    @Implementation
    public boolean requestSendAccessibilityEvent(View child, AccessibilityEvent event) {
      return true;
    }
  }
}
