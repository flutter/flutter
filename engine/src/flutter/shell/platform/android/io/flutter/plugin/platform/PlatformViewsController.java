// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugin.platform;

import android.annotation.TargetApi;
import android.content.Context;
import android.os.Build;
import android.util.Log;
import android.view.MotionEvent;
import android.view.View;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.StandardMethodCodec;
import io.flutter.view.TextureRegistry;

import java.nio.ByteBuffer;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import static android.view.MotionEvent.PointerCoords;
import static android.view.MotionEvent.PointerProperties;

/**
 * Manages platform views.
 * <p>
 * Each {@link io.flutter.app.FlutterPluginRegistry} has a single platform views controller.
 * A platform views controller can be attached to at most one Flutter view.
 */
public class PlatformViewsController implements MethodChannel.MethodCallHandler {
    private static final String TAG = "PlatformViewsController";

    private static final String CHANNEL_NAME = "flutter/platform_views";

    // API level 20 is required for VirtualDisplay#setSurface which we use when resizing a platform view.
    private static final int MINIMAL_SDK = Build.VERSION_CODES.KITKAT_WATCH;

    private final PlatformViewRegistryImpl mRegistry;

    // The context of the Activity or Fragment hosting the render target for the Flutter engine.
    private Context mContext;

    // The texture registry maintaining the textures into which the embedded views will be rendered.
    private TextureRegistry mTextureRegistry;

    // The messenger used to communicate with the framework over the platform views channel.
    private BinaryMessenger mMessenger;

    private final HashMap<Integer, VirtualDisplayController> vdControllers;

    public PlatformViewsController() {
        mRegistry = new PlatformViewRegistryImpl();
        vdControllers = new HashMap<>();
    }

    /**
     * Attaches this platform views controller to its input and output channels.
     *
     * @param context The base context that will be passed to embedded views created by this controller.
     *                This should be the context of the Activity hosting the Flutter application.
     * @param textureRegistry The texture registry which provides the output textures into which the embedded views
     *                        will be rendered.
     * @param messenger The Flutter application on the other side of this messenger drives this platform views controller.
     */
    public void attach(Context context, TextureRegistry textureRegistry, BinaryMessenger messenger) {
        if (mContext != null) {
            throw new AssertionError(
                    "A PlatformViewsController can only be attached to a single output target.\n" +
                            "attach was called while the PlatformViewsController was already attached."
            );
        }
        mContext = context;
        mTextureRegistry = textureRegistry;
        mMessenger = messenger;
        MethodChannel channel = new MethodChannel(messenger, CHANNEL_NAME, StandardMethodCodec.INSTANCE);
        channel.setMethodCallHandler(this);
    }

    /**
     * Detaches this platform views controller.
     *
     * This is typically called when a Flutter applications moves to run in the background, or is destroyed.
     * After calling this the platform views controller will no longer listen to it's previous messenger, and will
     * not maintain references to the texture registry, context, and messenger passed to the previous attach call.
     */
    public void detach() {
        mMessenger.setMessageHandler(CHANNEL_NAME, null);
        mMessenger = null;
        mContext = null;
        mTextureRegistry = null;
    }

    public PlatformViewRegistry getRegistry() {
        return mRegistry;
    }

    public void onFlutterViewDestroyed() {
        flushAllViews();
    }

    public void onPreEngineRestart() {
        flushAllViews();
    }

    @Override
    public void onMethodCall(final MethodCall call, final MethodChannel.Result result) {
        if (Build.VERSION.SDK_INT < MINIMAL_SDK) {
            Log.e(TAG, "Trying to use platform views with API " + Build.VERSION.SDK_INT
                    + ", required API level is: " + MINIMAL_SDK);
            return;
        }
        switch (call.method) {
            case "create":
                createPlatformView(call, result);
                return;
            case "dispose":
                disposePlatformView(call, result);
                return;
            case "resize":
                resizePlatformView(call, result);
                return;
            case "touch":
                onTouch(call, result);
                return;
            case "setDirection":
                setDirection(call, result);
                return;
        }
        result.notImplemented();
    }

    @TargetApi(Build.VERSION_CODES.JELLY_BEAN_MR1)
    private void createPlatformView(MethodCall call, MethodChannel.Result result) {
        Map<String, Object> args = call.arguments();
        int id = (int) args.get("id");
        String viewType = (String) args.get("viewType");
        double logicalWidth = (double) args.get("width");
        double logicalHeight = (double) args.get("height");
        int direction = (int) args.get("direction");

        if (!validateDirection(direction)) {
            result.error(
                    "error",
                    "Trying to create a view with unknown direction value: " + direction + "(view id: " + id + ")",
                    null
            );
            return;
        }

        if (vdControllers.containsKey(id)) {
            result.error(
                    "error",
                    "Trying to create an already created platform view, view id: " + id,
                    null
            );
            return;
        }

        PlatformViewFactory viewFactory = mRegistry.getFactory(viewType);
        if (viewFactory == null) {
            result.error(
                    "error",
                    "Trying to create a platform view of unregistered type: " + viewType,
                    null
            );
            return;
        }

        Object createParams = null;
        if (args.containsKey("params")) {
            createParams = viewFactory.getCreateArgsCodec().decodeMessage(ByteBuffer.wrap((byte[]) args.get("params")));
        }

        TextureRegistry.SurfaceTextureEntry textureEntry = mTextureRegistry.createSurfaceTexture();
        VirtualDisplayController vdController = VirtualDisplayController.create(
                mContext,
                viewFactory,
                textureEntry.surfaceTexture(),
                toPhysicalPixels(logicalWidth),
                toPhysicalPixels(logicalHeight),
                id,
                createParams
        );

        if (vdController == null) {
            result.error(
                    "error",
                    "Failed creating virtual display for a " + viewType + " with id: " + id,
                    null
            );
            return;
        }

        vdControllers.put(id, vdController);
        vdController.getView().setLayoutDirection(direction);

        // TODO(amirh): copy accessibility nodes to the FlutterView's accessibility tree.

        result.success(textureEntry.id());
    }

    private void disposePlatformView(MethodCall call, MethodChannel.Result result) {
        int id = call.arguments();

        VirtualDisplayController vdController = vdControllers.get(id);
        if (vdController == null) {
            result.error(
                    "error",
                    "Trying to dispose a platform view with unknown id: " + id,
                    null
            );
            return;
        }

        vdController.dispose();
        vdControllers.remove(id);
        result.success(null);
    }

    private void resizePlatformView(MethodCall call, final MethodChannel.Result result) {
        Map<String, Object> args = call.arguments();
        int id = (int) args.get("id");
        double width = (double) args.get("width");
        double height = (double) args.get("height");

        VirtualDisplayController vdController = vdControllers.get(id);
        if (vdController == null) {
            result.error(
                    "error",
                    "Trying to resize a platform view with unknown id: " + id,
                    null
            );
            return;
        }
        vdController.resize(
                toPhysicalPixels(width),
                toPhysicalPixels(height),
                new Runnable() {
                    @Override
                    public void run() {
                        result.success(null);
                    }
                }
        );
    }

    private void onTouch(MethodCall call, MethodChannel.Result result) {
        List<Object> args = call.arguments();

        float density = mContext.getResources().getDisplayMetrics().density;

        int id = (int) args.get(0);
        Number downTime = (Number) args.get(1);
        Number eventTime = (Number) args.get(2);
        int action = (int) args.get(3);
        int pointerCount = (int) args.get(4);
        PointerProperties[] pointerProperties =
                parsePointerPropertiesList(args.get(5)).toArray(new PointerProperties[pointerCount]);
        PointerCoords[] pointerCoords =
                parsePointerCoordsList(args.get(6), density).toArray(new PointerCoords[pointerCount]);

        int metaState = (int) args.get(7);
        int buttonState = (int) args.get(8);
        float xPrecision = (float) (double) args.get(9);
        float yPrecision = (float) (double) args.get(10);
        int deviceId = (int) args.get(11);
        int edgeFlags = (int) args.get(12);
        int source = (int) args.get(13);
        int flags = (int) args.get(14);

        View view = vdControllers.get(id).getView();
        if (view == null) {
            result.error(
                    "error",
                    "Sending touch to an unknown view with id: " + id,
                    null
            );
            return;
        }

        MotionEvent event = MotionEvent.obtain(
                downTime.longValue(),
                eventTime.longValue(),
                action,
                pointerCount,
                pointerProperties,
                pointerCoords,
                metaState,
                buttonState,
                xPrecision,
                yPrecision,
                deviceId,
                edgeFlags,
                source,
                flags
        );

        view.dispatchTouchEvent(event);
        result.success(null);
    }

    @TargetApi(Build.VERSION_CODES.JELLY_BEAN_MR1)
    private void setDirection(MethodCall call, MethodChannel.Result result) {
        Map<String, Object> args = call.arguments();
        int id = (int) args.get("id");
        int direction = (int) args.get("direction");

        if (!validateDirection(direction)) {
            result.error(
                    "error",
                    "Trying to set unknown direction value: " + direction + "(view id: " + id + ")",
                    null
            );
            return;
        }

        View view = vdControllers.get(id).getView();
        if (view == null) {
            result.error(
                    "error",
                    "Sending touch to an unknown view with id: " + id,
                    null
            );
            return;
        }

        view.setLayoutDirection(direction);
        result.success(null);
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

    private int toPhysicalPixels(double logicalPixels) {
        float density = mContext.getResources().getDisplayMetrics().density;
        return (int) Math.round(logicalPixels * density);
    }

    private void flushAllViews() {
        for (VirtualDisplayController controller : vdControllers.values()) {
            controller.dispose();
        }
        vdControllers.clear();
    }
}
