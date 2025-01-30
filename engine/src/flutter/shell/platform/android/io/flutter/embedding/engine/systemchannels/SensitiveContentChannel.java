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
import java.util.Map;

/**
 * {@link SensitiveContentChannel} is a platform channel that is used by the framework to set the
 * content sensitivity of native Flutter Android {@code View}s.
 */
public class SensitiveContentChannel {
  private static final String TAG = "SensitiveContentChannel";

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
          Map<String, Object> args = call.arguments();
          final int flutterViewId = (int) args.get("flutterViewId");
          Log.v(TAG, "Received '" + method + "' message.");
          switch (method) {
            case "SensitiveContent.setContentSensitivity":
              final int contentSensitivityLevel = (int) args.get("contentSensitivityLevel");
              try {
                sensitiveContentMethodHandler.setContentSensitivity(
                    flutterViewId, contentSensitivityLevel, result);
              } catch (IllegalStateException exception) {
                result.error("error", exception.getMessage(), null);
              }
              break;
            case "SensitiveContent.getContentSensitivity":
              try {
                sensitiveContentMethodHandler.getContentSensitivity(flutterViewId, result);
              } catch (IllegalStateException exception) {
                result.error("error", exception.getMessage(), null);
              }
              break;
            default:
              Log.v(
                  TAG, "Method " + method + " is not implemented for the SensitiveContentChannel.");
              result.notImplemented();
              break;
          }
        }
      };

  public SensitiveContentChannel(@NonNull DartExecutor dartExecutor) {
    channel =
        new MethodChannel(dartExecutor, "flutter/sensitivecontent", StandardMethodCodec.INSTANCE);
    channel.setMethodCallHandler(parsingMethodHandler);
  }

  /**
   * Sets the {@link SensitiveContentMethodHandler} which receives all requests to set a particular
   * content sensitivty level sent through this channel.
   */
  public void setSensitiveContentMethodHandler(
      @Nullable SensitiveContentMethodHandler sensitiveContentMethodHandler) {
    this.sensitiveContentMethodHandler = sensitiveContentMethodHandler;
  }

  public interface SensitiveContentMethodHandler {
    /**
     * Requests that the native Flutter Android {@code View} whose ID matches {@code flutterViewId}
     * sets its content sensitivity level to {@code requestedContentSensitivity}.
     */
    void setContentSensitivity(
        @NonNull int flutterViewId,
        @NonNull int requestedContentSensitivity,
        @NonNull MethodChannel.Result result);

    /**
     * Returns the current content sensitivity level of the Flutter Android {@code View} whose ID
     * matches {@code flutterViewId}.
     */
    void getContentSensitivity(@NonNull int flutterViewId, @NonNull MethodChannel.Result result);
  }
}
