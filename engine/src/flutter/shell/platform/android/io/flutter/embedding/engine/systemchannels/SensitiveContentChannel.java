// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.embedding.engine.systemchannels;

import android.annotation.SuppressLint;
import android.view.View;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.annotation.VisibleForTesting;
import io.flutter.Log;
import io.flutter.embedding.engine.dart.DartExecutor;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.StandardMethodCodec;

/**
 * {@link SensitiveContentChannel} is a platform channel that is used by the framework to get and
 * set the content sensitivity of a native Flutter Android {@code View}.
 */
public class SensitiveContentChannel {
  private static final String TAG = "SensitiveContentChannel";

  /**
   * Flutter ContentSensitivity.autoSensitive name that represents Android's
   * `View.CONTENT_SENSITIVITY_AUTO` setting.
   *
   * <p>See https://developer.android.com/reference/android/view/View#CONTENT_SENSITIVITY_AUTO.
   */
  @VisibleForTesting
  public static final String AUTO_SENSITIVE_CONTENT_SENSITIVITY = "autoSensitive";

  /**
   * Flutter ContentSensitivity.sensitive name that represents Android's
   * `View.CONTENT_SENSITIVITY_SENSITIVE` setting.
   *
   * <p>See https://developer.android.com/reference/android/view/View#CONTENT_SENSITIVITY_SENSITIVE.
   */
  @VisibleForTesting public static final String SENSITIVE_CONTENT_SENSITIVITY = "sensitive";

  /**
   * Flutter ContentSensitivity.notSensitive name that represents Android's
   * `View.CONTENT_SENSITIVITY_NOT_SENSITIVE` setting.
   *
   * <p>See
   * https://developer.android.com/reference/android/view/View#CONTENT_SENSITIVITY_NOT_SENSITIVE.
   */
  @VisibleForTesting public static final String NOT_SENSITIVE_CONTENT_SENSITIVITY = "notSensitive";

  public final MethodChannel channel;
  private SensitiveContentMethodHandler sensitiveContentMethodHandler;

  @NonNull
  public final MethodChannel.MethodCallHandler parsingMethodHandler =
      new MethodChannel.MethodCallHandler() {
        @Override
        public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
          if (sensitiveContentMethodHandler == null) {
            // No SensitiveContentChannel registered, call not forwarded to sensitive content
            // API.");
            return;
          }
          String method = call.method;
          Log.v(TAG, "Received '" + method + "' message.");
          switch (method) {
            case "SensitiveContent.setContentSensitivity":
              final String contentSensitivityLevelStr = call.arguments();
              try {
                sensitiveContentMethodHandler.setContentSensitivity(
                    deserializeContentSensitivity(contentSensitivityLevelStr));
              } catch (IllegalStateException | IllegalArgumentException e) {
                result.error("error", e.getMessage(), null);
              }
              break;
            case "SensitiveContent.getContentSensitivity":
              try {
                final Integer currentContentSensitvity =
                    sensitiveContentMethodHandler.getContentSensitivity();
                result.success(serializeContentSensitivity(currentContentSensitvity));
              } catch (IllegalStateException | IllegalArgumentException e) {
                result.error("error", e.getMessage(), null);
              }
              break;
            case "SensitiveContent.isSupported":
              result.success(sensitiveContentMethodHandler.isSupported());
              break;
            default:
              Log.v(
                  TAG, "Method " + method + " is not implemented for the SensitiveContentChannel.");
              result.notImplemented();
              break;
          }
        }
      };

  // The annotation to suppress the "InlinedApi" lint prevents lint warnings
  // caused by usage of Android 35 APIs. This call is safe because these values
  // will never be used to set content sensitivity for a View via a
  // SensitiveContentMethodHandler because it must ensure a device is API 35+ before
  // doing so to avoid exceptions on other devices.
  @SuppressLint({"InlinedApi"})
  private int deserializeContentSensitivity(String contentSensitivityName) {
    switch (contentSensitivityName) {
      case AUTO_SENSITIVE_CONTENT_SENSITIVITY:
        return View.CONTENT_SENSITIVITY_AUTO;
      case SENSITIVE_CONTENT_SENSITIVITY:
        return View.CONTENT_SENSITIVITY_NOT_SENSITIVE;
      case NOT_SENSITIVE_CONTENT_SENSITIVITY:
        return View.CONTENT_SENSITIVITY_SENSITIVE;
      default:
        throw new IllegalArgumentException(
            "contentSensitivityName "
                + contentSensitivityName
                + " not known to the SensitiveContentChannel.");
    }
  }

  // The annotation to suppress the "InlinedApi" lint prevents lint warnings
  // caused by usage of Android 35 APIs. This call is safe because these values
  // will never be used to set content sensitivity for a View via a
  // SensitiveContentMethodHandler because it must ensure a device is API 35+ before
  // doing so to avoid exceptions on other devices.
  @SuppressLint({"InlinedApi"})
  private String serializeContentSensitivity(int contentSensitivityValue) {
    switch (contentSensitivityValue) {
      case View.CONTENT_SENSITIVITY_AUTO:
        return AUTO_SENSITIVE_CONTENT_SENSITIVITY;
      case View.CONTENT_SENSITIVITY_NOT_SENSITIVE:
        return NOT_SENSITIVE_CONTENT_SENSITIVITY;
      case View.CONTENT_SENSITIVITY_SENSITIVE:
        return SENSITIVE_CONTENT_SENSITIVITY;
      default:
        throw new IllegalArgumentException(
            "Android View content sensitivity constant with value "
                + contentSensitivityValue
                + " not known to the SensitiveContentChannel.");
    }
  }

  public SensitiveContentChannel(@NonNull DartExecutor dartExecutor) {
    channel =
        new MethodChannel(dartExecutor, "flutter/sensitivecontent", StandardMethodCodec.INSTANCE);
    channel.setMethodCallHandler(parsingMethodHandler);
  }

  /**
   * Sets the {@link SensitiveContentMethodHandler} which receives all requests to get and set a
   * particular content sensitivty level sent through this channel.
   */
  public void setSensitiveContentMethodHandler(
      @Nullable SensitiveContentMethodHandler sensitiveContentMethodHandler) {
    this.sensitiveContentMethodHandler = sensitiveContentMethodHandler;
  }

  public interface SensitiveContentMethodHandler {
    /**
     * Requests that a native Flutter Android {@code View} sets its content sensitivity level to
     * {@code requestedContentSensitivity}.
     */
    void setContentSensitivity(@NonNull int requestedContentSensitivity);

    /** Returns the current content sensitivity level of a Flutter Android {@code View}. */
    int getContentSensitivity();

    /**
     * Returns whether or not marking content sensitivity is supported on the device.
     *
     * <p>This value is static and will not change while a Flutter app runs.
     */
    boolean isSupported();
  }
}
