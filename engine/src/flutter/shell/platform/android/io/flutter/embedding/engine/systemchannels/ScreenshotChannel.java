// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.embedding.engine.systemchannels;

import android.graphics.Bitmap;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.annotation.VisibleForTesting;
import io.flutter.Log;
import io.flutter.embedding.engine.dart.DartExecutor;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.StandardMethodCodec;
import java.nio.ByteBuffer;
import java.util.Map;
import java.util.function.Consumer;

/**
 * System channel that requests asynchronous {@link Bitmap} captures of a Flutter view from the
 * framework's {@code RendererBinding} over {@code flutter/screenshot}.
 */
public class ScreenshotChannel {
  private static final String TAG = "ScreenshotChannel";
  private static final String CHANNEL_NAME = "flutter/screenshot";
  private static final String CAPTURE_VIEW_METHOD = "Screenshot.captureView";
  // Four bytes per pixel for premultiplied RGBA_8888 / ARGB_8888 buffers.
  private static final int BYTES_PER_PIXEL_RGBA_8888 = 4;

  @NonNull public final MethodChannel channel;

  public ScreenshotChannel(@NonNull DartExecutor dartExecutor) {
    this(new MethodChannel(dartExecutor, CHANNEL_NAME, StandardMethodCodec.INSTANCE));
  }

  @VisibleForTesting
  public ScreenshotChannel(@NonNull MethodChannel channel) {
    this.channel = channel;
  }

  /**
   * Requests an asynchronous screenshot of the specified {@code viewId} from the Dart framework.
   *
   * @param viewId The target {@code FlutterView} identifier (e.g. {@code 0} for the implicit view),
   *     or {@code null} to capture the first active {@code RenderView}.
   * @param callback Invoked on the Android main thread with the captured {@link Bitmap}, or {@code
   *     null} if capture failed.
   */
  public void captureView(@Nullable Long viewId, @NonNull Consumer<Bitmap> callback) {
    channel.invokeMethod(
        CAPTURE_VIEW_METHOD,
        viewId,
        new MethodChannel.Result() {
          @Override
          public void success(@Nullable Object result) {
            if (!(result instanceof Map)) {
              callback.accept(null);
              return;
            }
            @SuppressWarnings("unchecked")
            Map<String, Object> map = (Map<String, Object>) result;
            Object widthObj = map.get("width");
            Object heightObj = map.get("height");
            Object bytesObj = map.get("bytes");
            if (!(widthObj instanceof Number)
                || !(heightObj instanceof Number)
                || !(bytesObj instanceof byte[])) {
              callback.accept(null);
              return;
            }
            int width = ((Number) widthObj).intValue();
            int height = ((Number) heightObj).intValue();
            byte[] rgbaBytes = (byte[]) bytesObj;
            long expectedBytes = (long) width * (long) height * BYTES_PER_PIXEL_RGBA_8888;
            if (width <= 0 || height <= 0 || rgbaBytes.length < expectedBytes) {
              Log.w(TAG, "Invalid screenshot buffer dimensions received from Dart.");
              callback.accept(null);
              return;
            }
            try {
              Bitmap bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888);
              bitmap.copyPixelsFromBuffer(ByteBuffer.wrap(rgbaBytes, 0, (int) expectedBytes));
              callback.accept(bitmap);
            } catch (RuntimeException e) {
              Log.w(TAG, "Failed to copy RGBA bytes into Bitmap.", e);
              callback.accept(null);
            }
          }

          @Override
          public void error(
              @NonNull String errorCode,
              @Nullable String errorMessage,
              @Nullable Object errorDetails) {
            Log.w(TAG, "Screenshot capture failed: " + errorCode + " (" + errorMessage + ")");
            callback.accept(null);
          }

          @Override
          public void notImplemented() {
            Log.w(TAG, "Screenshot.captureView is not implemented by the running isolate.");
            callback.accept(null);
          }
        });
  }
}
