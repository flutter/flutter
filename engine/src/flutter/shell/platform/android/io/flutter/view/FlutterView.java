// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.view;

import android.annotation.SuppressLint;
import android.annotation.TargetApi;
import android.app.Activity;
import android.content.Context;
import android.content.res.Configuration;
import android.graphics.Bitmap;
import android.graphics.Insets;
import android.graphics.PixelFormat;
import android.graphics.Rect;
import android.graphics.SurfaceTexture;
import android.os.Build;
import android.os.Handler;
import android.text.format.DateFormat;
import android.util.AttributeSet;
import android.util.SparseArray;
import android.view.DisplayCutout;
import android.view.KeyEvent;
import android.view.MotionEvent;
import android.view.PointerIcon;
import android.view.Surface;
import android.view.SurfaceHolder;
import android.view.SurfaceView;
import android.view.View;
import android.view.ViewConfiguration;
import android.view.ViewStructure;
import android.view.WindowInsets;
import android.view.WindowManager;
import android.view.accessibility.AccessibilityManager;
import android.view.accessibility.AccessibilityNodeProvider;
import android.view.autofill.AutofillValue;
import android.view.inputmethod.EditorInfo;
import android.view.inputmethod.InputConnection;
import android.view.inputmethod.InputMethodManager;
import androidx.annotation.NonNull;
import androidx.annotation.RequiresApi;
import androidx.annotation.UiThread;
import io.flutter.Log;
import io.flutter.app.FlutterPluginRegistry;
import io.flutter.embedding.android.AndroidTouchProcessor;
import io.flutter.embedding.android.KeyboardManager;
import io.flutter.embedding.engine.dart.DartExecutor;
import io.flutter.embedding.engine.renderer.FlutterRenderer;
import io.flutter.embedding.engine.renderer.SurfaceTextureWrapper;
import io.flutter.embedding.engine.systemchannels.AccessibilityChannel;
import io.flutter.embedding.engine.systemchannels.LifecycleChannel;
import io.flutter.embedding.engine.systemchannels.LocalizationChannel;
import io.flutter.embedding.engine.systemchannels.MouseCursorChannel;
import io.flutter.embedding.engine.systemchannels.NavigationChannel;
import io.flutter.embedding.engine.systemchannels.PlatformChannel;
import io.flutter.embedding.engine.systemchannels.SettingsChannel;
import io.flutter.embedding.engine.systemchannels.SystemChannel;
import io.flutter.embedding.engine.systemchannels.TextInputChannel;
import io.flutter.plugin.common.ActivityLifecycleListener;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.editing.TextInputPlugin;
import io.flutter.plugin.localization.LocalizationPlugin;
import io.flutter.plugin.mouse.MouseCursorPlugin;
import io.flutter.plugin.platform.PlatformPlugin;
import io.flutter.plugin.platform.PlatformViewsController;
import io.flutter.util.ViewUtils;
import java.nio.ByteBuffer;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.atomic.AtomicLong;

/**
 * Deprecated Android view containing a Flutter app.
 *
 * @deprecated {@link io.flutter.embedding.android.FlutterView} is the new API that now replaces
 *     this class. See https://flutter.dev/go/android-project-migration for more migration details.
 */
@Deprecated
public class FlutterView extends SurfaceView
    implements BinaryMessenger,
        TextureRegistry,
        MouseCursorPlugin.MouseCursorViewDelegate,
        KeyboardManager.ViewDelegate {
  /**
   * Interface for those objects that maintain and expose a reference to a {@code FlutterView} (such
   * as a full-screen Flutter activity).
   *
   * <p>This indirection is provided to support applications that use an activity other than {@link
   * io.flutter.app.FlutterActivity} (e.g. Android v4 support library's {@code FragmentActivity}).
   * It allows Flutter plugins to deal in this interface and not require that the activity be a
   * subclass of {@code FlutterActivity}.
   */
  public interface Provider {
    /**
     * Returns a reference to the Flutter view maintained by this object. This may be {@code null}.
     *
     * @return a reference to the Flutter view maintained by this object.
     */
    FlutterView getFlutterView();
  }

  private static final String TAG = "FlutterView";

  static final class ViewportMetrics {
    float devicePixelRatio = 1.0f;
    int physicalWidth = 0;
    int physicalHeight = 0;
    int physicalViewPaddingTop = 0;
    int physicalViewPaddingRight = 0;
    int physicalViewPaddingBottom = 0;
    int physicalViewPaddingLeft = 0;
    int physicalViewInsetTop = 0;
    int physicalViewInsetRight = 0;
    int physicalViewInsetBottom = 0;
    int physicalViewInsetLeft = 0;
    int systemGestureInsetTop = 0;
    int systemGestureInsetRight = 0;
    int systemGestureInsetBottom = 0;
    int systemGestureInsetLeft = 0;
    int physicalTouchSlop = -1;
  }

  private final DartExecutor dartExecutor;
  private final FlutterRenderer flutterRenderer;
  private final NavigationChannel navigationChannel;
  private final LifecycleChannel lifecycleChannel;
  private final LocalizationChannel localizationChannel;
  private final PlatformChannel platformChannel;
  private final SettingsChannel settingsChannel;
  private final SystemChannel systemChannel;
  private final InputMethodManager mImm;
  private final TextInputPlugin mTextInputPlugin;
  private final LocalizationPlugin mLocalizationPlugin;
  private final MouseCursorPlugin mMouseCursorPlugin;
  private final KeyboardManager mKeyboardManager;
  private final AndroidTouchProcessor androidTouchProcessor;
  private AccessibilityBridge mAccessibilityNodeProvider;
  private final SurfaceHolder.Callback mSurfaceCallback;
  private final ViewportMetrics mMetrics;
  private final List<ActivityLifecycleListener> mActivityLifecycleListeners;
  private final List<FirstFrameListener> mFirstFrameListeners;
  private final AtomicLong nextTextureId = new AtomicLong(0L);
  private FlutterNativeView mNativeView;
  private boolean mIsSoftwareRenderingEnabled = false; // using the software renderer or not
  private boolean didRenderFirstFrame = false;

  private final AccessibilityBridge.OnAccessibilityChangeListener onAccessibilityChangeListener =
      new AccessibilityBridge.OnAccessibilityChangeListener() {
        @Override
        public void onAccessibilityChanged(
            boolean isAccessibilityEnabled, boolean isTouchExplorationEnabled) {
          resetWillNotDraw(isAccessibilityEnabled, isTouchExplorationEnabled);
        }
      };

  public FlutterView(Context context) {
    this(context, null);
  }

  public FlutterView(Context context, AttributeSet attrs) {
    this(context, attrs, null);
  }

  public FlutterView(Context context, AttributeSet attrs, FlutterNativeView nativeView) {
    super(context, attrs);

    Activity activity = ViewUtils.getActivity(getContext());
    if (activity == null) {
      throw new IllegalArgumentException("Bad context");
    }

    if (nativeView == null) {
      mNativeView = new FlutterNativeView(activity.getApplicationContext());
    } else {
      mNativeView = nativeView;
    }

    dartExecutor = mNativeView.getDartExecutor();
    flutterRenderer = new FlutterRenderer(mNativeView.getFlutterJNI());
    mIsSoftwareRenderingEnabled = mNativeView.getFlutterJNI().getIsSoftwareRenderingEnabled();
    mMetrics = new ViewportMetrics();
    mMetrics.devicePixelRatio = context.getResources().getDisplayMetrics().density;
    mMetrics.physicalTouchSlop = ViewConfiguration.get(context).getScaledTouchSlop();
    setFocusable(true);
    setFocusableInTouchMode(true);

    mNativeView.attachViewAndActivity(this, activity);

    mSurfaceCallback =
        new SurfaceHolder.Callback() {
          @Override
          public void surfaceCreated(SurfaceHolder holder) {
            assertAttached();
            mNativeView.getFlutterJNI().onSurfaceCreated(holder.getSurface());
          }

          @Override
          public void surfaceChanged(SurfaceHolder holder, int format, int width, int height) {
            assertAttached();
            mNativeView.getFlutterJNI().onSurfaceChanged(width, height);
          }

          @Override
          public void surfaceDestroyed(SurfaceHolder holder) {
            assertAttached();
            mNativeView.getFlutterJNI().onSurfaceDestroyed();
          }
        };
    getHolder().addCallback(mSurfaceCallback);

    mActivityLifecycleListeners = new ArrayList<>();
    mFirstFrameListeners = new ArrayList<>();

    // Create all platform channels
    navigationChannel = new NavigationChannel(dartExecutor);
    lifecycleChannel = new LifecycleChannel(dartExecutor);
    localizationChannel = new LocalizationChannel(dartExecutor);
    platformChannel = new PlatformChannel(dartExecutor);
    systemChannel = new SystemChannel(dartExecutor);
    settingsChannel = new SettingsChannel(dartExecutor);

    // Create and set up plugins
    PlatformPlugin platformPlugin = new PlatformPlugin(activity, platformChannel);
    addActivityLifecycleListener(
        new ActivityLifecycleListener() {
          @Override
          public void onPostResume() {
            platformPlugin.updateSystemUiOverlays();
          }
        });
    mImm = (InputMethodManager) getContext().getSystemService(Context.INPUT_METHOD_SERVICE);
    PlatformViewsController platformViewsController =
        mNativeView.getPluginRegistry().getPlatformViewsController();
    mTextInputPlugin =
        new TextInputPlugin(this, new TextInputChannel(dartExecutor), platformViewsController);
    mKeyboardManager = new KeyboardManager(this);

    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
      mMouseCursorPlugin = new MouseCursorPlugin(this, new MouseCursorChannel(dartExecutor));
    } else {
      mMouseCursorPlugin = null;
    }
    mLocalizationPlugin = new LocalizationPlugin(context, localizationChannel);
    androidTouchProcessor =
        new AndroidTouchProcessor(flutterRenderer, /*trackMotionEvents=*/ false);
    platformViewsController.attachToFlutterRenderer(flutterRenderer);
    mNativeView
        .getPluginRegistry()
        .getPlatformViewsController()
        .attachTextInputPlugin(mTextInputPlugin);
    mNativeView.getFlutterJNI().setLocalizationPlugin(mLocalizationPlugin);

    // Send initial platform information to Dart
    mLocalizationPlugin.sendLocalesToFlutter(getResources().getConfiguration());
    sendUserPlatformSettingsToDart();
  }

  @NonNull
  public DartExecutor getDartExecutor() {
    return dartExecutor;
  }

  @Override
  public boolean dispatchKeyEvent(KeyEvent event) {
    Log.e(TAG, "dispatchKeyEvent: " + event.toString());
    if (event.getAction() == KeyEvent.ACTION_DOWN && event.getRepeatCount() == 0) {
      // Tell Android to start tracking this event.
      getKeyDispatcherState().startTracking(event, this);
    } else if (event.getAction() == KeyEvent.ACTION_UP) {
      // Stop tracking the event.
      getKeyDispatcherState().handleUpEvent(event);
    }
    // If the key processor doesn't handle it, then send it on to the
    // superclass. The key processor will typically handle all events except
    // those where it has re-dispatched the event after receiving a reply from
    // the framework that the framework did not handle it.
    return (isAttached() && mKeyboardManager.handleEvent(event)) || super.dispatchKeyEvent(event);
  }

  public FlutterNativeView getFlutterNativeView() {
    return mNativeView;
  }

  public FlutterPluginRegistry getPluginRegistry() {
    return mNativeView.getPluginRegistry();
  }

  public String getLookupKeyForAsset(String asset) {
    return FlutterMain.getLookupKeyForAsset(asset);
  }

  public String getLookupKeyForAsset(String asset, String packageName) {
    return FlutterMain.getLookupKeyForAsset(asset, packageName);
  }

  public void addActivityLifecycleListener(ActivityLifecycleListener listener) {
    mActivityLifecycleListeners.add(listener);
  }

  public void onStart() {
    lifecycleChannel.appIsInactive();
  }

  public void onPause() {
    lifecycleChannel.appIsInactive();
  }

  public void onPostResume() {
    for (ActivityLifecycleListener listener : mActivityLifecycleListeners) {
      listener.onPostResume();
    }
    lifecycleChannel.appIsResumed();
  }

  public void onStop() {
    lifecycleChannel.appIsPaused();
  }

  public void onMemoryPressure() {
    mNativeView.getFlutterJNI().notifyLowMemoryWarning();
    systemChannel.sendMemoryPressureWarning();
  }

  /**
   * Returns true if the Flutter experience associated with this {@code FlutterView} has rendered
   * its first frame, or false otherwise.
   */
  public boolean hasRenderedFirstFrame() {
    return didRenderFirstFrame;
  }

  /**
   * Provide a listener that will be called once when the FlutterView renders its first frame to the
   * underlaying SurfaceView.
   */
  public void addFirstFrameListener(FirstFrameListener listener) {
    mFirstFrameListeners.add(listener);
  }

  /** Remove an existing first frame listener. */
  public void removeFirstFrameListener(FirstFrameListener listener) {
    mFirstFrameListeners.remove(listener);
  }

  @Override
  public void enableBufferingIncomingMessages() {}

  @Override
  public void disableBufferingIncomingMessages() {}

  /**
   * Reverts this back to the {@link SurfaceView} defaults, at the back of its window and opaque.
   */
  public void disableTransparentBackground() {
    setZOrderOnTop(false);
    getHolder().setFormat(PixelFormat.OPAQUE);
  }

  public void setInitialRoute(String route) {
    navigationChannel.setInitialRoute(route);
  }

  public void pushRoute(String route) {
    navigationChannel.pushRoute(route);
  }

  public void popRoute() {
    navigationChannel.popRoute();
  }

  private void sendUserPlatformSettingsToDart() {
    // Lookup the current brightness of the Android OS.
    boolean isNightModeOn =
        (getResources().getConfiguration().uiMode & Configuration.UI_MODE_NIGHT_MASK)
            == Configuration.UI_MODE_NIGHT_YES;
    SettingsChannel.PlatformBrightness brightness =
        isNightModeOn
            ? SettingsChannel.PlatformBrightness.dark
            : SettingsChannel.PlatformBrightness.light;

    settingsChannel
        .startMessage()
        .setTextScaleFactor(getResources().getConfiguration().fontScale)
        .setUse24HourFormat(DateFormat.is24HourFormat(getContext()))
        .setPlatformBrightness(brightness)
        .send();
  }

  @Override
  protected void onConfigurationChanged(Configuration newConfig) {
    super.onConfigurationChanged(newConfig);
    mLocalizationPlugin.sendLocalesToFlutter(newConfig);
    sendUserPlatformSettingsToDart();
  }

  float getDevicePixelRatio() {
    return mMetrics.devicePixelRatio;
  }

  public FlutterNativeView detach() {
    if (!isAttached()) return null;
    getHolder().removeCallback(mSurfaceCallback);
    mNativeView.detachFromFlutterView();

    FlutterNativeView view = mNativeView;
    mNativeView = null;
    return view;
  }

  public void destroy() {
    if (!isAttached()) return;

    getHolder().removeCallback(mSurfaceCallback);
    releaseAccessibilityNodeProvider();

    mNativeView.destroy();
    mNativeView = null;
  }

  @Override
  public InputConnection onCreateInputConnection(EditorInfo outAttrs) {
    return mTextInputPlugin.createInputConnection(this, mKeyboardManager, outAttrs);
  }

  @Override
  public boolean checkInputConnectionProxy(View view) {
    return mNativeView
        .getPluginRegistry()
        .getPlatformViewsController()
        .checkInputConnectionProxy(view);
  }

  @Override
  public void onProvideAutofillVirtualStructure(ViewStructure structure, int flags) {
    super.onProvideAutofillVirtualStructure(structure, flags);
    mTextInputPlugin.onProvideAutofillVirtualStructure(structure, flags);
  }

  @Override
  public void autofill(SparseArray<AutofillValue> values) {
    mTextInputPlugin.autofill(values);
  }

  @Override
  public boolean onTouchEvent(MotionEvent event) {
    if (!isAttached()) {
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

  @Override
  public boolean onHoverEvent(MotionEvent event) {
    if (!isAttached()) {
      return super.onHoverEvent(event);
    }

    boolean handled = mAccessibilityNodeProvider.onAccessibilityHoverEvent(event);
    if (!handled) {
      // TODO(ianh): Expose hover events to the platform,
      // implementing ADD, REMOVE, etc.
    }
    return handled;
  }

  /**
   * Invoked by Android when a generic motion event occurs, e.g., joystick movement, mouse hover,
   * track pad touches, scroll wheel movements, etc.
   *
   * <p>Flutter handles all of its own gesture detection and processing, therefore this method
   * forwards all {@link MotionEvent} data from Android to Flutter.
   */
  @Override
  public boolean onGenericMotionEvent(MotionEvent event) {
    boolean handled = isAttached() && androidTouchProcessor.onGenericMotionEvent(event);
    return handled ? true : super.onGenericMotionEvent(event);
  }

  @Override
  protected void onSizeChanged(int width, int height, int oldWidth, int oldHeight) {
    mMetrics.physicalWidth = width;
    mMetrics.physicalHeight = height;
    updateViewportMetrics();
    super.onSizeChanged(width, height, oldWidth, oldHeight);
  }

  // TODO(garyq): Add support for notch cutout API
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

  // This callback is not present in API < 20, which means lower API devices will see
  // the wider than expected padding when the status and navigation bars are hidden.
  // The annotations to suppress "InlinedApi" and "NewApi" lints prevent lint warnings
  // caused by usage of Android Q APIs. These calls are safe because they are
  // guarded.
  @Override
  @TargetApi(20)
  @RequiresApi(20)
  @SuppressLint({"InlinedApi", "NewApi"})
  public final WindowInsets onApplyWindowInsets(WindowInsets insets) {
    // getSystemGestureInsets() was introduced in API 29 and immediately deprecated in 30.
    if (Build.VERSION.SDK_INT == Build.VERSION_CODES.Q) {
      Insets systemGestureInsets = insets.getSystemGestureInsets();
      mMetrics.systemGestureInsetTop = systemGestureInsets.top;
      mMetrics.systemGestureInsetRight = systemGestureInsets.right;
      mMetrics.systemGestureInsetBottom = systemGestureInsets.bottom;
      mMetrics.systemGestureInsetLeft = systemGestureInsets.left;
    }

    boolean statusBarVisible = (SYSTEM_UI_FLAG_FULLSCREEN & getWindowSystemUiVisibility()) == 0;
    boolean navigationBarVisible =
        (SYSTEM_UI_FLAG_HIDE_NAVIGATION & getWindowSystemUiVisibility()) == 0;

    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
      int mask = 0;
      if (navigationBarVisible) {
        mask = mask | android.view.WindowInsets.Type.navigationBars();
      }
      if (statusBarVisible) {
        mask = mask | android.view.WindowInsets.Type.statusBars();
      }
      Insets uiInsets = insets.getInsets(mask);
      mMetrics.physicalViewPaddingTop = uiInsets.top;
      mMetrics.physicalViewPaddingRight = uiInsets.right;
      mMetrics.physicalViewPaddingBottom = uiInsets.bottom;
      mMetrics.physicalViewPaddingLeft = uiInsets.left;

      Insets imeInsets = insets.getInsets(android.view.WindowInsets.Type.ime());
      mMetrics.physicalViewInsetTop = imeInsets.top;
      mMetrics.physicalViewInsetRight = imeInsets.right;
      mMetrics.physicalViewInsetBottom = imeInsets.bottom; // Typically, only bottom is non-zero
      mMetrics.physicalViewInsetLeft = imeInsets.left;

      Insets systemGestureInsets =
          insets.getInsets(android.view.WindowInsets.Type.systemGestures());
      mMetrics.systemGestureInsetTop = systemGestureInsets.top;
      mMetrics.systemGestureInsetRight = systemGestureInsets.right;
      mMetrics.systemGestureInsetBottom = systemGestureInsets.bottom;
      mMetrics.systemGestureInsetLeft = systemGestureInsets.left;

      // TODO(garyq): Expose the full rects of the display cutout.

      // Take the max of the display cutout insets and existing padding to merge them
      DisplayCutout cutout = insets.getDisplayCutout();
      if (cutout != null) {
        Insets waterfallInsets = cutout.getWaterfallInsets();
        mMetrics.physicalViewPaddingTop =
            Math.max(
                Math.max(mMetrics.physicalViewPaddingTop, waterfallInsets.top),
                cutout.getSafeInsetTop());
        mMetrics.physicalViewPaddingRight =
            Math.max(
                Math.max(mMetrics.physicalViewPaddingRight, waterfallInsets.right),
                cutout.getSafeInsetRight());
        mMetrics.physicalViewPaddingBottom =
            Math.max(
                Math.max(mMetrics.physicalViewPaddingBottom, waterfallInsets.bottom),
                cutout.getSafeInsetBottom());
        mMetrics.physicalViewPaddingLeft =
            Math.max(
                Math.max(mMetrics.physicalViewPaddingLeft, waterfallInsets.left),
                cutout.getSafeInsetLeft());
      }
    } else {
      // We zero the left and/or right sides to prevent the padding the
      // navigation bar would have caused.
      ZeroSides zeroSides = ZeroSides.NONE;
      if (!navigationBarVisible) {
        zeroSides = calculateShouldZeroSides();
      }

      // Status bar (top), navigation bar (bottom) and left/right system insets should
      // partially obscure the content (padding).
      mMetrics.physicalViewPaddingTop = statusBarVisible ? insets.getSystemWindowInsetTop() : 0;
      mMetrics.physicalViewPaddingRight =
          zeroSides == ZeroSides.RIGHT || zeroSides == ZeroSides.BOTH
              ? 0
              : insets.getSystemWindowInsetRight();
      mMetrics.physicalViewPaddingBottom =
          navigationBarVisible && guessBottomKeyboardInset(insets) == 0
              ? insets.getSystemWindowInsetBottom()
              : 0;
      mMetrics.physicalViewPaddingLeft =
          zeroSides == ZeroSides.LEFT || zeroSides == ZeroSides.BOTH
              ? 0
              : insets.getSystemWindowInsetLeft();

      // Bottom system inset (keyboard) should adjust scrollable bottom edge (inset).
      mMetrics.physicalViewInsetTop = 0;
      mMetrics.physicalViewInsetRight = 0;
      mMetrics.physicalViewInsetBottom = guessBottomKeyboardInset(insets);
      mMetrics.physicalViewInsetLeft = 0;
    }

    updateViewportMetrics();
    return super.onApplyWindowInsets(insets);
  }

  @Override
  @SuppressWarnings("deprecation")
  protected boolean fitSystemWindows(Rect insets) {
    if (Build.VERSION.SDK_INT <= Build.VERSION_CODES.KITKAT) {
      // Status bar, left/right system insets partially obscure content (padding).
      mMetrics.physicalViewPaddingTop = insets.top;
      mMetrics.physicalViewPaddingRight = insets.right;
      mMetrics.physicalViewPaddingBottom = 0;
      mMetrics.physicalViewPaddingLeft = insets.left;

      // Bottom system inset (keyboard) should adjust scrollable bottom edge (inset).
      mMetrics.physicalViewInsetTop = 0;
      mMetrics.physicalViewInsetRight = 0;
      mMetrics.physicalViewInsetBottom = insets.bottom;
      mMetrics.physicalViewInsetLeft = 0;
      updateViewportMetrics();
      return true;
    } else {
      return super.fitSystemWindows(insets);
    }
  }

  private boolean isAttached() {
    return mNativeView != null && mNativeView.isAttached();
  }

  void assertAttached() {
    if (!isAttached()) throw new AssertionError("Platform view is not attached");
  }

  private void preRun() {
    resetAccessibilityTree();
  }

  void resetAccessibilityTree() {
    if (mAccessibilityNodeProvider != null) {
      mAccessibilityNodeProvider.reset();
    }
  }

  private void postRun() {}

  public void runFromBundle(FlutterRunArguments args) {
    assertAttached();
    preRun();
    mNativeView.runFromBundle(args);
    postRun();
  }

  /**
   * Return the most recent frame as a bitmap.
   *
   * @return A bitmap.
   */
  public Bitmap getBitmap() {
    assertAttached();
    return mNativeView.getFlutterJNI().getBitmap();
  }

  private void updateViewportMetrics() {
    if (!isAttached()) return;
    mNativeView
        .getFlutterJNI()
        .setViewportMetrics(
            mMetrics.devicePixelRatio,
            mMetrics.physicalWidth,
            mMetrics.physicalHeight,
            mMetrics.physicalViewPaddingTop,
            mMetrics.physicalViewPaddingRight,
            mMetrics.physicalViewPaddingBottom,
            mMetrics.physicalViewPaddingLeft,
            mMetrics.physicalViewInsetTop,
            mMetrics.physicalViewInsetRight,
            mMetrics.physicalViewInsetBottom,
            mMetrics.physicalViewInsetLeft,
            mMetrics.systemGestureInsetTop,
            mMetrics.systemGestureInsetRight,
            mMetrics.systemGestureInsetBottom,
            mMetrics.systemGestureInsetLeft,
            mMetrics.physicalTouchSlop,
            new int[0],
            new int[0],
            new int[0]);
  }

  // Called by FlutterNativeView to notify first Flutter frame rendered.
  public void onFirstFrame() {
    didRenderFirstFrame = true;

    // Allow listeners to remove themselves when they are called.
    List<FirstFrameListener> listeners = new ArrayList<>(mFirstFrameListeners);
    for (FirstFrameListener listener : listeners) {
      listener.onFirstFrame();
    }
  }

  @Override
  protected void onAttachedToWindow() {
    super.onAttachedToWindow();

    PlatformViewsController platformViewsController =
        getPluginRegistry().getPlatformViewsController();
    mAccessibilityNodeProvider =
        new AccessibilityBridge(
            this,
            new AccessibilityChannel(dartExecutor, getFlutterNativeView().getFlutterJNI()),
            (AccessibilityManager) getContext().getSystemService(Context.ACCESSIBILITY_SERVICE),
            getContext().getContentResolver(),
            platformViewsController);
    mAccessibilityNodeProvider.setOnAccessibilityChangeListener(onAccessibilityChangeListener);

    resetWillNotDraw(
        mAccessibilityNodeProvider.isAccessibilityEnabled(),
        mAccessibilityNodeProvider.isTouchExplorationEnabled());
  }

  @Override
  protected void onDetachedFromWindow() {
    super.onDetachedFromWindow();
    releaseAccessibilityNodeProvider();
  }

  // TODO(mattcarroll): Confer with Ian as to why we need this method. Delete if possible, otherwise
  // add comments.
  private void resetWillNotDraw(boolean isAccessibilityEnabled, boolean isTouchExplorationEnabled) {
    if (!mIsSoftwareRenderingEnabled) {
      setWillNotDraw(!(isAccessibilityEnabled || isTouchExplorationEnabled));
    } else {
      setWillNotDraw(false);
    }
  }

  @Override
  public AccessibilityNodeProvider getAccessibilityNodeProvider() {
    if (mAccessibilityNodeProvider != null && mAccessibilityNodeProvider.isAccessibilityEnabled()) {
      return mAccessibilityNodeProvider;
    } else {
      // TODO(goderbauer): when a11y is off this should return a one-off snapshot of
      // the a11y
      // tree.
      return null;
    }
  }

  private void releaseAccessibilityNodeProvider() {
    if (mAccessibilityNodeProvider != null) {
      mAccessibilityNodeProvider.release();
      mAccessibilityNodeProvider = null;
    }
  }

  // -------- Start: Mouse -------

  @Override
  @TargetApi(Build.VERSION_CODES.N)
  @RequiresApi(Build.VERSION_CODES.N)
  @NonNull
  public PointerIcon getSystemPointerIcon(int type) {
    return PointerIcon.getSystemIcon(getContext(), type);
  }

  // -------- End: Mouse -------

  // -------- Start: Keyboard -------

  @Override
  public BinaryMessenger getBinaryMessenger() {
    return this;
  }

  @Override
  public boolean onTextInputKeyEvent(@NonNull KeyEvent keyEvent) {
    return mTextInputPlugin.handleKeyEvent(keyEvent);
  }

  @Override
  public void redispatch(@NonNull KeyEvent keyEvent) {
    getRootView().dispatchKeyEvent(keyEvent);
  }

  // -------- End: Keyboard -------

  @Override
  @UiThread
  public TaskQueue makeBackgroundTaskQueue(TaskQueueOptions options) {
    return null;
  }

  @Override
  @UiThread
  public void send(String channel, ByteBuffer message) {
    send(channel, message, null);
  }

  @Override
  @UiThread
  public void send(String channel, ByteBuffer message, BinaryReply callback) {
    if (!isAttached()) {
      Log.d(TAG, "FlutterView.send called on a detached view, channel=" + channel);
      return;
    }
    mNativeView.send(channel, message, callback);
  }

  @Override
  @UiThread
  public void setMessageHandler(@NonNull String channel, @NonNull BinaryMessageHandler handler) {
    mNativeView.setMessageHandler(channel, handler);
  }

  @Override
  @UiThread
  public void setMessageHandler(
      @NonNull String channel,
      @NonNull BinaryMessageHandler handler,
      @NonNull TaskQueue taskQueue) {
    mNativeView.setMessageHandler(channel, handler, taskQueue);
  }

  /** Listener will be called on the Android UI thread once when Flutter renders the first frame. */
  public interface FirstFrameListener {
    void onFirstFrame();
  }

  @Override
  @NonNull
  public TextureRegistry.SurfaceTextureEntry createSurfaceTexture() {
    final SurfaceTexture surfaceTexture = new SurfaceTexture(0);
    return registerSurfaceTexture(surfaceTexture);
  }

  @Override
  @NonNull
  public TextureRegistry.SurfaceTextureEntry registerSurfaceTexture(
      @NonNull SurfaceTexture surfaceTexture) {
    surfaceTexture.detachFromGLContext();
    final SurfaceTextureRegistryEntry entry =
        new SurfaceTextureRegistryEntry(nextTextureId.getAndIncrement(), surfaceTexture);
    mNativeView.getFlutterJNI().registerTexture(entry.id(), entry.textureWrapper());
    return entry;
  }

  final class SurfaceTextureRegistryEntry implements TextureRegistry.SurfaceTextureEntry {
    private final long id;
    private final SurfaceTextureWrapper textureWrapper;
    private boolean released;

    SurfaceTextureRegistryEntry(long id, SurfaceTexture surfaceTexture) {
      this.id = id;
      this.textureWrapper = new SurfaceTextureWrapper(surfaceTexture);

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

    private SurfaceTexture.OnFrameAvailableListener onFrameListener =
        new SurfaceTexture.OnFrameAvailableListener() {
          @Override
          public void onFrameAvailable(SurfaceTexture texture) {
            if (released || mNativeView == null) {
              // Even though we make sure to unregister the callback before releasing, as of Android
              // O
              // SurfaceTexture has a data race when accessing the callback, so the callback may
              // still be called by a stale reference after released==true and mNativeView==null.
              return;
            }

            mNativeView
                .getFlutterJNI()
                .markTextureFrameAvailable(SurfaceTextureRegistryEntry.this.id);
          }
        };

    public SurfaceTextureWrapper textureWrapper() {
      return textureWrapper;
    }

    @Override
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
      released = true;

      // The ordering of the next 3 calls is important:
      // First we remove the frame listener, then we release the SurfaceTexture, and only after we
      // unregister
      // the texture which actually deletes the GL texture.

      // Otherwise onFrameAvailableListener might be called after mNativeView==null
      // (https://github.com/flutter/flutter/issues/20951). See also the check in onFrameAvailable.
      surfaceTexture().setOnFrameAvailableListener(null);
      textureWrapper.release();
      mNativeView.getFlutterJNI().unregisterTexture(id);
    }
  }
}
