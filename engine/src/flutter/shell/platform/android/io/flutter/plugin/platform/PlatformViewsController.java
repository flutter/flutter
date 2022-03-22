// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugin.platform;

import static android.view.MotionEvent.PointerCoords;
import static android.view.MotionEvent.PointerProperties;

import android.annotation.TargetApi;
import android.content.Context;
import android.os.Build;
import android.util.SparseArray;
import android.view.MotionEvent;
import android.view.View;
import android.view.ViewGroup;
import android.widget.FrameLayout;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.annotation.UiThread;
import androidx.annotation.VisibleForTesting;
import io.flutter.Log;
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
import java.util.HashSet;
import java.util.List;

/**
 * Manages platform views.
 *
 * <p>Each {@link io.flutter.embedding.engine.FlutterEngine} or {@link
 * io.flutter.app.FlutterPluginRegistry} has a single platform views controller. A platform views
 * controller can be attached to at most one Flutter view.
 */
public class PlatformViewsController implements PlatformViewsAccessibilityDelegate {
  private static final String TAG = "PlatformViewsController";

  private final PlatformViewRegistryImpl registry;

  private AndroidTouchProcessor androidTouchProcessor;

  // The context of the Activity or Fragment hosting the render target for the Flutter engine.
  private Context context;

  // The View currently rendering the Flutter UI associated with these platform views.
  private FlutterView flutterView;

  // The texture registry maintaining the textures into which the embedded views will be rendered.
  @Nullable private TextureRegistry textureRegistry;

  @Nullable private TextInputPlugin textInputPlugin;

  // The system channel used to communicate with the framework about platform views.
  private PlatformViewsChannel platformViewsChannel;

  // The accessibility bridge to which accessibility events form the platform views will be
  // dispatched.
  private final AccessibilityEventsDelegate accessibilityEventsDelegate;

  // The platform views.
  private final SparseArray<PlatformView> platformViews;

  // The platform view parents that are appended to `FlutterView`.
  // If an entry in `platformViews` doesn't have an entry in this array, the platform view isn't
  // in the view hierarchy.
  //
  // This view provides a wrapper that applies scene builder operations to the platform view.
  // For example, a transform matrix, or setting opacity on the platform view layer.
  //
  // This is only applies to hybrid composition (PlatformViewLayer render).
  // TODO(egarciad): Eliminate this.
  // https://github.com/flutter/flutter/issues/96679
  private final SparseArray<FlutterMutatorView> platformViewParent;

  // Map of unique IDs to views that render overlay layers.
  private final SparseArray<FlutterImageView> overlayLayerViews;

  // View wrappers are FrameLayouts that contain a single child view.
  // This child view is the platform view.
  // This only applies to hybrid composition (TextureLayer render).
  private final SparseArray<PlatformViewWrapper> viewWrappers;

  // Next available unique ID for use in overlayLayerViews.
  private int nextOverlayLayerId = 0;

  // Tracks whether the flutterView has been converted to use a FlutterImageView.
  private boolean flutterViewConvertedToImageView = false;

  // When adding platform views using Hybrid Composition, the engine converts the render surface
  // to a FlutterImageView to help improve animation synchronization on Android. This flag allows
  // disabling this conversion through the PlatformView platform channel.
  private boolean synchronizeToNativeViewHierarchy = true;

  // Overlay layer IDs that were displayed since the start of the current frame.
  private final HashSet<Integer> currentFrameUsedOverlayLayerIds;

  // Platform view IDs that were displayed since the start of the current frame.
  private final HashSet<Integer> currentFrameUsedPlatformViewIds;

  // Used to acquire the original motion events using the motionEventIds.
  private final MotionEventTracker motionEventTracker;

  // Whether software rendering is used.
  private boolean usesSoftwareRendering = false;

  private final PlatformViewsChannel.PlatformViewsHandler channelHandler =
      new PlatformViewsChannel.PlatformViewsHandler() {

        @TargetApi(Build.VERSION_CODES.KITKAT)
        @Override
        // TODO(egarciad): Remove the need for this.
        // https://github.com/flutter/flutter/issues/96679
        public void createForPlatformViewLayer(
            @NonNull PlatformViewsChannel.PlatformViewCreationRequest request) {
          // API level 19 is required for `android.graphics.ImageReader`.
          ensureValidAndroidVersion(Build.VERSION_CODES.KITKAT);

          if (!validateDirection(request.direction)) {
            throw new IllegalStateException(
                "Trying to create a view with unknown direction value: "
                    + request.direction
                    + "(view id: "
                    + request.viewId
                    + ")");
          }

          final PlatformViewFactory factory = registry.getFactory(request.viewType);
          if (factory == null) {
            throw new IllegalStateException(
                "Trying to create a platform view of unregistered type: " + request.viewType);
          }

          Object createParams = null;
          if (request.params != null) {
            createParams = factory.getCreateArgsCodec().decodeMessage(request.params);
          }

          final PlatformView platformView = factory.create(context, request.viewId, createParams);
          platformView.getView().setLayoutDirection(request.direction);
          platformViews.put(request.viewId, platformView);
        }

        @TargetApi(Build.VERSION_CODES.M)
        @Override
        public long createForTextureLayer(
            @NonNull PlatformViewsChannel.PlatformViewCreationRequest request) {
          final int viewId = request.viewId;
          if (viewWrappers.get(viewId) != null) {
            throw new IllegalStateException(
                "Trying to create an already created platform view, view id: " + viewId);
          }
          if (!validateDirection(request.direction)) {
            throw new IllegalStateException(
                "Trying to create a view with unknown direction value: "
                    + request.direction
                    + "(view id: "
                    + viewId
                    + ")");
          }
          if (textureRegistry == null) {
            throw new IllegalStateException(
                "Texture registry is null. This means that platform views controller was detached, view id: "
                    + viewId);
          }
          if (flutterView == null) {
            throw new IllegalStateException(
                "Flutter view is null. This means the platform views controller doesn't have an attached view, view id: "
                    + viewId);
          }
          final PlatformViewFactory viewFactory = registry.getFactory(request.viewType);
          if (viewFactory == null) {
            throw new IllegalStateException(
                "Trying to create a platform view of unregistered type: " + request.viewType);
          }
          Object createParams = null;
          if (request.params != null) {
            createParams = viewFactory.getCreateArgsCodec().decodeMessage(request.params);
          }

          final PlatformView platformView = viewFactory.create(context, viewId, createParams);
          platformViews.put(viewId, platformView);

          PlatformViewWrapper wrapperView;
          long txId;
          if (usesSoftwareRendering) {
            wrapperView = new PlatformViewWrapper(context);
            txId = -1;
          } else {
            final TextureRegistry.SurfaceTextureEntry textureEntry =
                textureRegistry.createSurfaceTexture();
            wrapperView = new PlatformViewWrapper(context, textureEntry);
            txId = textureEntry.id();
          }
          wrapperView.setTouchProcessor(androidTouchProcessor);

          final int physicalWidth = toPhysicalPixels(request.logicalWidth);
          final int physicalHeight = toPhysicalPixels(request.logicalHeight);
          wrapperView.setBufferSize(physicalWidth, physicalHeight);

          final FrameLayout.LayoutParams layoutParams =
              new FrameLayout.LayoutParams(physicalWidth, physicalHeight);

          final int physicalTop = toPhysicalPixels(request.logicalTop);
          final int physicalLeft = toPhysicalPixels(request.logicalLeft);
          layoutParams.topMargin = physicalTop;
          layoutParams.leftMargin = physicalLeft;
          wrapperView.setLayoutParams(layoutParams);
          wrapperView.setLayoutDirection(request.direction);

          final View view = platformView.getView();
          if (view == null) {
            throw new IllegalStateException(
                "PlatformView#getView() returned null, but an Android view reference was expected.");
          } else if (view.getParent() != null) {
            throw new IllegalStateException(
                "The Android view returned from PlatformView#getView() was already added to a parent view.");
          }
          wrapperView.addView(view);
          wrapperView.setOnDescendantFocusChangeListener(
              (v, hasFocus) -> {
                if (hasFocus) {
                  platformViewsChannel.invokeViewFocused(viewId);
                } else if (textInputPlugin != null) {
                  textInputPlugin.clearPlatformViewClient(viewId);
                }
              });

          flutterView.addView(wrapperView);
          viewWrappers.append(viewId, wrapperView);
          return txId;
        }

        @Override
        public void dispose(int viewId) {
          final PlatformView platformView = platformViews.get(viewId);
          if (platformView != null) {
            platformViews.remove(viewId);
            platformView.dispose();
          }
          // The platform view is displayed using a TextureLayer.
          final PlatformViewWrapper viewWrapper = viewWrappers.get(viewId);
          if (viewWrapper != null) {
            viewWrapper.removeAllViews();
            viewWrapper.release();
            viewWrapper.unsetOnDescendantFocusChangeListener();

            final ViewGroup wrapperParent = (ViewGroup) viewWrapper.getParent();
            if (wrapperParent != null) {
              wrapperParent.removeView(viewWrapper);
            }
            viewWrappers.remove(viewId);
            return;
          }
          // The platform view is displayed using a PlatformViewLayer.
          // TODO(egarciad): Eliminate this case.
          // https://github.com/flutter/flutter/issues/96679
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
        public void offset(int viewId, double top, double left) {
          final PlatformViewWrapper wrapper = viewWrappers.get(viewId);
          if (wrapper == null) {
            Log.e(TAG, "Setting offset for unknown platform view with id: " + viewId);
            return;
          }
          final int physicalTop = toPhysicalPixels(top);
          final int physicalLeft = toPhysicalPixels(left);
          final FrameLayout.LayoutParams layoutParams =
              (FrameLayout.LayoutParams) wrapper.getLayoutParams();
          layoutParams.topMargin = physicalTop;
          layoutParams.leftMargin = physicalLeft;
          wrapper.setLayoutParams(layoutParams);
        }

        @Override
        public PlatformViewsChannel.PlatformViewBufferSize resize(
            @NonNull PlatformViewsChannel.PlatformViewResizeRequest request) {
          final int viewId = request.viewId;
          final PlatformViewWrapper view = viewWrappers.get(viewId);
          if (view == null) {
            Log.e(TAG, "Resizing unknown platform view with id: " + viewId);
            return null;
          }
          final int newWidth = toPhysicalPixels(request.newLogicalWidth);
          final int newHeight = toPhysicalPixels(request.newLogicalHeight);

          // Resize the buffer only when the current buffer size is smaller than the new size.
          // This is required to prevent a situation when smooth keyboard animation
          // resizes the texture too often, such that the GPU and the platform thread don't agree on
          // the
          // timing of the new size.
          // Resizing the texture causes pixel stretching since the size of the GL texture used in
          // the engine
          // is set by the framework, but the texture buffer size is set by the platform down below.
          if (newWidth > view.getBufferWidth() || newHeight > view.getBufferHeight()) {
            view.setBufferSize(newWidth, newHeight);
          }

          final FrameLayout.LayoutParams layoutParams =
              (FrameLayout.LayoutParams) view.getLayoutParams();
          layoutParams.width = newWidth;
          layoutParams.height = newHeight;
          view.setLayoutParams(layoutParams);

          return new PlatformViewsChannel.PlatformViewBufferSize(
              toLogicalPixels(view.getBufferWidth()), toLogicalPixels(view.getBufferHeight()));
        }

        @Override
        public void onTouch(@NonNull PlatformViewsChannel.PlatformViewTouch touch) {
          final int viewId = touch.viewId;
          final PlatformView platformView = platformViews.get(viewId);
          if (platformView == null) {
            Log.e(TAG, "Sending touch to an unknown view with id: " + viewId);
            return;
          }
          ensureValidAndroidVersion(Build.VERSION_CODES.KITKAT_WATCH);
          final float density = context.getResources().getDisplayMetrics().density;
          final MotionEvent event = toMotionEvent(density, touch);
          final View view = platformView.getView();
          if (view == null) {
            Log.e(TAG, "Sending touch to a null view with id: " + viewId);
            return;
          }
          view.dispatchTouchEvent(event);
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
          final PlatformView platformView = platformViews.get(viewId);
          if (platformView == null) {
            Log.e(TAG, "Setting direction to an unknown view with id: " + viewId);
            return;
          }
          ensureValidAndroidVersion(Build.VERSION_CODES.KITKAT_WATCH);
          final View view = platformView.getView();
          if (view == null) {
            Log.e(TAG, "Setting direction to a null view with id: " + viewId);
            return;
          }
          view.setLayoutDirection(direction);
        }

        @Override
        public void clearFocus(int viewId) {
          final PlatformView platformView = platformViews.get(viewId);
          if (platformView == null) {
            Log.e(TAG, "Clearing focus on an unknown view with id: " + viewId);
            return;
          }
          final View view = platformView.getView();
          if (view == null) {
            Log.e(TAG, "Clearing focus on a null view with id: " + viewId);
            return;
          }
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

        @Override
        public void synchronizeToNativeViewHierarchy(boolean yes) {
          synchronizeToNativeViewHierarchy = yes;
        }
      };

  @VisibleForTesting
  public MotionEvent toMotionEvent(float density, PlatformViewsChannel.PlatformViewTouch touch) {
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

    if (trackedEvent != null) {
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
    accessibilityEventsDelegate = new AccessibilityEventsDelegate();
    overlayLayerViews = new SparseArray<>();
    currentFrameUsedOverlayLayerIds = new HashSet<>();
    currentFrameUsedPlatformViewIds = new HashSet<>();
    viewWrappers = new SparseArray<>();
    platformViews = new SparseArray<>();
    platformViewParent = new SparseArray<>();

    motionEventTracker = MotionEventTracker.getInstance();
  }

  /**
   * Attaches this platform views controller to its input and output channels.
   *
   * @param context The base context that will be passed to embedded views created by this
   *     controller. This should be the context of the Activity hosting the Flutter application.
   * @param textureRegistry The texture registry which provides the output textures into which the
   *     embedded views will be rendered.
   * @param dartExecutor The dart execution context, which is used to set up a system channel.
   */
  public void attach(
      @Nullable Context context,
      @NonNull TextureRegistry textureRegistry,
      @NonNull DartExecutor dartExecutor) {
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
   * Sets whether Flutter uses software rendering.
   *
   * <p>When software rendering is used, no GL context is available on the raster thread. When this
   * is set to true, there's no Flutter composition of Android views and Flutter widgets since GL
   * textures cannot be used.
   *
   * <p>Software rendering is only used for testing in emulators, and it should never be set to true
   * in a production environment.
   *
   * @param useSoftwareRendering Whether software rendering is used.
   */
  public void setSoftwareRendering(boolean useSoftwareRendering) {
    usesSoftwareRendering = useSoftwareRendering;
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
    destroyOverlaySurfaces();
    platformViewsChannel = null;
    context = null;
    textureRegistry = null;
  }

  /**
   * This {@code PlatformViewsController} and its {@code FlutterEngine} is now attached to an
   * Android {@code View} that renders a Flutter UI.
   */
  public void attachToView(@NonNull FlutterView newFlutterView) {
    flutterView = newFlutterView;

    // Inform all existing platform views that they are now associated with
    // a Flutter View.
    for (int i = 0; i < platformViews.size(); i++) {
      final PlatformView view = platformViews.valueAt(i);
      view.onFlutterViewAttached(flutterView);
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
    for (int i = 0; i < platformViews.size(); i++) {
      final PlatformView view = platformViews.valueAt(i);
      view.onFlutterViewDetached();
    }
    // TODO(egarciad): Remove this.
    // https://github.com/flutter/flutter/issues/96679
    destroyOverlaySurfaces();
    removeOverlaySurfaces();
    flutterView = null;
    flutterViewConvertedToImageView = false;
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
    flushAllViews();
  }

  public void onPreEngineRestart() {
    flushAllViews();
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

  private float getDisplayDensity() {
    return context.getResources().getDisplayMetrics().density;
  }

  private int toPhysicalPixels(double logicalPixels) {
    return (int) Math.round(logicalPixels * getDisplayDensity());
  }

  private int toLogicalPixels(double physicalPixels) {
    return (int) Math.round(physicalPixels / getDisplayDensity());
  }

  private void flushAllViews() {
    while (platformViews.size() > 0) {
      channelHandler.dispose(platformViews.keyAt(0));
    }
  }

  private void initializeRootImageViewIfNeeded() {
    if (synchronizeToNativeViewHierarchy && !flutterViewConvertedToImageView) {
      flutterView.convertToImageView();
      flutterViewConvertedToImageView = true;
    }
  }

  /**
   * Initializes a platform view and adds it to the view hierarchy.
   *
   * @param viewId The view ID. This member is not intended for public use, and is only visible for
   *     testing.
   */
  @VisibleForTesting
  void initializePlatformViewIfNeeded(int viewId) {
    final PlatformView platformView = platformViews.get(viewId);
    if (platformView == null) {
      throw new IllegalStateException(
          "Platform view hasn't been initialized from the platform view channel.");
    }
    if (platformViewParent.get(viewId) != null) {
      return;
    }
    if (platformView.getView() == null) {
      throw new IllegalStateException(
          "PlatformView#getView() returned null, but an Android view reference was expected.");
    }
    if (platformView.getView().getParent() != null) {
      throw new IllegalStateException(
          "The Android view returned from PlatformView#getView() was already added to a parent view.");
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
    parentView.addView(platformView.getView());
    flutterView.addView(parentView);
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
  public void onDisplayPlatformView(
      int viewId,
      int x,
      int y,
      int width,
      int height,
      int viewWidth,
      int viewHeight,
      @NonNull FlutterMutatorsStack mutatorsStack) {
    initializeRootImageViewIfNeeded();
    initializePlatformViewIfNeeded(viewId);

    final FlutterMutatorView parentView = platformViewParent.get(viewId);
    parentView.readyToDisplay(mutatorsStack, x, y, width, height);
    parentView.setVisibility(View.VISIBLE);
    parentView.bringToFront();

    final FrameLayout.LayoutParams layoutParams =
        new FrameLayout.LayoutParams(viewWidth, viewHeight);
    final View view = platformViews.get(viewId).getView();
    if (view != null) {
      view.setLayoutParams(layoutParams);
      view.bringToFront();
    }
    currentFrameUsedPlatformViewIds.add(viewId);
  }

  /**
   * Called when an overlay surface is displayed in the current frame.
   *
   * @param id The ID of the surface.
   * @param x The left position relative to {@code FlutterView}.
   * @param y The top position relative to {@code FlutterView}.
   * @param width The width of the surface.
   * @param height The height of the surface. This member is not intended for public use, and is
   *     only visible for testing.
   */
  public void onDisplayOverlaySurface(int id, int x, int y, int width, int height) {
    if (overlayLayerViews.get(id) == null) {
      throw new IllegalStateException("The overlay surface (id:" + id + ") doesn't exist");
    }
    initializeRootImageViewIfNeeded();

    final FlutterImageView overlayView = overlayLayerViews.get(id);
    if (overlayView.getParent() == null) {
      flutterView.addView(overlayView);
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

  /**
   * Called by {@code FlutterJNI} when the Flutter frame was submitted.
   *
   * <p>This member is not intended for public use, and is only visible for testing.
   */
  public void onEndFrame() {
    // If there are no platform views in the current frame,
    // then revert the image view surface and use the previous surface.
    //
    // Otherwise, acquire the latest image.
    if (flutterViewConvertedToImageView && currentFrameUsedPlatformViewIds.isEmpty()) {
      flutterViewConvertedToImageView = false;
      flutterView.revertImageView(
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
    final boolean isFrameRenderedUsingImageReaders =
        flutterViewConvertedToImageView && flutterView.acquireLatestImageViewFrame();
    finishFrame(isFrameRenderedUsingImageReaders);
  }

  private void finishFrame(boolean isFrameRenderedUsingImageReaders) {
    for (int i = 0; i < overlayLayerViews.size(); i++) {
      final int overlayId = overlayLayerViews.keyAt(i);
      final FlutterImageView overlayView = overlayLayerViews.valueAt(i);

      if (currentFrameUsedOverlayLayerIds.contains(overlayId)) {
        flutterView.attachOverlaySurfaceToRender(overlayView);
        final boolean didAcquireOverlaySurfaceImage = overlayView.acquireLatestImage();
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

    for (int i = 0; i < platformViewParent.size(); i++) {
      final int viewId = platformViewParent.keyAt(i);
      final View parentView = platformViewParent.get(viewId);

      // This should only show platform views that are rendered in this frame and either:
      //  1. Surface has images available in this frame or,
      //  2. Surface does not have images available in this frame because the render surface should
      // not be an ImageView.
      //
      // The platform view is appended to a mutator view.
      //
      // Otherwise, hide the platform view, but don't remove it from the view hierarchy yet as
      // they are removed when the framework diposes the platform view widget.
      if (currentFrameUsedPlatformViewIds.contains(viewId)
          && (isFrameRenderedUsingImageReaders || !synchronizeToNativeViewHierarchy)) {
        parentView.setVisibility(View.VISIBLE);
      } else {
        parentView.setVisibility(View.GONE);
      }
    }
  }

  /**
   * Creates and tracks the overlay surface.
   *
   * @param imageView The surface that displays the overlay.
   * @return Wrapper object that provides the layer id and the surface. This member is not intended
   *     for public use, and is only visible for testing.
   */
  @VisibleForTesting
  @TargetApi(19)
  @NonNull
  public FlutterOverlaySurface createOverlaySurface(@NonNull FlutterImageView imageView) {
    final int id = nextOverlayLayerId++;
    overlayLayerViews.put(id, imageView);
    return new FlutterOverlaySurface(id, imageView.getSurface());
  }

  /**
   * Creates an overlay surface while the Flutter view is rendered by {@code FlutterImageView}.
   *
   * <p>This method is invoked by {@code FlutterJNI} only.
   *
   * <p>This member is not intended for public use, and is only visible for testing.
   */
  @TargetApi(19)
  @NonNull
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

  /**
   * Destroys the overlay surfaces and removes them from the view hierarchy.
   *
   * <p>This method is used only internally by {@code FlutterJNI}.
   */
  public void destroyOverlaySurfaces() {
    for (int i = 0; i < overlayLayerViews.size(); i++) {
      final FlutterImageView overlayView = overlayLayerViews.valueAt(i);
      overlayView.detachFromRenderer();
      overlayView.closeImageReader();
      // Don't remove overlayView from the view hierarchy since this method can
      // be called while the Android framework is iterating over the array of views.
      // See ViewGroup#dispatchDetachedFromWindow(), and
      // https://github.com/flutter/flutter/issues/97679.
    }
  }

  private void removeOverlaySurfaces() {
    if (flutterView == null) {
      Log.e(TAG, "removeOverlaySurfaces called while flutter view is null");
      return;
    }
    for (int i = 0; i < overlayLayerViews.size(); i++) {
      flutterView.removeView(overlayLayerViews.valueAt(i));
    }
    overlayLayerViews.clear();
  }
}
