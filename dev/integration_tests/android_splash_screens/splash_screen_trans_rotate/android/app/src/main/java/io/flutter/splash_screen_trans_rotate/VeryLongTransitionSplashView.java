// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.splash_screen_trans_rotate;

import android.animation.Animator;
import android.animation.AnimatorListenerAdapter;
import android.animation.ValueAnimator;
import android.content.Context;
import android.graphics.Color;
import android.os.Bundle;
import android.util.Log;
import android.view.ViewPropertyAnimator;
import android.widget.FrameLayout;
import androidx.annotation.Nullable;
import androidx.annotation.NonNull;

/**
 * {@code View} that appears entirely yellow and slowly fades away, upon request.
 * <p>
 * Call {@link #transitionToFlutter(Runnable)} to begin fading away.
 * <p>
 * Call {@link #saveSplashState()} to save the current state of this splash {@code View},
 * e.g., the current state of the fade transition.
 * <p>
 * Call {@link #restoreSplashState(Bundle)} to restore a previous state of this splash
 * {@code View}, e.g., the previous state of an interrupted fade transition.
 */
public class VeryLongTransitionSplashView extends FrameLayout {
  private static final String TAG = "VeryLongTransitionSplashView";

  private static final int ANIMATION_TIME_IN_MILLIS = 10000;

  private float transitionPercentWhenAnimationStarted = 0.0f;
  private float totalTransitionPercent = 0.0f;
  private Runnable onTransitionComplete;
  private ViewPropertyAnimator fadeAnimator;

  private final ValueAnimator.AnimatorUpdateListener animatorUpdateListener = new ValueAnimator.AnimatorUpdateListener() {
    @Override
    public void onAnimationUpdate(ValueAnimator animation) {
      // We have to represent transition percent as a starting value + the fraction of the
      // running animation. This is because there is no way to start an Animator and inform
      // it that it should already be X percent complete.
      totalTransitionPercent = transitionPercentWhenAnimationStarted
          + (animation.getAnimatedFraction() * (1.0f - transitionPercentWhenAnimationStarted));
    }
  };

  private final Animator.AnimatorListener animatorListener = new AnimatorListenerAdapter() {
    @Override
    public void onAnimationEnd(Animator animation) {
      // Remove all animation listeners to avoid memory leaks.
      animation.removeAllListeners();

      // Notify listener that we're done transitioning.
      if (onTransitionComplete != null) {
        onTransitionComplete.run();
      }
    }

    @Override
    public void onAnimationCancel(Animator animation) {
      // Remove all animation listeners to avoid memory leaks.
      animation.removeAllListeners();
    }
  };

  public VeryLongTransitionSplashView(Context context) {
    super(context);

    // Give the UI a yellow background to prove that this splash screen view takes up
    // all available space.
    setBackgroundColor(Color.YELLOW);
  }

  /**
   * Begins fading out.
   * <p>
   * If a previous transition state was restored, this method will begin fading out from the
   * previously restored transition percent. See {@link #restoreSplashState(Bundle)}.
   */
  public void transitionToFlutter(@NonNull Runnable onTransitionComplete) {
    Log.d(TAG, "Transitioning to flutter.");
    this.onTransitionComplete = onTransitionComplete;

    fadeAnimator = animate()
        .alpha(0.0f)
        .setDuration(Math.round(ANIMATION_TIME_IN_MILLIS * (1.0 - totalTransitionPercent)))
        .setUpdateListener(animatorUpdateListener)
        .setListener(animatorListener);
    fadeAnimator.start();
  }

  @Override
  protected void onDetachedFromWindow() {
    if (fadeAnimator != null) {
      // Cancel our animator to avoid leaks.
      fadeAnimator.cancel();
    }
    super.onDetachedFromWindow();
  }

  @Nullable
  public Bundle saveSplashState() {
    Log.d(TAG, "Saving splash state.");
    if (totalTransitionPercent > 0.0f && totalTransitionPercent < 1.0f) {
      Bundle state = new Bundle();
      state.putFloat("totalTransitionPercent", totalTransitionPercent);
      Log.d(TAG, String.format("Transition percent: %.2f", totalTransitionPercent));
      return state;
    } else {
      Log.d(TAG, "No transition to save.");
      return null;
    }
  }

  public void restoreSplashState(@Nullable Bundle bundle) {
    Log.d(TAG, "Restoring splash state: " + bundle);
    if (bundle != null) {
      transitionPercentWhenAnimationStarted = bundle.getFloat("totalTransitionPercent");
      setAlpha(1.0f - transitionPercentWhenAnimationStarted);
      Log.d(TAG, String.format("State restored with transition percent: %.2f", transitionPercentWhenAnimationStarted));
    } else {
      Log.d(TAG, "No state provided.");
    }
  }
}
