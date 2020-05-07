// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.splash_screen_load_rotate;

import android.content.Context;
import android.os.Bundle;
import android.view.View;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import io.flutter.embedding.android.SplashScreen;

public class SplashScreenThatNeverEnds implements SplashScreen {
  private NeverEndingSplashView splashView;

  @Nullable
  public View createSplashView(@NonNull Context context, @Nullable Bundle bundle) {
    if (splashView == null) {
      splashView = new NeverEndingSplashView(context);
      splashView.restoreSplashState(bundle);
    }
    return splashView;
  }

  public void transitionToFlutter(Runnable onTransitionComplete) {
    // Do nothing. Never ends.
  }

  /**
   * Informs Flutter that we are capable of restoring a transition that was previously
   * in progress.
   * <p>
   * A splash transition can be interrupted by configuration changes or other OS operations.
   * <p>
   * If we were to return false here, then an orientation change would skip the rest of
   * the transition and jump directly to the Flutter UI.
   */
  @Override
  public boolean doesSplashViewRememberItsTransition() {
    return true;
  }

  /**
   * Saves the state of our {@code splashView} so that we can restore the animation
   * state when we are recreated after a config change or other recreation event.
   */
  @Override
  @Nullable
  public Bundle saveSplashScreenState() {
    if (splashView != null) {
      return splashView.saveSplashState();
    } else {
      return null;
    }
  }

}
