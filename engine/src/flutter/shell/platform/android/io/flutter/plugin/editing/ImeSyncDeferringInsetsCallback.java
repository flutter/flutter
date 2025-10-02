// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugin.editing;

import static io.flutter.Build.API_LEVELS;

import android.annotation.SuppressLint;
import android.graphics.Insets;
import android.os.Build;
import android.view.View;
import android.view.WindowInsets;
import android.view.WindowInsetsAnimation;
import androidx.annotation.Keep;
import androidx.annotation.NonNull;
import androidx.annotation.RequiresApi;
import androidx.annotation.VisibleForTesting;
import androidx.core.view.ViewCompat;
import androidx.core.view.WindowInsetsCompat;
import java.util.List;

// Loosely based off of
// https://github.com/android/user-interface-samples/blob/main/WindowInsetsAnimation/app/src/main/java/com/google/android/samples/insetsanimation/RootViewDeferringInsetsCallback.kt
//
// When the IME is shown or hidden, it immediately sends an onApplyWindowInsets call
// with the final state of the IME. This initial call disrupts the animation, which
// causes a flicker in the beginning.
//
// To fix this, this class extends WindowInsetsAnimation.Callback and implements
// OnApplyWindowInsetsListener. We capture and defer the initial call to
// onApplyWindowInsets while the animation completes. When the animation
// finishes, we can then release the call by invoking it in the onEnd callback
//
// The WindowInsetsAnimation.Callback extension forwards the new state of the
// IME inset from onProgress() to the framework. We also make use of the
// onStart callback to detect which calls to onApplyWindowInsets would
// interrupt the animation and defer it.
//
// By implementing OnApplyWindowInsetsListener, we are able to capture Android's
// attempts to call the FlutterView's onApplyWindowInsets. When a call to onStart
// occurs, we can mark any non-animation calls to onApplyWindowInsets() that
// occurs between prepare and start as deferred by using this class' wrapper
// implementation to cache the WindowInsets passed in and turn the current call into
// a no-op. When onEnd indicates the end of the animation, the deferred call is
// dispatched again, this time avoiding any flicker since the animation is now
// complete.
@VisibleForTesting
@RequiresApi(API_LEVELS.API_30)
@SuppressLint({"NewApi", "Override"})
@Keep
class ImeSyncDeferringInsetsCallback {
  private final int deferredInsetTypes = WindowInsets.Type.ime();
  private View view;
  private WindowInsets lastWindowInsets;
  private AnimationCallback animationCallback;
  private InsetsListener insetsListener;
  private ImeVisibilityListener imeVisibilityListener;

  // True when an animation that matches deferredInsetTypes is active.
  //
  // While this is active, this class will capture the initial window inset
  // sent into lastWindowInsets by flagging needsSave to true, and will hold
  // onto the intitial inset until the animation is completed, when it will
  // re-dispatch the inset change.
  private boolean animating = false;
  // When an animation begins, android sends a WindowInset with the final
  // state of the animation. When needsSave is true, we know to capture this
  // initial WindowInset.
  //
  // Certain actions, like dismissing the keyboard, can trigger multiple
  // animations that are slightly offset in start time. To capture the
  // correct final insets in these situations we update needsSave to true
  // in each onPrepare callback, so that we save the latest final state
  // to apply in onEnd.
  private boolean needsSave = false;

  ImeSyncDeferringInsetsCallback(@NonNull View view) {
    this.view = view;
    this.animationCallback = new AnimationCallback();
    this.insetsListener = new InsetsListener();
  }

  // Add this object's event listeners to its view.
  void install() {
    view.setWindowInsetsAnimationCallback(animationCallback);
    view.setOnApplyWindowInsetsListener(insetsListener);
  }

  // Remove this object's event listeners from its view.
  void remove() {
    view.setWindowInsetsAnimationCallback(null);
    view.setOnApplyWindowInsetsListener(null);
  }

  // Set a listener to be notified when the IME visibility changes.
  void setImeVisibilityListener(ImeVisibilityListener imeVisibilityListener) {
    this.imeVisibilityListener = imeVisibilityListener;
  }

  @VisibleForTesting
  View.OnApplyWindowInsetsListener getInsetsListener() {
    return insetsListener;
  }

  @VisibleForTesting
  WindowInsetsAnimation.Callback getAnimationCallback() {
    return animationCallback;
  }

  @VisibleForTesting
  ImeVisibilityListener getImeVisibilityListener() {
    return imeVisibilityListener;
  }

  // WindowInsetsAnimation.Callback was introduced in API level 30.  The callback
  // subclass is separated into an inner class in order to avoid warnings from
  // the Android class loader on older platforms.
  @Keep
  private class AnimationCallback extends WindowInsetsAnimation.Callback {
    AnimationCallback() {
      super(WindowInsetsAnimation.Callback.DISPATCH_MODE_CONTINUE_ON_SUBTREE);
    }

    // In class AnimationCallback

    // In class AnimationCallback

    private boolean shouldExcludeNavigationInserts(View view) {
      // On modern APIs, we check if the window is laid out edge-to-edge.
      // On older APIs, we fall back to the system UI flags.
      if (Build.VERSION.SDK_INT >= API_LEVELS.API_30) {
        // If isDrawingBehindNavBar is true, it means the app is edge-to-edge,
        // so we should NOT exclude the navigation insets. The original method name
        // is inverted, so we return the opposite of our check.
        return !isDrawingBehindNavBar(view);
      }

      // Fallback for older APIs before WindowInsetsAnimation.Callback existed.
      // This logic is retained for consistency with potential older code paths,
      // even though this class is @RequiresApi(30).
      return !isDrawingBehindNavBarLegacy(view);
    }

    /**
     * Checks if the application is drawing behind the navigation bar on API 30+.
     *
     * <p>An app is considered edge-to-edge if the system is NOT applying a bottom inset for the
     * navigation bar by default. This is controlled by `WindowCompat.setDecorFitsSystemWindows`.
     * When `decorFitsSystemWindows` is false (edge-to-edge), the system does not add padding, and
     * the navigation bar insets are passed to the app to handle.
     */
    @RequiresApi(API_LEVELS.API_30)
    private boolean isDrawingBehindNavBar(View view) {
      // The modern equivalent of the legacy UI flags is checking decorFitsSystemWindows.
      // Since there's no direct getter, we can reliably infer this state by checking
      // if the system is applying insets for the navigation bars.
      WindowInsetsCompat insets = ViewCompat.getRootWindowInsets(view);
      if (insets == null) {
        // Cannot determine, assume not edge-to-edge as a safe default.
        return false;
      }
      // If the system applies insets for navigation bars, it means decorFitsSystemWindows is true
      // (the default, non-edge-to-edge behavior). We can check this by seeing if the insets
      // consumed by the system at the navigation bar type are non-zero.
      androidx.core.graphics.Insets navInsets =
          insets.getInsets(WindowInsetsCompat.Type.navigationBars());
      return navInsets.bottom > 0 || navInsets.top > 0 || navInsets.left > 0 || navInsets.right > 0;
    }

    /**
     * Checks if the relevant system UI flags are set to indicate that the application is drawing
     * behind the navigation bar (i.e., is in edge-to-edge mode for navigation).
     */
    @SuppressWarnings("deprecation")
    private boolean isDrawingBehindNavBarLegacy(View view) {
      int systemUiFlags = view.getWindowSystemUiVisibility();
      // The app is considered to be drawing behind the navigation bar if either:
      // 1. It has SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION set.
      // 2. It has both LAYOUT_STABLE and LAYOUT_FULLSCREEN (a common combination for fullscreen
      // apps).
      boolean layoutHideNavigation =
          (systemUiFlags & View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION) != 0;
      boolean layoutStable = (systemUiFlags & View.SYSTEM_UI_FLAG_LAYOUT_STABLE) != 0;
      boolean layoutFullscreen = (systemUiFlags & View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN) != 0;

      return layoutHideNavigation || (layoutStable && layoutFullscreen);
    }

    @Override
    public void onPrepare(WindowInsetsAnimation animation) {
      needsSave = true;
      if ((animation.getTypeMask() & deferredInsetTypes) != 0) {
        animating = true;
      }
    }

    @Override
    public WindowInsets onProgress(
        WindowInsets insets, List<WindowInsetsAnimation> runningAnimations) {
      if (!animating || needsSave) {
        return insets;
      }
      boolean matching = false;
      for (WindowInsetsAnimation animation : runningAnimations) {
        if ((animation.getTypeMask() & deferredInsetTypes) != 0) {
          matching = true;
          continue;
        }
      }
      if (!matching) {
        return insets;
      }

      // The IME insets include the height of the navigation bar. If the app isn't laid out behind
      // the navigation bar, this causes the IME insets to be too large during the animation.
      // To fix this, we subtract the navigationBars bottom inset if the system UI flags for laying
      // out behind the navigation bar aren't present.
      // In class AnimationCallback, inside onProgress method:
      int excludedInsets = 0;
      if (shouldExcludeNavigationInserts(view)) {
        excludedInsets = insets.getInsets(WindowInsets.Type.navigationBars()).bottom;
      }

      WindowInsets.Builder builder = new WindowInsets.Builder(lastWindowInsets);
      Insets newImeInsets =
          Insets.of(
              0, 0, 0, Math.max(insets.getInsets(deferredInsetTypes).bottom - excludedInsets, 0));
      builder.setInsets(deferredInsetTypes, newImeInsets);

      // Directly call onApplyWindowInsets of the view as we do not want to pass through
      // the onApplyWindowInsets defined in this class, which would consume the insets
      // as if they were a non-animation inset change and cache it for re-dispatch in
      // onEnd instead.
      view.onApplyWindowInsets(builder.build());
      return insets;
    }

    @Override
    public void onEnd(WindowInsetsAnimation animation) {
      if (animating && (animation.getTypeMask() & deferredInsetTypes) != 0) {
        // If we deferred the IME insets and an IME animation has finished, we need to reset
        // the flags
        animating = false;

        // And finally dispatch the deferred insets to the view now.
        // Ideally we would just call view.requestApplyInsets() and let the normal dispatch
        // cycle happen, but this happens too late resulting in a visual flicker.
        // Instead we manually dispatch the most recent WindowInsets to the view.
        if (lastWindowInsets != null && view != null) {
          view.dispatchApplyWindowInsets(lastWindowInsets);
        }
      }
      WindowInsetsCompat insets = ViewCompat.getRootWindowInsets(view);
      if (insets != null && imeVisibilityListener != null) {
        boolean imeVisible = insets.isVisible(WindowInsetsCompat.Type.ime());
        imeVisibilityListener.onImeVisibilityChanged(imeVisible);
      }
    }
  }

  private class InsetsListener implements View.OnApplyWindowInsetsListener {
    @Override
    public WindowInsets onApplyWindowInsets(View view, WindowInsets windowInsets) {
      ImeSyncDeferringInsetsCallback.this.view = view;
      if (needsSave) {
        // Store the view and insets for us in onEnd() below. This captured inset
        // is not part of the animation and instead, represents the final state
        // of the inset after the animation is completed. Thus, we defer the processing
        // of this WindowInset until the animation completes.
        lastWindowInsets = windowInsets;
        needsSave = false;
      }
      if (animating) {
        // While animation is running, we consume the insets to prevent disrupting
        // the animation, which skips this implementation and calls the view's
        // onApplyWindowInsets directly to avoid being consumed here.
        return WindowInsets.CONSUMED;
      }

      // If no animation is happening, pass the insets on to the view's own
      // inset handling.
      return view.onApplyWindowInsets(windowInsets);
    }
  }

  // Listener for IME visibility changes.
  public interface ImeVisibilityListener {
    void onImeVisibilityChanged(boolean visible);
  }
}
