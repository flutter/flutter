// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.embedding.engine.systemchannels;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import io.flutter.Log;
import io.flutter.embedding.engine.dart.DartExecutor;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.StandardMethodCodec;
import java.io.PrintWriter;
import java.io.StringWriter;
import java.nio.ByteBuffer;
import java.util.List;
import java.util.Map;

/**
 * System channel that sends 2-way communication between Flutter and Android to facilitate embedding
 * of Android Views within a Flutter application.
 *
 * <p>Register a {@link PlatformViewsHandler} to implement the Android side of this channel.
 */
public class PlatformViewsChannel {
  private static final String TAG = "PlatformViewsChannel";

  private final MethodChannel channel;
  private PlatformViewsHandler handler;

  public void invokeViewFocused(int viewId) {
    if (channel == null) {
      return;
    }
    channel.invokeMethod("viewFocused", viewId);
  }

  private static String detailedExceptionString(Exception exception) {
    StringWriter stringWriter = new StringWriter();
    PrintWriter printWriter = new PrintWriter(stringWriter);
    exception.printStackTrace(printWriter);
    return stringWriter.toString();
  }

  private final MethodChannel.MethodCallHandler parsingHandler =
      new MethodChannel.MethodCallHandler() {
        @Override
        public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
          // If there is no handler to respond to this message then we don't need to
          // parse it. Return.
          if (handler == null) {
            return;
          }

          Log.v(TAG, "Received '" + call.method + "' message.");
          switch (call.method) {
            case "create":
              create(call, result);
              break;
            case "dispose":
              dispose(call, result);
              break;
            case "resize":
              resize(call, result);
              break;
            case "touch":
              touch(call, result);
              break;
            case "setDirection":
              setDirection(call, result);
              break;
            case "clearFocus":
              clearFocus(call, result);
              break;
            default:
              result.notImplemented();
          }
        }

        private void create(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
          Map<String, Object> createArgs = call.arguments();
          PlatformViewCreationRequest request =
              new PlatformViewCreationRequest(
                  (int) createArgs.get("id"),
                  (String) createArgs.get("viewType"),
                  (double) createArgs.get("width"),
                  (double) createArgs.get("height"),
                  (int) createArgs.get("direction"),
                  createArgs.containsKey("params")
                      ? ByteBuffer.wrap((byte[]) createArgs.get("params"))
                      : null);

          try {
            long textureId = handler.createPlatformView(request);
            result.success(textureId);
          } catch (IllegalStateException exception) {
            result.error("error", detailedExceptionString(exception), null);
          }
        }

        private void dispose(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
          int viewId = call.arguments();
          try {
            handler.disposePlatformView(viewId);
            result.success(null);
          } catch (IllegalStateException exception) {
            result.error("error", detailedExceptionString(exception), null);
          }
        }

        private void resize(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
          Map<String, Object> resizeArgs = call.arguments();
          PlatformViewResizeRequest resizeRequest =
              new PlatformViewResizeRequest(
                  (int) resizeArgs.get("id"),
                  (double) resizeArgs.get("width"),
                  (double) resizeArgs.get("height"));
          try {
            handler.resizePlatformView(
                resizeRequest,
                new Runnable() {
                  @Override
                  public void run() {
                    result.success(null);
                  }
                });
          } catch (IllegalStateException exception) {
            result.error("error", detailedExceptionString(exception), null);
          }
        }

        private void touch(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
          List<Object> args = call.arguments();
          PlatformViewTouch touch =
              new PlatformViewTouch(
                  (int) args.get(0),
                  (Number) args.get(1),
                  (Number) args.get(2),
                  (int) args.get(3),
                  (int) args.get(4),
                  args.get(5),
                  args.get(6),
                  (int) args.get(7),
                  (int) args.get(8),
                  (float) (double) args.get(9),
                  (float) (double) args.get(10),
                  (int) args.get(11),
                  (int) args.get(12),
                  (int) args.get(13),
                  (int) args.get(14));

          try {
            handler.onTouch(touch);
            result.success(null);
          } catch (IllegalStateException exception) {
            result.error("error", detailedExceptionString(exception), null);
          }
        }

        private void setDirection(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
          Map<String, Object> setDirectionArgs = call.arguments();
          int newDirectionViewId = (int) setDirectionArgs.get("id");
          int direction = (int) setDirectionArgs.get("direction");

          try {
            handler.setDirection(newDirectionViewId, direction);
            result.success(null);
          } catch (IllegalStateException exception) {
            result.error("error", detailedExceptionString(exception), null);
          }
        }

        private void clearFocus(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
          int viewId = call.arguments();
          try {
            handler.clearFocus(viewId);
            result.success(null);
          } catch (IllegalStateException exception) {
            result.error("error", detailedExceptionString(exception), null);
          }
        }
      };

  /**
   * Constructs a {@code PlatformViewsChannel} that connects Android to the Dart code running in
   * {@code dartExecutor}.
   *
   * <p>The given {@code dartExecutor} is permitted to be idle or executing code.
   *
   * <p>See {@link DartExecutor}.
   */
  public PlatformViewsChannel(@NonNull DartExecutor dartExecutor) {
    channel =
        new MethodChannel(dartExecutor, "flutter/platform_views", StandardMethodCodec.INSTANCE);
    channel.setMethodCallHandler(parsingHandler);
  }

  /**
   * Sets the {@link PlatformViewsHandler} which receives all events and requests that are parsed
   * from the underlying platform views channel.
   */
  public void setPlatformViewsHandler(@Nullable PlatformViewsHandler handler) {
    this.handler = handler;
  }

  /**
   * Handler that receives platform view messages sent from Flutter to Android through a given
   * {@link PlatformViewsChannel}.
   *
   * <p>To register a {@code PlatformViewsHandler} with a {@link PlatformViewsChannel}, see {@link
   * PlatformViewsChannel#setPlatformViewsHandler(PlatformViewsHandler)}.
   */
  public interface PlatformViewsHandler {
    /**
     * The Flutter application would like to display a new Android {@code View}, i.e., platform
     * view.
     *
     * <p>The handler should instantiate the desired Android {@code View}, create a new {@link
     * io.flutter.view.FlutterView.SurfaceTextureRegistryEntry} within the given Flutter execution
     * context, and then return the new texture's ID.
     */
    // TODO(mattcarroll): Introduce an annotation for @TextureId
    long createPlatformView(@NonNull PlatformViewCreationRequest request);

    /**
     * The Flutter application could like dispose of an existing Android {@code View}, i.e.,
     * platform view.
     */
    void disposePlatformView(int viewId);

    /**
     * The Flutter application would like to resize an existing Android {@code View}, i.e., platform
     * view.
     */
    void resizePlatformView(
        @NonNull PlatformViewResizeRequest request, @NonNull Runnable onComplete);

    /**
     * The user touched a platform view within Flutter.
     *
     * <p>Touch data is reported in {@code touch}.
     */
    void onTouch(@NonNull PlatformViewTouch touch);

    /**
     * The Flutter application would like to change the layout direction of an existing Android
     * {@code View}, i.e., platform view.
     */
    // TODO(mattcarroll): Introduce an annotation for @TextureId
    void setDirection(int viewId, int direction);

    /** Clears the focus from the platform view with a give id if it is currently focused. */
    void clearFocus(int viewId);
  }

  /** Request sent from Flutter to create a new platform view. */
  public static class PlatformViewCreationRequest {
    /** The ID of the platform view as seen by the Flutter side. */
    public final int viewId;

    /** The type of Android {@code View} to create for this platform view. */
    @NonNull public final String viewType;

    /** The density independent width to display the platform view. */
    public final double logicalWidth;

    /** The density independent height to display the platform view. */
    public final double logicalHeight;

    /**
     * The layout direction of the new platform view.
     *
     * <p>See {@link android.view.View.LAYOUT_DIRECTION_LTR} and {@link
     * android.view.View.LAYOUT_DIRECTION_RTL}
     */
    public final int direction;

    /** Custom parameters that are unique to the desired platform view. */
    @Nullable public final ByteBuffer params;

    public PlatformViewCreationRequest(
        int viewId,
        @NonNull String viewType,
        double logicalWidth,
        double logicalHeight,
        int direction,
        @Nullable ByteBuffer params) {
      this.viewId = viewId;
      this.viewType = viewType;
      this.logicalWidth = logicalWidth;
      this.logicalHeight = logicalHeight;
      this.direction = direction;
      this.params = params;
    }
  }

  /** Request sent from Flutter to resize a platform view. */
  public static class PlatformViewResizeRequest {
    /** The ID of the platform view as seen by the Flutter side. */
    public final int viewId;

    /** The new density independent width to display the platform view. */
    public final double newLogicalWidth;

    /** The new density independent height to display the platform view. */
    public final double newLogicalHeight;

    public PlatformViewResizeRequest(int viewId, double newLogicalWidth, double newLogicalHeight) {
      this.viewId = viewId;
      this.newLogicalWidth = newLogicalWidth;
      this.newLogicalHeight = newLogicalHeight;
    }
  }

  /** The state of a touch event in Flutter within a platform view. */
  public static class PlatformViewTouch {
    /** The ID of the platform view as seen by the Flutter side. */
    public final int viewId;

    /** The amount of time that the touch has been pressed. */
    @NonNull public final Number downTime;
    /** TODO(mattcarroll): javadoc */
    @NonNull public final Number eventTime;

    public final int action;
    /** The number of pointers (e.g, fingers) involved in the touch event. */
    public final int pointerCount;
    /** Properties for each pointer, encoded in a raw format. */
    @NonNull public final Object rawPointerPropertiesList;
    /** Coordinates for each pointer, encoded in a raw format. */
    @NonNull public final Object rawPointerCoords;
    /** TODO(mattcarroll): javadoc */
    public final int metaState;
    /** TODO(mattcarroll): javadoc */
    public final int buttonState;
    /** Coordinate precision along the x-axis. */
    public final float xPrecision;
    /** Coordinate precision along the y-axis. */
    public final float yPrecision;
    /** TODO(mattcarroll): javadoc */
    public final int deviceId;
    /** TODO(mattcarroll): javadoc */
    public final int edgeFlags;
    /** TODO(mattcarroll): javadoc */
    public final int source;
    /** TODO(mattcarroll): javadoc */
    public final int flags;

    PlatformViewTouch(
        int viewId,
        @NonNull Number downTime,
        @NonNull Number eventTime,
        int action,
        int pointerCount,
        @NonNull Object rawPointerPropertiesList,
        @NonNull Object rawPointerCoords,
        int metaState,
        int buttonState,
        float xPrecision,
        float yPrecision,
        int deviceId,
        int edgeFlags,
        int source,
        int flags) {
      this.viewId = viewId;
      this.downTime = downTime;
      this.eventTime = eventTime;
      this.action = action;
      this.pointerCount = pointerCount;
      this.rawPointerPropertiesList = rawPointerPropertiesList;
      this.rawPointerCoords = rawPointerCoords;
      this.metaState = metaState;
      this.buttonState = buttonState;
      this.xPrecision = xPrecision;
      this.yPrecision = yPrecision;
      this.deviceId = deviceId;
      this.edgeFlags = edgeFlags;
      this.source = source;
      this.flags = flags;
    }
  }
}
