// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugin.editing;

import static io.flutter.Build.API_LEVELS;

import android.annotation.SuppressLint;
import android.graphics.Insets;
import android.view.View;
import android.view.WindowInsets;
import android.view.WindowInsetsAnimation;
import androidx.annotation.Keep;
import androidx.annotation.NonNull;
import androidx.annotation.RequiresApi;
import androidx.annotation.VisibleForTesting;
import androidx.core.view.ViewCompat;
import androidx.core.view.WindowInsetsCompat;
import io.flutter.util.TraceSection;
import java.util.List;

// When the IME is shown or hidden, Android sends an initial onApplyWindowInsets call with
// the target settled state of the IME. If passed through directly, this abrupt jump causes visual
// flicker and disrupts continuous insets animation.
//
// To resolve this, this class extends WindowInsetsAnimation.Callback and implements
// View.OnApplyWindowInsetsListener, delegating all lifecycle state transitions and insets
// interpolation to an encapsulated AnimationStateMachine:
//
// 1. IDLE: Non-animated insets changes (e.g. orientation changes, hardware keyboards) pass
//    directly to the view, keeping current tracked insets synchronized.
// 2. PREPARED: When an IME animation begins (onPrepare), the state machine captures the in-flight
//    starting height and captures the target settled insets arriving in the subsequent
//    onApplyWindowInsets call, deferring its direct application.
// 3. ANIMATING: During animation progress (onProgress), the state machine calculates mathematically
//    continuous insets interpolated from start to target, dispatching per-frame insets directly to
//    the view.
// 4. SETTLING / ON-END: Upon animation completion (onEnd), the state machine transitions to IDLE
//    and dispatches the deferred target WindowInsets to the view.
@VisibleForTesting
@RequiresApi(API_LEVELS.API_30)
@SuppressLint({"NewApi", "Override"})
@Keep
class ImeSyncDeferringInsetsCallback {
  private final int deferredInsetTypes = WindowInsets.Type.ime();
  private View view;
  private AnimationCallback animationCallback;
  private InsetsListener insetsListener;
  private ImeVisibilityListener imeVisibilityListener;
  private final AnimationStateMachine stateMachine;

  ImeSyncDeferringInsetsCallback(@NonNull View view) {
    this.view = view;
    this.animationCallback = new AnimationCallback();
    this.insetsListener = new InsetsListener();
    this.stateMachine = new AnimationStateMachine(deferredInsetTypes);
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
    view = null;
    imeVisibilityListener = null;
    stateMachine.reset();
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

  @VisibleForTesting
  AnimationStateMachine getStateMachine() {
    return stateMachine;
  }

  // WindowInsetsAnimation.Callback was introduced in API level 30.  The callback
  // subclass is separated into an inner class in order to avoid warnings from
  // the Android class loader on older platforms.
  @Keep
  private class AnimationCallback extends WindowInsetsAnimation.Callback {
    AnimationCallback() {
      super(WindowInsetsAnimation.Callback.DISPATCH_MODE_CONTINUE_ON_SUBTREE);
    }

    @Override
    public void onPrepare(WindowInsetsAnimation animation) {
      try (TraceSection e = TraceSection.scoped("ImeSyncDeferringInsetsCallback#onPrepare")) {
        stateMachine.onPrepare(animation);
      }
    }

    @Override
    public WindowInsets onProgress(
        WindowInsets insets, List<WindowInsetsAnimation> runningAnimations) {
      try (TraceSection e = TraceSection.scoped("ImeSyncDeferringInsetsCallback#onProgress")) {
        return stateMachine.onProgress(view, insets, runningAnimations);
      }
    }

    @Override
    public void onEnd(WindowInsetsAnimation animation) {
      try (TraceSection e = TraceSection.scoped("ImeSyncDeferringInsetsCallback#onEnd")) {
        stateMachine.onEnd(view, animation);
        if (view != null) {
          WindowInsetsCompat insets = ViewCompat.getRootWindowInsets(view);
          if (insets != null && imeVisibilityListener != null) {
            boolean imeVisible = insets.isVisible(WindowInsetsCompat.Type.ime());
            imeVisibilityListener.onImeVisibilityChanged(imeVisible);
          }
        }
      }
    }
  }

  private class InsetsListener implements View.OnApplyWindowInsetsListener {
    @Override
    public WindowInsets onApplyWindowInsets(View view, WindowInsets windowInsets) {
      try (TraceSection e =
          TraceSection.scoped("ImeSyncDeferringInsetsCallback#onApplyWindowInsets")) {
        ImeSyncDeferringInsetsCallback.this.view = view;
        return stateMachine.onApplyWindowInsets(view, windowInsets);
      }
    }
  }

  // Listener for IME visibility changes.
  public interface ImeVisibilityListener {
    void onImeVisibilityChanged(boolean visible);
  }

  /**
   * Helper class encapsulating discrete state transitions and mathematics for deferred IME window
   * insets animations.
   */
  @VisibleForTesting
  static class AnimationStateMachine {
    enum State {
      IDLE,
      PREPARED,
      ANIMATING,
    }

    private final int deferredInsetTypes;
    private State state = State.IDLE;
    private int startImeBottom = 0;
    private int currentImeBottom = 0;
    private WindowInsets lastWindowInsets;

    AnimationStateMachine(int deferredInsetTypes) {
      this.deferredInsetTypes = deferredInsetTypes;
    }

    @VisibleForTesting
    State getState() {
      return state;
    }

    @VisibleForTesting
    int getStartImeBottom() {
      return startImeBottom;
    }

    @VisibleForTesting
    int getCurrentImeBottom() {
      return currentImeBottom;
    }

    @VisibleForTesting
    WindowInsets getLastWindowInsets() {
      return lastWindowInsets;
    }

    void onPrepare(WindowInsetsAnimation animation) {
      if ((animation.getTypeMask() & deferredInsetTypes) != 0) {
        state = State.PREPARED;
        startImeBottom = currentImeBottom;
      } else if (state != State.IDLE) {
        // If an IME animation is already active or preparing and an accompanying animation
        // (such as a navigation bar animation during keyboard dismissal) prepares, transition to
        // PREPARED to capture the updated target WindowInsets in onApplyWindowInsets.
        state = State.PREPARED;
      }
    }

    WindowInsets onApplyWindowInsets(View view, WindowInsets windowInsets) {
      if (state == State.PREPARED) {
        // Store the captured target inset for dispatching in onEnd().
        // Represents the final state of the inset after animation completion.
        lastWindowInsets = windowInsets;
        state = State.ANIMATING;
        return WindowInsets.CONSUMED;
      }
      if (state == State.ANIMATING) {
        // While animation is running, consume insets to prevent disrupting the animation.
        return WindowInsets.CONSUMED;
      }

      // State.IDLE: Non-animated insets arrival (e.g. orientation changes, hardware keyboards).
      currentImeBottom = windowInsets.getInsets(deferredInsetTypes).bottom;
      lastWindowInsets = windowInsets;
      return view.onApplyWindowInsets(windowInsets);
    }

    WindowInsets onProgress(
        View view, WindowInsets insets, List<WindowInsetsAnimation> runningAnimations) {
      if (state != State.ANIMATING) {
        return insets;
      }
      WindowInsetsAnimation imeAnimation = null;
      final int count = runningAnimations.size();
      for (int i = 0; i < count; i++) {
        WindowInsetsAnimation animation = runningAnimations.get(i);
        if ((animation.getTypeMask() & deferredInsetTypes) != 0) {
          imeAnimation = animation;
          break;
        }
      }
      if (imeAnimation == null) {
        return insets;
      }

      // Rather than guessing whether the OS includes navigation bar insets in raw animated
      // values across different Android versions and system UI modes, smoothly interpolate
      // from the initial IME inset to the settled target IME inset captured in lastWindowInsets.
      // This guarantees mathematical continuity and eliminates any terminal jump in onEnd().
      int targetImeBottom =
          lastWindowInsets != null
              ? lastWindowInsets.getInsets(deferredInsetTypes).bottom
              : insets.getInsets(deferredInsetTypes).bottom;

      float fraction = imeAnimation.getInterpolatedFraction();
      int animatedImeBottom =
          Math.max(0, Math.round(startImeBottom + (targetImeBottom - startImeBottom) * fraction));

      WindowInsets.Builder builder = new WindowInsets.Builder(insets);
      Insets newImeInsets = Insets.of(0, 0, 0, animatedImeBottom);
      builder.setInsets(deferredInsetTypes, newImeInsets);

      // Directly call onApplyWindowInsets of the view as we do not want to pass through
      // the onApplyWindowInsets defined in this class, which would consume the insets
      // as if they were a non-animation inset change and cache it for re-dispatch in
      // onEnd instead.
      if (view != null) {
        view.onApplyWindowInsets(builder.build());
      }
      currentImeBottom = animatedImeBottom;
      return insets;
    }

    void onEnd(View view, WindowInsetsAnimation animation) {
      if ((animation.getTypeMask() & deferredInsetTypes) != 0) {
        if (state == State.ANIMATING) {
          int settledBottom =
              lastWindowInsets != null ? lastWindowInsets.getInsets(deferredInsetTypes).bottom : 0;
          startImeBottom = settledBottom;
          currentImeBottom = settledBottom;

          // Transition to IDLE BEFORE dispatching to the view, so that the view's
          // onApplyWindowInsets listener will pass the settled insets through
          // rather than consuming them.
          state = State.IDLE;

          if (lastWindowInsets != null && view != null) {
            view.dispatchApplyWindowInsets(lastWindowInsets);
          }
        } else {
          state = State.IDLE;
        }
      }
    }

    void reset() {
      state = State.IDLE;
      lastWindowInsets = null;
      startImeBottom = 0;
      currentImeBottom = 0;
    }
  }
}
