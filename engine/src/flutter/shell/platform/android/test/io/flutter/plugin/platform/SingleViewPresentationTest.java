// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugin.platform;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertNotNull;
import static org.junit.Assert.assertSame;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.spy;
import static org.mockito.Mockito.when;

import android.annotation.TargetApi;
import android.content.Context;
import android.content.MutableContextWrapper;
import android.hardware.display.DisplayManager;
import android.view.Display;
import android.view.View;
import android.view.inputmethod.InputMethodManager;
import android.widget.FrameLayout;
import androidx.lifecycle.LifecycleOwner;
import androidx.lifecycle.ViewModelStoreOwner;
import androidx.lifecycle.ViewTreeLifecycleOwner;
import androidx.lifecycle.ViewTreeViewModelStoreOwner;
import androidx.savedstate.SavedStateRegistryOwner;
import androidx.savedstate.ViewTreeSavedStateRegistryOwner;
import androidx.test.core.app.ApplicationProvider;
import androidx.test.ext.junit.runners.AndroidJUnit4;
import io.flutter.Build.API_LEVELS;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.annotation.Config;

@RunWith(AndroidJUnit4.class)
@TargetApi(API_LEVELS.API_28)
public class SingleViewPresentationTest {
  @Test
  @Config(minSdk = API_LEVELS.FLUTTER_MIN, maxSdk = API_LEVELS.API_30)
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
  @Config(minSdk = API_LEVELS.FLUTTER_MIN, maxSdk = API_LEVELS.API_30)
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
  public void onCreate_installsViewTreeOwnersBeforeAttachingView() {
    Context context = ApplicationProvider.getApplicationContext();
    Display display =
        ((DisplayManager) context.getSystemService(Context.DISPLAY_SERVICE)).getDisplay(0);

    FrameLayout hostFlutterView = new FrameLayout(context);
    LifecycleOwner expectedLifecycleOwner = mock(LifecycleOwner.class);
    SavedStateRegistryOwner expectedSavedStateOwner = mock(SavedStateRegistryOwner.class);
    ViewModelStoreOwner expectedViewModelOwner = mock(ViewModelStoreOwner.class);
    ViewTreeLifecycleOwner.set(hostFlutterView, expectedLifecycleOwner);
    ViewTreeSavedStateRegistryOwner.set(hostFlutterView, expectedSavedStateOwner);
    ViewTreeViewModelStoreOwner.set(hostFlutterView, expectedViewModelOwner);

    ViewTreeOwners owners = ViewTreeOwners.findFrom(hostFlutterView);
    assertNotNull(owners);

    View embeddedView = new View(new MutableContextWrapper(context));
    final LifecycleOwner[] attachedLifecycleOwner = {null};
    final SavedStateRegistryOwner[] attachedSavedStateOwner = {null};
    final ViewModelStoreOwner[] attachedViewModelOwner = {null};
    embeddedView.addOnAttachStateChangeListener(
        new View.OnAttachStateChangeListener() {
          @Override
          public void onViewAttachedToWindow(View v) {
            attachedLifecycleOwner[0] = ViewTreeLifecycleOwner.get(v);
            attachedSavedStateOwner[0] = ViewTreeSavedStateRegistryOwner.get(v);
            attachedViewModelOwner[0] = ViewTreeViewModelStoreOwner.get(v);
          }

          @Override
          public void onViewDetachedFromWindow(View v) {}
        });

    PlatformView platformView =
        new PlatformView() {
          @Override
          public View getView() {
            return embeddedView;
          }

          @Override
          public void dispose() {}
        };

    SingleViewPresentation svp =
        new SingleViewPresentation(
            context, display, platformView, new AccessibilityEventsDelegate(), 0, null);
    svp.setViewTreeOwners(owners);
    svp.onCreate(null);

    assertSame(expectedLifecycleOwner, ViewTreeLifecycleOwner.get(embeddedView));
    assertSame(expectedSavedStateOwner, ViewTreeSavedStateRegistryOwner.get(embeddedView));
    assertSame(expectedViewModelOwner, ViewTreeViewModelStoreOwner.get(embeddedView));
    if (attachedLifecycleOwner[0] != null) {
      assertSame(expectedLifecycleOwner, attachedLifecycleOwner[0]);
      assertSame(expectedSavedStateOwner, attachedSavedStateOwner[0]);
      assertSame(expectedViewModelOwner, attachedViewModelOwner[0]);
    }
  }
}
