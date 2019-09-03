// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.embedding.android;

import android.annotation.TargetApi;
import android.annotation.SuppressLint;
import android.content.Context;
import android.content.res.Configuration;
import android.graphics.Insets;
import android.graphics.Rect;
import android.os.Build;
import android.os.LocaleList;
import android.support.annotation.NonNull;
import android.support.annotation.Nullable;
import android.support.annotation.RequiresApi;
import android.support.annotation.VisibleForTesting;
import android.text.format.DateFormat;
import android.util.AttributeSet;
import android.view.KeyEvent;
import android.view.MotionEvent;
import android.view.View;
import android.view.WindowInsets;
import android.view.accessibility.AccessibilityManager;
import android.view.accessibility.AccessibilityNodeProvider;
import android.view.inputmethod.EditorInfo;
import android.view.inputmethod.InputConnection;
import android.widget.FrameLayout;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Locale;
import java.util.Set;

import io.flutter.Log;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.embedding.engine.renderer.FlutterRenderer;
import io.flutter.embedding.engine.renderer.FlutterUiDisplayListener;
import io.flutter.embedding.engine.renderer.RenderSurface;
import io.flutter.plugin.editing.TextInputPlugin;
import io.flutter.plugin.platform.PlatformViewsController;
import io.flutter.view.AccessibilityBridge;

/**
 * Displays a Flutter UI on an Android device.
 * <p>
 * A {@code FlutterView}'s UI is painted by a corresponding {@link FlutterEngine}.
 * <p>
 * A {@code FlutterView} can operate in 2 different {@link RenderMode}s:
 * <ol>
 *   <li>{@link RenderMode#surface}, which paints a Flutter UI to a {@link android.view.SurfaceView}.
 *   This mode has the best performance, but a {@code FlutterView} in this mode cannot be positioned
 *   between 2 other Android {@code View}s in the z-index, nor can it be animated/transformed.
 *   Unless the special capabilities of a {@link android.graphics.SurfaceTexture} are required,
 *   developers should strongly prefer this render mode.</li>
 *   <li>{@link RenderMode#texture}, which paints a Flutter UI to a {@link android.graphics.SurfaceTexture}.
 *   This mode is not as performant as {@link RenderMode#surface}, but a {@code FlutterView} in this
 *   mode can be animated and transformed, as well as positioned in the z-index between 2+ other
 *   Android {@code Views}. Unless the special capabilities of a {@link android.graphics.SurfaceTexture}
 *   are required, developers should strongly prefer the {@link RenderMode#surface} render mode.</li>
 * </ol>
 * See <a>https://source.android.com/devices/graphics/arch-tv#surface_or_texture</a> for more
 * information comparing {@link android.view.SurfaceView} and {@link android.view.TextureView}.
 */
public class FlutterView extends FrameLayout {
  private static final String TAG = "FlutterView";

  // Behavior configuration of this FlutterView.
  @NonNull
  private RenderMode renderMode;
  @Nullable
  private TransparencyMode transparencyMode;

  // Internal view hierarchy references.
  @Nullable
  private RenderSurface renderSurface;
  private final Set<FlutterUiDisplayListener> flutterUiDisplayListeners = new HashSet<>();
  private boolean isFlutterUiDisplayed;

  // Connections to a Flutter execution context.
  @Nullable
  private FlutterEngine flutterEngine;
  @NonNull
  private final Set<FlutterEngineAttachmentListener> flutterEngineAttachmentListeners = new HashSet<>();

  // Components that process various types of Android View input and events,
  // possibly storing intermediate state, and communicating those events to Flutter.
  //
  // These components essentially add some additional behavioral logic on top of
  // existing, stateless system channels, e.g., KeyEventChannel, TextInputChannel, etc.
  @Nullable
  private TextInputPlugin textInputPlugin;
  @Nullable
  private AndroidKeyProcessor androidKeyProcessor;
  @Nullable
  private AndroidTouchProcessor androidTouchProcessor;
  @Nullable
  private AccessibilityBridge accessibilityBridge;

  // Directly implemented View behavior that communicates with Flutter.
  private final FlutterRenderer.ViewportMetrics viewportMetrics = new FlutterRenderer.ViewportMetrics();

  private final AccessibilityBridge.OnAccessibilityChangeListener onAccessibilityChangeListener = new AccessibilityBridge.OnAccessibilityChangeListener() {
    @Override
    public void onAccessibilityChanged(boolean isAccessibilityEnabled, boolean isTouchExplorationEnabled) {
      resetWillNotDraw(isAccessibilityEnabled, isTouchExplorationEnabled);
    }
  };

  private final FlutterUiDisplayListener flutterUiDisplayListener = new FlutterUiDisplayListener() {
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
   * <p>
   * <ul>
   *   <li>{@link #renderMode} defaults to {@link RenderMode#surface}.</li>
   *   <li>{@link #transparencyMode} defaults to {@link TransparencyMode#opaque}.</li>
   * </ul>
   * {@code FlutterView} requires an {@code Activity} instead of a generic {@code Context}
   * to be compatible with {@link PlatformViewsController}.
   */
  public FlutterView(@NonNull Context context) {
    this(context, null, null, null);
  }

  /**
   * Constructs a {@code FlutterView} programmatically, without any XML attributes,
   * and allows selection of a {@link #renderMode}.
   * <p>
   * {@link #transparencyMode} defaults to {@link TransparencyMode#opaque}.
   * <p>
   * {@code FlutterView} requires an {@code Activity} instead of a generic {@code Context}
   * to be compatible with {@link PlatformViewsController}.
   */
  public FlutterView(@NonNull Context context, @NonNull RenderMode renderMode) {
    this(context, null, renderMode, null);
  }

  /**
   * Constructs a {@code FlutterView} programmatically, without any XML attributes,
   * assumes the use of {@link RenderMode#surface}, and allows selection of a {@link #transparencyMode}.
   * <p>
   * {@code FlutterView} requires an {@code Activity} instead of a generic {@code Context}
   * to be compatible with {@link PlatformViewsController}.
   */
  public FlutterView(@NonNull Context context, @NonNull TransparencyMode transparencyMode) {
    this(context, null, RenderMode.surface, transparencyMode);
  }

  /**
   * Constructs a {@code FlutterView} programmatically, without any XML attributes, and allows
   * a selection of {@link #renderMode} and {@link #transparencyMode}.
   * <p>
   * {@code FlutterView} requires an {@code Activity} instead of a generic {@code Context}
   * to be compatible with {@link PlatformViewsController}.
   */
  public FlutterView(@NonNull Context context, @NonNull RenderMode renderMode, @NonNull TransparencyMode transparencyMode) {
    this(context, null, renderMode, transparencyMode);
  }

  /**
   * Constructs a {@code FlutterSurfaceView} in an XML-inflation-compliant manner.
   * <p>
   * {@code FlutterView} requires an {@code Activity} instead of a generic {@code Context}
   * to be compatible with {@link PlatformViewsController}.
   */
   // TODO(mattcarroll): expose renderMode in XML when build system supports R.attr
  public FlutterView(@NonNull Context context, @Nullable AttributeSet attrs) {
    this(context, attrs, null, null);
  }

  private FlutterView(@NonNull Context context, @Nullable AttributeSet attrs, @Nullable RenderMode renderMode, @Nullable TransparencyMode transparencyMode) {
    super(context, attrs);

    this.renderMode = renderMode == null ? RenderMode.surface : renderMode;
    this.transparencyMode = transparencyMode != null ? transparencyMode : TransparencyMode.opaque;

    init();
  }

  private void init() {
    Log.v(TAG, "Initializing FlutterView");

    switch (renderMode) {
      case surface:
        Log.v(TAG, "Internally using a FlutterSurfaceView.");
        FlutterSurfaceView flutterSurfaceView = new FlutterSurfaceView(getContext(), transparencyMode == TransparencyMode.transparent);
        renderSurface = flutterSurfaceView;
        addView(flutterSurfaceView);
        break;
      case texture:
        Log.v(TAG, "Internally using a FlutterTextureView.");
        FlutterTextureView flutterTextureView = new FlutterTextureView(getContext());
        renderSurface = flutterTextureView;
        addView(flutterTextureView);
        break;
    }

    // FlutterView needs to be focusable so that the InputMethodManager can interact with it.
    setFocusable(true);
    setFocusableInTouchMode(true);
  }

  /**
   * Returns true if an attached {@link FlutterEngine} has rendered at least 1 frame to this
   * {@code FlutterView}.
   * <p>
   * Returns false if no {@link FlutterEngine} is attached.
   * <p>
   * This flag is specific to a given {@link FlutterEngine}. The following hypothetical timeline
   * demonstrates how this flag changes over time.
   * <ol>
   *   <li>{@code flutterEngineA} is attached to this {@code FlutterView}: returns false</li>
   *   <li>{@code flutterEngineA} renders its first frame to this {@code FlutterView}: returns true</li>
   *   <li>{@code flutterEngineA} is detached from this {@code FlutterView}: returns false</li>
   *   <li>{@code flutterEngineB} is attached to this {@code FlutterView}: returns false</li>
   *   <li>{@code flutterEngineB} renders its first frame to this {@code FlutterView}: returns true</li>
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
   * Removes the given {@code listener}, which was previously added with
   * {@link #addOnFirstFrameRenderedListener(FlutterUiDisplayListener)}.
   */
  public void removeOnFirstFrameRenderedListener(@NonNull FlutterUiDisplayListener listener) {
    flutterUiDisplayListeners.remove(listener);
  }

  //------- Start: Process View configuration that Flutter cares about. ------
  /**
   * Sends relevant configuration data from Android to Flutter when the Android
   * {@link Configuration} changes.
   *
   * The Android {@link Configuration} might change as a result of device orientation
   * change, device language change, device text scale factor change, etc.
   */
  @Override
  protected void onConfigurationChanged(@NonNull Configuration newConfig) {
    super.onConfigurationChanged(newConfig);
    Log.v(TAG, "Configuration changed. Sending locales and user settings to Flutter.");
    sendLocalesToFlutter(newConfig);
    sendUserSettingsToFlutter();
  }

  /**
   * Invoked when this {@code FlutterView} changes size, including upon initial
   * measure.
   *
   * The initial measure reports an {@code oldWidth} and {@code oldHeight} of zero.
   *
   * Flutter cares about the width and height of the view that displays it on the host
   * platform. Therefore, when this method is invoked, the new width and height are
   * communicated to Flutter as the "physical size" of the view that displays Flutter's
   * UI.
   */
  @Override
  protected void onSizeChanged(int width, int height, int oldWidth, int oldHeight) {
    super.onSizeChanged(width, height, oldWidth, oldHeight);
    Log.v(TAG, "Size changed. Sending Flutter new viewport metrics. FlutterView was "
        + oldWidth + " x " + oldHeight
        + ", it is now " + width + " x " + height);
    viewportMetrics.width = width;
    viewportMetrics.height = height;
    sendViewportMetricsToFlutter();
  }

  /**
   * Invoked when Android's desired window insets change, i.e., padding.
   *
   * Flutter does not use a standard {@code View} hierarchy and therefore Flutter is
   * unaware of these insets. Therefore, this method calculates the viewport metrics
   * that Flutter should use and then sends those metrics to Flutter.
   *
   * This callback is not present in API < 20, which means lower API devices will see
   * the wider than expected padding when the status and navigation bars are hidden.
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

    // Status bar (top) and left/right system insets should partially obscure the content (padding).
    viewportMetrics.paddingTop = insets.getSystemWindowInsetTop();
    viewportMetrics.paddingRight = insets.getSystemWindowInsetRight();
    viewportMetrics.paddingBottom = 0;
    viewportMetrics.paddingLeft = insets.getSystemWindowInsetLeft();

    // Bottom system inset (keyboard) should adjust scrollable bottom edge (inset).
    viewportMetrics.viewInsetTop = 0;
    viewportMetrics.viewInsetRight = 0;
    viewportMetrics.viewInsetBottom = insets.getSystemWindowInsetBottom();
    viewportMetrics.viewInsetLeft = 0;

    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
      Insets systemGestureInsets = insets.getSystemGestureInsets();
      viewportMetrics.systemGestureInsetTop = systemGestureInsets.top;
      viewportMetrics.systemGestureInsetRight = systemGestureInsets.right;
      viewportMetrics.systemGestureInsetBottom = systemGestureInsets.bottom;
      viewportMetrics.systemGestureInsetLeft = systemGestureInsets.left;
    }

    Log.v(TAG, "Updating window insets (onApplyWindowInsets()):\n"
      + "Status bar insets: Top: " + viewportMetrics.paddingTop
        + ", Left: " + viewportMetrics.paddingLeft + ", Right: " + viewportMetrics.paddingRight + "\n"
      + "Keyboard insets: Bottom: " + viewportMetrics.viewInsetBottom
        + ", Left: " + viewportMetrics.viewInsetLeft + ", Right: " + viewportMetrics.viewInsetRight
      + "System Gesture Insets - Left: " + viewportMetrics.systemGestureInsetLeft + ", Top: " + viewportMetrics.systemGestureInsetTop
        + ", Right: " + viewportMetrics.systemGestureInsetRight + ", Bottom: " + viewportMetrics.viewInsetBottom);

    sendViewportMetricsToFlutter();

    return newInsets;
  }

  /**
   * Invoked when Android's desired window insets change, i.e., padding.
   *
   * {@code fitSystemWindows} is an earlier version of
   * {@link #onApplyWindowInsets(WindowInsets)}. See that method for more details
   * about how window insets relate to Flutter.
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

      Log.v(TAG, "Updating window insets (fitSystemWindows()):\n"
          + "Status bar insets: Top: " + viewportMetrics.paddingTop
          + ", Left: " + viewportMetrics.paddingLeft + ", Right: " + viewportMetrics.paddingRight + "\n"
          + "Keyboard insets: Bottom: " + viewportMetrics.viewInsetBottom
          + ", Left: " + viewportMetrics.viewInsetLeft + ", Right: " + viewportMetrics.viewInsetRight);

      sendViewportMetricsToFlutter();
      return true;
    } else {
      return super.fitSystemWindows(insets);
    }
  }
  //------- End: Process View configuration that Flutter cares about. --------

  //-------- Start: Process UI I/O that Flutter cares about. -------
  /**
   * Creates an {@link InputConnection} to work with a {@link android.view.inputmethod.InputMethodManager}.
   *
   * Any {@code View} that can take focus or process text input must implement this
   * method by returning a non-null {@code InputConnection}. Flutter may render one or
   * many focusable and text-input widgets, therefore {@code FlutterView} must support
   * an {@code InputConnection}.
   *
   * The {@code InputConnection} returned from this method comes from a
   * {@link TextInputPlugin}, which is owned by this {@code FlutterView}. A
   * {@link TextInputPlugin} exists to encapsulate the nuances of input communication,
   * rather than spread that logic throughout this {@code FlutterView}.
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
   * <p>
   * Returns true to allow non-input-connection-targets to invoke methods on
   * {@code InputMethodManager}, or false to exclusively allow the input connection target to invoke
   * such methods.
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
   * This method is typically invoked in response to the release of a physical
   * keyboard key or a D-pad button. It is generally not invoked when a virtual
   * software keyboard is used, though a software keyboard may choose to invoke
   * this method in some situations.
   *
   * {@link KeyEvent}s are sent from Android to Flutter. {@link AndroidKeyProcessor}
   * may do some additional work with the given {@link KeyEvent}, e.g., combine this
   * {@code keyCode} with the previous {@code keyCode} to generate a unicode combined
   * character.
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
   * This method is typically invoked in response to the press of a physical
   * keyboard key or a D-pad button. It is generally not invoked when a virtual
   * software keyboard is used, though a software keyboard may choose to invoke
   * this method in some situations.
   *
   * {@link KeyEvent}s are sent from Android to Flutter. {@link AndroidKeyProcessor}
   * may do some additional work with the given {@link KeyEvent}, e.g., combine this
   * {@code keyCode} with the previous {@code keyCode} to generate a unicode combined
   * character.
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
   * Flutter handles all of its own gesture detection and processing, therefore this
   * method forwards all {@link MotionEvent} data from Android to Flutter.
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
   * Flutter handles all of its own gesture detection and processing, therefore this
   * method forwards all {@link MotionEvent} data from Android to Flutter.
   */
  @Override
  public boolean onGenericMotionEvent(@NonNull MotionEvent event) {
    boolean handled = isAttachedToFlutterEngine() && androidTouchProcessor.onGenericMotionEvent(event);
    return handled ? true : super.onGenericMotionEvent(event);
  }

  /**
   * Invoked by Android when a hover-compliant input system causes a hover event.
   *
   * An example of hover events is a stylus sitting near an Android screen. As the
   * stylus moves from outside a {@code View} to hover over a {@code View}, or move
   * around within a {@code View}, or moves from over a {@code View} to outside a
   * {@code View}, a corresponding {@link MotionEvent} is reported via this method.
   *
   * Hover events can be used for accessibility touch exploration and therefore are
   * processed here for accessibility purposes.
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
  //-------- End: Process UI I/O that Flutter cares about. ---------

  //-------- Start: Accessibility -------
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

  // TODO(mattcarroll): Confer with Ian as to why we need this method. Delete if possible, otherwise add comments.
  private void resetWillNotDraw(boolean isAccessibilityEnabled, boolean isTouchExplorationEnabled) {
    if (!flutterEngine.getRenderer().isSoftwareRenderingEnabled()) {
      setWillNotDraw(!(isAccessibilityEnabled || isTouchExplorationEnabled));
    } else {
      setWillNotDraw(false);
    }
  }
  //-------- End: Accessibility ---------

  /**
   * Connects this {@code FlutterView} to the given {@link FlutterEngine}.
   *
   * This {@code FlutterView} will begin rendering the UI painted by the given {@link FlutterEngine}.
   * This {@code FlutterView} will also begin forwarding interaction events from this
   * {@code FlutterView} to the given {@link FlutterEngine}, e.g., user touch events, accessibility
   * events, keyboard events, and others.
   *
   * See {@link #detachFromFlutterEngine()} for information on how to detach from a
   * {@link FlutterEngine}.
   */
  public void attachToFlutterEngine(
      @NonNull FlutterEngine flutterEngine
  ) {
    Log.d(TAG, "Attaching to a FlutterEngine: " + flutterEngine);
    if (isAttachedToFlutterEngine()) {
      if (flutterEngine == this.flutterEngine) {
        // We are already attached to this FlutterEngine
        Log.d(TAG, "Already attached to this engine. Doing nothing.");
        return;
      }

      // Detach from a previous FlutterEngine so we can attach to this new one.
      Log.d(TAG, "Currently attached to a different engine. Detaching and then attaching"
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
    textInputPlugin = new TextInputPlugin(
        this,
        this.flutterEngine.getDartExecutor(),
        this.flutterEngine.getPlatformViewsController()
    );
    androidKeyProcessor = new AndroidKeyProcessor(
        this.flutterEngine.getKeyEventChannel(),
        textInputPlugin
    );
    androidTouchProcessor = new AndroidTouchProcessor(this.flutterEngine.getRenderer());
    accessibilityBridge = new AccessibilityBridge(
        this,
        flutterEngine.getAccessibilityChannel(),
        (AccessibilityManager) getContext().getSystemService(Context.ACCESSIBILITY_SERVICE),
        getContext().getContentResolver(),
        this.flutterEngine.getPlatformViewsController()
    );
    accessibilityBridge.setOnAccessibilityChangeListener(onAccessibilityChangeListener);
    resetWillNotDraw(
        accessibilityBridge.isAccessibilityEnabled(),
        accessibilityBridge.isTouchExplorationEnabled()
    );

    // Connect AccessibilityBridge to the PlatformViewsController within the FlutterEngine.
    // This allows platform Views to hook into Flutter's overall accessibility system.
    this.flutterEngine.getPlatformViewsController().attachAccessibilityBridge(accessibilityBridge);

    // Inform the Android framework that it should retrieve a new InputConnection
    // now that an engine is attached.
    // TODO(mattcarroll): once this is proven to work, move this line ot TextInputPlugin
    textInputPlugin.getInputMethodManager().restartInput(this);

    // Push View and Context related information from Android to Flutter.
    sendUserSettingsToFlutter();
    sendLocalesToFlutter(getResources().getConfiguration());
    sendViewportMetricsToFlutter();

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
   * This {@code FlutterView} will clear its UI and stop forwarding all events to the previously-attached
   * {@link FlutterEngine}. This includes touch events, accessibility events, keyboard events,
   * and others.
   *
   * See {@link #attachToFlutterEngine(FlutterEngine)} for information on how to attach a
   * {@link FlutterEngine}.
   */
  public void detachFromFlutterEngine() {
    Log.d(TAG, "Detaching from a FlutterEngine: " + flutterEngine);
    if (!isAttachedToFlutterEngine()) {
      Log.d(TAG, "Not attached to an engine. Doing nothing.");
      return;
    }

    // Notify engine attachment listeners of the detachment.
    for (FlutterEngineAttachmentListener listener : flutterEngineAttachmentListeners) {
      listener.onFlutterEngineDetachedFromFlutterView();
    }

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

    // Instruct our FlutterRenderer that we are no longer interested in being its RenderSurface.
    FlutterRenderer flutterRenderer = flutterEngine.getRenderer();
    isFlutterUiDisplayed = false;
    flutterRenderer.removeIsDisplayingFlutterUiListener(flutterUiDisplayListener);
    flutterRenderer.stopRenderingToSurface();
    flutterEngine = null;
  }

  /**
   * Returns true if this {@code FlutterView} is currently attached to a {@link FlutterEngine}.
   */
  @VisibleForTesting
  public boolean isAttachedToFlutterEngine() {
    return flutterEngine != null
        && flutterEngine.getRenderer() == renderSurface.getAttachedRenderer();
  }

  /**
   * Returns the {@link FlutterEngine} to which this {@code FlutterView} is currently attached,
   * or null if this {@code FlutterView} is not currently attached to a {@link FlutterEngine}.
   */
  @VisibleForTesting
  @Nullable
  public FlutterEngine getAttachedFlutterEngine() {
    return flutterEngine;
  }

  /**
   * Adds a {@link FlutterEngineAttachmentListener}, which is notifed whenever this {@code FlutterView}
   * attached to/detaches from a {@link FlutterEngine}.
   */
  @VisibleForTesting
  public void addFlutterEngineAttachmentListener(@NonNull FlutterEngineAttachmentListener listener) {
    flutterEngineAttachmentListeners.add(listener);
  }

  /**
   * Removes a {@link FlutterEngineAttachmentListener} that was previously added with
   * {@link #addFlutterEngineAttachmentListener(FlutterEngineAttachmentListener)}.
   */
  @VisibleForTesting
  public void removeFlutterEngineAttachmentListener(@NonNull FlutterEngineAttachmentListener listener) {
    flutterEngineAttachmentListeners.remove(listener);
  }

  /**
   * Send the current {@link Locale} configuration to Flutter.
   *
   * FlutterEngine must be non-null when this method is invoked.
   */
  @SuppressWarnings("deprecation")
  private void sendLocalesToFlutter(@NonNull Configuration config) {
    List<Locale> locales = new ArrayList<>();
    if (Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.N) {
      LocaleList localeList = config.getLocales();
      int localeCount = localeList.size();
      for (int index = 0; index < localeCount; ++index) {
        Locale locale = localeList.get(index);
        locales.add(locale);
      }
    } else {
      locales.add(config.locale);
    }
    flutterEngine.getLocalizationChannel().sendLocales(locales);
  }

  /**
   * Send various user preferences of this Android device to Flutter.
   *
   * For example, sends the user's "text scale factor" preferences, as well as the user's clock
   * format preference.
   *
   * FlutterEngine must be non-null when this method is invoked.
   */
  private void sendUserSettingsToFlutter() {
    flutterEngine.getSettingsChannel().startMessage()
        .setTextScaleFactor(getResources().getConfiguration().fontScale)
        .setUse24HourFormat(DateFormat.is24HourFormat(getContext()))
        .send();
  }

  // TODO(mattcarroll): consider introducing a system channel for this communication instead of JNI
  private void sendViewportMetricsToFlutter() {
    if (!isAttachedToFlutterEngine()) {
      Log.w(TAG, "Tried to send viewport metrics from Android to Flutter but this "
          + "FlutterView was not attached to a FlutterEngine.");
      return;
    }

    viewportMetrics.devicePixelRatio = getResources().getDisplayMetrics().density;
    flutterEngine.getRenderer().setViewportMetrics(viewportMetrics);
  }

  /**
   * Render modes for a {@link FlutterView}.
   */
  public enum RenderMode {
    /**
     * {@code RenderMode}, which paints a Flutter UI to a {@link android.view.SurfaceView}.
     * This mode has the best performance, but a {@code FlutterView} in this mode cannot be positioned
     * between 2 other Android {@code View}s in the z-index, nor can it be animated/transformed.
     * Unless the special capabilities of a {@link android.graphics.SurfaceTexture} are required,
     * developers should strongly prefer this render mode.
     */
    surface,
    /**
     * {@code RenderMode}, which paints a Flutter UI to a {@link android.graphics.SurfaceTexture}.
     * This mode is not as performant as {@link RenderMode#surface}, but a {@code FlutterView} in this
     * mode can be animated and transformed, as well as positioned in the z-index between 2+ other
     * Android {@code Views}. Unless the special capabilities of a {@link android.graphics.SurfaceTexture}
     * are required, developers should strongly prefer the {@link RenderMode#surface} render mode.
     */
    texture
  }

  /**
   * Transparency mode for a {@code FlutterView}.
   * <p>
   * {@code TransparencyMode} impacts the visual behavior and performance of a {@link FlutterSurfaceView},
   * which is displayed when a {@code FlutterView} uses {@link RenderMode#surface}.
   * <p>
   * {@code TransparencyMode} does not impact {@link FlutterTextureView}, which is displayed when
   * a {@code FlutterView} uses {@link RenderMode#texture}, because a {@link FlutterTextureView}
   * automatically comes with transparency.
   */
  public enum TransparencyMode {
    /**
     * Renders a {@code FlutterView} without any transparency. This affects {@code FlutterView}s in
     * {@link RenderMode#surface} by introducing a base color of black, and places the
     * {@link FlutterSurfaceView}'s {@code Window} behind all other content.
     * <p>
     * In {@link RenderMode#surface}, this mode is the most performant and is a good choice for
     * fullscreen Flutter UIs that will not undergo {@code Fragment} transactions. If this mode is
     * used within a {@code Fragment}, and that {@code Fragment} is replaced by another one, a
     * brief black flicker may be visible during the switch.
     */
    opaque,
    /**
     * Renders a {@code FlutterView} with transparency. This affects {@code FlutterView}s in
     * {@link RenderMode#surface} by allowing background transparency, and places the
     * {@link FlutterSurfaceView}'s {@code Window} on top of all other content.
     * <p>
     * In {@link RenderMode#surface}, this mode is less performant than {@link #opaque}, but this
     * mode avoids the black flicker problem that {@link #opaque} has when going through
     * {@code Fragment} transactions. Consider using this {@code TransparencyMode} if you intend to
     * switch {@code Fragment}s at runtime that contain a Flutter UI.
     */
    transparent
  }

  /**
   * Listener that is notified when a {@link FlutterEngine} is attached to/detached from
   * a given {@code FlutterView}.
   */
  @VisibleForTesting
  public interface FlutterEngineAttachmentListener {
    /**
     * The given {@code engine} has been attached to the associated {@code FlutterView}.
     */
    void onFlutterEngineAttachedToFlutterView(@NonNull FlutterEngine engine);

    /**
     * A previously attached {@link FlutterEngine} has been detached from the associated
     * {@code FlutterView}.
     */
    void onFlutterEngineDetachedFromFlutterView();
  }
}
