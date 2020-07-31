// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugin.platform;

import static android.view.MotionEvent.PointerCoords;
import static android.view.MotionEvent.PointerProperties;

import android.annotation.TargetApi;
import android.content.Context;
import android.os.Build;
import android.util.DisplayMetrics;
import android.util.Log;
import android.util.SparseArray;
import android.view.MotionEvent;
import android.view.View;
import android.widget.FrameLayout;
import androidx.annotation.NonNull;
import androidx.annotation.UiThread;
import androidx.annotation.VisibleForTesting;
import io.flutter.embedding.android.AndroidTouchProcessor;
import io.flutter.embedding.android.FlutterImageView;
import io.flutter.embedding.android.FlutterView;
import io.flutter.embedding.android.MotionEventTracker;
import io.flutter.embedding.engine.FlutterOverlaySurface;
import io.flutter.embedding.engine.dart.DartExecutor;
import io.flutter.embedding.engine.mutatorsstack.*;
import io.flutter.embedding.engine.renderer.FlutterRenderer;
import io.flutter.embedding.engine.systemchannels.PlatformViewsChannel;
import io.flutter.plugin.editing.TextInputPlugin;
import io.flutter.view.AccessibilityBridge;
import io.flutter.view.TextureRegistry;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;

/**
 * Manages platform views.
 *
 * <p>Each {@link io.flutter.app.FlutterPluginRegistry} has a single platform views controller. A
 * platform views controller can be attached to at most one Flutter view.
 */
public class PlatformViewsController implements PlatformViewsAccessibilityDelegate {
  private static final String TAG = "PlatformViewsController";

  private final PlatformViewRegistryImpl registry;

  private AndroidTouchProcessor androidTouchProcessor;

  // The context of the Activity or Fragment hosting the render target for the Flutter engine.
  private Context context;

  // The View currently rendering the Flutter UI associated with these platform views.
  // TODO(egarciad): Investigate if this can be downcasted to `FlutterView`.
  private View flutterView;

  // The texture registry maintaining the textures into which the embedded views will be rendered.
  private TextureRegistry textureRegistry;

  private TextInputPlugin textInputPlugin;

  // The system channel used to communicate with the framework about platform views.
  private PlatformViewsChannel platformViewsChannel;

  // The accessibility bridge to which accessibility events form the platform views will be
  // dispatched.
  private final AccessibilityEventsDelegate accessibilityEventsDelegate;

  // TODO(mattcarroll): Refactor overall platform views to facilitate testing and then make
  // this private. This is visible as a hack to facilitate testing. This was deemed the least
  // bad option at the time of writing.
  @VisibleForTesting /* package */ final HashMap<Integer, VirtualDisplayController> vdControllers;

  // Maps a virtual display's context to the platform view hosted in this virtual display.
  // Since each virtual display has it's unique context this allows associating any view with the
  // platform view that
  // it is associated with(e.g if a platform view creates other views in the same virtual display.
  private final HashMap<Context, View> contextToPlatformView;

  private final SparseArray<PlatformViewsChannel.PlatformViewCreationRequest> platformViewRequests;
  private final SparseArray<View> platformViews;
  private final SparseArray<FlutterMutatorView> mutatorViews;

  // Map of unique IDs to views that render overlay layers.
  private final SparseArray<FlutterImageView> overlayLayerViews;

  // Next available unique ID for use in overlayLayerViews.
  private int nextOverlayLayerId = 0;

  // Tracks whether the flutterView has been converted to use a FlutterImageView.
  private boolean flutterViewConvertedToImageView = false;

  // Overlay layer IDs that were displayed since the start of the current frame.
  private HashSet<Integer> currentFrameUsedOverlayLayerIds;

  // Platform view IDs that were displayed since the start of the current frame.
  private HashSet<Integer> currentFrameUsedPlatformViewIds;

  // Used to acquire the original motion events using the motionEventIds.
  private final MotionEventTracker motionEventTracker;

  private final PlatformViewsChannel.PlatformViewsHandler channelHandler =
      new PlatformViewsChannel.PlatformViewsHandler() {

        @Override
        public void createAndroidViewForPlatformView(
            @NonNull PlatformViewsChannel.PlatformViewCreationRequest request) {
          // API level 19 is required for android.graphics.ImageReader.
          ensureValidAndroidVersion(Build.VERSION_CODES.KITKAT);
          platformViewRequests.put(request.viewId, request);
        }

        @Override
        public void disposeAndroidViewForPlatformView(int viewId) {
          // Hybrid view.
          if (platformViewRequests.get(viewId) != null) {
            platformViewRequests.remove(viewId);
          }

          final View platformView = platformViews.get(viewId);
          if (platformView != null) {
            final FlutterMutatorView mutatorView = mutatorViews.get(viewId);
            mutatorView.removeView(platformView);
            ((FlutterView) flutterView).removeView(mutatorView);
            platformViews.remove(viewId);
            mutatorViews.remove(viewId);
          }
        }

        @TargetApi(Build.VERSION_CODES.JELLY_BEAN_MR1)
        @Override
        public long createVirtualDisplayForPlatformView(
            @NonNull PlatformViewsChannel.PlatformViewCreationRequest request) {
          // API level 20 is required for VirtualDisplay#setSurface which we use when resizing a
          // platform view.
          ensureValidAndroidVersion(Build.VERSION_CODES.KITKAT_WATCH);
          if (!validateDirection(request.direction)) {
            throw new IllegalStateException(
                "Trying to create a view with unknown direction value: "
                    + request.direction
                    + "(view id: "
                    + request.viewId
                    + ")");
          }

          if (vdControllers.containsKey(request.viewId)) {
            throw new IllegalStateException(
                "Trying to create an already created platform view, view id: " + request.viewId);
          }

          PlatformViewFactory viewFactory = registry.getFactory(request.viewType);
          if (viewFactory == null) {
            throw new IllegalStateException(
                "Trying to create a platform view of unregistered type: " + request.viewType);
          }

          Object createParams = null;
          if (request.params != null) {
            createParams = viewFactory.getCreateArgsCodec().decodeMessage(request.params);
          }

          int physicalWidth = toPhysicalPixels(request.logicalWidth);
          int physicalHeight = toPhysicalPixels(request.logicalHeight);
          validateVirtualDisplayDimensions(physicalWidth, physicalHeight);

          TextureRegistry.SurfaceTextureEntry textureEntry = textureRegistry.createSurfaceTexture();
          VirtualDisplayController vdController =
              VirtualDisplayController.create(
                  context,
                  accessibilityEventsDelegate,
                  viewFactory,
                  textureEntry,
                  physicalWidth,
                  physicalHeight,
                  request.viewId,
                  createParams,
                  (view, hasFocus) -> {
                    if (hasFocus) {
                      platformViewsChannel.invokeViewFocused(request.viewId);
                    }
                  });

          if (vdController == null) {
            throw new IllegalStateException(
                "Failed creating virtual display for a "
                    + request.viewType
                    + " with id: "
                    + request.viewId);
          }

          // If our FlutterEngine is already attached to a Flutter UI, provide that Android
          // View to this new platform view.
          if (flutterView != null) {
            vdController.onFlutterViewAttached(flutterView);
          }

          vdControllers.put(request.viewId, vdController);
          View platformView = vdController.getView();
          platformView.setLayoutDirection(request.direction);
          contextToPlatformView.put(platformView.getContext(), platformView);

          // TODO(amirh): copy accessibility nodes to the FlutterView's accessibility tree.

          return textureEntry.id();
        }

        @Override
        public void disposeVirtualDisplayForPlatformView(int viewId) {
          ensureValidAndroidVersion(Build.VERSION_CODES.KITKAT_WATCH);
          VirtualDisplayController vdController = vdControllers.get(viewId);
          if (vdController == null) {
            throw new IllegalStateException(
                "Trying to dispose a platform view with unknown id: " + viewId);
          }

          if (textInputPlugin != null) {
            textInputPlugin.clearPlatformViewClient(viewId);
          }

          contextToPlatformView.remove(vdController.getView().getContext());
          vdController.dispose();
          vdControllers.remove(viewId);
        }

        @Override
        public void resizePlatformView(
            @NonNull PlatformViewsChannel.PlatformViewResizeRequest request,
            @NonNull Runnable onComplete) {
          ensureValidAndroidVersion(Build.VERSION_CODES.KITKAT_WATCH);

          final VirtualDisplayController vdController = vdControllers.get(request.viewId);
          if (vdController == null) {
            throw new IllegalStateException(
                "Trying to resize a platform view with unknown id: " + request.viewId);
          }

          int physicalWidth = toPhysicalPixels(request.newLogicalWidth);
          int physicalHeight = toPhysicalPixels(request.newLogicalHeight);
          validateVirtualDisplayDimensions(physicalWidth, physicalHeight);

          // Resizing involved moving the platform view to a new virtual display. Doing so
          // potentially results in losing an active input connection. To make sure we preserve
          // the input connection when resizing we lock it here and unlock after the resize is
          // complete.
          lockInputConnection(vdController);
          vdController.resize(
              physicalWidth,
              physicalHeight,
              new Runnable() {
                @Override
                public void run() {
                  unlockInputConnection(vdController);
                  onComplete.run();
                }
              });
        }

        @Override
        public void onTouch(@NonNull PlatformViewsChannel.PlatformViewTouch touch) {
          final int viewId = touch.viewId;
          float density = context.getResources().getDisplayMetrics().density;
          ensureValidAndroidVersion(Build.VERSION_CODES.KITKAT_WATCH);
          if (vdControllers.containsKey(viewId)) {
            final MotionEvent event = toMotionEvent(density, touch, /*usingVirtualDiplays=*/ true);
            vdControllers.get(touch.viewId).dispatchTouchEvent(event);
          } else if (platformViews.get(viewId) != null) {
            final MotionEvent event = toMotionEvent(density, touch, /*usingVirtualDiplays=*/ false);
            View view = platformViews.get(touch.viewId);
            view.dispatchTouchEvent(event);
          } else {
            throw new IllegalStateException("Sending touch to an unknown view with id: " + viewId);
          }
        }

        @TargetApi(Build.VERSION_CODES.JELLY_BEAN_MR1)
        @Override
        public void setDirection(int viewId, int direction) {
          if (!validateDirection(direction)) {
            throw new IllegalStateException(
                "Trying to set unknown direction value: "
                    + direction
                    + "(view id: "
                    + viewId
                    + ")");
          }

          ensureValidAndroidVersion(Build.VERSION_CODES.KITKAT_WATCH);
          View view = vdControllers.get(viewId).getView();
          if (view == null) {
            throw new IllegalStateException(
                "Sending touch to an unknown view with id: " + direction);
          }

          view.setLayoutDirection(direction);
        }

        @Override
        public void clearFocus(int viewId) {
          ensureValidAndroidVersion(Build.VERSION_CODES.KITKAT_WATCH);
          View view = vdControllers.get(viewId).getView();
          view.clearFocus();
        }

        private void ensureValidAndroidVersion(int minSdkVersion) {
          if (Build.VERSION.SDK_INT < minSdkVersion) {
            throw new IllegalStateException(
                "Trying to use platform views with API "
                    + Build.VERSION.SDK_INT
                    + ", required API level is: "
                    + minSdkVersion);
          }
        }
      };

  @VisibleForTesting
  public MotionEvent toMotionEvent(
      float density, PlatformViewsChannel.PlatformViewTouch touch, boolean usingVirtualDiplays) {
    MotionEventTracker.MotionEventId motionEventId =
        MotionEventTracker.MotionEventId.from(touch.motionEventId);
    MotionEvent trackedEvent = motionEventTracker.pop(motionEventId);

    // Pointer coordinates in the tracked events are global to FlutterView
    // framework converts them to be local to a widget, given that
    // motion events operate on local coords, we need to replace these in the tracked
    // event with their local counterparts.
    PointerProperties[] pointerProperties =
        parsePointerPropertiesList(touch.rawPointerPropertiesList)
            .toArray(new PointerProperties[touch.pointerCount]);
    PointerCoords[] pointerCoords =
        parsePointerCoordsList(touch.rawPointerCoords, density)
            .toArray(new PointerCoords[touch.pointerCount]);

    if (!usingVirtualDiplays && trackedEvent != null) {
      return MotionEvent.obtain(
          trackedEvent.getDownTime(),
          trackedEvent.getEventTime(),
          trackedEvent.getAction(),
          touch.pointerCount,
          pointerProperties,
          pointerCoords,
          trackedEvent.getMetaState(),
          trackedEvent.getButtonState(),
          trackedEvent.getXPrecision(),
          trackedEvent.getYPrecision(),
          trackedEvent.getDeviceId(),
          trackedEvent.getEdgeFlags(),
          trackedEvent.getSource(),
          trackedEvent.getFlags());
    }

    // TODO (kaushikiska) : warn that we are potentially using an untracked
    // event in the platform views.
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

  public PlatformViewsController() {
    registry = new PlatformViewRegistryImpl();
    vdControllers = new HashMap<>();
    accessibilityEventsDelegate = new AccessibilityEventsDelegate();
    contextToPlatformView = new HashMap<>();
    overlayLayerViews = new SparseArray<>();
    currentFrameUsedOverlayLayerIds = new HashSet<>();
    currentFrameUsedPlatformViewIds = new HashSet<>();

    platformViewRequests = new SparseArray<>();
    platformViews = new SparseArray<>();
    mutatorViews = new SparseArray<>();

    motionEventTracker = MotionEventTracker.getInstance();
  }

  /**
   * Attaches this platform views controller to its input and output channels.
   *
   * @param context The base context that will be passed to embedded views created by this
   *     controller. This should be the context of the Activity hosting the Flutter application.
   * @param textureRegistry The texture registry which provides the output textures into which the
   *     embedded views will be rendered.
   * @param dartExecutor The dart execution context, which is used to setup a system channel.
   */
  public void attach(
      Context context, TextureRegistry textureRegistry, @NonNull DartExecutor dartExecutor) {
    if (this.context != null) {
      throw new AssertionError(
          "A PlatformViewsController can only be attached to a single output target.\n"
              + "attach was called while the PlatformViewsController was already attached.");
    }
    this.context = context;
    this.textureRegistry = textureRegistry;
    platformViewsChannel = new PlatformViewsChannel(dartExecutor);
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
    platformViewsChannel.setPlatformViewsHandler(null);
    platformViewsChannel = null;
    context = null;
    textureRegistry = null;
  }

  /**
   * This {@code PlatformViewsController} and its {@code FlutterEngine} is now attached to an
   * Android {@code View} that renders a Flutter UI.
   */
  public void attachToView(@NonNull View flutterView) {
    this.flutterView = flutterView;

    // Inform all existing platform views that they are now associated with
    // a Flutter View.
    for (VirtualDisplayController controller : vdControllers.values()) {
      controller.onFlutterViewAttached(flutterView);
    }
  }

  /**
   * This {@code PlatformViewController} and its {@code FlutterEngine} are no longer attached to an
   * Android {@code View} that renders a Flutter UI.
   *
   * <p>All platform views controlled by this {@code PlatformViewController} will be detached from
   * the previously attached {@code View}.
   */
  public void detachFromView() {
    this.flutterView = null;

    // Inform all existing platform views that they are no longer associated with
    // a Flutter View.
    for (VirtualDisplayController controller : vdControllers.values()) {
      controller.onFlutterViewDetached();
    }
  }

  @Override
  public void attachAccessibilityBridge(AccessibilityBridge accessibilityBridge) {
    accessibilityEventsDelegate.setAccessibilityBridge(accessibilityBridge);
  }

  @Override
  public void detachAccessibiltyBridge() {
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
  public void attachTextInputPlugin(TextInputPlugin textInputPlugin) {
    this.textInputPlugin = textInputPlugin;
  }

  /** Detaches this controller from the currently attached text input plugin. */
  public void detachTextInputPlugin() {
    textInputPlugin = null;
  }

  /**
   * Returns true if Flutter should perform input connection proxying for the view.
   *
   * <p>If the view is a platform view managed by this platform views controller returns true. Else
   * if the view was created in a platform view's VD, delegates the decision to the platform view's
   * {@link View#checkInputConnectionProxy(View)} method. Else returns false.
   */
  public boolean checkInputConnectionProxy(View view) {
    if (!contextToPlatformView.containsKey(view.getContext())) {
      return false;
    }
    View platformView = contextToPlatformView.get(view.getContext());
    if (platformView == view) {
      return true;
    }
    return platformView.checkInputConnectionProxy(view);
  }

  public PlatformViewRegistry getRegistry() {
    return registry;
  }

  /**
   * Invoked when the {@link io.flutter.embedding.engine.FlutterEngine} that owns this {@link
   * PlatformViewsController} attaches to JNI.
   */
  public void onAttachedToJNI() {
    // Currently no action needs to be taken after JNI attachment.
  }

  /**
   * Invoked when the {@link io.flutter.embedding.engine.FlutterEngine} that owns this {@link
   * PlatformViewsController} detaches from JNI.
   */
  public void onDetachedFromJNI() {
    // Dispose all virtual displays so that any future updates to textures will not be
    // propagated to the native peer.
    flushAllViews();
  }

  public void onPreEngineRestart() {
    flushAllViews();
  }

  @Override
  public View getPlatformViewById(Integer id) {
    // Hybrid composition.
    if (platformViews.get(id) != null) {
      return platformViews.get(id);
    }
    VirtualDisplayController controller = vdControllers.get(id);
    if (controller == null) {
      return null;
    }
    return controller.getView();
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
    coords.toolMajor = (float) (double) coordsList.get(3) * density;
    coords.toolMinor = (float) (double) coordsList.get(4) * density;
    coords.touchMajor = (float) (double) coordsList.get(5) * density;
    coords.touchMinor = (float) (double) coordsList.get(6) * density;
    coords.x = (float) (double) coordsList.get(7) * density;
    coords.y = (float) (double) coordsList.get(8) * density;
    return coords;
  }

  // Creating a VirtualDisplay larger than the size of the device screen size
  // could cause the device to restart: https://github.com/flutter/flutter/issues/28978
  private void validateVirtualDisplayDimensions(int width, int height) {
    DisplayMetrics metrics = context.getResources().getDisplayMetrics();
    if (height > metrics.heightPixels || width > metrics.widthPixels) {
      String message =
          "Creating a virtual display of size: "
              + "["
              + width
              + ", "
              + height
              + "] may result in problems"
              + "(https://github.com/flutter/flutter/issues/2897)."
              + "It is larger than the device screen size: "
              + "["
              + metrics.widthPixels
              + ", "
              + metrics.heightPixels
              + "].";
      Log.w(TAG, message);
    }
  }

  private float getDisplayDensity() {
    return context.getResources().getDisplayMetrics().density;
  }

  private int toPhysicalPixels(double logicalPixels) {
    return (int) Math.round(logicalPixels * getDisplayDensity());
  }

  private void flushAllViews() {
    for (VirtualDisplayController controller : vdControllers.values()) {
      controller.dispose();
    }
    vdControllers.clear();
  }

  private void initializeRootImageViewIfNeeded() {
    if (!flutterViewConvertedToImageView) {
      ((FlutterView) flutterView).convertToImageView();
      flutterViewConvertedToImageView = true;
    }
  }

  @VisibleForTesting
  void initializePlatformViewIfNeeded(int viewId) {
    if (platformViews.get(viewId) != null) {
      return;
    }

    PlatformViewsChannel.PlatformViewCreationRequest request = platformViewRequests.get(viewId);
    if (request == null) {
      throw new IllegalStateException(
          "Platform view hasn't been initialized from the platform view channel.");
    }

    if (!validateDirection(request.direction)) {
      throw new IllegalStateException(
          "Trying to create a view with unknown direction value: "
              + request.direction
              + "(view id: "
              + viewId
              + ")");
    }

    PlatformViewFactory factory = registry.getFactory(request.viewType);
    if (factory == null) {
      throw new IllegalStateException(
          "Trying to create a platform view of unregistered type: " + request.viewType);
    }

    Object createParams = null;
    if (request.params != null) {
      createParams = factory.getCreateArgsCodec().decodeMessage(request.params);
    }

    PlatformView platformView = factory.create(context, viewId, createParams);
    View view = platformView.getView();

    if (view == null) {
      throw new IllegalStateException(
          "PlatformView#getView() returned null, but an Android view reference was expected.");
    }
    if (view.getParent() != null) {
      throw new IllegalStateException(
          "The Android view returned from PlatformView#getView() was already added to a parent view.");
    }
    platformViews.put(viewId, view);

    FlutterMutatorView mutatorView =
        new FlutterMutatorView(
            context, context.getResources().getDisplayMetrics().density, androidTouchProcessor);
    mutatorViews.put(viewId, mutatorView);
    mutatorView.addView(view);
    ((FlutterView) flutterView).addView(mutatorView);
  }

  public void attachToFlutterRenderer(FlutterRenderer flutterRenderer) {
    androidTouchProcessor = new AndroidTouchProcessor(flutterRenderer, /*trackMotionEvents=*/ true);
  }

  public void onDisplayPlatformView(
      int viewId,
      int x,
      int y,
      int width,
      int height,
      int viewWidth,
      int viewHeight,
      FlutterMutatorsStack mutatorsStack) {
    initializeRootImageViewIfNeeded();
    initializePlatformViewIfNeeded(viewId);

    FlutterMutatorView mutatorView = mutatorViews.get(viewId);
    mutatorView.readyToDisplay(mutatorsStack, x, y, width, height);
    mutatorView.setVisibility(View.VISIBLE);
    mutatorView.bringToFront();

    FrameLayout.LayoutParams layoutParams = new FrameLayout.LayoutParams(viewWidth, viewHeight);
    View platformView = platformViews.get(viewId);
    platformView.setLayoutParams(layoutParams);
    platformView.bringToFront();
    currentFrameUsedPlatformViewIds.add(viewId);
  }

  public void onDisplayOverlaySurface(int id, int x, int y, int width, int height) {
    initializeRootImageViewIfNeeded();

    FlutterImageView overlayView = overlayLayerViews.get(id);
    if (overlayView.getParent() == null) {
      ((FlutterView) flutterView).addView(overlayView);
    }

    FrameLayout.LayoutParams layoutParams = new FrameLayout.LayoutParams((int) width, (int) height);
    layoutParams.leftMargin = (int) x;
    layoutParams.topMargin = (int) y;
    overlayView.setLayoutParams(layoutParams);
    overlayView.setVisibility(View.VISIBLE);
    overlayView.bringToFront();
    currentFrameUsedOverlayLayerIds.add(id);
  }

  public void onBeginFrame() {
    currentFrameUsedOverlayLayerIds.clear();
    currentFrameUsedPlatformViewIds.clear();
  }

  public void onEndFrame() {
    final FlutterView view = (FlutterView) flutterView;
    // If there are no platform views in the current frame,
    // then revert the image view surface and use the previous surface.
    //
    // Otherwise, acquire the latest image.
    if (flutterViewConvertedToImageView && currentFrameUsedPlatformViewIds.isEmpty()) {
      flutterViewConvertedToImageView = false;
      view.revertImageView(
          () -> {
            // Destroy overlay surfaces once the surface reversion is completed.
            finishFrame(false);
          });
      return;
    }
    // Whether the current frame was rendered using ImageReaders.
    //
    // Since the image readers may not have images available at this point,
    // this becomes true if all the required surfaces have images available.
    //
    // This is used to decide if the platform views can be rendered in the current frame.
    // If one of the surfaces doesn't have an image, the frame may be incomplete and must be
    // dropped.
    // For example, a toolbar widget painted by Flutter may not be rendered.
    boolean isFrameRenderedUsingImageReaders =
        flutterViewConvertedToImageView && view.acquireLatestImageViewFrame();
    finishFrame(isFrameRenderedUsingImageReaders);
  }

  private void finishFrame(boolean isFrameRenderedUsingImageReaders) {
    for (int i = 0; i < overlayLayerViews.size(); i++) {
      int overlayId = overlayLayerViews.keyAt(i);
      FlutterImageView overlayView = overlayLayerViews.valueAt(i);

      if (currentFrameUsedOverlayLayerIds.contains(overlayId)) {
        ((FlutterView) flutterView).attachOverlaySurfaceToRender(overlayView);
        boolean didAcquireOverlaySurfaceImage = overlayView.acquireLatestImage();
        isFrameRenderedUsingImageReaders &= didAcquireOverlaySurfaceImage;
      } else {
        // If the background surface isn't rendered by the image view, then the
        // overlay surfaces can be detached from the rendered.
        // This releases resources used by the ImageReader.
        if (!flutterViewConvertedToImageView) {
          overlayView.detachFromRenderer();
        }
        // Hide overlay surfaces that aren't rendered in the current frame.
        overlayView.setVisibility(View.GONE);
      }
    }

    for (int i = 0; i < platformViews.size(); i++) {
      int viewId = platformViews.keyAt(i);
      View platformView = platformViews.get(viewId);
      View mutatorView = mutatorViews.get(viewId);

      // Show platform views only if the surfaces have images available in this frame,
      // and if the platform view is rendered in this frame.
      //
      // Otherwise, hide the platform view, but don't remove it from the view hierarchy yet as
      // they are removed when the framework diposes the platform view widget.
      if (isFrameRenderedUsingImageReaders && currentFrameUsedPlatformViewIds.contains(viewId)) {
        platformView.setVisibility(View.VISIBLE);
        mutatorView.setVisibility(View.VISIBLE);
      } else {
        platformView.setVisibility(View.GONE);
        mutatorView.setVisibility(View.GONE);
      }
    }
  }

  @VisibleForTesting
  @TargetApi(19)
  public FlutterOverlaySurface createOverlaySurface(@NonNull FlutterImageView imageView) {
    final int id = nextOverlayLayerId++;
    overlayLayerViews.put(id, imageView);
    return new FlutterOverlaySurface(id, imageView.getSurface());
  }

  @TargetApi(19)
  public FlutterOverlaySurface createOverlaySurface() {
    // Overlay surfaces have the same size as the background surface.
    //
    // This allows to reuse these surfaces in consecutive frames even
    // if the drawings they contain have a different tight bound.
    //
    // The final view size is determined when its frame is set.
    return createOverlaySurface(
        new FlutterImageView(
            flutterView.getContext(),
            flutterView.getWidth(),
            flutterView.getHeight(),
            FlutterImageView.SurfaceKind.overlay));
  }

  public void destroyOverlaySurfaces() {
    for (int i = 0; i < overlayLayerViews.size(); i++) {
      int overlayId = overlayLayerViews.keyAt(i);
      FlutterImageView overlayView = overlayLayerViews.valueAt(i);
      overlayView.detachFromRenderer();
      ((FlutterView) flutterView).removeView(overlayView);
    }
    overlayLayerViews.clear();
  }
}
