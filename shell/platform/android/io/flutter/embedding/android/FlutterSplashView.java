// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.embedding.android;

import android.content.Context;
import android.os.Bundle;
import android.os.Parcel;
import android.os.Parcelable;
import android.support.annotation.NonNull;
import android.support.annotation.Nullable;
import android.util.AttributeSet;
import android.view.View;
import android.widget.FrameLayout;

import io.flutter.Log;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.embedding.engine.renderer.FlutterUiDisplayListener;

/**
 * {@code View} that displays a {@link SplashScreen} until a given {@link FlutterView}
 * renders its first frame.
 */
/* package */ final class FlutterSplashView extends FrameLayout {
  private static String TAG = "FlutterSplashView";

  @Nullable
  private SplashScreen splashScreen;
  @Nullable
  private FlutterView flutterView;
  @Nullable
  private View splashScreenView;
  @Nullable
  private Bundle splashScreenState;
  @Nullable
  private String transitioningIsolateId;
  @Nullable
  private String previousCompletedSplashIsolate;

  @NonNull
  private final FlutterView.FlutterEngineAttachmentListener flutterEngineAttachmentListener = new FlutterView.FlutterEngineAttachmentListener() {
    @Override
    public void onFlutterEngineAttachedToFlutterView(@NonNull FlutterEngine engine) {
      flutterView.removeFlutterEngineAttachmentListener(this);
      displayFlutterViewWithSplash(flutterView, splashScreen);
    }

    @Override
    public void onFlutterEngineDetachedFromFlutterView() {}
  };

  @NonNull
  private final FlutterUiDisplayListener flutterUiDisplayListener = new FlutterUiDisplayListener() {
    @Override
    public void onFlutterUiDisplayed() {
      if (splashScreen != null) {
        transitionToFlutter();
      }
    }

    @Override
    public void onFlutterUiNoLongerDisplayed() {
      // no-op
    }
  };

  @NonNull
  private final Runnable onTransitionComplete = new Runnable() {
    @Override
    public void run() {
      removeView(splashScreenView);
      previousCompletedSplashIsolate = transitioningIsolateId;
    }
  };

  public FlutterSplashView(@NonNull Context context) {
    this(context, null, 0);
  }

  public FlutterSplashView(@NonNull Context context, @Nullable AttributeSet attrs) {
    this(context, attrs, 0);
  }

  public FlutterSplashView(@NonNull Context context, @Nullable AttributeSet attrs, int defStyleAttr) {
    super(context, attrs, defStyleAttr);

    setSaveEnabled(true);
  }

  @Nullable
  @Override
  protected Parcelable onSaveInstanceState() {
    Parcelable superState = super.onSaveInstanceState();
    SavedState savedState = new SavedState(superState);
    savedState.previousCompletedSplashIsolate = previousCompletedSplashIsolate;
    savedState.splashScreenState = splashScreen != null ? splashScreen.saveSplashScreenState() : null;
    return savedState;
  }

  @Override
  protected void onRestoreInstanceState(Parcelable state) {
    SavedState savedState = (SavedState) state;
    super.onRestoreInstanceState(savedState.getSuperState());
    previousCompletedSplashIsolate = savedState.previousCompletedSplashIsolate;
    splashScreenState = savedState.splashScreenState;
  }

  /**
   * Displays the given {@code splashScreen} on top of the given {@code flutterView} until
   * Flutter has rendered its first frame, then the {@code splashScreen} is transitioned away.
   * <p>
   * If no {@code splashScreen} is provided, this {@code FlutterSplashView} displays the
   * given {@code flutterView} on its own.
   */
  public void displayFlutterViewWithSplash(
      @NonNull FlutterView flutterView,
      @Nullable SplashScreen splashScreen
  ) {
    // If we were displaying a previous FlutterView, remove it.
    if (this.flutterView != null) {
      this.flutterView.removeOnFirstFrameRenderedListener(flutterUiDisplayListener);
      removeView(this.flutterView);
    }
    // If we were displaying a previous splash screen View, remove it.
    if (splashScreenView != null) {
      removeView(splashScreenView);
    }

    // Display the new FlutterView.
    this.flutterView = flutterView;
    addView(flutterView);

    this.splashScreen = splashScreen;

    // Display the new splash screen, if needed.
    if (splashScreen != null) {
      if (isSplashScreenNeededNow()) {
        Log.v(TAG, "Showing splash screen UI.");
        // This is the typical case. A FlutterEngine is attached to the FlutterView and we're
        // waiting for the first frame to render. Show a splash UI until that happens.
        splashScreenView = splashScreen.createSplashView(getContext(), splashScreenState);
        addView(this.splashScreenView);
        flutterView.addOnFirstFrameRenderedListener(flutterUiDisplayListener);
      } else if (isSplashScreenTransitionNeededNow()) {
        Log.v(TAG, "Showing an immediate splash transition to Flutter due to previously interrupted transition.");
        splashScreenView = splashScreen.createSplashView(getContext(), splashScreenState);
        addView(splashScreenView);
        transitionToFlutter();
      } else if (!flutterView.isAttachedToFlutterEngine()) {
        Log.v(TAG, "FlutterView is not yet attached to a FlutterEngine. Showing nothing until a FlutterEngine is attached.");
        flutterView.addFlutterEngineAttachmentListener(flutterEngineAttachmentListener);
      }
    }
  }

  /**
   * Returns true if current conditions require a splash UI to be displayed.
   * <p>
   * This method does not evaluate whether a previously interrupted splash transition needs
   * to resume. See {@link #isSplashScreenTransitionNeededNow()} to answer that question.
   */
  private boolean isSplashScreenNeededNow() {
    return flutterView != null
        && flutterView.isAttachedToFlutterEngine()
        && !flutterView.hasRenderedFirstFrame()
        && !hasSplashCompleted();
  }

  /**
   * Returns true if a previous splash transition was interrupted by recreation, e.g., an
   * orientation change, and that previous transition should be resumed.
   * <p>
   * Not all splash screens are capable of remembering their transition progress. In those
   * cases, this method will return false even if a previous visual transition was
   * interrupted.
   */
  private boolean isSplashScreenTransitionNeededNow() {
    return flutterView != null
        && flutterView.isAttachedToFlutterEngine()
        && splashScreen != null
        && splashScreen.doesSplashViewRememberItsTransition()
        && wasPreviousSplashTransitionInterrupted();
  }

  /**
   * Returns true if a splash screen was transitioning to a Flutter experience and was then
   * interrupted, e.g., by an Android configuration change. Returns false otherwise.
   * <p>
   * Invoking this method expects that a {@code flutterView} exists and it is attached to a
   * {@code FlutterEngine}.
   */
  private boolean wasPreviousSplashTransitionInterrupted() {
    if (flutterView == null) {
      throw new IllegalStateException("Cannot determine if previous splash transition was " +
          "interrupted when no FlutterView is set.");
    }
    if (!flutterView.isAttachedToFlutterEngine()) {
      throw new IllegalStateException("Cannot determine if previous splash transition was "
          + "interrupted when no FlutterEngine is attached to our FlutterView. This question "
          + "depends on an isolate ID to differentiate Flutter experiences.");
    }
    return flutterView.hasRenderedFirstFrame() && !hasSplashCompleted();
  }

  /**
   * Returns true if a splash UI for a specific Flutter experience has already completed.
   * <p>
   * A "specific Flutter experience" is defined as any experience with the same Dart isolate
   * ID. The purpose of this distinction is to prevent a situation where a user gets past a
   * splash UI, rotates the device (or otherwise triggers a recreation) and the splash screen
   * reappears.
   * <p>
   * An isolate ID is deemed reasonable as a key for a completion event because a Dart isolate
   * cannot be entered twice. Therefore, a single Dart isolate cannot return to an "un-rendered"
   * state after having previously rendered content.
   */
  private boolean hasSplashCompleted() {
    if (flutterView == null) {
      throw new IllegalStateException("Cannot determine if splash has completed when no FlutterView "
          + "is set.");
    }
    if (!flutterView.isAttachedToFlutterEngine()) {
      throw new IllegalStateException("Cannot determine if splash has completed when no "
          + "FlutterEngine is attached to our FlutterView. This question depends on an isolate ID "
          + "to differentiate Flutter experiences.");
    }

    // A null isolate ID on a non-null FlutterEngine indicates that the Dart isolate has not
    // been initialized. Therefore, no frame has been rendered for this engine, which means
    // no splash screen could have completed yet.
    return flutterView.getAttachedFlutterEngine().getDartExecutor().getIsolateServiceId() != null
      && flutterView.getAttachedFlutterEngine().getDartExecutor().getIsolateServiceId().equals(previousCompletedSplashIsolate);
  }

  /**
   * Transitions a splash screen to the Flutter UI.
   * <p>
   * This method requires that our FlutterView be attached to an engine, and that engine have
   * a Dart isolate ID. It also requires that a {@code splashScreen} exist.
   */
  private void transitionToFlutter() {
    transitioningIsolateId = flutterView.getAttachedFlutterEngine().getDartExecutor().getIsolateServiceId();
    Log.v(TAG, "Transitioning splash screen to a Flutter UI. Isolate: " + transitioningIsolateId);
    splashScreen.transitionToFlutter(onTransitionComplete);
  }

  public static class SavedState extends BaseSavedState {
    public static Creator CREATOR = new Creator() {
      @Override
      public SavedState createFromParcel(Parcel source) {
        return new SavedState(source);
      }

      @Override
      public SavedState[] newArray(int size) {
        return new SavedState[size];
      }
    };

    private String previousCompletedSplashIsolate;
    private Bundle splashScreenState;

    SavedState(Parcelable superState) {
      super(superState);
    }

    SavedState(Parcel source) {
      super(source);
      previousCompletedSplashIsolate = source.readString();
      splashScreenState = source.readBundle(getClass().getClassLoader());
    }

    @Override
    public void writeToParcel(Parcel out, int flags) {
      super.writeToParcel(out, flags);
      out.writeString(previousCompletedSplashIsolate);
      out.writeBundle(splashScreenState);
    }
  }
}
