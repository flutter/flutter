// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.embedding.engine.systemchannels;

import android.graphics.Rect;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import io.flutter.Log;
import io.flutter.embedding.engine.dart.DartExecutor;
import io.flutter.plugin.common.JSONMethodCodec;
import io.flutter.plugin.common.MethodChannel;
import java.util.HashMap;
import java.util.Map;
import org.json.JSONException;
import org.json.JSONObject;

/**
 * A {@link MethodChannel} that lets the platform capture scrolling content rendered by the Flutter
 * framework, as used by Android's scrolling screenshots ("Capture more").
 *
 * <p>All coordinates are in physical pixels. Bounds are relative to the {@code FlutterView}. The
 * vertical ranges passed to {@link #scrollTo} are relative to the top of the scroll bounds at the
 * scroll position when the session started.
 */
public class ScrollCaptureChannel {
  private static final String TAG = "ScrollCaptureChannel";

  /** Receives the result of a request sent over the {@link ScrollCaptureChannel}. */
  public interface Callback<T> {
    /**
     * Called with the result of the request, or {@code null} if the framework could not handle the
     * request (for example, because there is no scrollable content to capture).
     */
    void onResult(@Nullable T result);
  }

  @NonNull private final MethodChannel channel;

  public ScrollCaptureChannel(@NonNull DartExecutor dartExecutor) {
    this(new MethodChannel(dartExecutor, "flutter/scrollcapture", JSONMethodCodec.INSTANCE));
  }

  /* package */ ScrollCaptureChannel(@NonNull MethodChannel channel) {
    this.channel = channel;
  }

  /**
   * Asks the framework for the bounds of the primary vertically scrollable content, relative to the
   * {@code FlutterView}.
   */
  public void search(@NonNull Callback<Rect> callback) {
    channel.invokeMethod("ScrollCapture.search", null, new RectResult(callback));
  }

  /**
   * Starts a capture session for the primary vertically scrollable content and returns its bounds
   * relative to the {@code FlutterView}.
   */
  public void start(@NonNull Callback<Rect> callback) {
    channel.invokeMethod("ScrollCapture.start", null, new RectResult(callback));
  }

  /**
   * Scrolls so that as much as possible of the vertical range from {@code top} to {@code bottom} is
   * visible, and returns the distance the content has moved up since the session started once the
   * corresponding frame has been produced.
   */
  public void scrollTo(int top, int bottom, @NonNull Callback<Integer> callback) {
    Map<String, Object> arguments = new HashMap<>();
    arguments.put("top", top);
    arguments.put("bottom", bottom);
    channel.invokeMethod(
        "ScrollCapture.scrollTo",
        arguments,
        new BaseResult<Integer>(callback) {
          @Override
          Integer parse(@NonNull JSONObject json) throws JSONException {
            return json.getInt("scrollDelta");
          }
        });
  }

  /** Ends the capture session, restoring the original scroll position. */
  public void end(@NonNull Runnable onDone) {
    channel.invokeMethod(
        "ScrollCapture.end",
        null,
        new MethodChannel.Result() {
          @Override
          public void success(@Nullable Object result) {
            onDone.run();
          }

          @Override
          public void error(
              @NonNull String errorCode,
              @Nullable String errorMessage,
              @Nullable Object errorDetails) {
            Log.e(TAG, "Error ending scroll capture: " + errorMessage);
            onDone.run();
          }

          @Override
          public void notImplemented() {
            onDone.run();
          }
        });
  }

  private abstract static class BaseResult<T> implements MethodChannel.Result {
    private final Callback<T> callback;

    BaseResult(@NonNull Callback<T> callback) {
      this.callback = callback;
    }

    abstract T parse(@NonNull JSONObject json) throws JSONException;

    @Override
    public void success(@Nullable Object result) {
      if (!(result instanceof JSONObject)) {
        callback.onResult(null);
        return;
      }
      try {
        callback.onResult(parse((JSONObject) result));
      } catch (JSONException e) {
        Log.e(TAG, "Unable to parse scroll capture result: " + e);
        callback.onResult(null);
      }
    }

    @Override
    public void error(
        @NonNull String errorCode, @Nullable String errorMessage, @Nullable Object errorDetails) {
      Log.e(TAG, "Scroll capture request failed: " + errorMessage);
      callback.onResult(null);
    }

    @Override
    public void notImplemented() {
      // The framework does not support scroll capture.
      callback.onResult(null);
    }
  }

  private static class RectResult extends BaseResult<Rect> {
    RectResult(@NonNull Callback<Rect> callback) {
      super(callback);
    }

    @Override
    Rect parse(@NonNull JSONObject json) throws JSONException {
      return new Rect(
          json.getInt("left"), json.getInt("top"), json.getInt("right"), json.getInt("bottom"));
    }
  }
}
