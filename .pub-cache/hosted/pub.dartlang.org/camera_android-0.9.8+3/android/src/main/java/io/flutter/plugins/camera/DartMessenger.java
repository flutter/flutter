// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.camera;

import android.os.Handler;
import android.text.TextUtils;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import io.flutter.embedding.engine.systemchannels.PlatformChannel;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugins.camera.features.autofocus.FocusMode;
import io.flutter.plugins.camera.features.exposurelock.ExposureMode;
import java.util.HashMap;
import java.util.Map;

/** Utility class that facilitates communication to the Flutter client */
public class DartMessenger {
  @NonNull private final Handler handler;
  @Nullable private MethodChannel cameraChannel;
  @Nullable private MethodChannel deviceChannel;

  /** Specifies the different device related message types. */
  enum DeviceEventType {
    /** Indicates the device's orientation has changed. */
    ORIENTATION_CHANGED("orientation_changed");
    private final String method;

    DeviceEventType(String method) {
      this.method = method;
    }
  }

  /** Specifies the different camera related message types. */
  enum CameraEventType {
    /** Indicates that an error occurred while interacting with the camera. */
    ERROR("error"),
    /** Indicates that the camera is closing. */
    CLOSING("camera_closing"),
    /** Indicates that the camera is initialized. */
    INITIALIZED("initialized");

    private final String method;

    /**
     * Converts the supplied method name to the matching {@link CameraEventType}.
     *
     * @param method name to be converted into a {@link CameraEventType}.
     */
    CameraEventType(String method) {
      this.method = method;
    }
  }

  /**
   * Creates a new instance of the {@link DartMessenger} class.
   *
   * @param messenger is the {@link BinaryMessenger} that is used to communicate with Flutter.
   * @param cameraId identifies the camera which is the source of the communication.
   * @param handler the handler used to manage the thread's message queue. This should always be a
   *     handler managing the main thread since communication with Flutter should always happen on
   *     the main thread. The handler is mainly supplied so it will be easier test this class.
   */
  DartMessenger(BinaryMessenger messenger, long cameraId, @NonNull Handler handler) {
    cameraChannel =
        new MethodChannel(messenger, "plugins.flutter.io/camera_android/camera" + cameraId);
    deviceChannel = new MethodChannel(messenger, "plugins.flutter.io/camera_android/fromPlatform");
    this.handler = handler;
  }

  /**
   * Sends a message to the Flutter client informing the orientation of the device has been changed.
   *
   * @param orientation specifies the new orientation of the device.
   */
  public void sendDeviceOrientationChangeEvent(PlatformChannel.DeviceOrientation orientation) {
    assert (orientation != null);
    this.send(
        DeviceEventType.ORIENTATION_CHANGED,
        new HashMap<String, Object>() {
          {
            put("orientation", CameraUtils.serializeDeviceOrientation(orientation));
          }
        });
  }

  /**
   * Sends a message to the Flutter client informing that the camera has been initialized.
   *
   * @param previewWidth describes the preview width that is supported by the camera.
   * @param previewHeight describes the preview height that is supported by the camera.
   * @param exposureMode describes the current exposure mode that is set on the camera.
   * @param focusMode describes the current focus mode that is set on the camera.
   * @param exposurePointSupported indicates if the camera supports setting an exposure point.
   * @param focusPointSupported indicates if the camera supports setting a focus point.
   */
  void sendCameraInitializedEvent(
      Integer previewWidth,
      Integer previewHeight,
      ExposureMode exposureMode,
      FocusMode focusMode,
      Boolean exposurePointSupported,
      Boolean focusPointSupported) {
    assert (previewWidth != null);
    assert (previewHeight != null);
    assert (exposureMode != null);
    assert (focusMode != null);
    assert (exposurePointSupported != null);
    assert (focusPointSupported != null);
    this.send(
        CameraEventType.INITIALIZED,
        new HashMap<String, Object>() {
          {
            put("previewWidth", previewWidth.doubleValue());
            put("previewHeight", previewHeight.doubleValue());
            put("exposureMode", exposureMode.toString());
            put("focusMode", focusMode.toString());
            put("exposurePointSupported", exposurePointSupported);
            put("focusPointSupported", focusPointSupported);
          }
        });
  }

  /** Sends a message to the Flutter client informing that the camera is closing. */
  void sendCameraClosingEvent() {
    send(CameraEventType.CLOSING);
  }

  /**
   * Sends a message to the Flutter client informing that an error occurred while interacting with
   * the camera.
   *
   * @param description contains details regarding the error that occurred.
   */
  void sendCameraErrorEvent(@Nullable String description) {
    this.send(
        CameraEventType.ERROR,
        new HashMap<String, Object>() {
          {
            if (!TextUtils.isEmpty(description)) put("description", description);
          }
        });
  }

  private void send(CameraEventType eventType) {
    send(eventType, new HashMap<>());
  }

  private void send(CameraEventType eventType, Map<String, Object> args) {
    if (cameraChannel == null) {
      return;
    }

    handler.post(
        new Runnable() {
          @Override
          public void run() {
            cameraChannel.invokeMethod(eventType.method, args);
          }
        });
  }

  private void send(DeviceEventType eventType) {
    send(eventType, new HashMap<>());
  }

  private void send(DeviceEventType eventType, Map<String, Object> args) {
    if (deviceChannel == null) {
      return;
    }

    handler.post(
        new Runnable() {
          @Override
          public void run() {
            deviceChannel.invokeMethod(eventType.method, args);
          }
        });
  }

  /**
   * Send a success payload to a {@link MethodChannel.Result} on the main thread.
   *
   * @param payload The payload to send.
   */
  public void finish(MethodChannel.Result result, Object payload) {
    handler.post(() -> result.success(payload));
  }

  /**
   * Send an error payload to a {@link MethodChannel.Result} on the main thread.
   *
   * @param errorCode error code.
   * @param errorMessage error message.
   * @param errorDetails error details.
   */
  public void error(
      MethodChannel.Result result,
      String errorCode,
      @Nullable String errorMessage,
      @Nullable Object errorDetails) {
    handler.post(() -> result.error(errorCode, errorMessage, errorDetails));
  }
}
