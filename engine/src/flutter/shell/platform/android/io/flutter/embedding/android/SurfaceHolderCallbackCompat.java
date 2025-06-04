package io.flutter.embedding.android;

import android.view.SurfaceHolder;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.annotation.RequiresApi;
import androidx.annotation.VisibleForTesting;
import io.flutter.Build;
import io.flutter.Log;
import io.flutter.embedding.engine.renderer.FlutterRenderer;
import io.flutter.embedding.engine.renderer.FlutterUiDisplayListener;

public class SurfaceHolderCallbackCompat {

  private static final String TAG = "SurfaceHolderCallbackCompat";
  private final FlutterSurfaceView flutterSurfaceView;
  @Nullable private FlutterRenderer flutterRenderer;

  private final SurfaceHolder.Callback innerCallback;

  /**
   * Flag to determine if the alpha compositing workaround is needed for this Android version. On
   * Android versions prior to API 26 (Oreo), a {@link android.view.SurfaceView} used for Flutter
   * might initially render as a black rectangle before Flutter draws its first frame. To prevent
   * this visual glitch, if {@code shouldSetAlpha} is true, the associated {@link
   * FlutterSurfaceView} is initially made transparent (alpha 0.0f). It is then set to opaque (alpha
   * 1.0f) only when the Flutter engine signals that the first frame is ready via the {@link
   * FlutterUiDisplayListener#onFlutterUiDisplayed()} callback. This behavior is not needed on API
   * 26+ where SurfaceView handles this more gracefully.
   */
  private final boolean shouldSetAlpha = android.os.Build.VERSION.SDK_INT < Build.API_LEVELS.API_26;

  public void onAttachToRenderer(FlutterRenderer flutterRenderer) {
    if (shouldSetAlpha && this.flutterRenderer != null) {
      this.flutterRenderer.removeIsDisplayingFlutterUiListener(alphaCallback);
    }
    this.flutterRenderer = flutterRenderer;
  }

  public void onDetachFromRenderer() {
    if (shouldSetAlpha) {
      // Make the SurfaceView invisible to avoid showing a black rectangle.
      this.flutterSurfaceView.setAlpha(0.0f);
      if (this.flutterRenderer != null) {
        this.flutterRenderer.removeIsDisplayingFlutterUiListener(alphaCallback);
      }
    }
    this.flutterRenderer = null;
  }

  public void onResume() {
    if (shouldSetAlpha && this.flutterRenderer != null) {
      this.flutterRenderer.addIsDisplayingFlutterUiListener(alphaCallback);
    }
  }

  ///  Listens for a callback from the Flutter Engine to indicate that a frame is ready to display.
  @VisibleForTesting
  final FlutterUiDisplayListener alphaCallback =
      new FlutterUiDisplayListener() {
        @Override
        public void onFlutterUiDisplayed() {
          Log.v(TAG, "onFlutterUiDisplayed()");
          // Now that a frame is ready to display, take this SurfaceView from transparent to opaque.
          flutterSurfaceView.setAlpha(1.0f);

          if (flutterRenderer != null) {
            flutterRenderer.removeIsDisplayingFlutterUiListener(this);
          }
        }

        @Override
        public void onFlutterUiNoLongerDisplayed() {
          // no-op
        }
      };

  private class SufaceHolderCallback implements SurfaceHolder.Callback {
    @Override
    public void surfaceCreated(@NonNull SurfaceHolder holder) {
      if (innerCallback != null) {
        innerCallback.surfaceCreated(holder);
      }
    }

    @Override
    public void surfaceChanged(@NonNull SurfaceHolder holder, int format, int width, int height) {
      if (innerCallback != null) {
        innerCallback.surfaceChanged(holder, format, width, height);
      }
    }

    @Override
    public void surfaceDestroyed(@NonNull SurfaceHolder holder) {
      if (innerCallback != null) {
        innerCallback.surfaceDestroyed(holder);
      }
    }
  }

  private class SurfaceHolderCallback2Compat extends SufaceHolderCallback
      implements SurfaceHolder.Callback2 {
    @Override
    public void surfaceRedrawNeeded(@NonNull SurfaceHolder holder) {
      Log.v(TAG, "SurfaceHolder.Callback2.surfaceRedrawNeeded()");
      /*
       no-op - instead use surfaceRedrawNeededAsync()
       Since Flutter rendering now occurs on the main UI thread, we cannot block here
       and expect to receive a callback. Instead, the Async version of this method
       should be used. See surfaceRedrawNeededAsync().
      */
    }
  }

  private class SurfaceHolderCallback2AsyncCompat extends SurfaceHolderCallback2Compat
      implements SurfaceHolder.Callback2 {
    @Override
    @RequiresApi(api = Build.API_LEVELS.API_26)
    public void surfaceRedrawNeededAsync(
        @NonNull SurfaceHolder holder, @NonNull Runnable finishDrawing) {
      Log.v(TAG, "SurfaceHolder.Callback2.surfaceRedrawNeededAsync()");
      if (flutterRenderer == null) {
        return;
      }
      // Run `finishDrawing` when the Flutter UI is ready to display.
      flutterRenderer.addIsDisplayingFlutterUiListener(
          new FlutterUiDisplayListener() {
            @Override
            public void onFlutterUiDisplayed() {
              finishDrawing.run();
              if (flutterRenderer != null) {
                flutterRenderer.removeIsDisplayingFlutterUiListener(this);
              }
            }

            @Override
            public void onFlutterUiNoLongerDisplayed() {
              // no-op
            }
          });
    }
  }

  final SurfaceHolder.Callback callback =
      shouldSetAlpha ? new SurfaceHolderCallback2Compat() : new SurfaceHolderCallback2AsyncCompat();

  public SurfaceHolderCallbackCompat(
      SurfaceHolder.Callback innerCallback,
      FlutterSurfaceView flutterSurfaceView,
      @Nullable FlutterRenderer flutterRenderer) {
    this.innerCallback = innerCallback;
    this.flutterRenderer = flutterRenderer;
    this.flutterSurfaceView = flutterSurfaceView;

    Log.v(TAG, "SurfaceHolderCallbackCompat()");

    if (shouldSetAlpha) {
      // Keep this SurfaceView transparent until Flutter has a frame ready to render. This avoids
      // displaying a black rectangle in our place.
      this.flutterSurfaceView.setAlpha(0.0f);
    }
  }
}
