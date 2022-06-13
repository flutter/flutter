// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.embedding.engine.renderer;

import android.graphics.Bitmap;
import android.graphics.Rect;
import android.graphics.SurfaceTexture;
import android.os.Build;
import android.os.Handler;
import android.view.Surface;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.annotation.VisibleForTesting;
import io.flutter.Log;
import io.flutter.embedding.engine.FlutterJNI;
import io.flutter.view.TextureRegistry;
import java.lang.ref.WeakReference;
import java.nio.ByteBuffer;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.Iterator;
import java.util.List;
import java.util.Set;
import java.util.concurrent.atomic.AtomicLong;

/**
 * Represents the rendering responsibilities of a {@code FlutterEngine}.
 *
 * <p>{@code FlutterRenderer} works in tandem with a provided {@link RenderSurface} to paint Flutter
 * pixels to an Android {@code View} hierarchy.
 *
 * <p>{@code FlutterRenderer} manages textures for rendering, and forwards some Java calls to native
 * Flutter code via JNI. The corresponding {@link RenderSurface} provides the Android {@link
 * Surface} that this renderer paints.
 *
 * <p>{@link io.flutter.embedding.android.FlutterSurfaceView} and {@link
 * io.flutter.embedding.android.FlutterTextureView} are implementations of {@link RenderSurface}.
 */
public class FlutterRenderer implements TextureRegistry {
  private static final String TAG = "FlutterRenderer";

  @NonNull private final FlutterJNI flutterJNI;
  @NonNull private final AtomicLong nextTextureId = new AtomicLong(0L);
  @Nullable private Surface surface;
  private boolean isDisplayingFlutterUi = false;
  private Handler handler = new Handler();

  @NonNull
  private final Set<WeakReference<TextureRegistry.OnTrimMemoryListener>> onTrimMemoryListeners =
      new HashSet<>();

  @NonNull
  private final FlutterUiDisplayListener flutterUiDisplayListener =
      new FlutterUiDisplayListener() {
        @Override
        public void onFlutterUiDisplayed() {
          isDisplayingFlutterUi = true;
        }

        @Override
        public void onFlutterUiNoLongerDisplayed() {
          isDisplayingFlutterUi = false;
        }
      };

  public FlutterRenderer(@NonNull FlutterJNI flutterJNI) {
    this.flutterJNI = flutterJNI;
    this.flutterJNI.addIsDisplayingFlutterUiListener(flutterUiDisplayListener);
  }

  /**
   * Returns true if this {@code FlutterRenderer} is painting pixels to an Android {@code View}
   * hierarchy, false otherwise.
   */
  public boolean isDisplayingFlutterUi() {
    return isDisplayingFlutterUi;
  }

  /**
   * Adds a listener that is invoked whenever this {@code FlutterRenderer} starts and stops painting
   * pixels to an Android {@code View} hierarchy.
   */
  public void addIsDisplayingFlutterUiListener(@NonNull FlutterUiDisplayListener listener) {
    flutterJNI.addIsDisplayingFlutterUiListener(listener);

    if (isDisplayingFlutterUi) {
      listener.onFlutterUiDisplayed();
    }
  }

  /**
   * Removes a listener added via {@link
   * #addIsDisplayingFlutterUiListener(FlutterUiDisplayListener)}.
   */
  public void removeIsDisplayingFlutterUiListener(@NonNull FlutterUiDisplayListener listener) {
    flutterJNI.removeIsDisplayingFlutterUiListener(listener);
  }

  private void clearDeadListeners() {
    final Iterator<WeakReference<OnTrimMemoryListener>> iterator = onTrimMemoryListeners.iterator();
    while (iterator.hasNext()) {
      WeakReference<OnTrimMemoryListener> listenerRef = iterator.next();
      final OnTrimMemoryListener listener = listenerRef.get();
      if (listener == null) {
        iterator.remove();
      }
    }
  }

  /** Adds a listener that is invoked when a memory pressure warning was forward. */
  @VisibleForTesting
  /* package */ void addOnTrimMemoryListener(@NonNull OnTrimMemoryListener listener) {
    // Purge dead listener to avoid accumulating.
    clearDeadListeners();
    onTrimMemoryListeners.add(new WeakReference<>(listener));
  }

  /**
   * Removes a {@link OnTrimMemoryListener} that was added with {@link
   * #addOnTrimMemoryListener(OnTrimMemoryListener)}.
   */
  @VisibleForTesting
  /* package */ void removeOnTrimMemoryListener(@NonNull OnTrimMemoryListener listener) {
    for (WeakReference<OnTrimMemoryListener> listenerRef : onTrimMemoryListeners) {
      if (listenerRef.get() == listener) {
        onTrimMemoryListeners.remove(listenerRef);
        break;
      }
    }
  }

  // ------ START TextureRegistry IMPLEMENTATION -----
  /**
   * Creates and returns a new {@link SurfaceTexture} managed by the Flutter engine that is also
   * made available to Flutter code.
   */
  @Override
  public SurfaceTextureEntry createSurfaceTexture() {
    Log.v(TAG, "Creating a SurfaceTexture.");
    final SurfaceTexture surfaceTexture = new SurfaceTexture(0);
    return registerSurfaceTexture(surfaceTexture);
  }

  /**
   * Registers and returns a {@link SurfaceTexture} managed by the Flutter engine that is also made
   * available to Flutter code.
   */
  @Override
  public SurfaceTextureEntry registerSurfaceTexture(@NonNull SurfaceTexture surfaceTexture) {
    surfaceTexture.detachFromGLContext();
    final SurfaceTextureRegistryEntry entry =
        new SurfaceTextureRegistryEntry(nextTextureId.getAndIncrement(), surfaceTexture);
    Log.v(TAG, "New SurfaceTexture ID: " + entry.id());
    registerTexture(entry.id(), entry.textureWrapper());
    addOnTrimMemoryListener(entry);
    return entry;
  }

  @Override
  public void onTrimMemory(int level) {
    final Iterator<WeakReference<OnTrimMemoryListener>> iterator = onTrimMemoryListeners.iterator();
    while (iterator.hasNext()) {
      WeakReference<OnTrimMemoryListener> listenerRef = iterator.next();
      final OnTrimMemoryListener listener = listenerRef.get();
      if (listener != null) {
        listener.onTrimMemory(level);
      } else {
        // Purge cleared refs to avoid accumulating a lot of dead listener
        iterator.remove();
      }
    }
  }

  final class SurfaceTextureRegistryEntry
      implements TextureRegistry.SurfaceTextureEntry, TextureRegistry.OnTrimMemoryListener {
    private final long id;
    @NonNull private final SurfaceTextureWrapper textureWrapper;
    private boolean released;
    @Nullable private OnTrimMemoryListener trimMemoryListener;
    @Nullable private OnFrameConsumedListener frameConsumedListener;
    private final Runnable onFrameConsumed =
        new Runnable() {
          @Override
          public void run() {
            if (frameConsumedListener != null) {
              frameConsumedListener.onFrameConsumed();
            }
          }
        };

    SurfaceTextureRegistryEntry(long id, @NonNull SurfaceTexture surfaceTexture) {
      this.id = id;
      this.textureWrapper = new SurfaceTextureWrapper(surfaceTexture, onFrameConsumed);

      if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
        // The callback relies on being executed on the UI thread (unsynchronised read of
        // mNativeView
        // and also the engine code check for platform thread in
        // Shell::OnPlatformViewMarkTextureFrameAvailable),
        // so we explicitly pass a Handler for the current thread.
        this.surfaceTexture().setOnFrameAvailableListener(onFrameListener, new Handler());
      } else {
        // Android documentation states that the listener can be called on an arbitrary thread.
        // But in practice, versions of Android that predate the newer API will call the listener
        // on the thread where the SurfaceTexture was constructed.
        this.surfaceTexture().setOnFrameAvailableListener(onFrameListener);
      }
    }

    @Override
    public void onTrimMemory(int level) {
      if (trimMemoryListener != null) {
        trimMemoryListener.onTrimMemory(level);
      }
    }

    private SurfaceTexture.OnFrameAvailableListener onFrameListener =
        new SurfaceTexture.OnFrameAvailableListener() {
          @Override
          public void onFrameAvailable(@NonNull SurfaceTexture texture) {
            if (released || !flutterJNI.isAttached()) {
              // Even though we make sure to unregister the callback before releasing, as of
              // Android O, SurfaceTexture has a data race when accessing the callback, so the
              // callback may still be called by a stale reference after released==true and
              // mNativeView==null.
              return;
            }
            markTextureFrameAvailable(id);
          }
        };

    private void removeListener() {
      removeOnTrimMemoryListener(this);
    }

    @NonNull
    public SurfaceTextureWrapper textureWrapper() {
      return textureWrapper;
    }

    @Override
    @NonNull
    public SurfaceTexture surfaceTexture() {
      return textureWrapper.surfaceTexture();
    }

    @Override
    public long id() {
      return id;
    }

    @Override
    public void release() {
      if (released) {
        return;
      }
      Log.v(TAG, "Releasing a SurfaceTexture (" + id + ").");
      textureWrapper.release();
      unregisterTexture(id);
      removeListener();
      released = true;
    }

    @Override
    protected void finalize() throws Throwable {
      try {
        if (released) {
          return;
        }

        handler.post(new SurfaceTextureFinalizerRunnable(id, flutterJNI));
      } finally {
        super.finalize();
      }
    }

    @Override
    public void setOnFrameConsumedListener(@Nullable OnFrameConsumedListener listener) {
      frameConsumedListener = listener;
    }

    @Override
    public void setOnTrimMemoryListener(@Nullable OnTrimMemoryListener listener) {
      trimMemoryListener = listener;
    }
  }

  static final class SurfaceTextureFinalizerRunnable implements Runnable {
    private final long id;
    private final FlutterJNI flutterJNI;

    SurfaceTextureFinalizerRunnable(long id, @NonNull FlutterJNI flutterJNI) {
      this.id = id;
      this.flutterJNI = flutterJNI;
    }

    @Override
    public void run() {
      if (!flutterJNI.isAttached()) {
        return;
      }
      Log.v(TAG, "Releasing a SurfaceTexture (" + id + ").");
      flutterJNI.unregisterTexture(id);
    }
  }
  // ------ END TextureRegistry IMPLEMENTATION ----

  /**
   * Notifies Flutter that the given {@code surface} was created and is available for Flutter
   * rendering.
   *
   * <p>If called more than once, the current native resources are released. This can be undesired
   * if the Engine expects to reuse this surface later. For example, this is true when platform
   * views are displayed in a frame, and then removed in the next frame.
   *
   * <p>To avoid releasing the current surface resources, set {@code keepCurrentSurface} to true.
   *
   * <p>See {@link android.view.SurfaceHolder.Callback} and {@link
   * android.view.TextureView.SurfaceTextureListener}
   *
   * @param surface The render surface.
   * @param keepCurrentSurface True if the current active surface should not be released.
   */
  public void startRenderingToSurface(@NonNull Surface surface, boolean keepCurrentSurface) {
    // Don't stop rendering the surface if it's currently paused.
    // Stop rendering to the surface releases the associated native resources, which
    // causes a glitch when showing platform views.
    // For more, https://github.com/flutter/flutter/issues/95343
    if (this.surface != null && !keepCurrentSurface) {
      stopRenderingToSurface();
    }

    this.surface = surface;

    flutterJNI.onSurfaceCreated(surface);
  }

  /**
   * Swaps the {@link Surface} used to render the current frame.
   *
   * <p>In hybrid composition, the root surfaces changes from {@link
   * android.view.SurfaceHolder#getSurface()} to {@link android.media.ImageReader#getSurface()} when
   * a platform view is in the current frame.
   */
  public void swapSurface(@NonNull Surface surface) {
    this.surface = surface;
    flutterJNI.onSurfaceWindowChanged(surface);
  }

  /**
   * Notifies Flutter that a {@code surface} previously registered with {@link
   * #startRenderingToSurface(Surface, boolean)} has changed size to the given {@code width} and
   * {@code height}.
   *
   * <p>See {@link android.view.SurfaceHolder.Callback} and {@link
   * android.view.TextureView.SurfaceTextureListener}
   */
  public void surfaceChanged(int width, int height) {
    flutterJNI.onSurfaceChanged(width, height);
  }

  /**
   * Notifies Flutter that a {@code surface} previously registered with {@link
   * #startRenderingToSurface(Surface, boolean)} has been destroyed and needs to be released and
   * cleaned up on the Flutter side.
   *
   * <p>See {@link android.view.SurfaceHolder.Callback} and {@link
   * android.view.TextureView.SurfaceTextureListener}
   */
  public void stopRenderingToSurface() {
    flutterJNI.onSurfaceDestroyed();

    surface = null;

    // TODO(mattcarroll): the source of truth for this call should be FlutterJNI, which is where
    // the call to onFlutterUiDisplayed() comes from. However, no such native callback exists yet,
    // so until the engine and FlutterJNI are configured to call us back when rendering stops,
    // we will manually monitor that change here.
    if (isDisplayingFlutterUi) {
      flutterUiDisplayListener.onFlutterUiNoLongerDisplayed();
    }

    isDisplayingFlutterUi = false;
  }

  /**
   * Notifies Flutter that the viewport metrics, e.g. window height and width, have changed.
   *
   * <p>If the width, height, or devicePixelRatio are less than or equal to 0, this update is
   * ignored.
   *
   * @param viewportMetrics The metrics to send to the Dart application.
   */
  public void setViewportMetrics(@NonNull ViewportMetrics viewportMetrics) {
    // We might get called with just the DPR if width/height aren't available yet.
    // Just ignore, as it will get called again when width/height are set.
    if (!viewportMetrics.validate()) {
      return;
    }
    Log.v(
        TAG,
        "Setting viewport metrics\n"
            + "Size: "
            + viewportMetrics.width
            + " x "
            + viewportMetrics.height
            + "\n"
            + "Padding - L: "
            + viewportMetrics.viewPaddingLeft
            + ", T: "
            + viewportMetrics.viewPaddingTop
            + ", R: "
            + viewportMetrics.viewPaddingRight
            + ", B: "
            + viewportMetrics.viewPaddingBottom
            + "\n"
            + "Insets - L: "
            + viewportMetrics.viewInsetLeft
            + ", T: "
            + viewportMetrics.viewInsetTop
            + ", R: "
            + viewportMetrics.viewInsetRight
            + ", B: "
            + viewportMetrics.viewInsetBottom
            + "\n"
            + "System Gesture Insets - L: "
            + viewportMetrics.systemGestureInsetLeft
            + ", T: "
            + viewportMetrics.systemGestureInsetTop
            + ", R: "
            + viewportMetrics.systemGestureInsetRight
            + ", B: "
            + viewportMetrics.systemGestureInsetRight
            + "\n"
            + "Display Features: "
            + viewportMetrics.displayFeatures.size());

    int[] displayFeaturesBounds = new int[viewportMetrics.displayFeatures.size() * 4];
    int[] displayFeaturesType = new int[viewportMetrics.displayFeatures.size()];
    int[] displayFeaturesState = new int[viewportMetrics.displayFeatures.size()];
    for (int i = 0; i < viewportMetrics.displayFeatures.size(); i++) {
      DisplayFeature displayFeature = viewportMetrics.displayFeatures.get(i);
      displayFeaturesBounds[4 * i] = displayFeature.bounds.left;
      displayFeaturesBounds[4 * i + 1] = displayFeature.bounds.top;
      displayFeaturesBounds[4 * i + 2] = displayFeature.bounds.right;
      displayFeaturesBounds[4 * i + 3] = displayFeature.bounds.bottom;
      displayFeaturesType[i] = displayFeature.type.encodedValue;
      displayFeaturesState[i] = displayFeature.state.encodedValue;
    }

    flutterJNI.setViewportMetrics(
        viewportMetrics.devicePixelRatio,
        viewportMetrics.width,
        viewportMetrics.height,
        viewportMetrics.viewPaddingTop,
        viewportMetrics.viewPaddingRight,
        viewportMetrics.viewPaddingBottom,
        viewportMetrics.viewPaddingLeft,
        viewportMetrics.viewInsetTop,
        viewportMetrics.viewInsetRight,
        viewportMetrics.viewInsetBottom,
        viewportMetrics.viewInsetLeft,
        viewportMetrics.systemGestureInsetTop,
        viewportMetrics.systemGestureInsetRight,
        viewportMetrics.systemGestureInsetBottom,
        viewportMetrics.systemGestureInsetLeft,
        viewportMetrics.physicalTouchSlop,
        displayFeaturesBounds,
        displayFeaturesType,
        displayFeaturesState);
  }

  // TODO(mattcarroll): describe the native behavior that this invokes
  // TODO(mattcarroll): determine if this is nullable or nonnull
  public Bitmap getBitmap() {
    return flutterJNI.getBitmap();
  }

  // TODO(mattcarroll): describe the native behavior that this invokes
  public void dispatchPointerDataPacket(@NonNull ByteBuffer buffer, int position) {
    flutterJNI.dispatchPointerDataPacket(buffer, position);
  }

  // TODO(mattcarroll): describe the native behavior that this invokes
  private void registerTexture(long textureId, @NonNull SurfaceTextureWrapper textureWrapper) {
    flutterJNI.registerTexture(textureId, textureWrapper);
  }

  // TODO(mattcarroll): describe the native behavior that this invokes
  private void markTextureFrameAvailable(long textureId) {
    flutterJNI.markTextureFrameAvailable(textureId);
  }

  // TODO(mattcarroll): describe the native behavior that this invokes
  private void unregisterTexture(long textureId) {
    flutterJNI.unregisterTexture(textureId);
  }

  // TODO(mattcarroll): describe the native behavior that this invokes
  public boolean isSoftwareRenderingEnabled() {
    return flutterJNI.getIsSoftwareRenderingEnabled();
  }

  // TODO(mattcarroll): describe the native behavior that this invokes
  public void setAccessibilityFeatures(int flags) {
    flutterJNI.setAccessibilityFeatures(flags);
  }

  // TODO(mattcarroll): describe the native behavior that this invokes
  public void setSemanticsEnabled(boolean enabled) {
    flutterJNI.setSemanticsEnabled(enabled);
  }

  // TODO(mattcarroll): describe the native behavior that this invokes
  public void dispatchSemanticsAction(
      int id, int action, @Nullable ByteBuffer args, int argsPosition) {
    flutterJNI.dispatchSemanticsAction(id, action, args, argsPosition);
  }

  /**
   * Mutable data structure that holds all viewport metrics properties that Flutter cares about.
   *
   * <p>All distance measurements, e.g., width, height, padding, viewInsets, are measured in device
   * pixels, not logical pixels.
   */
  public static final class ViewportMetrics {
    /** A value that indicates the setting has not been set. */
    public static final int unsetValue = -1;

    public float devicePixelRatio = 1.0f;
    public int width = 0;
    public int height = 0;
    public int viewPaddingTop = 0;
    public int viewPaddingRight = 0;
    public int viewPaddingBottom = 0;
    public int viewPaddingLeft = 0;
    public int viewInsetTop = 0;
    public int viewInsetRight = 0;
    public int viewInsetBottom = 0;
    public int viewInsetLeft = 0;
    public int systemGestureInsetTop = 0;
    public int systemGestureInsetRight = 0;
    public int systemGestureInsetBottom = 0;
    public int systemGestureInsetLeft = 0;
    public int physicalTouchSlop = unsetValue;

    /**
     * Whether this instance contains valid metrics for the Flutter application.
     *
     * @return True if width, height, and devicePixelRatio are > 0; false otherwise.
     */
    boolean validate() {
      return width > 0 && height > 0 && devicePixelRatio > 0;
    }

    public List<DisplayFeature> displayFeatures = new ArrayList<DisplayFeature>();
  }

  /**
   * Description of a physical feature on the display.
   *
   * <p>A display feature is a distinctive physical attribute located within the display panel of
   * the device. It can intrude into the application window space and create a visual distortion,
   * visual or touch discontinuity, make some area invisible or create a logical divider or
   * separation in the screen space.
   *
   * <p>Based on {@link androidx.window.layout.DisplayFeature}, with added support for cutouts.
   */
  public static final class DisplayFeature {
    public final Rect bounds;
    public final DisplayFeatureType type;
    public final DisplayFeatureState state;

    public DisplayFeature(Rect bounds, DisplayFeatureType type, DisplayFeatureState state) {
      this.bounds = bounds;
      this.type = type;
      this.state = state;
    }

    public DisplayFeature(Rect bounds, DisplayFeatureType type) {
      this.bounds = bounds;
      this.type = type;
      this.state = DisplayFeatureState.UNKNOWN;
    }
  }

  /**
   * Types of display features that can appear on the viewport.
   *
   * <p>Some, like {@link #FOLD}, can be reported without actually occluding the screen. They are
   * useful for knowing where the display is bent or has a crease. The {@link DisplayFeature#bounds}
   * can be 0-width in such cases.
   */
  public enum DisplayFeatureType {
    /**
     * Type of display feature not yet known to Flutter. This can happen if WindowManager is updated
     * with new types. The {@link DisplayFeature#bounds} is the only known property.
     */
    UNKNOWN(0),

    /**
     * A fold in the flexible display that does not occlude the screen. Corresponds to {@link
     * androidx.window.layout.FoldingFeature.OcclusionType#NONE}
     */
    FOLD(1),

    /**
     * Splits the display in two separate panels that can fold. Occludes the screen. Corresponds to
     * {@link androidx.window.layout.FoldingFeature.OcclusionType#FULL}
     */
    HINGE(2),

    /**
     * Area of the screen that usually houses cameras or sensors. Occludes the screen. Corresponds
     * to {@link android.view.DisplayCutout}
     */
    CUTOUT(3);

    public final int encodedValue;

    DisplayFeatureType(int encodedValue) {
      this.encodedValue = encodedValue;
    }
  }

  /**
   * State of the display feature.
   *
   * <p>For foldables, the state is the posture. For cutouts, this property is {@link #UNKNOWN}
   */
  public enum DisplayFeatureState {
    /** The display feature is a cutout or this state is new and not yet known to Flutter. */
    UNKNOWN(0),

    /**
     * The foldable device is completely open. The screen space that is presented to the user is
     * flat. Corresponds to {@link androidx.window.layout.FoldingFeature.State#FLAT}
     */
    POSTURE_FLAT(1),

    /**
     * The foldable device's hinge is in an intermediate position between opened and closed state.
     * There is a non-flat angle between parts of the flexible screen or between physical display
     * panels. Corresponds to {@link androidx.window.layout.FoldingFeature.State#HALF_OPENED}
     */
    POSTURE_HALF_OPENED(2);

    public final int encodedValue;

    DisplayFeatureState(int encodedValue) {
      this.encodedValue = encodedValue;
    }
  }
}
