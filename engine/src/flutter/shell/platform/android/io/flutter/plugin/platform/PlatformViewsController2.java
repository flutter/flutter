// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugin.platform;

import static io.flutter.Build.API_LEVELS;

import android.content.Context;
import android.graphics.Path;
import android.graphics.PixelFormat;
import android.graphics.Rect;
import android.graphics.RectF;
import android.os.Build;
import android.util.SparseArray;
import android.view.AttachedSurfaceControl;
import android.view.Gravity;
import android.view.MotionEvent;
import android.view.MotionEvent.PointerCoords;
import android.view.MotionEvent.PointerProperties;
import android.view.Surface;
import android.view.SurfaceControl;
import android.view.SurfaceHolder;
import android.view.SurfaceView;
import android.view.View;
import android.view.ViewGroup;
import android.view.WindowManager;
import android.widget.FrameLayout;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.annotation.RequiresApi;
import androidx.annotation.UiThread;
import androidx.annotation.VisibleForTesting;
import io.flutter.Log;
import io.flutter.embedding.android.AndroidTouchProcessor;
import io.flutter.embedding.android.FlutterView;
import io.flutter.embedding.android.MotionEventTracker;
import io.flutter.embedding.engine.FlutterJNI;
import io.flutter.embedding.engine.FlutterOverlaySurface;
import io.flutter.embedding.engine.dart.DartExecutor;
import io.flutter.embedding.engine.mutatorsstack.*;
import io.flutter.embedding.engine.renderer.FlutterRenderer;
import io.flutter.embedding.engine.systemchannels.PlatformViewCreationRequest;
import io.flutter.embedding.engine.systemchannels.PlatformViewTouch;
import io.flutter.embedding.engine.systemchannels.PlatformViewsChannel2;
import io.flutter.plugin.editing.TextInputPlugin;
import io.flutter.view.AccessibilityBridge;
import java.lang.reflect.Method;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;

/**
 * Manages platform views.
 *
 * <p>Each {@link io.flutter.embedding.engine.FlutterEngine} has a single platform views controller.
 * A platform views controller can be attached to at most one Flutter view.
 * [PlatformViewsController2] is intentionally a different class from [PlatformViewsController] in
 * order to separate out the complexity of the first 3 platform view implementations (Virtual
 * Display, Texture Layer, and Hybrid Composition). From the 4th platform view implementation,
 * Hybrid Composition++.
 */
public class PlatformViewsController2 implements PlatformViewsAccessibilityDelegate {
  private static final String TAG = "PlatformViewsController2";

  private PlatformViewRegistryImpl registry;
  private AndroidTouchProcessor androidTouchProcessor;
  private Context context;
  private FlutterView flutterView;
  private FlutterJNI flutterJNI = null;

  @Nullable private TextInputPlugin textInputPlugin;

  private PlatformViewsChannel2 platformViewsChannel;
  private final AccessibilityEventsDelegate accessibilityEventsDelegate;

  private final SparseArray<PlatformView> platformViews;
  private final SparseArray<FlutterMutatorView> platformViewParent;
  private final MotionEventTracker motionEventTracker;

  // Guarded by transactionLock: the raster thread appends; the platform thread drains.
  private final ArrayList<SurfaceControl.Transaction> pendingRasterTransactions;
  private final Object transactionLock = new Object();

  // Platform-thread only: populated by swapTransactions(), drained by onEndFrame().
  private final ArrayList<SurfaceControl.Transaction> activeRasterTransactions;

  // Platform-thread only. Clips and overlay visibility share one transaction per frame.
  private SurfaceControl.Transaction pendingPlatformTransaction;
  private SurfaceControl.Transaction activePlatformTransaction;

  private Surface overlayerSurface = null;
  private SurfaceControl overlaySurfaceControl = null;

  private final HashSet<Integer> viewsWithPendingSurfaceCallback = new HashSet<>();

  public PlatformViewsController2() {
    accessibilityEventsDelegate = new AccessibilityEventsDelegate();
    platformViews = new SparseArray<>();
    platformViewParent = new SparseArray<>();
    pendingRasterTransactions = new ArrayList<>();
    activeRasterTransactions = new ArrayList<>();
    motionEventTracker = MotionEventTracker.getInstance();
  }

  public void setRegistry(@NonNull PlatformViewRegistry registry) {
    this.registry = (PlatformViewRegistryImpl) registry;
  }

  /** Whether the SurfaceControl swapchain mode is enabled. */
  public void setFlutterJNI(FlutterJNI flutterJNI) {
    this.flutterJNI = flutterJNI;
  }

  @Override
  public boolean usesVirtualDisplay(int id) {
    return false;
  }

  public PlatformView createFlutterPlatformView(@NonNull PlatformViewCreationRequest request) {
    final PlatformViewFactory viewFactory = registry.getFactory(request.viewType);
    if (viewFactory == null) {
      throw new IllegalStateException(
          "Trying to create a platform view of unregistered type: " + request.viewType);
    }

    Object createParams = null;
    if (request.params != null) {
      createParams = viewFactory.getCreateArgsCodec().decodeMessage(request.params);
    }
    final PlatformView platformView = viewFactory.create(context, request.viewId, createParams);

    // Configure the view to match the requested layout direction.
    final View embeddedView = platformView.getView();
    if (embeddedView == null) {
      throw new IllegalStateException(
          "PlatformView#getView() returned null, but an Android view reference was expected.");
    }
    embeddedView.setLayoutDirection(request.direction);
    platformViews.put(request.viewId, platformView);
    maybeInvokeOnFlutterViewAttached(platformView);
    return platformView;
  }

  /**
   * Translates an original touch event to have the same locations as the ones that Flutter
   * calculates (because original + flutter's - original = flutter's).
   *
   * @param originalEvent The saved original input event.
   * @param pointerCoords The coordinates that Flutter thinks the touch is happening at.
   */
  private static void translateMotionEvent(
      MotionEvent originalEvent, PointerCoords[] pointerCoords) {
    if (pointerCoords.length < 1) {
      return;
    }

    float xOffset = pointerCoords[0].x - originalEvent.getX();
    float yOffset = pointerCoords[0].y - originalEvent.getY();

    originalEvent.offsetLocation(xOffset, yOffset);
  }

  @VisibleForTesting
  public MotionEvent toMotionEvent(float density, PlatformViewTouch touch) {
    MotionEventTracker.MotionEventId motionEventId =
        MotionEventTracker.MotionEventId.from(touch.motionEventId);
    MotionEvent trackedEvent = motionEventTracker.pop(motionEventId);

    // Pointer coordinates in the tracked events are global to FlutterView
    // The framework converts them to be local to a widget, given that
    // motion events operate on local coords, we need to replace these in the tracked
    // event with their local counterparts.
    // Compute this early so it can be used as input to translateNonVirtualDisplayMotionEvent.
    PointerCoords[] pointerCoords =
        parsePointerCoordsList(touch.rawPointerCoords, density)
            .toArray(new PointerCoords[touch.pointerCount]);

    if (trackedEvent != null) {
      // We have the original event, deliver it after offsetting as it will pass the verifiable
      // input check.
      translateMotionEvent(trackedEvent, pointerCoords);
      return trackedEvent;
    }
    // We don't have a reference to the original MotionEvent.
    // In this case we manually recreate a MotionEvent to be delivered. This MotionEvent
    // will fail the verifiable input check.
    PointerProperties[] pointerProperties =
        parsePointerPropertiesList(touch.rawPointerPropertiesList)
            .toArray(new PointerProperties[touch.pointerCount]);

    return MotionEvent.obtain(
        touch.downTime.longValue(),
        touch.eventTime.longValue(),
        touch.action,
        touch.pointerCount,
        pointerProperties,
        pointerCoords,
        touch.metaState,
        touch.buttonState,
        touch.xPrecision,
        touch.yPrecision,
        touch.deviceId,
        touch.edgeFlags,
        touch.source,
        touch.flags);
  }

  /**
   * Attaches this platform views controller to its input and output channels.
   *
   * @param context The base context that will be passed to embedded views created by this
   *     controller. This should be the context of the Activity hosting the Flutter application.
   * @param dartExecutor The dart execution context, which is used to set up a system channel.
   */
  public void attach(@Nullable Context context, @NonNull DartExecutor dartExecutor) {
    if (this.context != null) {
      throw new AssertionError(
          "A PlatformViewsController can only be attached to a single output target.\n"
              + "attach was called while the PlatformViewsController was already attached.");
    }
    this.context = context;
    // TODO(gmackall): We should remove this channel once hcpp has been enabled on existing
    //  platform view widgets.
    platformViewsChannel = new PlatformViewsChannel2(dartExecutor);
    platformViewsChannel.setPlatformViewsHandler(channelHandler);
  }

  /**
   * Detaches this platform views controller.
   *
   * <p>This is typically called when a Flutter applications moves to run in the background, or is
   * destroyed. After calling this the platform views controller will no longer listen to it's
   * previous messenger, and will not maintain references to the texture registry, context, and
   * messenger passed to the previous attach call.
   */
  @UiThread
  public void detach() {
    if (platformViewsChannel != null) {
      platformViewsChannel.setPlatformViewsHandler(null);
    }
    destroyOverlaySurface();
    platformViewsChannel = null;
    context = null;
  }

  /**
   * Attaches the controller to a {@link FlutterView}.
   *
   * <p>When {@link io.flutter.embedding.android.FlutterFragment} is used, this method is called
   * after the device rotates since the FlutterView is recreated after a rotation.
   */
  public void attachToView(@NonNull FlutterView newFlutterView) {
    flutterView = newFlutterView;
    // Add wrapper for platform views that are composed at the view hierarchy level.
    for (int index = 0; index < platformViewParent.size(); index++) {
      final FlutterMutatorView view = platformViewParent.valueAt(index);
      flutterView.addView(view);
    }
    // Notify platform views that they are now attached to a FlutterView.
    for (int index = 0; index < platformViews.size(); index++) {
      final PlatformView view = platformViews.valueAt(index);
      view.onFlutterViewAttached(flutterView);
    }
  }

  /**
   * Detaches the controller from {@link FlutterView}.
   *
   * <p>When {@link io.flutter.embedding.android.FlutterFragment} is used, this method is called
   * when the device rotates since the FlutterView is detached from the fragment. The next time the
   * fragment needs to be displayed, a new Flutter view is created, so attachToView is called again.
   */
  public void detachFromView() {
    // Remove wrapper for platform views that are composed at the view hierarchy level.
    for (int index = 0; index < platformViewParent.size(); index++) {
      final FlutterMutatorView view = platformViewParent.valueAt(index);
      flutterView.removeView(view);
    }

    destroyOverlaySurface();
    flutterView = null;

    if (Build.VERSION.SDK_INT >= API_LEVELS.API_34) {
      dropTransactions();
    }

    // Notify that the platform view have been detached from FlutterView.
    for (int index = 0; index < platformViews.size(); index++) {
      final PlatformView view = platformViews.valueAt(index);
      view.onFlutterViewDetached();
    }
  }

  private void maybeInvokeOnFlutterViewAttached(PlatformView view) {
    if (flutterView == null) {
      Log.i(TAG, "null flutterView");
      // There is currently no FlutterView that we are attached to.
      return;
    }
    view.onFlutterViewAttached(flutterView);
  }

  @Override
  public void attachAccessibilityBridge(@NonNull AccessibilityBridge accessibilityBridge) {
    accessibilityEventsDelegate.setAccessibilityBridge(accessibilityBridge);
  }

  @Override
  public void detachAccessibilityBridge() {
    accessibilityEventsDelegate.setAccessibilityBridge(null);
  }

  /**
   * Attaches this controller to a text input plugin.
   *
   * <p>While a text input plugin is available, the platform views controller interacts with it to
   * facilitate delegation of text input connections to platform views.
   *
   * <p>A platform views controller should be attached to a text input plugin whenever it is
   * possible for the Flutter framework to receive text input.
   */
  public void attachTextInputPlugin(@NonNull TextInputPlugin textInputPlugin) {
    this.textInputPlugin = textInputPlugin;
  }

  /** Detaches this controller from the currently attached text input plugin. */
  public void detachTextInputPlugin() {
    textInputPlugin = null;
  }

  public PlatformViewRegistry getRegistry() {
    return registry;
  }

  /**
   * Invoked when the {@link io.flutter.embedding.engine.FlutterEngine} that owns this {@link
   * PlatformViewsController} detaches from JNI.
   */
  public void onDetachedFromJNI() {
    disposeAllViews();
  }

  public void onPreEngineRestart() {
    disposeAllViews();
  }

  @Override
  @Nullable
  public View getPlatformViewById(int viewId) {
    final PlatformView platformView = platformViews.get(viewId);
    if (platformView == null) {
      return null;
    }
    return platformView.getView();
  }

  private void lockInputConnection(@NonNull VirtualDisplayController controller) {
    if (textInputPlugin == null) {
      return;
    }
    textInputPlugin.lockPlatformViewInputConnection();
    controller.onInputConnectionLocked();
  }

  private void unlockInputConnection(@NonNull VirtualDisplayController controller) {
    if (textInputPlugin == null) {
      return;
    }
    textInputPlugin.unlockPlatformViewInputConnection();
    controller.onInputConnectionUnlocked();
  }

  private static boolean validateDirection(int direction) {
    return direction == View.LAYOUT_DIRECTION_LTR || direction == View.LAYOUT_DIRECTION_RTL;
  }

  @SuppressWarnings("unchecked")
  private static List<PointerProperties> parsePointerPropertiesList(Object rawPropertiesList) {
    List<Object> rawProperties = (List<Object>) rawPropertiesList;
    List<PointerProperties> pointerProperties = new ArrayList<>();
    for (Object o : rawProperties) {
      pointerProperties.add(parsePointerProperties(o));
    }
    return pointerProperties;
  }

  @SuppressWarnings("unchecked")
  private static PointerProperties parsePointerProperties(Object rawProperties) {
    List<Object> propertiesList = (List<Object>) rawProperties;
    PointerProperties properties = new MotionEvent.PointerProperties();
    properties.id = (int) propertiesList.get(0);
    properties.toolType = (int) propertiesList.get(1);
    return properties;
  }

  @SuppressWarnings("unchecked")
  private static List<PointerCoords> parsePointerCoordsList(Object rawCoordsList, float density) {
    List<Object> rawCoords = (List<Object>) rawCoordsList;
    List<PointerCoords> pointerCoords = new ArrayList<>();
    for (Object o : rawCoords) {
      pointerCoords.add(parsePointerCoords(o, density));
    }
    return pointerCoords;
  }

  @SuppressWarnings("unchecked")
  private static PointerCoords parsePointerCoords(Object rawCoords, float density) {
    List<Object> coordsList = (List<Object>) rawCoords;
    PointerCoords coords = new MotionEvent.PointerCoords();
    coords.orientation = (float) (double) coordsList.get(0);
    coords.pressure = (float) (double) coordsList.get(1);
    coords.size = (float) (double) coordsList.get(2);
    coords.toolMajor = (float) ((double) coordsList.get(3) * density);
    coords.toolMinor = (float) ((double) coordsList.get(4) * density);
    coords.touchMajor = (float) ((double) coordsList.get(5) * density);
    coords.touchMinor = (float) ((double) coordsList.get(6) * density);
    coords.x = (float) ((double) coordsList.get(7) * density);
    coords.y = (float) ((double) coordsList.get(8) * density);
    return coords;
  }

  private float getDisplayDensity() {
    return context.getResources().getDisplayMetrics().density;
  }

  private int toPhysicalPixels(double logicalPixels) {
    return (int) Math.round(logicalPixels * getDisplayDensity());
  }

  private int toLogicalPixels(double physicalPixels, float displayDensity) {
    return (int) Math.round(physicalPixels / displayDensity);
  }

  private int toLogicalPixels(double physicalPixels) {
    return toLogicalPixels(physicalPixels, getDisplayDensity());
  }

  private void disposeAllViews() {
    while (platformViews.size() > 0) {
      final int viewId = platformViews.keyAt(0);
      // Dispose deletes the entry from platformViews and clears associated resources.
      channelHandler.dispose(viewId);
    }
  }

  /**
   * Disposes a single
   *
   * @param viewId the PlatformView ID.
   */
  @VisibleForTesting
  public void disposePlatformView(int viewId) {
    channelHandler.dispose(viewId);
  }

  @VisibleForTesting
  FlutterMutatorView getPlatformViewParent(int viewId) {
    return platformViewParent.get(viewId);
  }

  /**
   * Initializes a platform view and adds it to the view hierarchy.
   *
   * @param viewId The view ID. This member is not intended for public use, and is only visible for
   *     testing.
   */
  @VisibleForTesting
  boolean initializePlatformViewIfNeeded(int viewId) {
    final PlatformView platformView = platformViews.get(viewId);
    if (platformView == null) {
      return false;
    }
    if (platformViewParent.get(viewId) != null) {
      return true;
    }
    final View embeddedView = platformView.getView();
    if (embeddedView == null) {
      throw new IllegalStateException(
          "PlatformView#getView() returned null, but an Android view reference was expected.");
    }
    if (embeddedView.getParent() != null) {
      throw new IllegalStateException(
          "The Android view returned from PlatformView#getView() was already added to a parent"
              + " view.");
    }
    final FlutterMutatorView parentView =
        new FlutterMutatorView(
            context, context.getResources().getDisplayMetrics().density, androidTouchProcessor);

    parentView.setOnDescendantFocusChangeListener(
        (view, hasFocus) -> {
          if (hasFocus) {
            platformViewsChannel.invokeViewFocused(viewId);
          } else if (textInputPlugin != null) {
            textInputPlugin.clearPlatformViewClient(viewId);
          }
        });

    platformViewParent.put(viewId, parentView);

    // Accessibility in the embedded view is initially disabled because if a Flutter app disabled
    // accessibility in the first frame, the embedding won't receive an update to disable
    // accessibility since the embedding never received an update to enable it.
    // The AccessibilityBridge keeps track of the accessibility nodes, and handles the deltas when
    // the framework sends a new a11y tree to the embedding.
    // To prevent races, the framework populate the SemanticsNode after the platform view has been
    // created.
    embeddedView.setImportantForAccessibility(View.IMPORTANT_FOR_ACCESSIBILITY_NO_HIDE_DESCENDANTS);

    parentView.addView(embeddedView);
    flutterView.addView(parentView);
    return true;
  }

  public void attachToFlutterRenderer(@NonNull FlutterRenderer flutterRenderer) {
    androidTouchProcessor = new AndroidTouchProcessor(flutterRenderer, /*trackMotionEvents=*/ true);
  }

  /**
   * Called when a platform view id displayed in the current frame.
   *
   * @param viewId The ID of the platform view.
   * @param x The left position relative to {@code FlutterView}.
   * @param y The top position relative to {@code FlutterView}.
   * @param width The width of the platform view.
   * @param height The height of the platform view.
   * @param viewWidth The original width of the platform view before applying the mutator stack.
   * @param viewHeight The original height of the platform view before applying the mutator stack.
   * @param mutatorsStack The mutator stack. This member is not intended for public use, and is only
   *     visible for testing.
   */
  @RequiresApi(API_LEVELS.API_34)
  public void onDisplayPlatformView(
      int viewId,
      int x,
      int y,
      int width,
      int height,
      int viewWidth,
      int viewHeight,
      @NonNull FlutterMutatorsStack mutatorsStack) {
    if (!initializePlatformViewIfNeeded(viewId)) {
      return;
    }

    final FlutterMutatorView parentView = platformViewParent.get(viewId);
    parentView.readyToDisplay(mutatorsStack, x, y, width, height);
    parentView.setVisibility(View.VISIBLE);
    parentView.bringToFront();

    final FrameLayout.LayoutParams layoutParams =
        new FrameLayout.LayoutParams(viewWidth, viewHeight, Gravity.LEFT | Gravity.TOP);
    final View view = platformViews.get(viewId).getView();
    if (view != null) {
      view.setLayoutParams(layoutParams);
      view.bringToFront();
      if (view instanceof SurfaceView) {
        maybeApplyClipToSurfaceView((SurfaceView) view, x, y, width, height, mutatorsStack, viewId);
      }
    }
  }

  @RequiresApi(API_LEVELS.API_34)
  private void maybeApplyClipToSurfaceView(
      SurfaceView surfaceView,
      int x,
      int y,
      int width,
      int height,
      FlutterMutatorsStack mutatorsStack,
      int viewId) {
    // 1. CALCULATE THE FINAL RECT (RECT, RRECT, PATH, TRANSFORM)
    // We start with the view's final on-screen bounds.
    RectF screenRectF = new RectF(x, y, x + width, y + height);
    Rect screenRect = new Rect();
    screenRectF.roundOut(screenRect);

    List<Path> clippingPaths = mutatorsStack.getFinalClippingPaths();

    if (clippingPaths != null && !clippingPaths.isEmpty()) {
      RectF pathBounds = new RectF();
      for (Path path : clippingPaths) {
        // Compute the axis-aligned bounding box of the path.
        path.computeBounds(pathBounds, true);

        // Round out to ensure we cover the pixels (ceil/floor logic).
        Rect pathRectInt = new Rect();
        pathBounds.roundOut(pathRectInt);

        // Intersect the current visible area with this clip.
        // If the path is a complex shape (star, rounded rect), this
        // constrains the surface to the bounding box of that shape.
        boolean anyIntersection = screenRect.intersect(pathRectInt);
        if (!anyIntersection) {
          screenRect.setEmpty();
          break;
        }
      }
    }

    // 2. CONVERT TO LOCAL SURFACE COORDINATES
    // SurfaceControl.setCrop expects coordinates relative to the Surface (0,0).
    // We shift the calculated screen-space rect by the view's origin (-x, -y).
    screenRect.offset(-x, -y);
    if (screenRect.width() < 0 || screenRect.height() < 0) {
      screenRect.setEmpty();
    }

    // 3. APPLY EITHER IN TIME, OR AS A CALLBACK
    // If the widget tree recently changed, the SurfaceControl will likely be null.
    // So apply via a SurfaceHolder.Callback(). Otherwise, apply via standard
    // transaction apis.
    float opacity = mutatorsStack.getFinalOpacity();
    SurfaceControl sc = surfaceView.getSurfaceControl();
    if (sc == null) {
      if (viewsWithPendingSurfaceCallback.contains(viewId)) {
        return;
      }
      viewsWithPendingSurfaceCallback.add(viewId);
      SurfaceHolder.Callback cb =
          createSurfaceClipCallback(surfaceView, opacity, screenRect, viewId);
      surfaceView.getHolder().addCallback(cb);
      return;
    }
    if (!sc.isValid()) {
      Log.i(
          TAG,
          "Skipping applying clip to SurfaceView: "
              + surfaceView.getId()
              + " because it has an invalid SurfaceControl.");
      return;
    }
    SurfaceControl.Transaction tx =
        platformTransaction().setAlpha(sc, opacity).setCrop(sc, screenRect);
  }

  @RequiresApi(API_LEVELS.API_34)
  private SurfaceHolder.Callback createSurfaceClipCallback(
      @NonNull final SurfaceView surfaceView,
      final float opacity,
      @NonNull final Rect screenRect,
      final int viewId) {
    return new SurfaceHolder.Callback() {
      @Override
      public void surfaceCreated(@NonNull SurfaceHolder holder) {
        SurfaceControl surfaceControl = surfaceView.getSurfaceControl();
        if (surfaceControl != null && surfaceControl.isValid()) {
          SurfaceControl.Transaction tx =
              platformTransaction()
                  .setAlpha(surfaceControl, opacity)
                  .setCrop(surfaceControl, screenRect);
        } else {
          Log.i(
              TAG,
              "Failed to apply clipping to SurfaceView: "
                  + surfaceView.getId()
                  + " - the SurfaceControl was null or invalid during surfaceCreated callback.");
        }
        // Because this transaction is created outside of the frame timing, we can't
        // guarantee there is another frame coming (if, say, the app has a static
        // layout). So we schedule one to ensure the crop is rendered properly.
        // See https://github.com/flutter/flutter/issues/175546.
        flutterJNI.scheduleFrame();
        viewsWithPendingSurfaceCallback.remove(viewId);
        surfaceView.getHolder().removeCallback(this);
      }

      @Override
      public void surfaceChanged(
          @NonNull SurfaceHolder holder, int format, int width, int height) {}

      @Override
      public void surfaceDestroyed(@NonNull SurfaceHolder holder) {
        viewsWithPendingSurfaceCallback.remove(viewId);
        surfaceView.getHolder().removeCallback(this);
      }
    };
  }

  public void hidePlatformView(int viewId) {
    if (!initializePlatformViewIfNeeded(viewId)) {
      return;
    }

    final FlutterMutatorView parentView = platformViewParent.get(viewId);
    parentView.setVisibility(View.GONE);
  }

  @UiThread
  @RequiresApi(API_LEVELS.API_34)
  public void onEndFrame() {
    final SurfaceControl.Transaction platformTx = activePlatformTransaction;
    activePlatformTransaction = null;

    // Use a fresh destination so cleanup cannot close a raster input still in native use.
    // Bypass newTransaction(), which tests may override to return an existing input.
    SurfaceControl.Transaction tx = new SurfaceControl.Transaction();
    if (platformTx != null) {
      tx = tx.merge(platformTx);
      platformTx.close();
    }
    for (SurfaceControl.Transaction rasterTx : activeRasterTransactions) {
      tx = tx.merge(rasterTx);
    }
    activeRasterTransactions.clear();

    // The view or its window may detach before this posted frame runs.
    final AttachedSurfaceControl rootSurfaceControl =
        flutterView == null ? null : flutterView.getRootSurfaceControl();
    if (rootSurfaceControl == null) {
      // Release the unapplied transaction and its owned fence FDs.
      tx.close();
      return;
    }

    flutterView.invalidate();
    rootSurfaceControl.applyTransactionOnDraw(tx);
  }

  @UiThread
  @RequiresApi(API_LEVELS.API_34)
  public void swapTransactions() {
    // Do not close discarded raster inputs; native producers may still use them.
    activeRasterTransactions.clear();
    synchronized (transactionLock) {
      activeRasterTransactions.addAll(pendingRasterTransactions);
      pendingRasterTransactions.clear();
    }

    if (activePlatformTransaction != null) {
      // Discard a platform transaction whose onEndFrame() never ran.
      activePlatformTransaction.close();
    }
    activePlatformTransaction = pendingPlatformTransaction;
    pendingPlatformTransaction = null;
  }

  /**
   * Discards the transaction state of the view that just detached.
   *
   * <p>Platform transactions are closed here: they only touch SurfaceControls that this detach
   * invalidates, including the overlay that {@link #destroyOverlaySurface()} just released, and
   * nothing outside the platform thread references them. Raster transactions are dropped without
   * closing them, because their native producers may still be writing into them.
   */
  @UiThread
  @RequiresApi(API_LEVELS.API_34)
  private void dropTransactions() {
    activeRasterTransactions.clear();
    synchronized (transactionLock) {
      pendingRasterTransactions.clear();
    }

    if (activePlatformTransaction != null) {
      activePlatformTransaction.close();
      activePlatformTransaction = null;
    }
    if (pendingPlatformTransaction != null) {
      pendingPlatformTransaction.close();
      pendingPlatformTransaction = null;
    }
  }

  @UiThread
  @RequiresApi(API_LEVELS.API_34)
  private SurfaceControl.Transaction platformTransaction() {
    if (pendingPlatformTransaction == null) {
      pendingPlatformTransaction = newTransaction();
    }
    return pendingPlatformTransaction;
  }

  // Called from the raster thread through FlutterJNI.
  @RequiresApi(API_LEVELS.API_34)
  public SurfaceControl.Transaction createTransaction() {
    final SurfaceControl.Transaction tx = newTransaction();
    // This lock protects the list, not AHBSwapchainImplVK::Present's later native writes.
    // Those can race merging or GC freeing the transaction. Fix both hazards by retaining it
    // natively and publishing only after the writes finish.
    synchronized (transactionLock) {
      pendingRasterTransactions.add(tx);
    }
    return tx;
  }

  /** Allocates a transaction so tests can spy on the instance retained by the controller. */
  @VisibleForTesting
  @RequiresApi(API_LEVELS.API_34)
  SurfaceControl.Transaction newTransaction() {
    return new SurfaceControl.Transaction();
  }

  @RequiresApi(API_LEVELS.API_34)
  public FlutterOverlaySurface createOverlaySurface() {
    if (overlayerSurface == null) {
      final SurfaceControl.Builder surfaceControlBuilder = new SurfaceControl.Builder();
      surfaceControlBuilder.setBufferSize(flutterView.getWidth(), flutterView.getHeight());
      surfaceControlBuilder.setFormat(PixelFormat.RGBA_8888);
      surfaceControlBuilder.setName("Flutter Overlay Surface");
      surfaceControlBuilder.setOpaque(false);
      surfaceControlBuilder.setHidden(false);
      final SurfaceControl surfaceControl = surfaceControlBuilder.build();
      final SurfaceControl.Transaction tx =
          flutterView.getRootSurfaceControl().buildReparentTransaction(surfaceControl);
      tx.setLayer(surfaceControl, 1000);
      tx.apply();
      overlayerSurface = new Surface(surfaceControl);
      overlaySurfaceControl = surfaceControl;
      overlayParentedToCarrier = false;
      if (blurCarrierView != null) {
        reparentOverlayToCarrier();
      }
    }

    return new FlutterOverlaySurface(0, overlayerSurface);
  }

  public void destroyOverlaySurface() {
    if (overlayerSurface != null) {
      overlayerSurface.release();
      overlayerSurface = null;
      overlaySurfaceControl = null;
      overlayHasBlurRegions = false;
    }
    releaseBackdropBlurLayers();
    releaseBlurCarrierView();
  }

  // ----- PROTOTYPE: native backdrop blur for HCPP platform views -----
  //
  // Under HCPP the platform view's pixels never reach Flutter, so a BackdropFilter blur drawn by
  // Flutter cannot include them. Instead, the engine reports blurs that cover platform views, and we
  // ask SurfaceFlinger to do the blur: one buffer-less layer per blur, placed above the window
  // content (and therefore the platform views) and below the Flutter overlay (which holds the
  // filter's children), with a background blur radius. SurfaceFlinger blurs the real composite, so
  // there is no seam between platform view and Flutter content.
  //
  // The per-layer background blur API on SurfaceControl.Transaction is hidden, so this uses
  // reflection and requires hidden API enforcement to be relaxed (prototype only).

  private static final String BLUR_TAG = "HcppBackdropBlur";
  // Z order of blur layers relative to the root surface control. The overlay is at 1000.
  private static final int BACKDROP_BLUR_LAYER_Z = 999;
  private static final int BLUR_FIELDS = 6;

  private final ArrayList<SurfaceControl> backdropBlurLayers = new ArrayList<>();
  private int visibleBackdropBlurLayers = 0;
  private boolean backdropBlurReflectionResolved = false;
  private Method setBackgroundBlurRadiusMethod;
  private Method setCornerRadiusMethod;
  private boolean loggedBackdropBlurUnavailable = false;

  /**
   * Applies this frame's backdrop blurs. Each blur is [left, top, right, bottom, sigma,
   * cornerRadius] in physical pixels.
   */
  @UiThread
  @RequiresApi(API_LEVELS.API_34)
  public void onBackdropBlurs(@NonNull float[] blurs) {
    if (!"layers".equals(readSystemProperty("debug.flutter.blur_mode"))) {
      if ("regions".equals(readSystemProperty("debug.flutter.blur_mode"))) {
        onBackdropBlursAsRegions(blurs);
      } else {
        onBackdropBlursViaCarrierSurfaceView(blurs);
      }
      return;
    }
    int count = blurs.length / BLUR_FIELDS;
    if (count > 0 && !isBackdropBlurAvailable()) {
      count = 0;
    }

    final SurfaceControl.Transaction tx = count > 0 || visibleBackdropBlurLayers > 0
        ? platformTransaction()
        : null;
    int applied = 0;
    for (int i = 0; i < count; i++) {
      final SurfaceControl layer = obtainBackdropBlurLayer(i);
      if (layer == null) {
        break;
      }
      final int base = i * BLUR_FIELDS;
      final Rect crop =
          new Rect(
              Math.round(blurs[base]),
              Math.round(blurs[base + 1]),
              Math.round(blurs[base + 2]),
              Math.round(blurs[base + 3]));
      final float sigma = blurs[base + 4];
      final float corner = blurs[base + 5];
      tx.setPosition(layer, 0, 0);
      tx.setCrop(layer, crop);
      tx.setVisibility(layer, true);
      invokeQuietly(setBackgroundBlurRadiusMethod, tx, layer, sigmaToBlurRadius(sigma));
      invokeQuietly(setCornerRadiusMethod, tx, layer, corner);
      applied++;
    }
    for (int i = applied; i < visibleBackdropBlurLayers && i < backdropBlurLayers.size(); i++) {
      tx.setVisibility(backdropBlurLayers.get(i), false);
    }
    visibleBackdropBlurLayers = applied;
  }

  // Hidden SurfaceControl.Transaction#setBlurRegions(SurfaceControl, float[][]). Each row is
  // [blurRadius, alpha, left, top, right, bottom, cornerTL, cornerTR, cornerBL, cornerBR] in the
  // layer's coordinate space (see nativeSetBlurRegions in android_view_SurfaceControl.cpp). This is
  // what the public SurfaceView#setBlurRegions(Collection<BlurRegion>) uses under the hood.
  private Method setBlurRegionsMethod;
  private boolean blurRegionsReflectionResolved = false;
  private boolean overlayHasBlurRegions = false;

  @UiThread
  @RequiresApi(API_LEVELS.API_34)
  private void onBackdropBlursAsRegions(@NonNull float[] blurs) {
    if (!blurRegionsReflectionResolved) {
      blurRegionsReflectionResolved = true;
      try {
        setBlurRegionsMethod =
            SurfaceControl.Transaction.class.getMethod(
                "setBlurRegions", SurfaceControl.class, float[][].class);
      } catch (Exception e) {
        Log.w(BLUR_TAG, "SurfaceControl.Transaction#setBlurRegions unavailable: " + e);
      }
    }
    // The pooled layers from the other mode must not linger.
    if (visibleBackdropBlurLayers > 0) {
      final SurfaceControl.Transaction tx = platformTransaction();
      for (int i = 0; i < visibleBackdropBlurLayers && i < backdropBlurLayers.size(); i++) {
        tx.setVisibility(backdropBlurLayers.get(i), false);
      }
      visibleBackdropBlurLayers = 0;
    }
    int count = blurs.length / BLUR_FIELDS;
    if (setBlurRegionsMethod == null || overlaySurfaceControl == null) {
      return;
    }
    if (count == 0 && !overlayHasBlurRegions) {
      return;
    }
    final float[][] regions = new float[count][];
    for (int i = 0; i < count; i++) {
      final int base = i * BLUR_FIELDS;
      final float corner = blurs[base + 5];
      regions[i] =
          new float[] {
            sigmaToBlurRadius(blurs[base + 4]),
            1.0f,
            blurs[base],
            blurs[base + 1],
            blurs[base + 2],
            blurs[base + 3],
            corner,
            corner,
            corner,
            corner
          };
    }
    try {
      setBlurRegionsMethod.invoke(platformTransaction(), overlaySurfaceControl, (Object) regions);
      overlayHasBlurRegions = count > 0;
    } catch (Exception e) {
      Log.w(BLUR_TAG, "Failed to invoke setBlurRegions: " + e);
    }
  }

  @Nullable
  private static String readSystemProperty(String key) {
    try {
      final Class<?> props = Class.forName("android.os.SystemProperties");
      return (String) props.getMethod("get", String.class).invoke(null, key);
    } catch (Exception e) {
      return null;
    }
  }

  // ----- PROTOTYPE (public API only): blur carrier SurfaceView -----
  //
  // SurfaceView#setBlurRegions(Collection<BlurRegion>) is public since API 37. The blur does not
  // have to live on the Flutter overlay: it only has to sit above the platform views and below the
  // overlay. So we add one full-size, transparent, buffer-less SurfaceView to the FlutterView with
  // setZOrderOnTop(true) (layer 1 under the window: above the main window content at 0 and the
  // base FlutterSurfaceView at -2, below the overlay at 1000) and hand it this frame's blur rects.
  // SurfaceView applies the regions from a RenderThread position listener that is merged into the
  // same frame as the View draw, which is also the frame applyTransactionOnDraw targets.

  private SurfaceView blurCarrierView;
  private boolean carrierHasBlurRegions = false;
  private boolean loggedCarrierUnavailable = false;

  @UiThread
  @RequiresApi(API_LEVELS.API_34)
  private void onBackdropBlursViaCarrierSurfaceView(@NonNull float[] blurs) {
    // The pooled layers / overlay regions from the other modes must not linger.
    if (visibleBackdropBlurLayers > 0) {
      final SurfaceControl.Transaction tx = platformTransaction();
      for (int i = 0; i < visibleBackdropBlurLayers && i < backdropBlurLayers.size(); i++) {
        tx.setVisibility(backdropBlurLayers.get(i), false);
      }
      visibleBackdropBlurLayers = 0;
    }
    final int count = blurs.length / BLUR_FIELDS;
    if (count == 0 && !carrierHasBlurRegions) {
      return;
    }
    if (Build.VERSION.SDK_INT < API_LEVELS.API_37 || flutterView == null) {
      if (!loggedCarrierUnavailable && count > 0) {
        Log.w(BLUR_TAG, "SurfaceView#setBlurRegions needs API 37; platform view not blurred.");
        loggedCarrierUnavailable = true;
      }
      return;
    }
    if (count > 0 && !isCrossWindowBlurEnabled()) {
      if (!loggedCarrierUnavailable) {
        Log.w(BLUR_TAG, "Cross-window blur is disabled on this device; platform view not blurred.");
        loggedCarrierUnavailable = true;
      }
      return;
    }
    applyCarrierBlurRegions(blurs, count);
  }

  @RequiresApi(API_LEVELS.API_37)
  private void applyCarrierBlurRegions(@NonNull float[] blurs, int count) {
    if (blurCarrierView == null) {
      final SurfaceView carrier = new SurfaceView(flutterView.getContext());
      carrier.setZOrderOnTop(true);
      carrier.getHolder().setFormat(PixelFormat.TRANSLUCENT);
      carrier.setSurfaceLifecycle(SurfaceView.SURFACE_LIFECYCLE_FOLLOWS_ATTACHMENT);
      carrier.setClickable(false);
      carrier.setFocusable(false);
      carrier.setFocusableInTouchMode(false);
      carrier.setImportantForAccessibility(View.IMPORTANT_FOR_ACCESSIBILITY_NO);
      carrier.setContentDescription(null);
      // setZOrderOnTop puts the carrier at z=1 *relative to the ViewRootImpl layer*, which draws
      // after the whole bounds-layer subtree, i.e. above our overlay (a child of the bounds layer
      // at z=1000). Transaction#setLayer (public) resets the relative layer and makes it a plain
      // child of the bounds layer, so z=999 lands between the window content and the overlay.
      carrier
          .getHolder()
          .addCallback(
              new SurfaceHolder.Callback() {
                @Override
                public void surfaceCreated(@NonNull SurfaceHolder holder) {
                  // SurfaceView keeps re-asserting its relative z (onTop => above the whole
                  // window subtree, including our overlay). Instead of fighting it, hang the
                  // overlay off the carrier: children with z >= 0 draw above the parent, and the
                  // parent's blur samples what is behind it (including the BLAST child at -1).
                  carrier.post(() -> reparentOverlayToCarrier());
                }

                @Override
                public void surfaceChanged(
                    @NonNull SurfaceHolder holder, int format, int width, int height) {}

                @Override
                public void surfaceDestroyed(@NonNull SurfaceHolder holder) {}
              });
      flutterView.addView(
          carrier,
          new FrameLayout.LayoutParams(
              ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT));
      blurCarrierView = carrier;
      Log.i(BLUR_TAG, "Created blur carrier SurfaceView");
    }
    final ArrayList<android.view.BlurRegion> regions = new ArrayList<>(count);
    for (int i = 0; i < count; i++) {
      final int base = i * BLUR_FIELDS;
      final float corner = blurs[base + 5];
      // Constructor order is (bounds, cornerRadii, alpha, blurRadius).
      regions.add(
          new android.view.RoundedRectBlurRegion(
              new RectF(blurs[base], blurs[base + 1], blurs[base + 2], blurs[base + 3]),
              new float[] {corner, corner, corner, corner, corner, corner, corner, corner},
              1.0f,
              sigmaToBlurRadius(blurs[base + 4])));
    }
    blurCarrierView.setBlurRegions(regions);
    carrierHasBlurRegions = count > 0;
    if (!overlayParentedToCarrier) {
      reparentOverlayToCarrier();
    }
  }

  /** Makes the Flutter overlay a child of the blur carrier's SurfaceControl (public API only). */
  @RequiresApi(API_LEVELS.API_34)
  private void reparentOverlayToCarrier() {
    if (blurCarrierView == null || overlaySurfaceControl == null) {
      return;
    }
    final SurfaceControl carrierSc = blurCarrierView.getSurfaceControl();
    if (carrierSc == null || !carrierSc.isValid() || !overlaySurfaceControl.isValid()) {
      return;
    }
    final SurfaceControl.Transaction tx = new SurfaceControl.Transaction();
    tx.reparent(overlaySurfaceControl, carrierSc).setLayer(overlaySurfaceControl, 1000).apply();
    overlayParentedToCarrier = true;
    Log.i(BLUR_TAG, "Overlay reparented under blur carrier");
  }

  private boolean overlayParentedToCarrier = false;

  @RequiresApi(API_LEVELS.API_34)
  private boolean isCrossWindowBlurEnabled() {
    if (flutterView == null) {
      return false;
    }
    final WindowManager wm = flutterView.getContext().getSystemService(WindowManager.class);
    return wm != null && wm.isCrossWindowBlurEnabled();
  }

  private void releaseBlurCarrierView() {
    if (blurCarrierView != null) {
      if (overlayParentedToCarrier
          && overlaySurfaceControl != null
          && overlaySurfaceControl.isValid()
          && flutterView != null
          && flutterView.getRootSurfaceControl() != null
          && Build.VERSION.SDK_INT >= API_LEVELS.API_34) {
        final SurfaceControl.Transaction tx =
            flutterView.getRootSurfaceControl().buildReparentTransaction(overlaySurfaceControl);
        if (tx != null) {
          tx.setLayer(overlaySurfaceControl, 1000).apply();
        }
      }
      overlayParentedToCarrier = false;
      final ViewGroup parent = (ViewGroup) blurCarrierView.getParent();
      if (parent != null) {
        parent.removeView(blurCarrierView);
      }
      blurCarrierView = null;
      carrierHasBlurRegions = false;
    }
  }

  /**
   * Converts a Gaussian sigma to a SurfaceFlinger background blur radius. SurfaceFlinger's radius
   * is not a sigma; the default scale is tuned by eye against Flutter's own blur and can be
   * overridden with {@code adb shell setprop debug.flutter.blur_scale <float>}.
   */
  private static int sigmaToBlurRadius(float sigma) {
    float scale = 2.0f;
    try {
      final Class<?> props = Class.forName("android.os.SystemProperties");
      final String value =
          (String) props.getMethod("get", String.class).invoke(null, "debug.flutter.blur_scale");
      if (value != null && !value.isEmpty()) {
        scale = Float.parseFloat(value);
      }
    } catch (Exception ignored) {
      // Keep the default.
    }
    return Math.max(0, Math.round(sigma * scale));
  }

  @RequiresApi(API_LEVELS.API_34)
  private boolean isBackdropBlurAvailable() {
    if (!backdropBlurReflectionResolved) {
      backdropBlurReflectionResolved = true;
      try {
        setBackgroundBlurRadiusMethod =
            SurfaceControl.Transaction.class.getMethod(
                "setBackgroundBlurRadius", SurfaceControl.class, int.class);
        setCornerRadiusMethod =
            SurfaceControl.Transaction.class.getMethod(
                "setCornerRadius", SurfaceControl.class, float.class);
      } catch (Exception e) {
        Log.w(BLUR_TAG, "SurfaceControl background blur API unavailable: " + e);
      }
    }
    String reason = null;
    if (setBackgroundBlurRadiusMethod == null) {
      reason = "the SurfaceControl blur API is not accessible";
    } else if (flutterView == null || flutterView.getRootSurfaceControl() == null) {
      reason = "the FlutterView is not attached";
    } else {
      final WindowManager wm = flutterView.getContext().getSystemService(WindowManager.class);
      if (wm == null || !wm.isCrossWindowBlurEnabled()) {
        reason = "cross-window blur is disabled on this device";
      }
    }
    if (reason != null) {
      if (!loggedBackdropBlurUnavailable) {
        Log.w(
            BLUR_TAG,
            "A BackdropFilter blur covers a platform view, but "
                + reason
                + ". The platform view will not be blurred. Use a texture-based platform view"
                + " mode if this effect is required.");
        loggedBackdropBlurUnavailable = true;
      }
      return false;
    }
    return true;
  }

  @Nullable
  @RequiresApi(API_LEVELS.API_34)
  private SurfaceControl obtainBackdropBlurLayer(int index) {
    if (index < backdropBlurLayers.size()) {
      return backdropBlurLayers.get(index);
    }
    final AttachedSurfaceControl root = flutterView.getRootSurfaceControl();
    if (root == null) {
      return null;
    }
    final SurfaceControl layer =
        new SurfaceControl.Builder()
            .setName("Flutter Backdrop Blur " + index)
            .setHidden(true)
            .build();
    final SurfaceControl.Transaction tx = root.buildReparentTransaction(layer);
    if (tx == null) {
      layer.release();
      return null;
    }
    tx.setLayer(layer, BACKDROP_BLUR_LAYER_Z);
    tx.apply();
    backdropBlurLayers.add(layer);
    return layer;
  }

  private void releaseBackdropBlurLayers() {
    if (backdropBlurLayers.isEmpty() || Build.VERSION.SDK_INT < API_LEVELS.API_29) {
      return;
    }
    final SurfaceControl.Transaction tx = new SurfaceControl.Transaction();
    for (SurfaceControl layer : backdropBlurLayers) {
      if (layer.isValid()) {
        tx.reparent(layer, null);
      }
    }
    tx.apply();
    for (SurfaceControl layer : backdropBlurLayers) {
      layer.release();
    }
    backdropBlurLayers.clear();
    visibleBackdropBlurLayers = 0;
  }

  private static void invokeQuietly(
      @Nullable Method method, SurfaceControl.Transaction tx, SurfaceControl layer, Object arg) {
    if (method == null) {
      return;
    }
    try {
      method.invoke(tx, layer, arg);
    } catch (Exception e) {
      Log.w(BLUR_TAG, "Failed to invoke " + method.getName() + ": " + e);
    }
  }

  @RequiresApi(API_LEVELS.API_34)
  public void showOverlaySurface() {
    if (overlaySurfaceControl == null) {
      return;
    }
    SurfaceControl.Transaction tx = platformTransaction();
    tx.setVisibility(overlaySurfaceControl, /*visible=*/ true);
  }

  @RequiresApi(API_LEVELS.API_34)
  public void hideOverlaySurface() {
    if (overlaySurfaceControl == null) {
      return;
    }
    SurfaceControl.Transaction tx = platformTransaction();
    tx.setVisibility(overlaySurfaceControl, /*visible=*/ false);
  }

  public boolean isHcppEnabled() {
    if (flutterJNI == null) {
      return false;
    }
    return flutterJNI.IsSurfaceControlEnabled();
  }

  //// Message Handler ///////

  final PlatformViewsChannel2.PlatformViewsHandler channelHandler =
      new PlatformViewsChannel2.PlatformViewsHandler() {

        @Override
        public void createPlatformView(@NonNull PlatformViewCreationRequest request) {
          createFlutterPlatformView(request);
        }

        @Override
        public void dispose(int viewId) {
          viewsWithPendingSurfaceCallback.remove(viewId);
          final PlatformView platformView = platformViews.get(viewId);
          if (platformView == null) {
            Log.e(TAG, "Disposing unknown platform view with id: " + viewId);
            return;
          }
          if (platformView.getView() != null) {
            final View embeddedView = platformView.getView();
            final ViewGroup pvParent = (ViewGroup) embeddedView.getParent();
            if (pvParent != null) {
              // Eagerly remove the embedded view from the PlatformViewWrapper.
              // Without this call, we see some crashes because removing the view
              // is used as a signal to stop processing.
              pvParent.removeView(embeddedView);
            }
          }
          platformViews.remove(viewId);
          try {
            platformView.dispose();
          } catch (RuntimeException exception) {
            Log.e(TAG, "Disposing platform view threw an exception", exception);
          }

          // The platform view is displayed using a PlatformViewLayer.
          final FlutterMutatorView parentView = platformViewParent.get(viewId);
          if (parentView != null) {
            parentView.removeAllViews();
            parentView.unsetOnDescendantFocusChangeListener();

            final ViewGroup mutatorViewParent = (ViewGroup) parentView.getParent();
            if (mutatorViewParent != null) {
              mutatorViewParent.removeView(parentView);
            }
            platformViewParent.remove(viewId);
          }
        }

        @Override
        public void onTouch(@NonNull PlatformViewTouch touch) {
          final int viewId = touch.viewId;
          final float density = context.getResources().getDisplayMetrics().density;

          final PlatformView platformView = platformViews.get(viewId);
          if (platformView == null) {
            Log.e(TAG, "Sending touch to an unknown view with id: " + viewId);
            return;
          }
          final View view = platformView.getView();
          if (view == null) {
            Log.e(TAG, "Sending touch to a null view with id: " + viewId);
            return;
          }
          final MotionEvent event = toMotionEvent(density, touch);
          view.dispatchTouchEvent(event);
        }

        @Override
        public void setDirection(int viewId, int direction) {
          final PlatformView platformView = platformViews.get(viewId);
          if (platformView == null) {
            Log.e(TAG, "Setting direction to an unknown view with id: " + viewId);
            return;
          }
          View embeddedView = platformView.getView();
          if (embeddedView == null) {
            Log.e(TAG, "Setting direction to a null view with id: " + viewId);
            return;
          }
          embeddedView.setLayoutDirection(direction);
        }

        @Override
        public void clearFocus(int viewId) {
          final PlatformView platformView = platformViews.get(viewId);
          if (platformView == null) {
            Log.e(TAG, "Clearing focus on an unknown view with id: " + viewId);
            return;
          }
          View embeddedView = platformView.getView();
          if (embeddedView == null) {
            Log.e(TAG, "Clearing focus on a null view with id: " + viewId);
            return;
          }
          embeddedView.clearFocus();
        }

        @Override
        public void onRejectGesture(int viewId, long gestureId) {
          final MotionEvent event =
              motionEventTracker.peek(MotionEventTracker.MotionEventId.from(gestureId));
          if (event == null) {
            return;
          }
          final FlutterMutatorView parentView = platformViewParent.get(viewId);
          if (parentView != null) {
            parentView.onFlutterWonGesture(event.getDownTime());
          }
        }

        @Override
        public boolean isSurfaceControlEnabled() {
          return isHcppEnabled();
        }
      };
}
