// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugin.platform;

import static android.view.MotionEvent.PointerCoords;
import static android.view.MotionEvent.PointerProperties;

import android.annotation.TargetApi;
import android.content.Context;
import android.os.Build;
import android.support.annotation.UiThread;
import android.util.DisplayMetrics;
import android.support.annotation.NonNull;
import android.util.Log;
import android.view.MotionEvent;
import android.view.View;

import io.flutter.embedding.engine.dart.DartExecutor;
import io.flutter.embedding.engine.systemchannels.PlatformViewsChannel;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.StandardMethodCodec;
import io.flutter.view.AccessibilityBridge;
import io.flutter.view.TextureRegistry;

import java.nio.ByteBuffer;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;

/**
 * Manages platform views.
 * <p>
 * Each {@link io.flutter.app.FlutterPluginRegistry} has a single platform views controller.
 * A platform views controller can be attached to at most one Flutter view.
 */
public class PlatformViewsController implements PlatformViewsAccessibilityDelegate {
    private static final String TAG = "PlatformViewsController";

    // API level 20 is required for VirtualDisplay#setSurface which we use when resizing a platform view.
    private static final int MINIMAL_SDK = Build.VERSION_CODES.KITKAT_WATCH;

    private final PlatformViewRegistryImpl registry;

    // The context of the Activity or Fragment hosting the render target for the Flutter engine.
    private Context context;

    // The texture registry maintaining the textures into which the embedded views will be rendered.
    private TextureRegistry textureRegistry;

    // The system channel used to communicate with the framework about platform views.
    private PlatformViewsChannel platformViewsChannel;

    // The accessibility bridge to which accessibility events form the platform views will be dispatched.
    private final AccessibilityEventsDelegate accessibilityEventsDelegate;

    private final HashMap<Integer, VirtualDisplayController> vdControllers;

    private final PlatformViewsChannel.PlatformViewsHandler channelHandler = new PlatformViewsChannel.PlatformViewsHandler() {
        @TargetApi(Build.VERSION_CODES.JELLY_BEAN_MR1)
        @Override
        public long createPlatformView(@NonNull PlatformViewsChannel.PlatformViewCreationRequest request) {
            ensureValidAndroidVersion();

            if (!validateDirection(request.direction)) {
                throw new IllegalStateException("Trying to create a view with unknown direction value: "
                    + request.direction + "(view id: " + request.viewId + ")");
            }

            if (vdControllers.containsKey(request.viewId)) {
                throw new IllegalStateException("Trying to create an already created platform view, view id: "
                    + request.viewId);
            }

            PlatformViewFactory viewFactory = registry.getFactory(request.viewType);
            if (viewFactory == null) {
                throw new IllegalStateException("Trying to create a platform view of unregistered type: "
                    + request.viewType);
            }

            Object createParams = null;
            if (request.params != null) {
                createParams = viewFactory.getCreateArgsCodec().decodeMessage(request.params);
            }

            int physicalWidth = toPhysicalPixels(request.logicalWidth);
            int physicalHeight = toPhysicalPixels(request.logicalHeight);
            validateVirtualDisplayDimensions(physicalWidth, physicalHeight);

            TextureRegistry.SurfaceTextureEntry textureEntry = textureRegistry.createSurfaceTexture();
            VirtualDisplayController vdController = VirtualDisplayController.create(
                context,
                accessibilityEventsDelegate,
                viewFactory,
                textureEntry,
                toPhysicalPixels(request.logicalWidth),
                toPhysicalPixels(request.logicalHeight),
                request.viewId,
                createParams
            );

            if (vdController == null) {
                throw new IllegalStateException("Failed creating virtual display for a "
                    + request.viewType + " with id: " + request.viewId);
            }

            vdControllers.put(request.viewId, vdController);
            vdController.getView().setLayoutDirection(request.direction);

            // TODO(amirh): copy accessibility nodes to the FlutterView's accessibility tree.

            return textureEntry.id();
        }

        @Override
        public void disposePlatformView(int viewId) {
            ensureValidAndroidVersion();

            VirtualDisplayController vdController = vdControllers.get(viewId);
            if (vdController == null) {
                throw new IllegalStateException("Trying to dispose a platform view with unknown id: "
                    + viewId);
            }

            vdController.dispose();
            vdControllers.remove(viewId);
        }

        @Override
        public void resizePlatformView(@NonNull PlatformViewsChannel.PlatformViewResizeRequest request, @NonNull Runnable onComplete) {
            ensureValidAndroidVersion();

            VirtualDisplayController vdController = vdControllers.get(request.viewId);
            if (vdController == null) {
                throw new IllegalStateException("Trying to resize a platform view with unknown id: "
                    + request.viewId);
            }

            int physicalWidth = toPhysicalPixels(request.newLogicalWidth);
            int physicalHeight = toPhysicalPixels(request.newLogicalHeight);
            validateVirtualDisplayDimensions(physicalWidth, physicalHeight);

            vdController.resize(
                physicalWidth,
                physicalHeight,
                onComplete
            );
        }

        @Override
        public void onTouch(@NonNull PlatformViewsChannel.PlatformViewTouch touch) {
            ensureValidAndroidVersion();

            float density = context.getResources().getDisplayMetrics().density;
            PointerProperties[] pointerProperties =
                parsePointerPropertiesList(touch.rawPointerPropertiesList)
                    .toArray(new PointerProperties[touch.pointerCount]);
            PointerCoords[] pointerCoords =
                parsePointerCoordsList(touch.rawPointerCoords, density)
                    .toArray(new PointerCoords[touch.pointerCount]);

            View view = vdControllers.get(touch.viewId).getView();
            if (view == null) {
                throw new IllegalStateException("Sending touch to an unknown view with id: "
                    + touch.viewId);
            }

            MotionEvent event = MotionEvent.obtain(
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
                touch.flags
            );

            view.dispatchTouchEvent(event);
        }

        @TargetApi(Build.VERSION_CODES.JELLY_BEAN_MR1)
        @Override
        public void setDirection(int viewId, int direction) {
            ensureValidAndroidVersion();

            if (!validateDirection(direction)) {
                throw new IllegalStateException("Trying to set unknown direction value: " + direction
                    + "(view id: " + viewId + ")");
            }

            View view = vdControllers.get(viewId).getView();
            if (view == null) {
                throw new IllegalStateException("Sending touch to an unknown view with id: "
                    + direction);
            }

            view.setLayoutDirection(direction);
        }

        private void ensureValidAndroidVersion() {
            if (Build.VERSION.SDK_INT < MINIMAL_SDK) {
                Log.e(TAG, "Trying to use platform views with API " + Build.VERSION.SDK_INT
                    + ", required API level is: " + MINIMAL_SDK);
                throw new IllegalStateException("An attempt was made to use platform views on a"
                    + " version of Android that platform views does not support.");
            }
        }
    };

    public PlatformViewsController() {
        registry = new PlatformViewRegistryImpl();
        vdControllers = new HashMap<>();
        accessibilityEventsDelegate = new AccessibilityEventsDelegate();
    }

    /**
     * Attaches this platform views controller to its input and output channels.
     *
     * @param context The base context that will be passed to embedded views created by this controller.
     *                This should be the {@code Application} {@code Context}.
     * @param textureRegistry The texture registry which provides the output textures into which the embedded views
     *                        will be rendered.
     * @param dartExecutor The dart execution context, which is used to setup a system channel.
     */
    public void attach(Context context, TextureRegistry textureRegistry, @NonNull DartExecutor dartExecutor) {
        if (this.context != null) {
            throw new AssertionError(
                    "A PlatformViewsController can only be attached to a single output target.\n" +
                            "attach was called while the PlatformViewsController was already attached."
            );
        }
        this.context = context.getApplicationContext();
        this.textureRegistry = textureRegistry;
        platformViewsChannel = new PlatformViewsChannel(dartExecutor);
        platformViewsChannel.setPlatformViewsHandler(channelHandler);
    }

    /**
     * Detaches this platform views controller.
     *
     * This is typically called when a Flutter applications moves to run in the background, or is destroyed.
     * After calling this the platform views controller will no longer listen to it's previous messenger, and will
     * not maintain references to the texture registry, context, and messenger passed to the previous attach call.
     */
    @UiThread
    public void detach() {
        platformViewsChannel.setPlatformViewsHandler(null);
        platformViewsChannel = null;
        context = null;
        textureRegistry = null;
    }

    @Override
    public void attachAccessibilityBridge(AccessibilityBridge accessibilityBridge) {
        accessibilityEventsDelegate.setAccessibilityBridge(accessibilityBridge);
    }

    @Override
    public void detachAccessibiltyBridge() {
        accessibilityEventsDelegate.setAccessibilityBridge(null);
    }

    public PlatformViewRegistry getRegistry() {
        return registry;
    }

    public void onFlutterViewDestroyed() {
        flushAllViews();
    }

    public void onPreEngineRestart() {
        flushAllViews();
    }

    @Override
    public View getPlatformViewById(Integer id) {
        VirtualDisplayController controller = vdControllers.get(id);
        if (controller == null) {
            return null;
        }
        return controller.getView();
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
            String message = "Creating a virtual display of size: "
                +  "[" + width + ", " + height + "] may result in problems"
                +  "(https://github.com/flutter/flutter/issues/2897)."
                +  "It is larger than the device screen size: "
                +  "[" + metrics.widthPixels + ", " + metrics.heightPixels + "].";
            Log.w(TAG, message);
        }
    }

    private int toPhysicalPixels(double logicalPixels) {
        float density = context.getResources().getDisplayMetrics().density;
        return (int) Math.round(logicalPixels * density);
    }

    private void flushAllViews() {
        for (VirtualDisplayController controller : vdControllers.values()) {
            controller.dispose();
        }
        vdControllers.clear();
    }
}
