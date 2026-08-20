// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugin.editing;

import static io.flutter.Build.API_LEVELS;
import static org.junit.Assert.assertEquals;
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
import org.junit.Test;
import org.junit.runner.RunWith;
import org.mockito.ArgumentCaptor;
import org.robolectric.annotation.Config;

@TargetApi(API_LEVELS.API_30)
@Config(sdk = {API_LEVELS.API_30, API_LEVELS.API_34})
@RunWith(AndroidJUnit4.class)
public class ImeSyncDeferringInsetsCallbackTest {
  // Target settled IME keyboard height in pixels.
  private static final int FINAL_IME_BOTTOM_INSET = 100;
  // Navigation bar height in pixels.
  private static final int NAVIGATION_BAR_BOTTOM_INSET = 40;

  @SuppressWarnings("deprecation")
  // getWindowSystemUiVisibility.
  @Test
  public void imeAnimation_edgeToEdgeOpening_smoothlyInterpolatesToFinalValue() {
    View view = mock(View.class);
    // Legacy flags are 0 in modern edge-to-edge mode.
    when(view.getWindowSystemUiVisibility()).thenReturn(0);

    ImeSyncDeferringInsetsCallback callback = new ImeSyncDeferringInsetsCallback(view);
    WindowInsetsAnimation animation = mock(WindowInsetsAnimation.class);
    when(animation.getTypeMask()).thenReturn(WindowInsets.Type.ime());

    callback.getAnimationCallback().onPrepare(animation);
    WindowInsets finalInsets =
        new WindowInsets.Builder()
            .setInsets(WindowInsets.Type.ime(), Insets.of(0, 0, 0, FINAL_IME_BOTTOM_INSET))
            .setInsets(
                WindowInsets.Type.navigationBars(), Insets.of(0, 0, 0, NAVIGATION_BAR_BOTTOM_INSET))
            .build();
    callback.getInsetsListener().onApplyWindowInsets(view, finalInsets);

    // At 50% fraction (progress = 0.5f).
    when(animation.getInterpolatedFraction()).thenReturn(0.5f);
    WindowInsets midProgressInsets =
        new WindowInsets.Builder()
            .setInsets(WindowInsets.Type.ime(), Insets.of(0, 0, 0, FINAL_IME_BOTTOM_INSET / 2))
            .setInsets(
                WindowInsets.Type.navigationBars(), Insets.of(0, 0, 0, NAVIGATION_BAR_BOTTOM_INSET))
            .build();
    callback
        .getAnimationCallback()
        .onProgress(midProgressInsets, Collections.singletonList(animation));

    ArgumentCaptor<WindowInsets> midInsetsCaptor = ArgumentCaptor.forClass(WindowInsets.class);
    verify(view).onApplyWindowInsets(midInsetsCaptor.capture());
    // 50% of 100px target = 50px.
    assertEquals(50, midInsetsCaptor.getValue().getInsets(WindowInsets.Type.ime()).bottom);

    // At 100% fraction (terminal progress = 1.0f).
    when(animation.getInterpolatedFraction()).thenReturn(1.0f);
    WindowInsets terminalProgressInsets =
        new WindowInsets.Builder()
            .setInsets(WindowInsets.Type.ime(), Insets.of(0, 0, 0, FINAL_IME_BOTTOM_INSET))
            .setInsets(
                WindowInsets.Type.navigationBars(), Insets.of(0, 0, 0, NAVIGATION_BAR_BOTTOM_INSET))
            .build();
    callback
        .getAnimationCallback()
        .onProgress(terminalProgressInsets, Collections.singletonList(animation));

    ArgumentCaptor<WindowInsets> terminalInsetsCaptor = ArgumentCaptor.forClass(WindowInsets.class);
    verify(view, org.mockito.Mockito.times(2)).onApplyWindowInsets(terminalInsetsCaptor.capture());
    // At 1.0f fraction, terminal progress must equal the settled value (100px) with 0 jump.
    assertEquals(
        FINAL_IME_BOTTOM_INSET,
        terminalInsetsCaptor.getValue().getInsets(WindowInsets.Type.ime()).bottom);

    // When onEnd is called, the dispatched insets must match terminal progress.
    callback.getAnimationCallback().onEnd(animation);
    ArgumentCaptor<WindowInsets> endInsetsCaptor = ArgumentCaptor.forClass(WindowInsets.class);
    verify(view).dispatchApplyWindowInsets(endInsetsCaptor.capture());
    assertEquals(
        FINAL_IME_BOTTOM_INSET,
        endInsetsCaptor.getValue().getInsets(WindowInsets.Type.ime()).bottom);
  }

  @SuppressWarnings("deprecation")
  // getWindowSystemUiVisibility.
  @Test
  public void imeAnimation_nonEdgeToEdgeOpening_smoothlyInterpolatesToFinalValue() {
    View view = mock(View.class);
    // Legacy flags are 0 in non-edge-to-edge mode.
    when(view.getWindowSystemUiVisibility()).thenReturn(0);

    ImeSyncDeferringInsetsCallback callback = new ImeSyncDeferringInsetsCallback(view);
    WindowInsetsAnimation animation = mock(WindowInsetsAnimation.class);
    when(animation.getTypeMask()).thenReturn(WindowInsets.Type.ime());

    callback.getAnimationCallback().onPrepare(animation);
    // In non-edge-to-edge mode, settled final inset is FINAL_IME_BOTTOM_INSET (e.g. 100px).
    WindowInsets finalInsets =
        new WindowInsets.Builder()
            .setInsets(WindowInsets.Type.ime(), Insets.of(0, 0, 0, FINAL_IME_BOTTOM_INSET))
            .build();
    callback.getInsetsListener().onApplyWindowInsets(view, finalInsets);

    // At 50% fraction (progress = 0.5f).
    when(animation.getInterpolatedFraction()).thenReturn(0.5f);
    WindowInsets midProgressInsets =
        new WindowInsets.Builder()
            .setInsets(
                WindowInsets.Type.ime(),
                Insets.of(0, 0, 0, (FINAL_IME_BOTTOM_INSET + NAVIGATION_BAR_BOTTOM_INSET) / 2))
            .build();
    callback
        .getAnimationCallback()
        .onProgress(midProgressInsets, Collections.singletonList(animation));

    ArgumentCaptor<WindowInsets> midInsetsCaptor = ArgumentCaptor.forClass(WindowInsets.class);
    verify(view).onApplyWindowInsets(midInsetsCaptor.capture());
    assertEquals(50, midInsetsCaptor.getValue().getInsets(WindowInsets.Type.ime()).bottom);

    // At 100% fraction (progress = 1.0f).
    when(animation.getInterpolatedFraction()).thenReturn(1.0f);
    WindowInsets terminalProgressInsets =
        new WindowInsets.Builder()
            .setInsets(
                WindowInsets.Type.ime(),
                Insets.of(0, 0, 0, FINAL_IME_BOTTOM_INSET + NAVIGATION_BAR_BOTTOM_INSET))
            .build();
    callback
        .getAnimationCallback()
        .onProgress(terminalProgressInsets, Collections.singletonList(animation));

    ArgumentCaptor<WindowInsets> terminalInsetsCaptor = ArgumentCaptor.forClass(WindowInsets.class);
    verify(view, org.mockito.Mockito.times(2)).onApplyWindowInsets(terminalInsetsCaptor.capture());
    assertEquals(
        FINAL_IME_BOTTOM_INSET,
        terminalInsetsCaptor.getValue().getInsets(WindowInsets.Type.ime()).bottom);

    callback.getAnimationCallback().onEnd(animation);
    ArgumentCaptor<WindowInsets> endInsetsCaptor = ArgumentCaptor.forClass(WindowInsets.class);
    verify(view).dispatchApplyWindowInsets(endInsetsCaptor.capture());
    assertEquals(
        FINAL_IME_BOTTOM_INSET,
        endInsetsCaptor.getValue().getInsets(WindowInsets.Type.ime()).bottom);
  }

  @SuppressWarnings("deprecation")
  // SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION, getWindowSystemUiVisibility.
  @Test
  public void imeAnimation_legacyEdgeToEdgeOpening_smoothlyInterpolatesToFinalValue() {
    View view = mock(View.class);
    when(view.getWindowSystemUiVisibility()).thenReturn(View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION);

    ImeSyncDeferringInsetsCallback callback = new ImeSyncDeferringInsetsCallback(view);
    WindowInsetsAnimation animation = mock(WindowInsetsAnimation.class);
    when(animation.getTypeMask()).thenReturn(WindowInsets.Type.ime());

    callback.getAnimationCallback().onPrepare(animation);
    WindowInsets finalInsets =
        new WindowInsets.Builder()
            .setInsets(WindowInsets.Type.ime(), Insets.of(0, 0, 0, FINAL_IME_BOTTOM_INSET))
            .setInsets(
                WindowInsets.Type.navigationBars(), Insets.of(0, 0, 0, NAVIGATION_BAR_BOTTOM_INSET))
            .build();
    callback.getInsetsListener().onApplyWindowInsets(view, finalInsets);

    when(animation.getInterpolatedFraction()).thenReturn(1.0f);
    WindowInsets terminalProgressInsets =
        new WindowInsets.Builder()
            .setInsets(WindowInsets.Type.ime(), Insets.of(0, 0, 0, FINAL_IME_BOTTOM_INSET))
            .setInsets(
                WindowInsets.Type.navigationBars(), Insets.of(0, 0, 0, NAVIGATION_BAR_BOTTOM_INSET))
            .build();
    callback
        .getAnimationCallback()
        .onProgress(terminalProgressInsets, Collections.singletonList(animation));

    ArgumentCaptor<WindowInsets> terminalInsetsCaptor = ArgumentCaptor.forClass(WindowInsets.class);
    verify(view).onApplyWindowInsets(terminalInsetsCaptor.capture());
    assertEquals(
        FINAL_IME_BOTTOM_INSET,
        terminalInsetsCaptor.getValue().getInsets(WindowInsets.Type.ime()).bottom);

    callback.getAnimationCallback().onEnd(animation);
    ArgumentCaptor<WindowInsets> endInsetsCaptor = ArgumentCaptor.forClass(WindowInsets.class);
    verify(view).dispatchApplyWindowInsets(endInsetsCaptor.capture());
    assertEquals(
        FINAL_IME_BOTTOM_INSET,
        endInsetsCaptor.getValue().getInsets(WindowInsets.Type.ime()).bottom);
  }

  @SuppressWarnings("deprecation")
  // getWindowSystemUiVisibility.
  @Test
  public void imeAnimation_closing_smoothlyInterpolatesToZero() {
    View view = mock(View.class);
    when(view.getWindowSystemUiVisibility()).thenReturn(0);

    ImeSyncDeferringInsetsCallback callback = new ImeSyncDeferringInsetsCallback(view);
    WindowInsetsAnimation openAnimation = mock(WindowInsetsAnimation.class);
    when(openAnimation.getTypeMask()).thenReturn(WindowInsets.Type.ime());

    // First, open the keyboard to establish initial settled insets.
    callback.getAnimationCallback().onPrepare(openAnimation);
    WindowInsets openInsets =
        new WindowInsets.Builder()
            .setInsets(WindowInsets.Type.ime(), Insets.of(0, 0, 0, FINAL_IME_BOTTOM_INSET))
            .build();
    callback.getInsetsListener().onApplyWindowInsets(view, openInsets);
    when(openAnimation.getInterpolatedFraction()).thenReturn(1.0f);
    callback
        .getAnimationCallback()
        .onProgress(openInsets, Collections.singletonList(openAnimation));
    callback.getAnimationCallback().onEnd(openAnimation);

    // Now start closing animation.
    WindowInsetsAnimation closeAnimation = mock(WindowInsetsAnimation.class);
    when(closeAnimation.getTypeMask()).thenReturn(WindowInsets.Type.ime());
    callback.getAnimationCallback().onPrepare(closeAnimation);
    WindowInsets closedInsets =
        new WindowInsets.Builder()
            .setInsets(WindowInsets.Type.ime(), Insets.of(0, 0, 0, 0))
            .build();
    callback.getInsetsListener().onApplyWindowInsets(view, closedInsets);

    // At 50% closing (fraction = 0.5f).
    when(closeAnimation.getInterpolatedFraction()).thenReturn(0.5f);
    WindowInsets midCloseInsets =
        new WindowInsets.Builder()
            .setInsets(WindowInsets.Type.ime(), Insets.of(0, 0, 0, FINAL_IME_BOTTOM_INSET / 2))
            .build();
    callback
        .getAnimationCallback()
        .onProgress(midCloseInsets, Collections.singletonList(closeAnimation));

    ArgumentCaptor<WindowInsets> midCloseCaptor = ArgumentCaptor.forClass(WindowInsets.class);
    verify(view, org.mockito.Mockito.atLeastOnce()).onApplyWindowInsets(midCloseCaptor.capture());
    // 50% closed from 100px = 50px.
    assertEquals(50, midCloseCaptor.getValue().getInsets(WindowInsets.Type.ime()).bottom);

    // At 100% closing (fraction = 1.0f).
    when(closeAnimation.getInterpolatedFraction()).thenReturn(1.0f);
    WindowInsets finalCloseInsets =
        new WindowInsets.Builder()
            .setInsets(WindowInsets.Type.ime(), Insets.of(0, 0, 0, 0))
            .build();
    callback
        .getAnimationCallback()
        .onProgress(finalCloseInsets, Collections.singletonList(closeAnimation));

    ArgumentCaptor<WindowInsets> finalCloseCaptor = ArgumentCaptor.forClass(WindowInsets.class);
    verify(view, org.mockito.Mockito.atLeastOnce()).onApplyWindowInsets(finalCloseCaptor.capture());
    assertEquals(0, finalCloseCaptor.getValue().getInsets(WindowInsets.Type.ime()).bottom);

    callback.getAnimationCallback().onEnd(closeAnimation);
    ArgumentCaptor<WindowInsets> endInsetsCaptor = ArgumentCaptor.forClass(WindowInsets.class);
    verify(view, org.mockito.Mockito.atLeastOnce())
        .dispatchApplyWindowInsets(endInsetsCaptor.capture());
    assertEquals(0, endInsetsCaptor.getValue().getInsets(WindowInsets.Type.ime()).bottom);
  }
}
