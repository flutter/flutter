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
   * Flutter ContentSensitivity.autoSensitive index that represents Android's
   * `View.CONTENT_SENSITIVITY_AUTO` setting.
   *
   * <p>See https://developer.android.com/reference/android/view/View#CONTENT_SENSITIVITY_AUTO.
   */
  @VisibleForTesting public static final int AUTO_SENSITIVE_CONTENT_SENSITIVITY = 0;

  /**
   * Flutter ContentSensitivity.sensitive index that represents Android's
   * `View.CONTENT_SENSITIVITY_SENSITIVE` setting.
   *
   * <p>See https://developer.android.com/reference/android/view/View#CONTENT_SENSITIVITY_SENSITIVE.
   */
  @VisibleForTesting public static final int SENSITIVE_CONTENT_SENSITIVITY = 1;

  /**
   * Flutter ContentSensitivity.notSensitive index that represents Android's
   * `View.CONTENT_SENSITIVITY_NOT_SENSITIVE` setting.
   *
   * <p>See
   * https://developer.android.com/reference/android/view/View#CONTENT_SENSITIVITY_NOT_SENSITIVE.
   */
  @VisibleForTesting public static final int NOT_SENSITIVE_CONTENT_SENSITIVITY = 2;

  /**
   * Flutter ContentSensitivity._unknown index that represents a content sensitivity setting that
   * the Flutter SensitiveContent widget does not recognize.
   */
  @VisibleForTesting public static final int UNKNOWN_CONTENT_SENSITIVITY = 3;

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
              final int contentSensitivityLevel = call.arguments();
              try {
                sensitiveContentMethodHandler.setContentSensitivity(
                    deserializeContentSensitivity(contentSensitivityLevel));
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
  private int deserializeContentSensitivity(int contentSensitivityIndex) {
    switch (contentSensitivityIndex) {
      case AUTO_SENSITIVE_CONTENT_SENSITIVITY:
        return View.CONTENT_SENSITIVITY_AUTO;
      case SENSITIVE_CONTENT_SENSITIVITY:
        return View.CONTENT_SENSITIVITY_SENSITIVE;
      case NOT_SENSITIVE_CONTENT_SENSITIVITY:
        return View.CONTENT_SENSITIVITY_NOT_SENSITIVE;
      default:
        throw new IllegalArgumentException(
            "contentSensitivityIndex "
                + contentSensitivityIndex
                + " not known to the SensitiveContentChannel.");
    }
  }

  // The annotation to suppress the "InlinedApi" lint prevents lint warnings
  // caused by usage of Android 35 APIs. This call is safe because these values
  // will never be used to set content sensitivity for a View via a
  // SensitiveContentMethodHandler because it must ensure a device is API 35+ before
  // doing so to avoid exceptions on other devices.
  @SuppressLint({"InlinedApi"})
  private int serializeContentSensitivity(int contentSensitivityValue) {
    switch (contentSensitivityValue) {
      case View.CONTENT_SENSITIVITY_AUTO:
        return AUTO_SENSITIVE_CONTENT_SENSITIVITY;
      case View.CONTENT_SENSITIVITY_SENSITIVE:
        return SENSITIVE_CONTENT_SENSITIVITY;
      case View.CONTENT_SENSITIVITY_NOT_SENSITIVE:
        return NOT_SENSITIVE_CONTENT_SENSITIVITY;
      default:
        // Signal to Flutter framework that the embedder does not recognize
        // the content sensitivity mode queried.
        return UNKNOWN_CONTENT_SENSITIVITY;
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
     *
     * <p>The {@code requestedContentSensitivity} should be one of the {@code View} constants that
     * represent a content sensitivity mode. See
     * https://developer.android.com/reference/android/view/View#setContentSensitivity(int) for the
     * available modes.
     */
    void setContentSensitivity(@NonNull int requestedContentSensitivity);

    /**
     * Returns the current content sensitivity level of a Flutter Android {@code View}.
     *
     * <p>The return value should be one of the {@code View} constants that represent a content
     * sensitivity modes. See
     * https://developer.android.com/reference/android/view/View#getContentSensitivity() for the
     * available modes.
     */
    int getContentSensitivity();

    /**
     * Returns whether or not setting/getting content sensitivity via Android APIs is supported on
     * the device.
     *
     * <p>This value is static and will not change while a Flutter app runs.
     */
    boolean isSupported();
  }
}
