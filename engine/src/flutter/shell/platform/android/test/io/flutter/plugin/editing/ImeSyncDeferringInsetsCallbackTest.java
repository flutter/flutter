// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugin.editing;

import static io.flutter.Build.API_LEVELS;
import static org.junit.Assert.assertArrayEquals;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import android.annotation.TargetApi;
import android.graphics.Insets;
import android.view.View;
import android.view.WindowInsets;
import android.view.WindowInsetsAnimation;
import androidx.test.ext.junit.runners.AndroidJUnit4;
import java.util.Collections;
import java.util.concurrent.atomic.AtomicBoolean;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.mockito.ArgumentCaptor;
import org.robolectric.annotation.Config;

@TargetApi(API_LEVELS.API_30)
@Config(sdk = {API_LEVELS.API_30, API_LEVELS.API_34})
@RunWith(AndroidJUnit4.class)
public class ImeSyncDeferringInsetsCallbackTest {
  private static final int FINAL_IME_BOTTOM_INSET = 100;
  private static final int NAVIGATION_BAR_BOTTOM_INSET = 40;

  @Test
  public void imeAnimation_modernEdgeToEdgeIncludesNavigationBarInsets() {
    int[] dispatchedImeInsets = dispatchTerminalImeInsets(true, 0, FINAL_IME_BOTTOM_INSET);

    assertArrayEquals(
        new int[] {FINAL_IME_BOTTOM_INSET, FINAL_IME_BOTTOM_INSET}, dispatchedImeInsets);
  }

  @Test
  public void imeAnimation_nonEdgeToEdgeExcludesNavigationBarInsets() {
    int[] dispatchedImeInsets =
        dispatchTerminalImeInsets(false, 0, FINAL_IME_BOTTOM_INSET + NAVIGATION_BAR_BOTTOM_INSET);

    assertArrayEquals(
        new int[] {FINAL_IME_BOTTOM_INSET, FINAL_IME_BOTTOM_INSET}, dispatchedImeInsets);
  }

  @SuppressWarnings("deprecation")
  // SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION.
  @Test
  public void imeAnimation_legacyEdgeToEdgeIncludesNavigationBarInsets() {
    int[] dispatchedImeInsets =
        dispatchTerminalImeInsets(
            false, View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION, FINAL_IME_BOTTOM_INSET);

    assertArrayEquals(
        new int[] {FINAL_IME_BOTTOM_INSET, FINAL_IME_BOTTOM_INSET}, dispatchedImeInsets);
  }

  @SuppressWarnings("deprecation")
  // getWindowSystemUiVisibility.
  private int[] dispatchTerminalImeInsets(
      boolean enableModernEdgeToEdge,
      int windowSystemUiVisibility,
      int terminalProgressImeBottomInset) {
    View view = mock(View.class);
    when(view.getWindowSystemUiVisibility()).thenReturn(windowSystemUiVisibility);

    AtomicBoolean isEdgeToEdgeEnabled = new AtomicBoolean(false);
    ImeSyncDeferringInsetsCallback callback =
        new ImeSyncDeferringInsetsCallback(view, isEdgeToEdgeEnabled::get);
    WindowInsetsAnimation animation = mock(WindowInsetsAnimation.class);
    when(animation.getTypeMask()).thenReturn(WindowInsets.Type.ime());

    callback.getAnimationCallback().onPrepare(animation);
    WindowInsets finalInsets =
        new WindowInsets.Builder()
            .setInsets(WindowInsets.Type.ime(), Insets.of(0, 0, 0, FINAL_IME_BOTTOM_INSET))
            .build();
    callback.getInsetsListener().onApplyWindowInsets(view, finalInsets);

    // The callback is installed before the framework can request a system UI mode, so the
    // edge-to-edge state must be read when the animation progresses rather than at construction.
    isEdgeToEdgeEnabled.set(enableModernEdgeToEdge);
    WindowInsets terminalProgressInsets =
        new WindowInsets.Builder()
            .setInsets(WindowInsets.Type.ime(), Insets.of(0, 0, 0, terminalProgressImeBottomInset))
            .setInsets(
                WindowInsets.Type.navigationBars(), Insets.of(0, 0, 0, NAVIGATION_BAR_BOTTOM_INSET))
            .build();
    callback
        .getAnimationCallback()
        .onProgress(terminalProgressInsets, Collections.singletonList(animation));

    ArgumentCaptor<WindowInsets> progressInsetsCaptor = ArgumentCaptor.forClass(WindowInsets.class);
    verify(view).onApplyWindowInsets(progressInsetsCaptor.capture());

    callback.getAnimationCallback().onEnd(animation);

    ArgumentCaptor<WindowInsets> endInsetsCaptor = ArgumentCaptor.forClass(WindowInsets.class);
    verify(view).dispatchApplyWindowInsets(endInsetsCaptor.capture());

    return new int[] {
      progressInsetsCaptor.getValue().getInsets(WindowInsets.Type.ime()).bottom,
      endInsetsCaptor.getValue().getInsets(WindowInsets.Type.ime()).bottom
    };
  }
}
