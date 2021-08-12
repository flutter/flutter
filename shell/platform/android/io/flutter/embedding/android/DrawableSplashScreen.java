// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.embedding.android;

import android.animation.Animator;
import android.content.Context;
import android.graphics.drawable.Drawable;
import android.os.Bundle;
import android.util.AttributeSet;
import android.view.View;
import android.widget.ImageView;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

/**
 * {@link SplashScreen} that displays a given {@link Drawable}, which then fades its alpha to zero
 * when instructed to {@link #transitionToFlutter(Runnable)}.
 *
 * <p>Please use the new Splash screen API available on Android S. On lower versions of Android,
 * it's no longer necessary to display a splash screen to wait for the Flutter first frame.
 *
 * @deprecated
 */
@Deprecated
public final class DrawableSplashScreen implements SplashScreen {
  private final Drawable drawable;
  private final ImageView.ScaleType scaleType;
  private final long crossfadeDurationInMillis;
  private DrawableSplashScreenView splashView;

  /**
   * Constructs a {@code DrawableSplashScreen} that displays the given {@code drawable} and
   * crossfades to Flutter content in 500 milliseconds.
   *
   * @param drawable A drawable to display on the Splash screen view.
   */
  public DrawableSplashScreen(@NonNull Drawable drawable) {
    this(drawable, ImageView.ScaleType.FIT_XY, 500);
  }

  /**
   * Constructs a {@code DrawableSplashScreen} that displays the given {@code drawable} and
   * crossfades to Flutter content in the given {@code crossfadeDurationInMillis}.
   *
   * @param drawable The {@code Drawable} to be displayed as a splash screen.
   * @param scaleType The {@link android.widget.ImageView.ScaleType} to be applied to the {@code
   *     Drawable} when the {@code Drawable} is displayed full-screen.
   * @param crossfadeDurationInMillis Duration of the crossfade in milliseconds.
   */
  public DrawableSplashScreen(
      @NonNull Drawable drawable,
      @NonNull ImageView.ScaleType scaleType,
      long crossfadeDurationInMillis) {
    this.drawable = drawable;
    this.scaleType = scaleType;
    this.crossfadeDurationInMillis = crossfadeDurationInMillis;
  }

  @Nullable
  @Override
  public View createSplashView(@NonNull Context context, @Nullable Bundle savedInstanceState) {
    splashView = new DrawableSplashScreenView(context);
    splashView.setSplashDrawable(drawable, scaleType);
    return splashView;
  }

  @Override
  public void transitionToFlutter(@NonNull Runnable onTransitionComplete) {
    if (splashView == null) {
      onTransitionComplete.run();
      return;
    }

    splashView
        .animate()
        .alpha(0.0f)
        .setDuration(crossfadeDurationInMillis)
        .setListener(
            new Animator.AnimatorListener() {
              @Override
              public void onAnimationStart(Animator animation) {}

              @Override
              public void onAnimationEnd(Animator animation) {
                onTransitionComplete.run();
              }

              @Override
              public void onAnimationCancel(Animator animation) {
                onTransitionComplete.run();
              }

              @Override
              public void onAnimationRepeat(Animator animation) {}
            });
  }

  // Public for Android OS requirements. This View should not be used by external developers.
  public static class DrawableSplashScreenView extends ImageView {
    public DrawableSplashScreenView(@NonNull Context context) {
      this(context, null, 0);
    }

    public DrawableSplashScreenView(@NonNull Context context, @Nullable AttributeSet attrs) {
      this(context, attrs, 0);
    }

    public DrawableSplashScreenView(
        @NonNull Context context, @Nullable AttributeSet attrs, int defStyleAttr) {
      super(context, attrs, defStyleAttr);
    }

    public void setSplashDrawable(@Nullable Drawable drawable) {
      setSplashDrawable(drawable, ImageView.ScaleType.FIT_XY);
    }

    public void setSplashDrawable(
        @Nullable Drawable drawable, @NonNull ImageView.ScaleType scaleType) {
      setScaleType(scaleType);
      setImageDrawable(drawable);
    }
  }
}
