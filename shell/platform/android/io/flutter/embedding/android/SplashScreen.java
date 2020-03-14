// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.embedding.android;

import android.annotation.SuppressLint;
import android.content.Context;
import android.os.Bundle;
import android.view.View;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

/**
 * Splash screen configuration for a given Flutter experience.
 *
 * <p>Implementations provide a visual representation of a splash screen in {@link
 * #createSplashView(Context, Bundle)}, and implement a transition from the splash UI to Flutter's
 * UI in {@link #transitionToFlutter(Runnable)}.
 */
public interface SplashScreen {
  /**
   * Creates a {@code View} to be displayed as a splash screen before Flutter renders its first
   * frame.
   *
   * <p>This method can be called at any time, and may be called multiple times depending on Android
   * configuration changes that require recreation of a view hierarchy. Implementers that provide a
   * stateful splash view, such as one with animations, should take care to migrate that animation
   * state from the previously returned splash view to the newly created splash view.
   */
  @Nullable
  View createSplashView(@NonNull Context context, @Nullable Bundle savedInstanceState);

  /**
   * Invoked by Flutter when Flutter has rendered its first frame, and would like the {@code
   * splashView} to disappear.
   *
   * <p>The provided {@code onTransitionComplete} callback must be invoked when the splash {@code
   * View} has finished transitioning itself away. The splash {@code View} will be removed and
   * destroyed when the callback is invoked.
   */
  void transitionToFlutter(@NonNull Runnable onTransitionComplete);

  /**
   * Returns {@code true} if the splash {@code View} built by this {@code SplashScreen} remembers
   * its transition progress across configuration changes by saving that progress to {@code View}
   * state. Returns {@code false} otherwise.
   *
   * <p>The typical return value for this method is {@code false}. When the return value is {@code
   * false}, the following can happen:
   *
   * <ol>
   *   <li>Splash {@code View} begins transitioning to the Flutter UI.
   *   <li>A configuration change occurs, like an orientation change, and the {@code Activity} is
   *       re-created, along with the {@code View} hierarchy.
   *   <li>The remainder of the splash transition is skipped and the Flutter UI is displayed.
   * </ol>
   *
   * In the vast majority of cases, skipping a little bit of the splash transition should be
   * acceptable. Most users will never experience such a situation, and those that do are unlikely
   * to notice the visual artifact. However, a workaround is available for those developers who need
   * it.
   *
   * <p>Returning {@code true} from this method will cause the given splash {@code View} to be
   * displayed in the {@code View} hierarchy, even if Flutter has already rendered its first frame.
   * It is then the responsibility of the splash {@code View} to remember its previous transition
   * progress, restart any animations, and then trigger its completion callback when appropriate. It
   * is also the responsibility of the splash {@code View} to immediately invoke the completion
   * callback if it has already completed its transition. By meeting these requirements, and
   * returning {@code true} from this method, the splash screen experience will be completely
   * seamless, including configuration changes.
   */
  // We suppress NewApi because the CI linter thinks that "default" methods are unsupported.
  @SuppressLint("NewApi")
  default boolean doesSplashViewRememberItsTransition() {
    return false;
  }

  /**
   * Returns whatever state is necessary to restore a splash {@code View} after destruction and
   * recreation, e.g., orientation change.
   */
  // We suppress NewApi because the CI linter thinks that "default" methods are unsupported.
  @SuppressLint("NewApi")
  @Nullable
  default Bundle saveSplashScreenState() {
    return null;
  }
}
