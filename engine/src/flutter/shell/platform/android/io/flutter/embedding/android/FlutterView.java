// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.embedding.android;

import android.annotation.SuppressLint;
import android.annotation.TargetApi;
import android.content.Context;
import android.content.res.Configuration;
import android.graphics.Insets;
import android.graphics.Rect;
import android.os.Build;
import android.text.format.DateFormat;
import android.util.AttributeSet;
import android.util.SparseArray;
import android.view.KeyEvent;
import android.view.MotionEvent;
import android.view.PointerIcon;
import android.view.Surface;
import android.view.View;
import android.view.ViewStructure;
import android.view.WindowInsets;
import android.view.WindowManager;
import android.view.accessibility.AccessibilityManager;
import android.view.accessibility.AccessibilityNodeProvider;
import android.view.autofill.AutofillValue;
import android.view.inputmethod.EditorInfo;
import android.view.inputmethod.InputConnection;
import android.widget.FrameLayout;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.annotation.RequiresApi;
import androidx.annotation.VisibleForTesting;
import io.flutter.Log;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.embedding.engine.renderer.FlutterRenderer;
import io.flutter.embedding.engine.renderer.FlutterUiDisplayListener;
import io.flutter.embedding.engine.renderer.RenderSurface;
import io.flutter.embedding.engine.systemchannels.SettingsChannel;
import io.flutter.plugin.editing.TextInputPlugin;
import io.flutter.plugin.localization.LocalizationPlugin;
import io.flutter.plugin.mouse.MouseCursorPlugin;
import io.flutter.plugin.platform.PlatformViewsController;
import io.flutter.view.AccessibilityBridge;
import java.util.HashSet;
import java.util.Set;

/**
 * Displays a Flutter UI on an Android device.
 *
 * <p>A {@code FlutterView}'s UI is painted by a corresponding {@link FlutterEngine}.
 *
 * <p>A {@code FlutterView} can operate in 2 different {@link
 * io.flutter.embedding.android.RenderMode}s:
 *
 * <ol>
 *   <li>{@link io.flutter.embedding.android.RenderMode#surface}, which paints a Flutter UI to a
 *       {@link android.view.SurfaceView}. This mode has the best performance, but a {@code
 *       FlutterView} in this mode cannot be positioned between 2 other Android {@code View}s in the
 *       z-index, nor can it be animated/transformed. Unless the special capabilities of a {@link
 *       android.graphics.SurfaceTexture} are required, developers should strongly prefer this
 *       render mode.
 *   <li>{@link io.flutter.embedding.android.RenderMode#texture}, which paints a Flutter UI to a
 *       {@link android.graphics.SurfaceTexture}. This mode is not as performant as {@link
 *       io.flutter.embedding.android.RenderMode#surface}, but a {@code FlutterView} in this mode
 *       can be animated and transformed, as well as positioned in the z-index between 2+ other
 *       Android {@code Views}. Unless the special capabilities of a {@link
 *       android.graphics.SurfaceTexture} are required, developers should strongly prefer the {@link
 *       io.flutter.embedding.android.RenderMode#surface} render mode.
 * </ol>
 *
 * See <a>https://source.android.com/devices/graphics/arch-tv#surface_or_texture</a> for more
 * information comparing {@link android.view.SurfaceView} and {@link android.view.TextureView}.
 */
public class FlutterView extends FrameLayout implements MouseCursorPlugin.MouseCursorViewDelegate {
  private static final String TAG = "FlutterView";

  // Internal view hierarchy references.
  @Nullable private FlutterSurfaceView flutterSurfaceView;
  @Nullable private FlutterTextureView flutterTextureView;
  @Nullable private FlutterImageView flutterImageView;
  @Nullable private RenderSurface renderSurface;
  @Nullable private RenderSurface previousRenderSurface;
  private final Set<FlutterUiDisplayListener> flutterUiDisplayListeners = new HashSet<>();
  private boolean isFlutterUiDisplayed;

  // Connections to a Flutter execution context.
  @Nullable private FlutterEngine flutterEngine;

  @NonNull
  private final Set<FlutterEngineAttachmentListener> flutterEngineAttachmentListeners =
      new HashSet<>();

  // Components that process various types of Android View input and events,
  // possibly storing intermediate state, and communicating those events to Flutter.
  //
  // These components essentially add some additional behavioral logic on top of
  // existing, stateless system channels, e.g., KeyEventChannel, TextInputChannel, etc.
  @Nullable private MouseCursorPlugin mouseCursorPlugin;
  @Nullable private TextInputPlugin textInputPlugin;
  @Nullable private LocalizationPlugin localizationPlugin;
  @Nullable private AndroidKeyProcessor androidKeyProcessor;
  @Nullable private AndroidTouchProcessor androidTouchProcessor;
  @Nullable private AccessibilityBridge accessibilityBridge;

  // Directly implemented View behavior that communicates with Flutter.
  private final FlutterRenderer.ViewportMetrics viewportMetrics =
      new FlutterRenderer.ViewportMetrics();

  private final AccessibilityBridge.OnAccessibilityChangeListener onAccessibilityChangeListener =
      new AccessibilityBridge.OnAccessibilityChangeListener() {
        @Override
        public void onAccessibilityChanged(
            boolean isAccessibilityEnabled, boolean isTouchExplorationEnabled) {
          resetWillNotDraw(isAccessibilityEnabled, isTouchExplorationEnabled);
        }
      };

  private final FlutterUiDisplayListener flutterUiDisplayListener =
      new FlutterUiDisplayListener() {
        @Override
        public void onFlutterUiDisplayed() {
          isFlutterUiDisplayed = true;

          for (FlutterUiDisplayListener listener : flutterUiDisplayListeners) {
            listener.onFlutterUiDisplayed();
          }
        }

        @Override
        public void onFlutterUiNoLongerDisplayed() {
          isFlutterUiDisplayed = false;

          for (FlutterUiDisplayListener listener : flutterUiDisplayListeners) {
            listener.onFlutterUiNoLongerDisplayed();
          }
        }
      };

  /**
   * Constructs a {@code FlutterView} programmatically, without any XML attributes.
   *
   * <p>
   *
   * <ul>
   *   <li>A {@link FlutterSurfaceView} is used to render the Flutter UI.
   *   <li>{@code transparencyMode} defaults to {@link TransparencyMode#opaque}.
   * </ul>
   *
   * {@code FlutterView} requires an {@code Activity} instead of a generic {@code Context} to be
   * compatible with {@link PlatformViewsController}.
   */
  public FlutterView(@NonNull Context context) {
    this(context, null, new FlutterSurfaceView(context));
  }

  /**
   * Deprecated - use {@link #FlutterView(Context, FlutterSurfaceView)} or {@link
   * #FlutterView(Context, FlutterTextureView)} or {@link #FlutterView(Context, FlutterImageView)}
   * instead.
   */
  @Deprecated
  public FlutterView(@NonNull Context context, @NonNull RenderMode renderMode) {
    super(context, null);

    if (renderMode == RenderMode.surface) {
      flutterSurfaceView = new FlutterSurfaceView(context);
      renderSurface = flutterSurfaceView;
    } else if (renderMode == RenderMode.texture) {
      flutterTextureView = new FlutterTextureView(context);
      renderSurface = flutterTextureView;
    } else {
      throw new IllegalArgumentException(
          String.format("RenderMode not supported with this constructor: %s", renderMode));
    }

    init();
  }

  /**
   * Deprecated - use {@link #FlutterView(Context, FlutterSurfaceView)} or {@link
   * #FlutterView(Context, FlutterTextureView)} instead, and configure the incoming {@code
   * FlutterSurfaceView} or {@code FlutterTextureView} for transparency as desired.
   *
   * <p>Constructs a {@code FlutterView} programmatically, without any XML attributes, uses a {@link
   * FlutterSurfaceView} to render the Flutter UI, and allows selection of a {@code
   * transparencyMode}.
   *
   * <p>{@code FlutterView} requires an {@code Activity} instead of a generic {@code Context} to be
   * compatible with {@link PlatformViewsController}.
   */
  @Deprecated
  public FlutterView(@NonNull Context context, @NonNull TransparencyMode transparencyMode) {
    this(
        context,
        null,
        new FlutterSurfaceView(context, transparencyMode == TransparencyMode.transparent));
  }

  /**
   * Constructs a {@code FlutterView} programmatically, without any XML attributes, uses the given
   * {@link FlutterSurfaceView} to render the Flutter UI, and allows selection of a {@code
   * transparencyMode}.
   *
   * <p>{@code FlutterView} requires an {@code Activity} instead of a generic {@code Context} to be
   * compatible with {@link PlatformViewsController}.
   */
  public FlutterView(@NonNull Context context, @NonNull FlutterSurfaceView flutterSurfaceView) {
    this(context, null, flutterSurfaceView);
  }

  /**
   * Constructs a {@code FlutterView} programmatically, without any XML attributes, uses the given
   * {@link FlutterTextureView} to render the Flutter UI, and allows selection of a {@code
   * transparencyMode}.
   *
   * <p>{@code FlutterView} requires an {@code Activity} instead of a generic {@code Context} to be
   * compatible with {@link PlatformViewsController}.
   */
  public FlutterView(@NonNull Context context, @NonNull FlutterTextureView flutterTextureView) {
    this(context, null, flutterTextureView);
  }

  /**
   * Constructs a {@code FlutterView} programmatically, without any XML attributes, uses the given
   * {@link FlutterImageView} to render the Flutter UI.
   *
   * <p>{@code FlutterView} requires an {@code Activity} instead of a generic {@code Context} to be
   * compatible with {@link PlatformViewsController}.
   */
  @TargetApi(19)
  public FlutterView(@NonNull Context context, @NonNull FlutterImageView flutterImageView) {
    this(context, null, flutterImageView);
  }

  /**
   * Constructs a {@code FlutterView} in an XML-inflation-compliant manner.
   *
   * <p>{@code FlutterView} requires an {@code Activity} instead of a generic {@code Context} to be
   * compatible with {@link PlatformViewsController}.
   */
  // TODO(mattcarroll): expose renderMode in XML when build system supports R.attr
  public FlutterView(@NonNull Context context, @Nullable AttributeSet attrs) {
    this(context, attrs, new FlutterSurfaceView(context));
  }

  /**
   * Deprecated - use {@link #FlutterView(Context, FlutterSurfaceView)} or {@link
   * #FlutterView(Context, FlutterTextureView)} instead, and configure the incoming {@code
   * FlutterSurfaceView} or {@code FlutterTextureView} for transparency as desired.
   */
  @Deprecated
  public FlutterView(
      @NonNull Context context,
      @NonNull RenderMode renderMode,
      @NonNull TransparencyMode transparencyMode) {
    super(context, null);

    if (renderMode == RenderMode.surface) {
      flutterSurfaceView =
          new FlutterSurfaceView(context, transparencyMode == TransparencyMode.transparent);
      renderSurface = flutterSurfaceView;
    } else if (renderMode == RenderMode.texture) {
      flutterTextureView = new FlutterTextureView(context);
      renderSurface = flutterTextureView;
    } else {
      throw new IllegalArgumentException(
          String.format("RenderMode not supported with this constructor: %s", renderMode));
    }

    init();
  }

  private FlutterView(
      @NonNull Context context,
      @Nullable AttributeSet attrs,
      @NonNull FlutterSurfaceView flutterSurfaceView) {
    super(context, attrs);

    this.flutterSurfaceView = flutterSurfaceView;
    this.renderSurface = flutterSurfaceView;

    init();
  }

  private FlutterView(
      @NonNull Context context,
      @Nullable AttributeSet attrs,
      @NonNull FlutterTextureView flutterTextureView) {
    super(context, attrs);

    this.flutterTextureView = flutterTextureView;
    this.renderSurface = flutterTextureView;

    init();
  }

  @TargetApi(19)
  private FlutterView(
      @NonNull Context context,
      @Nullable AttributeSet attrs,
      @NonNull FlutterImageView flutterImageView) {
    super(context, attrs);

    this.flutterImageView = flutterImageView;
    this.renderSurface = flutterImageView;

    init();
  }

  private void init() {
    Log.v(TAG, "Initializing FlutterView");

    if (flutterSurfaceView != null) {
      Log.v(TAG, "Internally using a FlutterSurfaceView.");
      addView(flutterSurfaceView);
    } else if (flutterTextureView != null) {
      Log.v(TAG, "Internally using a FlutterTextureView.");
      addView(flutterTextureView);
    } else {
      Log.v(TAG, "Internally using a FlutterImageView.");
      addView(flutterImageView);
    }

    // FlutterView needs to be focusable so that the InputMethodManager can interact with it.
    setFocusable(true);
    setFocusableInTouchMode(true);
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
      setImportantForAutofill(View.IMPORTANT_FOR_AUTOFILL_YES_EXCLUDE_DESCENDANTS);
    }
  }

  /**
   * Returns true if an attached {@link FlutterEngine} has rendered at least 1 frame to this {@code
   * FlutterView}.
   *
   * <p>Returns false if no {@link FlutterEngine} is attached.
   *
   * <p>This flag is specific to a given {@link FlutterEngine}. The following hypothetical timeline
   * demonstrates how this flag changes over time.
   *
   * <ol>
   *   <li>{@code flutterEngineA} is attached to this {@code FlutterView}: returns false
   *   <li>{@code flutterEngineA} renders its first frame to this {@code FlutterView}: returns true
   *   <li>{@code flutterEngineA} is detached from this {@code FlutterView}: returns false
   *   <li>{@code flutterEngineB} is attached to this {@code FlutterView}: returns false
   *   <li>{@code flutterEngineB} renders its first frame to this {@code FlutterView}: returns true
   * </ol>
   */
  public boolean hasRenderedFirstFrame() {
    return isFlutterUiDisplayed;
  }

  /**
   * Adds the given {@code listener} to this {@code FlutterView}, to be notified upon Flutter's
   * first rendered frame.
   */
  public void addOnFirstFrameRenderedListener(@NonNull FlutterUiDisplayListener listener) {
    flutterUiDisplayListeners.add(listener);
  }

  /**
   * Removes the given {@code listener}, which was previously added with {@link
   * #addOnFirstFrameRenderedListener(FlutterUiDisplayListener)}.
   */
  public void removeOnFirstFrameRenderedListener(@NonNull FlutterUiDisplayListener listener) {
    flutterUiDisplayListeners.remove(listener);
  }

  // ------- Start: Process View configuration that Flutter cares about. ------
  /**
   * Sends relevant configuration data from Android to Flutter when the Android {@link
   * Configuration} changes.
   *
   * <p>The Android {@link Configuration} might change as a result of device orientation change,
   * device language change, device text scale factor change, etc.
   */
  @Override
  protected void onConfigurationChanged(@NonNull Configuration newConfig) {
    super.onConfigurationChanged(newConfig);
    // We've observed on Android Q that going to the background, changing
    // orientation, and bringing the app back to foreground results in a sequence
    // of detatch from flutterEngine, onConfigurationChanged, followed by attach
    // to flutterEngine.
    // No-op here so that we avoid NPE; these channels will get notified once
    // the activity or fragment tell the view to attach to the Flutter engine
    // again (e.g. in onStart).
    if (flutterEngine != null) {
      Log.v(TAG, "Configuration changed. Sending locales and user settings to Flutter.");
      localizationPlugin.sendLocalesToFlutter(newConfig);
      sendUserSettingsToFlutter();
    }
  }

  /**
   * Invoked when this {@code FlutterView} changes size, including upon initial measure.
   *
   * <p>The initial measure reports an {@code oldWidth} and {@code oldHeight} of zero.
   *
   * <p>Flutter cares about the width and height of the view that displays it on the host platform.
   * Therefore, when this method is invoked, the new width and height are communicated to Flutter as
   * the "physical size" of the view that displays Flutter's UI.
   */
  @Override
  protected void onSizeChanged(int width, int height, int oldWidth, int oldHeight) {
    super.onSizeChanged(width, height, oldWidth, oldHeight);
    Log.v(
        TAG,
        "Size changed. Sending Flutter new viewport metrics. FlutterView was "
            + oldWidth
            + " x "
            + oldHeight
            + ", it is now "
            + width
            + " x "
            + height);
    viewportMetrics.width = width;
    viewportMetrics.height = height;
    sendViewportMetricsToFlutter();
  }

  // TODO(garyq): Add support for notch cutout API: https://github.com/flutter/flutter/issues/56592
  // Decide if we want to zero the padding of the sides. When in Landscape orientation,
  // android may decide to place the software navigation bars on the side. When the nav
  // bar is hidden, the reported insets should be removed to prevent extra useless space
  // on the sides.
  private enum ZeroSides {
    NONE,
    LEFT,
    RIGHT,
    BOTH
  }

  private ZeroSides calculateShouldZeroSides() {
    // We get both orientation and rotation because rotation is all 4
    // rotations relative to default rotation while orientation is portrait
    // or landscape. By combining both, we can obtain a more precise measure
    // of the rotation.
    Context context = getContext();
    int orientation = context.getResources().getConfiguration().orientation;
    int rotation =
        ((WindowManager) context.getSystemService(Context.WINDOW_SERVICE))
            .getDefaultDisplay()
            .getRotation();

    if (orientation == Configuration.ORIENTATION_LANDSCAPE) {
      if (rotation == Surface.ROTATION_90) {
        return ZeroSides.RIGHT;
      } else if (rotation == Surface.ROTATION_270) {
        // In android API >= 23, the nav bar always appears on the "bottom" (USB) side.
        return Build.VERSION.SDK_INT >= 23 ? ZeroSides.LEFT : ZeroSides.RIGHT;
      }
      // Ambiguous orientation due to landscape left/right default. Zero both sides.
      else if (rotation == Surface.ROTATION_0 || rotation == Surface.ROTATION_180) {
        return ZeroSides.BOTH;
      }
    }
    // Square orientation deprecated in API 16, we will not check for it and return false
    // to be safe and not remove any unique padding for the devices that do use it.
    return ZeroSides.NONE;
  }

  // TODO(garyq): Use new Android R getInsets API
  // TODO(garyq): The keyboard detection may interact strangely with
  //   https://github.com/flutter/flutter/issues/22061

  // Uses inset heights and screen heights as a heuristic to determine if the insets should
  // be padded. When the on-screen keyboard is detected, we want to include the full inset
  // but when the inset is just the hidden nav bar, we want to provide a zero inset so the space
  // can be used.
  @TargetApi(20)
  @RequiresApi(20)
  private int guessBottomKeyboardInset(WindowInsets insets) {
    int screenHeight = getRootView().getHeight();
    // Magic number due to this being a heuristic. This should be replaced, but we have not
    // found a clean way to do it yet (Sept. 2018)
    final double keyboardHeightRatioHeuristic = 0.18;
    if (insets.getSystemWindowInsetBottom() < screenHeight * keyboardHeightRatioHeuristic) {
      // Is not a keyboard, so return zero as inset.
      return 0;
    } else {
      // Is a keyboard, so return the full inset.
      return insets.getSystemWindowInsetBottom();
    }
  }

  /**
   * Invoked when Android's desired window insets change, i.e., padding.
   *
   * <p>Flutter does not use a standard {@code View} hierarchy and therefore Flutter is unaware of
   * these insets. Therefore, this method calculates the viewport metrics that Flutter should use
   * and then sends those metrics to Flutter.
   *
   * <p>This callback is not present in API < 20, which means lower API devices will see the wider
   * than expected padding when the status and navigation bars are hidden.
   */
  @Override
  @TargetApi(20)
  @RequiresApi(20)
  // The annotations to suppress "InlinedApi" and "NewApi" lints prevent lint warnings
  // caused by usage of Android Q APIs. These calls are safe because they are
  // guarded.
  @SuppressLint({"InlinedApi", "NewApi"})
  @NonNull
  public final WindowInsets onApplyWindowInsets(@NonNull WindowInsets insets) {
    WindowInsets newInsets = super.onApplyWindowInsets(insets);

    boolean statusBarHidden = (SYSTEM_UI_FLAG_FULLSCREEN & getWindowSystemUiVisibility()) != 0;
    boolean navigationBarHidden =
        (SYSTEM_UI_FLAG_HIDE_NAVIGATION & getWindowSystemUiVisibility()) != 0;
    // We zero the left and/or right sides to prevent the padding the
    // navigation bar would have caused.
    ZeroSides zeroSides = ZeroSides.NONE;
    if (navigationBarHidden) {
      zeroSides = calculateShouldZeroSides();
    }

    // Status bar (top) and left/right system insets should partially obscure the content (padding).
    viewportMetrics.paddingTop = statusBarHidden ? 0 : insets.getSystemWindowInsetTop();
    viewportMetrics.paddingRight =
        zeroSides == ZeroSides.RIGHT || zeroSides == ZeroSides.BOTH
            ? 0
            : insets.getSystemWindowInsetRight();
    viewportMetrics.paddingBottom = 0;
    viewportMetrics.paddingLeft =
        zeroSides == ZeroSides.LEFT || zeroSides == ZeroSides.BOTH
            ? 0
            : insets.getSystemWindowInsetLeft();

    // Bottom system inset (keyboard) should adjust scrollable bottom edge (inset).
    viewportMetrics.viewInsetTop = 0;
    viewportMetrics.viewInsetRight = 0;
    viewportMetrics.viewInsetBottom =
        navigationBarHidden
            ? guessBottomKeyboardInset(insets)
            : insets.getSystemWindowInsetBottom();
    viewportMetrics.viewInsetLeft = 0;

    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
      Insets systemGestureInsets = insets.getSystemGestureInsets();
      viewportMetrics.systemGestureInsetTop = systemGestureInsets.top;
      viewportMetrics.systemGestureInsetRight = systemGestureInsets.right;
      viewportMetrics.systemGestureInsetBottom = systemGestureInsets.bottom;
      viewportMetrics.systemGestureInsetLeft = systemGestureInsets.left;
    }

    Log.v(
        TAG,
        "Updating window insets (onApplyWindowInsets()):\n"
            + "Status bar insets: Top: "
            + viewportMetrics.paddingTop
            + ", Left: "
            + viewportMetrics.paddingLeft
            + ", Right: "
            + viewportMetrics.paddingRight
            + "\n"
            + "Keyboard insets: Bottom: "
            + viewportMetrics.viewInsetBottom
            + ", Left: "
            + viewportMetrics.viewInsetLeft
            + ", Right: "
            + viewportMetrics.viewInsetRight
            + "System Gesture Insets - Left: "
            + viewportMetrics.systemGestureInsetLeft
            + ", Top: "
            + viewportMetrics.systemGestureInsetTop
            + ", Right: "
            + viewportMetrics.systemGestureInsetRight
            + ", Bottom: "
            + viewportMetrics.viewInsetBottom);

    sendViewportMetricsToFlutter();

    return newInsets;
  }

  /**
   * Invoked when Android's desired window insets change, i.e., padding.
   *
   * <p>{@code fitSystemWindows} is an earlier version of {@link
   * #onApplyWindowInsets(WindowInsets)}. See that method for more details about how window insets
   * relate to Flutter.
   */
  @Override
  @SuppressWarnings("deprecation")
  protected boolean fitSystemWindows(@NonNull Rect insets) {
    if (Build.VERSION.SDK_INT <= Build.VERSION_CODES.KITKAT) {
      // Status bar, left/right system insets partially obscure content (padding).
      viewportMetrics.paddingTop = insets.top;
      viewportMetrics.paddingRight = insets.right;
      viewportMetrics.paddingBottom = 0;
      viewportMetrics.paddingLeft = insets.left;

      // Bottom system inset (keyboard) should adjust scrollable bottom edge (inset).
      viewportMetrics.viewInsetTop = 0;
      viewportMetrics.viewInsetRight = 0;
      viewportMetrics.viewInsetBottom = insets.bottom;
      viewportMetrics.viewInsetLeft = 0;

      Log.v(
          TAG,
          "Updating window insets (fitSystemWindows()):\n"
              + "Status bar insets: Top: "
              + viewportMetrics.paddingTop
              + ", Left: "
              + viewportMetrics.paddingLeft
              + ", Right: "
              + viewportMetrics.paddingRight
              + "\n"
              + "Keyboard insets: Bottom: "
              + viewportMetrics.viewInsetBottom
              + ", Left: "
              + viewportMetrics.viewInsetLeft
              + ", Right: "
              + viewportMetrics.viewInsetRight);

      sendViewportMetricsToFlutter();
      return true;
    } else {
      return super.fitSystemWindows(insets);
    }
  }
  // ------- End: Process View configuration that Flutter cares about. --------

  // -------- Start: Process UI I/O that Flutter cares about. -------
  /**
   * Creates an {@link InputConnection} to work with a {@link
   * android.view.inputmethod.InputMethodManager}.
   *
   * <p>Any {@code View} that can take focus or process text input must implement this method by
   * returning a non-null {@code InputConnection}. Flutter may render one or many focusable and
   * text-input widgets, therefore {@code FlutterView} must support an {@code InputConnection}.
   *
   * <p>The {@code InputConnection} returned from this method comes from a {@link TextInputPlugin},
   * which is owned by this {@code FlutterView}. A {@link TextInputPlugin} exists to encapsulate the
   * nuances of input communication, rather than spread that logic throughout this {@code
   * FlutterView}.
   */
  @Override
  @Nullable
  public InputConnection onCreateInputConnection(@NonNull EditorInfo outAttrs) {
    if (!isAttachedToFlutterEngine()) {
      return super.onCreateInputConnection(outAttrs);
    }

    return textInputPlugin.createInputConnection(this, outAttrs);
  }

  /**
   * Allows a {@code View} that is not currently the input connection target to invoke commands on
   * the {@link android.view.inputmethod.InputMethodManager}, which is otherwise disallowed.
   *
   * <p>Returns true to allow non-input-connection-targets to invoke methods on {@code
   * InputMethodManager}, or false to exclusively allow the input connection target to invoke such
   * methods.
   */
  @Override
  public boolean checkInputConnectionProxy(View view) {
    return flutterEngine != null
        ? flutterEngine.getPlatformViewsController().checkInputConnectionProxy(view)
        : super.checkInputConnectionProxy(view);
  }

  /**
   * Invoked when key is released.
   *
   * <p>This method is typically invoked in response to the release of a physical keyboard key or a
   * D-pad button. It is generally not invoked when a virtual software keyboard is used, though a
   * software keyboard may choose to invoke this method in some situations.
   *
   * <p>{@link KeyEvent}s are sent from Android to Flutter. {@link AndroidKeyProcessor} may do some
   * additional work with the given {@link KeyEvent}, e.g., combine this {@code keyCode} with the
   * previous {@code keyCode} to generate a unicode combined character.
   */
  @Override
  public boolean onKeyUp(int keyCode, @NonNull KeyEvent event) {
    if (!isAttachedToFlutterEngine()) {
      return super.onKeyUp(keyCode, event);
    }

    androidKeyProcessor.onKeyUp(event);
    return super.onKeyUp(keyCode, event);
  }

  /**
   * Invoked when key is pressed.
   *
   * <p>This method is typically invoked in response to the press of a physical keyboard key or a
   * D-pad button. It is generally not invoked when a virtual software keyboard is used, though a
   * software keyboard may choose to invoke this method in some situations.
   *
   * <p>{@link KeyEvent}s are sent from Android to Flutter. {@link AndroidKeyProcessor} may do some
   * additional work with the given {@link KeyEvent}, e.g., combine this {@code keyCode} with the
   * previous {@code keyCode} to generate a unicode combined character.
   */
  @Override
  public boolean onKeyDown(int keyCode, @NonNull KeyEvent event) {
    if (!isAttachedToFlutterEngine()) {
      return super.onKeyDown(keyCode, event);
    }

    androidKeyProcessor.onKeyDown(event);
    return super.onKeyDown(keyCode, event);
  }

  /**
   * Invoked by Android when a user touch event occurs.
   *
   * <p>Flutter handles all of its own gesture detection and processing, therefore this method
   * forwards all {@link MotionEvent} data from Android to Flutter.
   */
  @Override
  public boolean onTouchEvent(@NonNull MotionEvent event) {
    if (!isAttachedToFlutterEngine()) {
      return super.onTouchEvent(event);
    }

    // TODO(abarth): This version check might not be effective in some
    // versions of Android that statically compile code and will be upset
    // at the lack of |requestUnbufferedDispatch|. Instead, we should factor
    // version-dependent code into separate classes for each supported
    // version and dispatch dynamically.
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
      requestUnbufferedDispatch(event);
    }

    return androidTouchProcessor.onTouchEvent(event);
  }

  /**
   * Invoked by Android when a generic motion event occurs, e.g., joystick movement, mouse hover,
   * track pad touches, scroll wheel movements, etc.
   *
   * <p>Flutter handles all of its own gesture detection and processing, therefore this method
   * forwards all {@link MotionEvent} data from Android to Flutter.
   */
  @Override
  public boolean onGenericMotionEvent(@NonNull MotionEvent event) {
    boolean handled =
        isAttachedToFlutterEngine() && androidTouchProcessor.onGenericMotionEvent(event);
    return handled ? true : super.onGenericMotionEvent(event);
  }

  /**
   * Invoked by Android when a hover-compliant input system causes a hover event.
   *
   * <p>An example of hover events is a stylus sitting near an Android screen. As the stylus moves
   * from outside a {@code View} to hover over a {@code View}, or move around within a {@code View},
   * or moves from over a {@code View} to outside a {@code View}, a corresponding {@link
   * MotionEvent} is reported via this method.
   *
   * <p>Hover events can be used for accessibility touch exploration and therefore are processed
   * here for accessibility purposes.
   */
  @Override
  public boolean onHoverEvent(@NonNull MotionEvent event) {
    if (!isAttachedToFlutterEngine()) {
      return super.onHoverEvent(event);
    }

    boolean handled = accessibilityBridge.onAccessibilityHoverEvent(event);
    if (!handled) {
      // TODO(ianh): Expose hover events to the platform,
      // implementing ADD, REMOVE, etc.
    }
    return handled;
  }
  // -------- End: Process UI I/O that Flutter cares about. ---------

  // -------- Start: Accessibility -------
  @Override
  @Nullable
  public AccessibilityNodeProvider getAccessibilityNodeProvider() {
    if (accessibilityBridge != null && accessibilityBridge.isAccessibilityEnabled()) {
      return accessibilityBridge;
    } else {
      // TODO(goderbauer): when a11y is off this should return a one-off snapshot of
      // the a11y
      // tree.
      return null;
    }
  }

  // TODO(mattcarroll): Confer with Ian as to why we need this method. Delete if possible, otherwise
  // add comments.
  private void resetWillNotDraw(boolean isAccessibilityEnabled, boolean isTouchExplorationEnabled) {
    if (!flutterEngine.getRenderer().isSoftwareRenderingEnabled()) {
      setWillNotDraw(!(isAccessibilityEnabled || isTouchExplorationEnabled));
    } else {
      setWillNotDraw(false);
    }
  }
  // -------- End: Accessibility ---------

  // -------- Start: Mouse -------
  @Override
  @TargetApi(Build.VERSION_CODES.N)
  @RequiresApi(Build.VERSION_CODES.N)
  @NonNull
  public PointerIcon getSystemPointerIcon(int type) {
    return PointerIcon.getSystemIcon(getContext(), type);
  }
  // -------- End: Mouse ---------

  /**
   * Connects this {@code FlutterView} to the given {@link FlutterEngine}.
   *
   * <p>This {@code FlutterView} will begin rendering the UI painted by the given {@link
   * FlutterEngine}. This {@code FlutterView} will also begin forwarding interaction events from
   * this {@code FlutterView} to the given {@link FlutterEngine}, e.g., user touch events,
   * accessibility events, keyboard events, and others.
   *
   * <p>See {@link #detachFromFlutterEngine()} for information on how to detach from a {@link
   * FlutterEngine}.
   */
  public void attachToFlutterEngine(@NonNull FlutterEngine flutterEngine) {
    Log.v(TAG, "Attaching to a FlutterEngine: " + flutterEngine);
    if (isAttachedToFlutterEngine()) {
      if (flutterEngine == this.flutterEngine) {
        // We are already attached to this FlutterEngine
        Log.v(TAG, "Already attached to this engine. Doing nothing.");
        return;
      }

      // Detach from a previous FlutterEngine so we can attach to this new one.
      Log.v(
          TAG,
          "Currently attached to a different engine. Detaching and then attaching"
              + " to new engine.");
      detachFromFlutterEngine();
    }

    this.flutterEngine = flutterEngine;

    // Instruct our FlutterRenderer that we are now its designated RenderSurface.
    FlutterRenderer flutterRenderer = this.flutterEngine.getRenderer();
    isFlutterUiDisplayed = flutterRenderer.isDisplayingFlutterUi();
    renderSurface.attachToRenderer(flutterRenderer);
    flutterRenderer.addIsDisplayingFlutterUiListener(flutterUiDisplayListener);

    // Initialize various components that know how to process Android View I/O
    // in a way that Flutter understands.
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
      mouseCursorPlugin = new MouseCursorPlugin(this, this.flutterEngine.getMouseCursorChannel());
    }
    textInputPlugin =
        new TextInputPlugin(
            this,
            this.flutterEngine.getTextInputChannel(),
            this.flutterEngine.getPlatformViewsController());
    localizationPlugin = this.flutterEngine.getLocalizationPlugin();
    androidKeyProcessor =
        new AndroidKeyProcessor(this.flutterEngine.getKeyEventChannel(), textInputPlugin);
    androidTouchProcessor =
        new AndroidTouchProcessor(this.flutterEngine.getRenderer(), /*trackMotionEvents=*/ false);
    accessibilityBridge =
        new AccessibilityBridge(
            this,
            flutterEngine.getAccessibilityChannel(),
            (AccessibilityManager) getContext().getSystemService(Context.ACCESSIBILITY_SERVICE),
            getContext().getContentResolver(),
            this.flutterEngine.getPlatformViewsController());
    accessibilityBridge.setOnAccessibilityChangeListener(onAccessibilityChangeListener);
    resetWillNotDraw(
        accessibilityBridge.isAccessibilityEnabled(),
        accessibilityBridge.isTouchExplorationEnabled());

    // Connect AccessibilityBridge to the PlatformViewsController within the FlutterEngine.
    // This allows platform Views to hook into Flutter's overall accessibility system.
    this.flutterEngine.getPlatformViewsController().attachAccessibilityBridge(accessibilityBridge);
    this.flutterEngine
        .getPlatformViewsController()
        .attachToFlutterRenderer(this.flutterEngine.getRenderer());

    // Inform the Android framework that it should retrieve a new InputConnection
    // now that an engine is attached.
    // TODO(mattcarroll): once this is proven to work, move this line ot TextInputPlugin
    textInputPlugin.getInputMethodManager().restartInput(this);

    // Push View and Context related information from Android to Flutter.
    sendUserSettingsToFlutter();
    localizationPlugin.sendLocalesToFlutter(getResources().getConfiguration());
    sendViewportMetricsToFlutter();

    flutterEngine.getPlatformViewsController().attachToView(this);

    // Notify engine attachment listeners of the attachment.
    for (FlutterEngineAttachmentListener listener : flutterEngineAttachmentListeners) {
      listener.onFlutterEngineAttachedToFlutterView(flutterEngine);
    }

    // If the first frame has already been rendered, notify all first frame listeners.
    // Do this after all other initialization so that listeners don't inadvertently interact
    // with a FlutterView that is only partially attached to a FlutterEngine.
    if (isFlutterUiDisplayed) {
      flutterUiDisplayListener.onFlutterUiDisplayed();
    }
  }

  /**
   * Disconnects this {@code FlutterView} from a previously attached {@link FlutterEngine}.
   *
   * <p>This {@code FlutterView} will clear its UI and stop forwarding all events to the
   * previously-attached {@link FlutterEngine}. This includes touch events, accessibility events,
   * keyboard events, and others.
   *
   * <p>See {@link #attachToFlutterEngine(FlutterEngine)} for information on how to attach a {@link
   * FlutterEngine}.
   */
  public void detachFromFlutterEngine() {
    Log.v(TAG, "Detaching from a FlutterEngine: " + flutterEngine);
    if (!isAttachedToFlutterEngine()) {
      Log.v(TAG, "Not attached to an engine. Doing nothing.");
      return;
    }

    // Notify engine attachment listeners of the detachment.
    for (FlutterEngineAttachmentListener listener : flutterEngineAttachmentListeners) {
      listener.onFlutterEngineDetachedFromFlutterView();
    }

    flutterEngine.getPlatformViewsController().detachFromView();

    // Disconnect the FlutterEngine's PlatformViewsController from the AccessibilityBridge.
    flutterEngine.getPlatformViewsController().detachAccessibiltyBridge();

    // Disconnect and clean up the AccessibilityBridge.
    accessibilityBridge.release();
    accessibilityBridge = null;

    // Inform the Android framework that it should retrieve a new InputConnection
    // now that the engine is detached. The new InputConnection will be null, which
    // signifies that this View does not process input (until a new engine is attached).
    // TODO(mattcarroll): once this is proven to work, move this line ot TextInputPlugin
    textInputPlugin.getInputMethodManager().restartInput(this);
    textInputPlugin.destroy();

    if (mouseCursorPlugin != null) {
      mouseCursorPlugin.destroy();
    }

    // Instruct our FlutterRenderer that we are no longer interested in being its RenderSurface.
    FlutterRenderer flutterRenderer = flutterEngine.getRenderer();
    isFlutterUiDisplayed = false;
    flutterRenderer.removeIsDisplayingFlutterUiListener(flutterUiDisplayListener);
    flutterRenderer.stopRenderingToSurface();
    flutterRenderer.setSemanticsEnabled(false);
    renderSurface.detachFromRenderer();

    flutterImageView = null;
    previousRenderSurface = null;
    flutterEngine = null;
  }

  @VisibleForTesting
  @NonNull
  public FlutterImageView createImageView() {
    return new FlutterImageView(
        getContext(), getWidth(), getHeight(), FlutterImageView.SurfaceKind.background);
  }

  /**
   * Converts the current render surface to a {@link FlutterImageView} if it's not one already.
   * Otherwise, it resizes the {@link FlutterImageView} based on the current view size.
   */
  public void convertToImageView() {
    renderSurface.pause();

    if (flutterImageView == null) {
      flutterImageView = createImageView();
      addView(flutterImageView);
    } else {
      flutterImageView.resizeIfNeeded(getWidth(), getHeight());
    }

    previousRenderSurface = renderSurface;
    renderSurface = flutterImageView;
    if (flutterEngine != null) {
      renderSurface.attachToRenderer(flutterEngine.getRenderer());
    }
  }

  /**
   * If the surface is rendered by a {@link FlutterImageView}, then calling this method will stop
   * rendering to a {@link FlutterImageView}, and render on the previous surface instead.
   *
   * @param onDone a callback called when Flutter UI is rendered on the previous surface. Use this
   *     callback to perform cleanups. For example, destroy overlay surfaces.
   */
  public void revertImageView(@NonNull Runnable onDone) {
    if (flutterImageView == null) {
      Log.v(TAG, "Tried to revert the image view, but no image view is used.");
      return;
    }
    if (previousRenderSurface == null) {
      Log.v(TAG, "Tried to revert the image view, but no previous surface was used.");
      return;
    }
    renderSurface = previousRenderSurface;
    previousRenderSurface = null;
    if (flutterEngine == null) {
      flutterImageView.detachFromRenderer();
      onDone.run();
      return;
    }
    final FlutterRenderer renderer = flutterEngine.getRenderer();
    if (renderer == null) {
      flutterImageView.detachFromRenderer();
      onDone.run();
      return;
    }
    // Start rendering on the previous surface.
    // This surface is typically `FlutterSurfaceView` or `FlutterTextureView`.
    renderSurface.attachToRenderer(renderer);

    // Install a Flutter UI listener to wait until the first frame is rendered
    // in the new surface to call the `onDone` callback.
    renderer.addIsDisplayingFlutterUiListener(
        new FlutterUiDisplayListener() {
          @Override
          public void onFlutterUiDisplayed() {
            renderer.removeIsDisplayingFlutterUiListener(this);
            onDone.run();
            flutterImageView.detachFromRenderer();
          }

          @Override
          public void onFlutterUiNoLongerDisplayed() {
            // no-op
          }
        });
  }

  public void attachOverlaySurfaceToRender(FlutterImageView view) {
    if (flutterEngine != null) {
      view.attachToRenderer(flutterEngine.getRenderer());
    }
  }

  public boolean acquireLatestImageViewFrame() {
    if (flutterImageView != null) {
      return flutterImageView.acquireLatestImage();
    }
    return false;
  }

  /** Returns true if this {@code FlutterView} is currently attached to a {@link FlutterEngine}. */
  @VisibleForTesting
  public boolean isAttachedToFlutterEngine() {
    return flutterEngine != null
        && flutterEngine.getRenderer() == renderSurface.getAttachedRenderer();
  }

  /**
   * Returns the {@link FlutterEngine} to which this {@code FlutterView} is currently attached, or
   * null if this {@code FlutterView} is not currently attached to a {@link FlutterEngine}.
   */
  @VisibleForTesting
  @Nullable
  public FlutterEngine getAttachedFlutterEngine() {
    return flutterEngine;
  }

  /**
   * Adds a {@link FlutterEngineAttachmentListener}, which is notified whenever this {@code
   * FlutterView} attached to/detaches from a {@link FlutterEngine}.
   */
  @VisibleForTesting
  public void addFlutterEngineAttachmentListener(
      @NonNull FlutterEngineAttachmentListener listener) {
    flutterEngineAttachmentListeners.add(listener);
  }

  /**
   * Removes a {@link FlutterEngineAttachmentListener} that was previously added with {@link
   * #addFlutterEngineAttachmentListener(FlutterEngineAttachmentListener)}.
   */
  @VisibleForTesting
  public void removeFlutterEngineAttachmentListener(
      @NonNull FlutterEngineAttachmentListener listener) {
    flutterEngineAttachmentListeners.remove(listener);
  }

  /**
   * Send various user preferences of this Android device to Flutter.
   *
   * <p>For example, sends the user's "text scale factor" preferences, as well as the user's clock
   * format preference.
   *
   * <p>FlutterEngine must be non-null when this method is invoked.
   */
  @VisibleForTesting
  /* package */ void sendUserSettingsToFlutter() {
    // Lookup the current brightness of the Android OS.
    boolean isNightModeOn =
        (getResources().getConfiguration().uiMode & Configuration.UI_MODE_NIGHT_MASK)
            == Configuration.UI_MODE_NIGHT_YES;
    SettingsChannel.PlatformBrightness brightness =
        isNightModeOn
            ? SettingsChannel.PlatformBrightness.dark
            : SettingsChannel.PlatformBrightness.light;

    flutterEngine
        .getSettingsChannel()
        .startMessage()
        .setTextScaleFactor(getResources().getConfiguration().fontScale)
        .setUse24HourFormat(DateFormat.is24HourFormat(getContext()))
        .setPlatformBrightness(brightness)
        .send();
  }

  // TODO(mattcarroll): consider introducing a system channel for this communication instead of JNI
  private void sendViewportMetricsToFlutter() {
    if (!isAttachedToFlutterEngine()) {
      Log.w(
          TAG,
          "Tried to send viewport metrics from Android to Flutter but this "
              + "FlutterView was not attached to a FlutterEngine.");
      return;
    }

    viewportMetrics.devicePixelRatio = getResources().getDisplayMetrics().density;
    flutterEngine.getRenderer().setViewportMetrics(viewportMetrics);
  }

  @Override
  public void onProvideAutofillVirtualStructure(ViewStructure structure, int flags) {
    super.onProvideAutofillVirtualStructure(structure, flags);
    textInputPlugin.onProvideAutofillVirtualStructure(structure, flags);
  }

  @Override
  public void autofill(SparseArray<AutofillValue> values) {
    textInputPlugin.autofill(values);
  }

  /**
   * Render modes for a {@link FlutterView}.
   *
   * <p>Deprecated - please use {@link io.flutter.embedding.android.RenderMode} instead.
   */
  @Deprecated()
  public enum RenderMode {
    /**
     * {@code RenderMode}, which paints a Flutter UI to a {@link android.view.SurfaceView}. This
     * mode has the best performance, but a {@code FlutterView} in this mode cannot be positioned
     * between 2 other Android {@code View}s in the z-index, nor can it be animated/transformed.
     * Unless the special capabilities of a {@link android.graphics.SurfaceTexture} are required,
     * developers should strongly prefer this render mode.
     */
    surface,
    /**
     * {@code RenderMode}, which paints a Flutter UI to a {@link android.graphics.SurfaceTexture}.
     * This mode is not as performant as {@link RenderMode#surface}, but a {@code FlutterView} in
     * this mode can be animated and transformed, as well as positioned in the z-index between 2+
     * other Android {@code Views}. Unless the special capabilities of a {@link
     * android.graphics.SurfaceTexture} are required, developers should strongly prefer the {@link
     * RenderMode#surface} render mode.
     */
    texture,
    /**
     * {@code RenderMode}, which paints Paints a Flutter UI provided by an {@link
     * android.media.ImageReader} onto a {@link android.graphics.Canvas}. This mode is not as
     * performant as {@link RenderMode#surface}, but a {@code FlutterView} in this mode can handle
     * full interactivity with a {@link io.flutter.plugin.platform.PlatformView}. Unless {@link
     * io.flutter.plugin.platform.PlatformView}s are required developers should strongly prefer the
     * {@link RenderMode#surface} render mode.
     */
    image
  }

  /**
   * Transparency mode for a {@code FlutterView}.
   *
   * <p>Deprecated - please use {@link io.flutter.embedding.android.TransparencyMode} instead.
   *
   * <p>{@code TransparencyMode} impacts the visual behavior and performance of a {@link
   * FlutterSurfaceView}, which is displayed when a {@code FlutterView} uses {@link
   * RenderMode#surface}.
   *
   * <p>{@code TransparencyMode} does not impact {@link FlutterTextureView}, which is displayed when
   * a {@code FlutterView} uses {@link RenderMode#texture}, because a {@link FlutterTextureView}
   * automatically comes with transparency.
   */
  @Deprecated
  public enum TransparencyMode {
    /**
     * Renders a {@code FlutterView} without any transparency. This affects {@code FlutterView}s in
     * {@link io.flutter.embedding.android.RenderMode#surface} by introducing a base color of black,
     * and places the {@link FlutterSurfaceView}'s {@code Window} behind all other content.
     *
     * <p>In {@link io.flutter.embedding.android.RenderMode#surface}, this mode is the most
     * performant and is a good choice for fullscreen Flutter UIs that will not undergo {@code
     * Fragment} transactions. If this mode is used within a {@code Fragment}, and that {@code
     * Fragment} is replaced by another one, a brief black flicker may be visible during the switch.
     */
    opaque,
    /**
     * Renders a {@code FlutterView} with transparency. This affects {@code FlutterView}s in {@link
     * io.flutter.embedding.android.RenderMode#surface} by allowing background transparency, and
     * places the {@link FlutterSurfaceView}'s {@code Window} on top of all other content.
     *
     * <p>In {@link io.flutter.embedding.android.RenderMode#surface}, this mode is less performant
     * than {@link #opaque}, but this mode avoids the black flicker problem that {@link #opaque} has
     * when going through {@code Fragment} transactions. Consider using this {@code
     * TransparencyMode} if you intend to switch {@code Fragment}s at runtime that contain a Flutter
     * UI.
     */
    transparent
  }

  /**
   * Listener that is notified when a {@link FlutterEngine} is attached to/detached from a given
   * {@code FlutterView}.
   */
  @VisibleForTesting
  public interface FlutterEngineAttachmentListener {
    /** The given {@code engine} has been attached to the associated {@code FlutterView}. */
    void onFlutterEngineAttachedToFlutterView(@NonNull FlutterEngine engine);

    /**
     * A previously attached {@link FlutterEngine} has been detached from the associated {@code
     * FlutterView}.
     */
    void onFlutterEngineDetachedFromFlutterView();
  }
}
