// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.splash_screen_kitchen_sink;

import android.animation.TimeAnimator;
import android.annotation.SuppressLint;
import android.content.Context;
import android.graphics.Color;
import android.os.Bundle;
import android.util.Log;
import android.view.View;
import android.view.ViewGroup;
import android.view.animation.AccelerateInterpolator;
import android.view.animation.AlphaAnimation;
import android.view.animation.Animation;
import android.view.animation.AnimationSet;
import android.view.animation.ScaleAnimation;
import android.widget.FrameLayout;
import android.widget.ImageView;

import androidx.annotation.Nullable;

public class FlutterZoomSplashView extends FrameLayout {
  private static final String TAG = "FlutterZoomSplashView";

  private float transitionPercentWhenAnimationStarted = 0.0f;
  private float totalTransitionPercent = 0.0f;
  private Runnable onTransitionComplete;
  private View whiteUnderlay;
  private ImageView imageView;
  private AnimationSet transitionAnimation;
  private TimeAnimator timeAnimator;

  private final TimeAnimator.TimeListener timeListener = new TimeAnimator.TimeListener() {
    @Override
    public void onTimeUpdate(TimeAnimator animation, long totalTime, long deltaTime) {
      // We have to represent transition percent as a starting value + the fraction of the
      // running animation. This is because there is no way to start an Animator and inform
      // it that it should already be X percent complete.
      totalTransitionPercent = transitionPercentWhenAnimationStarted
          + (animation.getAnimatedFraction() * (1.0f - transitionPercentWhenAnimationStarted));
    }
  };

  private final Animation.AnimationListener animationListener = new Animation.AnimationListener() {
    @Override
    public void onAnimationStart(Animation animation) {}

    @Override
    public void onAnimationEnd(Animation animation) {
      Log.d(TAG, "Animation ended.");
      transitionAnimation = null;
      animation.setAnimationListener(null);

      timeAnimator.cancel();
      timeAnimator.setTimeListener(null);

      onTransitionComplete.run();
    }

    @Override
    public void onAnimationRepeat(Animation animation) {}
  };

  public FlutterZoomSplashView(Context context) {
    super(context);
    Log.d(TAG, "Creating FlutterZoomSplashView");

    whiteUnderlay = new View(getContext());
    whiteUnderlay.setBackgroundColor(Color.WHITE);
    addView(whiteUnderlay);

    imageView = new ImageView(getContext());
    imageView.setImageDrawable(getResources().getDrawable(R.drawable.splash_screen, getContext().getTheme()));
    imageView.setScaleType(ImageView.ScaleType.FIT_XY);
    addView(imageView, new LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT));
  }

  public void transitionToFlutter(Runnable onTransitionComplete) {
    Log.d(TAG, "Animating transition.");
    this.onTransitionComplete = onTransitionComplete;
    animateWhiteUnderlay();
    animateLogoOverlay();
  }

  private void animateWhiteUnderlay() {
    AlphaAnimation fadeOut = new AlphaAnimation(1f, 0f);
    fadeOut.setStartOffset(0);
    fadeOut.setDuration(500);

    whiteUnderlay.startAnimation(fadeOut);
  }

  @SuppressLint("NewApi")
  private void animateLogoOverlay() {
    // Notice that each animation might begin part way through the animation based on
    // a previous transition amount that we need to restore.
    float startAlpha = 1f - totalTransitionPercent;
    long fadeStartDelay = Math.round(400 * (1.0 - (Math.min(totalTransitionPercent, 0.8) / 0.8)));
    long fadeDuration = Math.round(100 * (1.0 - Math.max(0, (totalTransitionPercent - 0.8)) / 0.2));

    float startScale = 1f + (7f * totalTransitionPercent);
    long scaleDuration = Math.round(500 * (1.0 - totalTransitionPercent));

    long globalTimerLength = Math.round(500 * (1.0 - totalTransitionPercent));

    Animation scaleUp = new ScaleAnimation(
        startScale, 8f,
        startScale, 8f,
        Animation.RELATIVE_TO_SELF, 0.5f,
        Animation.RELATIVE_TO_SELF, 0.5f
    );
    scaleUp.setFillAfter(true);
    scaleUp.setDuration(scaleDuration);
    scaleUp.setInterpolator(new AccelerateInterpolator());

    AlphaAnimation fadeOut = new AlphaAnimation(startAlpha, 0f);
    fadeOut.setStartOffset(fadeStartDelay);
    fadeOut.setDuration(fadeDuration);

    transitionAnimation = new AnimationSet(false);
    transitionAnimation.addAnimation(scaleUp);
    transitionAnimation.addAnimation(fadeOut);
    transitionAnimation.setFillAfter(true);
    transitionAnimation.setAnimationListener(animationListener);

    timeAnimator = new TimeAnimator();
    timeAnimator.setDuration(globalTimerLength);
    timeAnimator.setTimeListener(timeListener);

    imageView.startAnimation(transitionAnimation);
    timeAnimator.start();
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
      Log.d(TAG, String.format("State restored with transition percent: %.2f", transitionPercentWhenAnimationStarted));
    } else {
      Log.d(TAG, "No state provided.");
    }
  }
}
