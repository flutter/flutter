// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.splash_screen_load_rotate;

import android.animation.Animator;
import android.animation.AnimatorListenerAdapter;
import android.annotation.SuppressLint;
import android.content.Context;
import android.graphics.Color;
import android.os.Bundle;
import android.util.Log;
import android.view.Gravity;
import android.view.View;
import android.view.ViewPropertyAnimator;
import android.view.animation.AccelerateDecelerateInterpolator;
import android.widget.FrameLayout;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

public class NeverEndingSplashView extends FrameLayout {
  private static final String TAG = "NeverEndingSplashView";

  private static final float ANIMATION_SLIDE_DISTANCE = 800;
  private static final int ANIMATION_TIME_IN_MILLIS = 5000;

  private final View animatedThing;
  private float destinationTranslationY = 0;
  private ViewPropertyAnimator animator;

  private final Animator.AnimatorListener animatorListener = new AnimatorListenerAdapter() {
    @SuppressLint("NewApi")
    @Override
    public void onAnimationEnd(Animator animation) {
      // Remove all animation listeners to avoid memory leaks.
      animation.removeAllListeners();

      // Start the next animation by reversing direction.
      if (destinationTranslationY < 0) {
        animateTheThing(ANIMATION_SLIDE_DISTANCE / 2);
      } else {
        animateTheThing(-ANIMATION_SLIDE_DISTANCE / 2);
      }
    }

    @SuppressLint("NewApi")
    @Override
    public void onAnimationCancel(Animator animation) {
      // Remove all animation listeners to avoid memory leaks.
      animation.removeAllListeners();
    }
  };

  @SuppressLint("NewApi")
  public NeverEndingSplashView(Context context) {
    super(context);
    // Give the UI a yellow background to prove that this splash screen view takes up
    // all available space.
    setBackgroundColor(Color.YELLOW);

    // Create and display a little square that slides up and down.
    animatedThing = new View(context);
    animatedThing.setBackgroundColor(Color.BLACK);
    addView(animatedThing, new FrameLayout.LayoutParams(100, 100, Gravity.CENTER));

    // Start the animation immediately.
    animateTheThing(ANIMATION_SLIDE_DISTANCE / 2);
  }

  @SuppressLint("NewApi")
  private void animateTheThing(float destinationTranslationY) {
    // Save the destination translation Y so that we can save our state, if needed.
    this.destinationTranslationY = destinationTranslationY;

    animator = animatedThing
        .animate()
        .translationY(destinationTranslationY)
        .setDuration(Math.round(ANIMATION_TIME_IN_MILLIS * Math.abs((destinationTranslationY - animatedThing.getTranslationY()) / ANIMATION_SLIDE_DISTANCE)))
        .setInterpolator(new AccelerateDecelerateInterpolator())
        .setListener(animatorListener);
    animator.start();
  }

  @SuppressLint("NewApi")
  @Override
  protected void onDetachedFromWindow() {
    if (animator != null) {
      // Cancel our animation to avoid leaks.
      animator.cancel();
    }
    super.onDetachedFromWindow();
  }

  @Nullable
  public Bundle saveSplashState() {
    Log.d(TAG, "Saving splash state.");
    Bundle state = new Bundle();
    state.putFloat("currentTranslationY", animatedThing.getTranslationY());
    state.putFloat("destinationTranslationY", destinationTranslationY);
    return state;
  }

  public void restoreSplashState(@Nullable Bundle bundle) {
    Log.d(TAG, "Restoring splash state: " + bundle);
    if (bundle != null) {
      this.destinationTranslationY = bundle.getFloat("destinationTranslationY");
      this.animatedThing.setTranslationY(bundle.getFloat("currentTranslationY"));
      animateTheThing(destinationTranslationY);
    } else {
      Log.d(TAG, "No state provided.");
    }
  }
}
