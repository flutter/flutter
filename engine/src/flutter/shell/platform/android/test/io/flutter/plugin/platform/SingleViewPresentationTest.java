// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugin.platform;

import static android.os.Build.VERSION_CODES.KITKAT;
import static android.os.Build.VERSION_CODES.P;
import static android.os.Build.VERSION_CODES.R;
import static android.os.Build.VERSION_CODES.S;
import static org.junit.Assert.assertEquals;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.spy;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

import android.annotation.TargetApi;
import android.content.Context;
import android.hardware.display.DisplayManager;
import android.view.Display;
import android.view.View;
import android.view.ViewGroup;
import android.view.WindowManager;
import android.view.inputmethod.InputMethodManager;
import androidx.test.core.app.ApplicationProvider;
import androidx.test.ext.junit.runners.AndroidJUnit4;
import java.util.concurrent.Executor;
import java.util.function.Consumer;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.annotation.Config;

@Config(manifest = Config.NONE)
@RunWith(AndroidJUnit4.class)
@TargetApi(P)
public class SingleViewPresentationTest {
  @Test
  @Config(minSdk = KITKAT, maxSdk = R)
  public void returnsOuterContextInputMethodManager() {
    // There's a bug in Android Q caused by the IMM being instanced per display.
    // https://github.com/flutter/flutter/issues/38375. We need the context returned by
    // SingleViewPresentation to be consistent from its instantiation instead of defaulting to
    // what the system would have returned at call time.

    // It's not possible to set up the exact same conditions as the unit test in the bug here,
    // but we can make sure that we're wrapping the Context passed in at instantiation time and
    // returning the same InputMethodManager from it. This test passes in a Spy context instance
    // that initially returns a mock. Without the bugfix this test falls back to Robolectric's
    // system service instead of the spy's and fails.

    // Create an SVP under test with a Context that returns a local IMM mock.
    Context context = spy(ApplicationProvider.getApplicationContext());
    InputMethodManager expected = mock(InputMethodManager.class);
    when(context.getSystemService(Context.INPUT_METHOD_SERVICE)).thenReturn(expected);
    DisplayManager dm = (DisplayManager) context.getSystemService(Context.DISPLAY_SERVICE);
    SingleViewPresentation svp =
        new SingleViewPresentation(context, dm.getDisplay(0), null, null, null, false);

    // Get the IMM from the SVP's context.
    InputMethodManager actual =
        (InputMethodManager) svp.getContext().getSystemService(Context.INPUT_METHOD_SERVICE);

    // This should be the mocked instance from construction, not the IMM from the greater
    // Android OS (or Robolectric's shadow, in this case).
    assertEquals(expected, actual);
  }

  @Test
  @Config(minSdk = KITKAT, maxSdk = R)
  public void returnsOuterContextInputMethodManager_createDisplayContext() {
    // The IMM should also persist across display contexts created from the base context.

    // Create an SVP under test with a Context that returns a local IMM mock.
    Context context = spy(ApplicationProvider.getApplicationContext());
    InputMethodManager expected = mock(InputMethodManager.class);
    when(context.getSystemService(Context.INPUT_METHOD_SERVICE)).thenReturn(expected);
    Display display =
        ((DisplayManager) context.getSystemService(Context.DISPLAY_SERVICE)).getDisplay(0);
    SingleViewPresentation svp =
        new SingleViewPresentation(context, display, null, null, null, false);

    // Get the IMM from the SVP's context.
    InputMethodManager actual =
        (InputMethodManager)
            svp.getContext()
                .createDisplayContext(display)
                .getSystemService(Context.INPUT_METHOD_SERVICE);

    // This should be the mocked instance from construction, not the IMM from the greater
    // Android OS (or Robolectric's shadow, in this case).
    assertEquals(expected, actual);
  }

  @Test
  @Config(minSdk = R)
  public void windowManagerHandler_passesCorrectlyToFakeWindowViewGroup() {
    // Mock the WindowManager and FakeWindowViewGroup that get used by the WindowManagerHandler.
    WindowManager mockWindowManager = mock(WindowManager.class);
    SingleViewPresentation.FakeWindowViewGroup mockFakeWindowViewGroup =
        mock(SingleViewPresentation.FakeWindowViewGroup.class);

    View mockView = mock(View.class);
    ViewGroup.LayoutParams mockLayoutParams = mock(ViewGroup.LayoutParams.class);

    SingleViewPresentation.WindowManagerHandler windowManagerHandler =
        new SingleViewPresentation.WindowManagerHandler(mockWindowManager, mockFakeWindowViewGroup);

    // removeViewImmediate
    windowManagerHandler.removeViewImmediate(mockView);
    verify(mockView).clearAnimation();
    verify(mockFakeWindowViewGroup).removeView(mockView);
    verifyNoInteractions(mockWindowManager);

    // addView
    windowManagerHandler.addView(mockView, mockLayoutParams);
    verify(mockFakeWindowViewGroup).addView(mockView, mockLayoutParams);
    verifyNoInteractions(mockWindowManager);

    // updateViewLayout
    windowManagerHandler.updateViewLayout(mockView, mockLayoutParams);
    verify(mockFakeWindowViewGroup).updateViewLayout(mockView, mockLayoutParams);
    verifyNoInteractions(mockWindowManager);

    // removeView
    windowManagerHandler.updateViewLayout(mockView, mockLayoutParams);
    verify(mockFakeWindowViewGroup).removeView(mockView);
    verifyNoInteractions(mockWindowManager);
  }

  @Test
  @Config(minSdk = R)
  public void windowManagerHandler_logAndReturnEarly_whenFakeWindowViewGroupIsNull() {
    // Mock the WindowManager and FakeWindowViewGroup that get used by the WindowManagerHandler.
    WindowManager mockWindowManager = mock(WindowManager.class);

    View mockView = mock(View.class);
    ViewGroup.LayoutParams mockLayoutParams = mock(ViewGroup.LayoutParams.class);

    SingleViewPresentation.WindowManagerHandler windowManagerHandler =
        new SingleViewPresentation.WindowManagerHandler(mockWindowManager, null);

    // removeViewImmediate
    windowManagerHandler.removeViewImmediate(mockView);
    verifyNoInteractions(mockView);
    verifyNoInteractions(mockWindowManager);

    // addView
    windowManagerHandler.addView(mockView, mockLayoutParams);
    verifyNoInteractions(mockWindowManager);

    // updateViewLayout
    windowManagerHandler.updateViewLayout(mockView, mockLayoutParams);
    verifyNoInteractions(mockWindowManager);

    // removeView
    windowManagerHandler.updateViewLayout(mockView, mockLayoutParams);
    verifyNoInteractions(mockWindowManager);
  }

  // This section tests that WindowManagerHandler forwards all of the non-special case calls to the
  // delegate WindowManager. Because this must include some deprecated WindowManager method calls
  // (because the proxy overrides every method), we suppress deprecation warnings here.
  @Test
  @Config(minSdk = S)
  @SuppressWarnings("deprecation")
  public void windowManagerHandler_forwardsAllOtherCallsToDelegate() {
    // Mock the WindowManager and FakeWindowViewGroup that get used by the WindowManagerHandler.
    WindowManager mockWindowManager = mock(WindowManager.class);
    SingleViewPresentation.FakeWindowViewGroup mockFakeWindowViewGroup =
        mock(SingleViewPresentation.FakeWindowViewGroup.class);

    SingleViewPresentation.WindowManagerHandler windowManagerHandler =
        new SingleViewPresentation.WindowManagerHandler(mockWindowManager, mockFakeWindowViewGroup);

    // Verify that all other calls get forwarded to the delegate.
    Executor mockExecutor = mock(Executor.class);
    @SuppressWarnings("Unchecked cast")
    Consumer<Boolean> mockListener = (Consumer<Boolean>) mock(Consumer.class);

    windowManagerHandler.getDefaultDisplay();
    verify(mockWindowManager).getDefaultDisplay();

    windowManagerHandler.getCurrentWindowMetrics();
    verify(mockWindowManager).getCurrentWindowMetrics();

    windowManagerHandler.getMaximumWindowMetrics();
    verify(mockWindowManager).getMaximumWindowMetrics();

    windowManagerHandler.isCrossWindowBlurEnabled();
    verify(mockWindowManager).isCrossWindowBlurEnabled();

    windowManagerHandler.addCrossWindowBlurEnabledListener(mockListener);
    verify(mockWindowManager).addCrossWindowBlurEnabledListener(mockListener);

    windowManagerHandler.addCrossWindowBlurEnabledListener(mockExecutor, mockListener);
    verify(mockWindowManager).addCrossWindowBlurEnabledListener(mockExecutor, mockListener);

    windowManagerHandler.removeCrossWindowBlurEnabledListener(mockListener);
    verify(mockWindowManager).removeCrossWindowBlurEnabledListener(mockListener);
  }
}
