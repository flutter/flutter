// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.embedding.engine.systemchannels;

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
                    deserializeContentSensitivity(contentSensitivityLevelStr), result);
              } catch (IllegalArgumentException exception) {
                result.error("error", exception.getMessage(), null);
              }
              break;
            case "SensitiveContent.getContentSensitivity":
              try {
                final Integer currentContentSensitvity =
                    sensitiveContentMethodHandler.getContentSensitivity(result);

                // Report result if fetching currentContentSensitvity did not encounter
                // an error.
                result.success(serializeContentSensitivity(currentContentSensitvity));
              } catch (IllegalArgumentException exception) {
                result.error("error", exception.getMessage(), null);
              }
              break;
            case "SensitiveContent.isSupported":
              sensitiveContentMethodHandler.isSupported(result);
              break;
            default:
              Log.v(
                  TAG, "Method " + method + " is not implemented for the SensitiveContentChannel.");
              result.notImplemented();
              break;
          }
        }
      };

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
    void setContentSensitivity(
        @NonNull int requestedContentSensitivity, @NonNull MethodChannel.Result result);

    /**
     * Returns the current content sensitivity level of a Flutter Android {@code View}.
     *
     * <p>{@code result} passed in the event that this method encounters an error. In the case that
     * an error is encounted, {@code null} is returned.
     */
    Integer getContentSensitivity(@NonNull MethodChannel.Result result);

    /**
     * Returns whether or not marking content sensitivity is supported on the device.
     *
     * <p>This value is static and will not change while a Flutter app runs.
     */
    void isSupported(@NonNull MethodChannel.Result result);
  }
}
