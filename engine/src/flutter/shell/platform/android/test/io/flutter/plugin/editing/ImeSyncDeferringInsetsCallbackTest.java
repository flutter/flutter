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
@SuppressWarnings("deprecation")
public class ImeSyncDeferringInsetsCallbackTest {
  // Target settled IME keyboard height in pixels.
  private static final int FINAL_IME_BOTTOM_INSET = 100;
  // Navigation bar height in pixels.
  private static final int NAVIGATION_BAR_BOTTOM_INSET = 40;

  /**
   * Tests soft keyboard opening animation in modern edge-to-edge mode (API 30-34).
   *
   * <p>Rationale / Added for: Fixes flutter/flutter#190974. In modern edge-to-edge mode (where
   * legacy systemUiVisibility flags are 0), onProgress previously subtracted the navigation bar
   * height (e.g. 40px) during animation, while onEnd dispatched the full target insets (100px),
   * causing a visible terminal jump. This test verifies that onProgress smoothly interpolates
   * towards the settled target inset (100px) so that at fraction 1.0f the animated insets exactly
   * match the onEnd settled insets.
   */
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

  /**
   * Tests soft keyboard opening animation in standard non-edge-to-edge mode.
   *
   * <p>Rationale / Added for: Verifies that in non-edge-to-edge mode, target-inset interpolation
   * smoothly scales from 0 to the target IME inset without jumping or clipping, regardless of raw
   * OS animated insets.
   */
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

  /**
   * Tests soft keyboard opening animation with legacy SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION flags.
   *
   * <p>Rationale / Added for: Ensures backward compatibility with legacy apps that explicitly
   * configure View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION on their root view.
   */
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

  /**
   * Tests soft keyboard dismissal (closing) animation.
   *
   * <p>Rationale / Added for: Verifies that during dismissal, animated insets interpolate smoothly
   * from the established keyboard height (100px) down to 0px without dropping by the navigation bar
   * height on frame 0.
   */
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

  /**
   * Tests interrupted animations (e.g. keyboard closing gesture triggered while opening is
   * in-flight).
   *
   * <p>Rationale / Added for: Fixes a critical flaw identified in adversarial review. If
   * startImeBottom was read from lastWindowInsets (which stored the prior target of 100px),
   * interrupting an opening animation at 50px would calculate 100 + (0 - 100) * fraction, snapping
   * instantly from 50px up to 100px on frame 0 of the closing animation. This test verifies that
   * tracking currentImeBottom enables smooth interpolation from the in-flight inset (50px) down to
   * 0px (reaching 25px at 50% closing).
   */
  @Test
  public void imeAnimation_interruptedAnimation_smoothlyInterpolatesFromInFlightInset() {
    View view = mock(View.class);
    when(view.getWindowSystemUiVisibility()).thenReturn(0);

    ImeSyncDeferringInsetsCallback callback = new ImeSyncDeferringInsetsCallback(view);
    WindowInsetsAnimation openAnimation = mock(WindowInsetsAnimation.class);
    when(openAnimation.getTypeMask()).thenReturn(WindowInsets.Type.ime());

    // 1. Start opening animation towards 100px.
    callback.getAnimationCallback().onPrepare(openAnimation);
    WindowInsets openTargetInsets =
        new WindowInsets.Builder()
            .setInsets(WindowInsets.Type.ime(), Insets.of(0, 0, 0, FINAL_IME_BOTTOM_INSET))
            .build();
    callback.getInsetsListener().onApplyWindowInsets(view, openTargetInsets);

    // Advance opening animation to 50% (fraction = 0.5f -> in-flight = 50px).
    when(openAnimation.getInterpolatedFraction()).thenReturn(0.5f);
    WindowInsets midOpenInsets =
        new WindowInsets.Builder()
            .setInsets(WindowInsets.Type.ime(), Insets.of(0, 0, 0, 50))
            .build();
    callback
        .getAnimationCallback()
        .onProgress(midOpenInsets, Collections.singletonList(openAnimation));

    ArgumentCaptor<WindowInsets> midOpenCaptor = ArgumentCaptor.forClass(WindowInsets.class);
    verify(view).onApplyWindowInsets(midOpenCaptor.capture());
    assertEquals(50, midOpenCaptor.getValue().getInsets(WindowInsets.Type.ime()).bottom);

    // 2. Interrupt mid-flight with a closing animation towards 0px (without onEnd of the open).
    WindowInsetsAnimation interruptCloseAnimation = mock(WindowInsetsAnimation.class);
    when(interruptCloseAnimation.getTypeMask()).thenReturn(WindowInsets.Type.ime());
    callback.getAnimationCallback().onPrepare(interruptCloseAnimation);

    WindowInsets closeTargetInsets =
        new WindowInsets.Builder()
            .setInsets(WindowInsets.Type.ime(), Insets.of(0, 0, 0, 0))
            .build();
    callback.getInsetsListener().onApplyWindowInsets(view, closeTargetInsets);

    // At 50% fraction of the closing animation, it must smoothly interpolate
    // from the in-flight starting inset (50px) down to 0px: 50 + (0 - 50) * 0.5 = 25px!
    when(interruptCloseAnimation.getInterpolatedFraction()).thenReturn(0.5f);
    WindowInsets midInterruptCloseInsets =
        new WindowInsets.Builder()
            .setInsets(WindowInsets.Type.ime(), Insets.of(0, 0, 0, 25))
            .build();
    callback
        .getAnimationCallback()
        .onProgress(midInterruptCloseInsets, Collections.singletonList(interruptCloseAnimation));

    ArgumentCaptor<WindowInsets> midInterruptCaptor = ArgumentCaptor.forClass(WindowInsets.class);
    verify(view, org.mockito.Mockito.times(2)).onApplyWindowInsets(midInterruptCaptor.capture());
    assertEquals(25, midInterruptCaptor.getValue().getInsets(WindowInsets.Type.ime()).bottom);

    // At 100% closing, reaches 0px.
    when(interruptCloseAnimation.getInterpolatedFraction()).thenReturn(1.0f);
    WindowInsets finalInterruptCloseInsets =
        new WindowInsets.Builder()
            .setInsets(WindowInsets.Type.ime(), Insets.of(0, 0, 0, 0))
            .build();
    callback
        .getAnimationCallback()
        .onProgress(finalInterruptCloseInsets, Collections.singletonList(interruptCloseAnimation));

    ArgumentCaptor<WindowInsets> finalInterruptCaptor = ArgumentCaptor.forClass(WindowInsets.class);
    verify(view, org.mockito.Mockito.times(3)).onApplyWindowInsets(finalInterruptCaptor.capture());
    assertEquals(0, finalInterruptCaptor.getValue().getInsets(WindowInsets.Type.ime()).bottom);

    callback.getAnimationCallback().onEnd(interruptCloseAnimation);
    ArgumentCaptor<WindowInsets> endInsetsCaptor = ArgumentCaptor.forClass(WindowInsets.class);
    verify(view).dispatchApplyWindowInsets(endInsetsCaptor.capture());
    assertEquals(0, endInsetsCaptor.getValue().getInsets(WindowInsets.Type.ime()).bottom);
  }

  /**
   * Tests aborted animation lifecycles (onPrepare immediately followed by onEnd without
   * onApplyWindowInsets).
   *
   * <p>Rationale / Added for: Fixes a state-machine leak identified in adversarial review. If
   * onPrepare sets needsSave = true and the animation is aborted before onApplyWindowInsets fires,
   * onEnd must reset needsSave = false so subsequent animations are not stalled by dropped
   * onProgress frames.
   */
  @Test
  public void imeAnimation_abortedLifecycle_resetsNeedsSaveAndAllowsSubsequentAnimations() {
    View view = mock(View.class);
    when(view.getWindowSystemUiVisibility()).thenReturn(0);

    ImeSyncDeferringInsetsCallback callback = new ImeSyncDeferringInsetsCallback(view);
    WindowInsetsAnimation abortedAnimation = mock(WindowInsetsAnimation.class);
    when(abortedAnimation.getTypeMask()).thenReturn(WindowInsets.Type.ime());

    // 1. Animation prepared but immediately ended without onApplyWindowInsets or onProgress.
    callback.getAnimationCallback().onPrepare(abortedAnimation);
    callback.getAnimationCallback().onEnd(abortedAnimation);

    // 2. Subsequent animation should not be blocked or stalled by stale needsSave state.
    WindowInsetsAnimation nextAnimation = mock(WindowInsetsAnimation.class);
    when(nextAnimation.getTypeMask()).thenReturn(WindowInsets.Type.ime());

    callback.getAnimationCallback().onPrepare(nextAnimation);
    WindowInsets targetInsets =
        new WindowInsets.Builder()
            .setInsets(WindowInsets.Type.ime(), Insets.of(0, 0, 0, FINAL_IME_BOTTOM_INSET))
            .build();
    callback.getInsetsListener().onApplyWindowInsets(view, targetInsets);

    when(nextAnimation.getInterpolatedFraction()).thenReturn(1.0f);
    callback
        .getAnimationCallback()
        .onProgress(targetInsets, Collections.singletonList(nextAnimation));

    ArgumentCaptor<WindowInsets> progressCaptor = ArgumentCaptor.forClass(WindowInsets.class);
    verify(view).onApplyWindowInsets(progressCaptor.capture());
    assertEquals(
        FINAL_IME_BOTTOM_INSET,
        progressCaptor.getValue().getInsets(WindowInsets.Type.ime()).bottom);

    callback.getAnimationCallback().onEnd(nextAnimation);
    ArgumentCaptor<WindowInsets> endInsetsCaptor = ArgumentCaptor.forClass(WindowInsets.class);
    verify(view).dispatchApplyWindowInsets(endInsetsCaptor.capture());
    assertEquals(
        FINAL_IME_BOTTOM_INSET,
        endInsetsCaptor.getValue().getInsets(WindowInsets.Type.ime()).bottom);
  }

  /**
   * Tests concurrent animation of IME and other system bars (status bars / navigation bars).
   *
   * <p>Rationale / Added for: Fixes a bug identified in adversarial review where
   * WindowInsets.Builder used a stale lastWindowInsets snapshot, freezing non-IME system bar
   * animations during IME transitions. This test verifies that non-IME insets from the current
   * frame's insets object are preserved.
   */
  @Test
  public void imeAnimation_concurrentSystemBarAnimations_preservesNonImeInsets() {
    View view = mock(View.class);
    when(view.getWindowSystemUiVisibility()).thenReturn(0);

    ImeSyncDeferringInsetsCallback callback = new ImeSyncDeferringInsetsCallback(view);
    WindowInsetsAnimation imeAnimation = mock(WindowInsetsAnimation.class);
    when(imeAnimation.getTypeMask()).thenReturn(WindowInsets.Type.ime());

    callback.getAnimationCallback().onPrepare(imeAnimation);
    WindowInsets initialInsets =
        new WindowInsets.Builder()
            .setInsets(WindowInsets.Type.ime(), Insets.of(0, 0, 0, FINAL_IME_BOTTOM_INSET))
            .setInsets(WindowInsets.Type.statusBars(), Insets.of(0, 50, 0, 0))
            .setInsets(WindowInsets.Type.navigationBars(), Insets.of(0, 0, 0, 40))
            .build();
    callback.getInsetsListener().onApplyWindowInsets(view, initialInsets);

    // During onProgress, status bar insets change concurrently from 50px to 60px.
    when(imeAnimation.getInterpolatedFraction()).thenReturn(0.5f);
    WindowInsets progressInsetsWithChangedStatusBar =
        new WindowInsets.Builder()
            .setInsets(WindowInsets.Type.ime(), Insets.of(0, 0, 0, 50))
            .setInsets(WindowInsets.Type.statusBars(), Insets.of(0, 60, 0, 0))
            .setInsets(WindowInsets.Type.navigationBars(), Insets.of(0, 0, 0, 40))
            .build();
    callback
        .getAnimationCallback()
        .onProgress(progressInsetsWithChangedStatusBar, Collections.singletonList(imeAnimation));

    ArgumentCaptor<WindowInsets> progressCaptor = ArgumentCaptor.forClass(WindowInsets.class);
    verify(view).onApplyWindowInsets(progressCaptor.capture());

    // IME insets interpolated to 50px.
    assertEquals(50, progressCaptor.getValue().getInsets(WindowInsets.Type.ime()).bottom);
    // Non-IME status bar insets from the current frame (60px) are preserved and not locked to 50px.
    assertEquals(60, progressCaptor.getValue().getInsets(WindowInsets.Type.statusBars()).top);
  }

  /**
   * Tests arrival of non-animated window insets while !animating.
   *
   * <p>Rationale / Added for: Fixes a critical desynchronization defect identified in adversarial
   * review. When window insets arrive without an animation (e.g. initial layout, orientation
   * change, split screen, or hardware keyboard toggle), onApplyWindowInsets must update
   * currentImeBottom and lastWindowInsets. If not updated, currentImeBottom remains 0, causing any
   * subsequent animated dismissal to start from 0 and immediately collapse on frame 1.
   */
  @Test
  public void
      imeAnimation_nonAnimatedInsetsArrival_synchronizesCurrentImeBottomAndAllowsSubsequentAnimatedDismissal() {
    View view = mock(View.class);
    when(view.getWindowSystemUiVisibility()).thenReturn(0);

    ImeSyncDeferringInsetsCallback callback = new ImeSyncDeferringInsetsCallback(view);

    // 1. Non-animated insets arrive (e.g. keyboard shown instantly or orientation changed).
    WindowInsets nonAnimatedInsets =
        new WindowInsets.Builder()
            .setInsets(WindowInsets.Type.ime(), Insets.of(0, 0, 0, FINAL_IME_BOTTOM_INSET))
            .build();
    callback.getInsetsListener().onApplyWindowInsets(view, nonAnimatedInsets);

    // 2. An animated dismissal is initiated.
    WindowInsetsAnimation closeAnimation = mock(WindowInsetsAnimation.class);
    when(closeAnimation.getTypeMask()).thenReturn(WindowInsets.Type.ime());
    callback.getAnimationCallback().onPrepare(closeAnimation);

    WindowInsets closeTargetInsets =
        new WindowInsets.Builder()
            .setInsets(WindowInsets.Type.ime(), Insets.of(0, 0, 0, 0))
            .build();
    callback.getInsetsListener().onApplyWindowInsets(view, closeTargetInsets);

    // At 50% fraction, animated insets must smoothly interpolate from 100px down to 0px (reaching
    // 50px).
    // Without synchronizing currentImeBottom, startImeBottom would have been 0px and output 0px.
    when(closeAnimation.getInterpolatedFraction()).thenReturn(0.5f);
    WindowInsets midCloseInsets =
        new WindowInsets.Builder()
            .setInsets(WindowInsets.Type.ime(), Insets.of(0, 0, 0, 50))
            .build();
    callback
        .getAnimationCallback()
        .onProgress(midCloseInsets, Collections.singletonList(closeAnimation));

    ArgumentCaptor<WindowInsets> midCloseCaptor = ArgumentCaptor.forClass(WindowInsets.class);
    verify(view, org.mockito.Mockito.atLeastOnce()).onApplyWindowInsets(midCloseCaptor.capture());
    assertEquals(50, midCloseCaptor.getValue().getInsets(WindowInsets.Type.ime()).bottom);

    // Dismissal reaches 0px at fraction 1.0f.
    when(closeAnimation.getInterpolatedFraction()).thenReturn(1.0f);
    WindowInsets terminalCloseInsets =
        new WindowInsets.Builder()
            .setInsets(WindowInsets.Type.ime(), Insets.of(0, 0, 0, 0))
            .build();
    callback
        .getAnimationCallback()
        .onProgress(terminalCloseInsets, Collections.singletonList(closeAnimation));

    callback.getAnimationCallback().onEnd(closeAnimation);
    ArgumentCaptor<WindowInsets> endInsetsCaptor = ArgumentCaptor.forClass(WindowInsets.class);
    verify(view, org.mockito.Mockito.atLeastOnce())
        .dispatchApplyWindowInsets(endInsetsCaptor.capture());
    assertEquals(0, endInsetsCaptor.getValue().getInsets(WindowInsets.Type.ime()).bottom);
  }

  /**
   * Tests non-IME animation preparation (e.g. status bar / caption bar animations).
   *
   * <p>Rationale / Added for: Fixes a state pollution defect identified in adversarial review.
   * onPrepare for non-IME animations must not set needsSave = true, ensuring that running IME
   * animations are not stalled or interrupted.
   */
  @Test
  public void imeAnimation_nonImeAnimationPrepare_doesNotSetNeedsSaveOrStallRunningImeAnimations() {
    View view = mock(View.class);
    when(view.getWindowSystemUiVisibility()).thenReturn(0);

    ImeSyncDeferringInsetsCallback callback = new ImeSyncDeferringInsetsCallback(view);

    // 1. IME animation prepared and started.
    WindowInsetsAnimation imeAnimation = mock(WindowInsetsAnimation.class);
    when(imeAnimation.getTypeMask()).thenReturn(WindowInsets.Type.ime());
    callback.getAnimationCallback().onPrepare(imeAnimation);

    WindowInsets imeTargetInsets =
        new WindowInsets.Builder()
            .setInsets(WindowInsets.Type.ime(), Insets.of(0, 0, 0, FINAL_IME_BOTTOM_INSET))
            .build();
    callback.getInsetsListener().onApplyWindowInsets(view, imeTargetInsets);

    // 2. A non-IME animation (e.g. status bar transition) prepares during IME animation,
    // followed by target insets delivery per Android WindowInsetsAnimation contract.
    WindowInsetsAnimation statusBarAnimation = mock(WindowInsetsAnimation.class);
    when(statusBarAnimation.getTypeMask()).thenReturn(WindowInsets.Type.statusBars());
    callback.getAnimationCallback().onPrepare(statusBarAnimation);
    callback.getInsetsListener().onApplyWindowInsets(view, imeTargetInsets);

    // 3. onProgress for IME animation smoothly continues after target insets capture.
    when(imeAnimation.getInterpolatedFraction()).thenReturn(0.5f);
    WindowInsets midProgressInsets =
        new WindowInsets.Builder()
            .setInsets(WindowInsets.Type.ime(), Insets.of(0, 0, 0, 50))
            .build();
    callback
        .getAnimationCallback()
        .onProgress(midProgressInsets, Collections.singletonList(imeAnimation));

    ArgumentCaptor<WindowInsets> progressCaptor = ArgumentCaptor.forClass(WindowInsets.class);
    verify(view).onApplyWindowInsets(progressCaptor.capture());
    assertEquals(50, progressCaptor.getValue().getInsets(WindowInsets.Type.ime()).bottom);
  }

  /**
   * Tests cleanup of callbacks and internal state in remove().
   *
   * <p>Rationale / Added for: Verifies that unhooking listeners from the view resets all internal
   * state flags (animating, needsSave, startImeBottom, currentImeBottom) to prevent stale state on
   * re-install.
   */
  @Test
  public void imeAnimation_remove_cleansUpAllState() {
    View view = mock(View.class);
    ImeSyncDeferringInsetsCallback callback = new ImeSyncDeferringInsetsCallback(view);
    callback.install();
    verify(view).setWindowInsetsAnimationCallback(callback.getAnimationCallback());
    verify(view).setOnApplyWindowInsetsListener(callback.getInsetsListener());

    callback.remove();
    verify(view).setWindowInsetsAnimationCallback(null);
    verify(view).setOnApplyWindowInsetsListener(null);
    assertEquals(
        ImeSyncDeferringInsetsCallback.AnimationStateMachine.State.IDLE,
        callback.getStateMachine().getState());
    assertEquals(0, callback.getStateMachine().getStartImeBottom());
    assertEquals(0, callback.getStateMachine().getCurrentImeBottom());
  }

  /**
   * Tests discrete state transitions of AnimationStateMachine across a full animation lifecycle.
   *
   * <p>Rationale / Added for: Validates the encapsulated State Machine helper class transitions
   * explicitly: IDLE -> PREPARED -> ANIMATING -> IDLE.
   */
  @Test
  public void stateMachine_fullLifecycleTransitions() {
    View view = mock(View.class);
    ImeSyncDeferringInsetsCallback.AnimationStateMachine stateMachine =
        new ImeSyncDeferringInsetsCallback.AnimationStateMachine(WindowInsets.Type.ime());

    // 1. Initial State: IDLE
    assertEquals(
        ImeSyncDeferringInsetsCallback.AnimationStateMachine.State.IDLE, stateMachine.getState());

    // 2. onPrepare -> PREPARED
    WindowInsetsAnimation imeAnimation = mock(WindowInsetsAnimation.class);
    when(imeAnimation.getTypeMask()).thenReturn(WindowInsets.Type.ime());
    stateMachine.onPrepare(imeAnimation);
    assertEquals(
        ImeSyncDeferringInsetsCallback.AnimationStateMachine.State.PREPARED,
        stateMachine.getState());

    // 3. onApplyWindowInsets -> ANIMATING
    WindowInsets targetInsets =
        new WindowInsets.Builder()
            .setInsets(WindowInsets.Type.ime(), Insets.of(0, 0, 0, FINAL_IME_BOTTOM_INSET))
            .build();
    WindowInsets consumedResult = stateMachine.onApplyWindowInsets(view, targetInsets);
    assertEquals(WindowInsets.CONSUMED, consumedResult);
    assertEquals(
        ImeSyncDeferringInsetsCallback.AnimationStateMachine.State.ANIMATING,
        stateMachine.getState());

    // 4. onProgress -> remains ANIMATING
    when(imeAnimation.getInterpolatedFraction()).thenReturn(0.5f);
    WindowInsets progressInsets =
        new WindowInsets.Builder()
            .setInsets(WindowInsets.Type.ime(), Insets.of(0, 0, 0, 50))
            .build();
    stateMachine.onProgress(view, progressInsets, Collections.singletonList(imeAnimation));
    assertEquals(
        ImeSyncDeferringInsetsCallback.AnimationStateMachine.State.ANIMATING,
        stateMachine.getState());
    assertEquals(50, stateMachine.getCurrentImeBottom());

    // 5. onEnd -> settles and transitions to IDLE
    stateMachine.onEnd(view, imeAnimation);
    assertEquals(
        ImeSyncDeferringInsetsCallback.AnimationStateMachine.State.IDLE, stateMachine.getState());
    assertEquals(100, stateMachine.getCurrentImeBottom());
  }

  /**
   * Tests discrete state transition when an animation is aborted before onApplyWindowInsets.
   *
   * <p>Rationale / Added for: Verifies that onEnd while in PREPARED state resets cleanly to IDLE
   * without applying stale insets.
   */
  @Test
  public void stateMachine_abortedLifecycle_resetsToIdle() {
    View view = mock(View.class);
    ImeSyncDeferringInsetsCallback.AnimationStateMachine stateMachine =
        new ImeSyncDeferringInsetsCallback.AnimationStateMachine(WindowInsets.Type.ime());

    WindowInsetsAnimation imeAnimation = mock(WindowInsetsAnimation.class);
    when(imeAnimation.getTypeMask()).thenReturn(WindowInsets.Type.ime());

    stateMachine.onPrepare(imeAnimation);
    assertEquals(
        ImeSyncDeferringInsetsCallback.AnimationStateMachine.State.PREPARED,
        stateMachine.getState());

    // Aborted: onEnd called immediately
    stateMachine.onEnd(view, imeAnimation);
    assertEquals(
        ImeSyncDeferringInsetsCallback.AnimationStateMachine.State.IDLE, stateMachine.getState());
  }

  /**
   * Tests that onEnd transitions to IDLE before invoking view.dispatchApplyWindowInsets.
   *
   * <p>Rationale / Added for: Fixes a critical defect identified in adversarial review. In a real
   * Android View hierarchy, view.dispatchApplyWindowInsets immediately forwards to the view's
   * OnApplyWindowInsetsListener (the callback's insets listener). If state is still ANIMATING,
   * onApplyWindowInsets returns CONSUMED and drops the final insets. Transitioning to IDLE before
   * dispatching ensures the settled insets are delivered to view.onApplyWindowInsets.
   */
  @Test
  public void stateMachine_onEnd_transitionsToIdleBeforeDispatchingSoViewReceivesSettledInsets() {
    View view = mock(View.class);
    ImeSyncDeferringInsetsCallback.AnimationStateMachine stateMachine =
        new ImeSyncDeferringInsetsCallback.AnimationStateMachine(WindowInsets.Type.ime());

    WindowInsetsAnimation imeAnimation = mock(WindowInsetsAnimation.class);
    when(imeAnimation.getTypeMask()).thenReturn(WindowInsets.Type.ime());

    // 1. Prepare and capture target insets
    stateMachine.onPrepare(imeAnimation);
    WindowInsets targetInsets =
        new WindowInsets.Builder()
            .setInsets(WindowInsets.Type.ime(), Insets.of(0, 0, 0, FINAL_IME_BOTTOM_INSET))
            .build();
    stateMachine.onApplyWindowInsets(view, targetInsets);
    assertEquals(
        ImeSyncDeferringInsetsCallback.AnimationStateMachine.State.ANIMATING,
        stateMachine.getState());

    // 2. Simulate Android framework forwarding: dispatchApplyWindowInsets invokes
    // onApplyWindowInsets
    org.mockito.Mockito.doAnswer(
            invocation -> {
              WindowInsets insets = invocation.getArgument(0);
              return stateMachine.onApplyWindowInsets(view, insets);
            })
        .when(view)
        .dispatchApplyWindowInsets(org.mockito.ArgumentMatchers.any(WindowInsets.class));

    // 3. onEnd is called
    stateMachine.onEnd(view, imeAnimation);

    // State is IDLE, and view.onApplyWindowInsets was invoked with targetInsets
    assertEquals(
        ImeSyncDeferringInsetsCallback.AnimationStateMachine.State.IDLE, stateMachine.getState());
    ArgumentCaptor<WindowInsets> captor = ArgumentCaptor.forClass(WindowInsets.class);
    verify(view, org.mockito.Mockito.atLeastOnce()).onApplyWindowInsets(captor.capture());
    assertEquals(
        FINAL_IME_BOTTOM_INSET, captor.getValue().getInsets(WindowInsets.Type.ime()).bottom);
  }

  /**
   * Tests backgrounding and resuming the app with a cancelled hide animation (issue #191156).
   *
   * <p>Rationale / Added for: Verifies that when an app resumes from the background after the
   * keyboard is dismissed, and Android cancels an internal hide animation
   * (PHASE_CLIENT_ANIMATION_CANCEL), stale keyboard insets from the previous open state are not
   * restored.
   */
  @Test
  public void backgroundResume_cancelledHideAnimation_doesNotRestoreStaleKeyboardInsets() {
    View view = mock(View.class);
    ImeSyncDeferringInsetsCallback callback = new ImeSyncDeferringInsetsCallback(view);

    WindowInsetsAnimation openAnimation = mock(WindowInsetsAnimation.class);
    when(openAnimation.getTypeMask()).thenReturn(WindowInsets.Type.ime());

    // 1. Keyboard opens to full height (e.g. 100px).
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

    // Verify keyboard settled at 100px.
    ArgumentCaptor<WindowInsets> openCaptor = ArgumentCaptor.forClass(WindowInsets.class);
    verify(view).dispatchApplyWindowInsets(openCaptor.capture());
    assertEquals(
        FINAL_IME_BOTTOM_INSET, openCaptor.getValue().getInsets(WindowInsets.Type.ime()).bottom);

    // 2. App is backgrounded and resumes: OS delivers non-animated insets with ime = 0.
    WindowInsets resumeZeroInsets =
        new WindowInsets.Builder()
            .setInsets(WindowInsets.Type.ime(), Insets.of(0, 0, 0, 0))
            .build();
    callback.getInsetsListener().onApplyWindowInsets(view, resumeZeroInsets);

    ArgumentCaptor<WindowInsets> resumeCaptor = ArgumentCaptor.forClass(WindowInsets.class);
    verify(view, org.mockito.Mockito.atLeastOnce()).onApplyWindowInsets(resumeCaptor.capture());
    assertEquals(0, resumeCaptor.getValue().getInsets(WindowInsets.Type.ime()).bottom);

    // 3. Android InsetsController initiates hide(ime()) animation, which gets cancelled
    // (onPrepare called, followed immediately by onEnd without onApplyWindowInsets or onProgress).
    WindowInsetsAnimation cancelledHideAnimation = mock(WindowInsetsAnimation.class);
    when(cancelledHideAnimation.getTypeMask()).thenReturn(WindowInsets.Type.ime());

    callback.getAnimationCallback().onPrepare(cancelledHideAnimation);
    callback.getAnimationCallback().onEnd(cancelledHideAnimation);

    // 4. Assert that view.dispatchApplyWindowInsets was NOT called again with the stale 100px
    // insets.
    // The only dispatchApplyWindowInsets call should have been the initial open from step 1.
    verify(view, org.mockito.Mockito.times(1))
        .dispatchApplyWindowInsets(org.mockito.ArgumentMatchers.any(WindowInsets.class));
  }
}
