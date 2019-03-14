// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.embedding.engine;

import android.content.res.AssetManager;
import android.graphics.Bitmap;
import android.graphics.SurfaceTexture;
import android.support.annotation.NonNull;
import android.support.annotation.Nullable;
import android.support.annotation.UiThread;
import android.view.Surface;

import java.nio.ByteBuffer;
import java.util.HashSet;
import java.util.Set;

import io.flutter.embedding.engine.dart.PlatformMessageHandler;
import io.flutter.embedding.engine.FlutterEngine.EngineLifecycleListener;
import io.flutter.embedding.engine.renderer.FlutterRenderer;
import io.flutter.embedding.engine.renderer.OnFirstFrameRenderedListener;
import io.flutter.plugin.common.StandardMessageCodec;
import io.flutter.view.AccessibilityBridge;

/**
 * Interface between Flutter embedding's Java code and Flutter engine's C/C++ code.
 *
 * WARNING: THIS CLASS IS EXPERIMENTAL. DO NOT SHIP A DEPENDENCY ON THIS CODE.
 * IF YOU USE IT, WE WILL BREAK YOU.
 *
 * Flutter's engine is built with C/C++. The Android Flutter embedding is responsible for
 * coordinating Android OS events and app user interactions with the C/C++ engine. Such coordination
 * requires messaging from an Android app in Java code to the C/C++ engine code. This
 * communication requires a JNI (Java Native Interface) API to cross the Java/native boundary.
 *
 * The entirety of Flutter's JNI API is codified in {@code FlutterJNI}. There are multiple reasons
 * that all such calls are centralized in one class. First, JNI calls are inherently static and
 * contain no Java implementation, therefore there is little reason to associate calls with different
 * classes. Second, every JNI call must be registered in C/C++ code and this registration becomes
 * more complicated with every additional Java class that contains JNI calls. Third, most Android
 * developers are not familiar with native development or JNI intricacies, therefore it is in the
 * interest of future maintenance to reduce the API surface that includes JNI declarations. Thus,
 * all Flutter JNI calls are centralized in {@code FlutterJNI}.
 *
 * Despite the fact that individual JNI calls are inherently static, there is state that exists
 * within {@code FlutterJNI}. Most calls within {@code FlutterJNI} correspond to a specific
 * "platform view", of which there may be many. Therefore, each {@code FlutterJNI} instance holds
 * onto a "native platform view ID" after {@link #attachToNative(boolean)}, which is shared with
 * the native C/C++ engine code. That ID is passed to every platform-view-specific native method.
 * ID management is handled within {@code FlutterJNI} so that developers don't have to hold onto
 * that ID.
 *
 * To connect part of an Android app to Flutter's C/C++ engine, instantiate a {@code FlutterJNI} and
 * then attach it to the native side:
 *
 * {@code
 *     // Instantiate FlutterJNI and attach to the native side.
 *     FlutterJNI flutterJNI = new FlutterJNI();
 *     flutterJNI.attachToNative();
 *
 *     // Use FlutterJNI as desired.
 *     flutterJNI.dispatchPointerDataPacket(...);
 *
 *     // Destroy the connection to the native side and cleanup.
 *     flutterJNI.detachFromNativeAndReleaseResources();
 * }
 *
 * To provide a visual, interactive surface for Flutter rendering and touch events, register a
 * {@link FlutterRenderer.RenderSurface} with {@link #setRenderSurface(FlutterRenderer.RenderSurface)}
 *
 * To receive callbacks for certain events that occur on the native side, register listeners:
 *
 * <ol>
 *   <li>{@link #addEngineLifecycleListener(EngineLifecycleListener)}</li>
 *   <li>{@link #addOnFirstFrameRenderedListener(OnFirstFrameRenderedListener)}</li>
 * </ol>
 *
 * To facilitate platform messages between Java and Dart running in Flutter, register a handler:
 *
 * {@link #setPlatformMessageHandler(PlatformMessageHandler)}
 *
 * To invoke a native method that is not associated with a platform view, invoke it statically:
 *
 * {@code
 *    String uri = FlutterJNI.nativeGetObservatoryUri();
 * }
 */
public class FlutterJNI {
  private static final String TAG = "FlutterJNI";

  @UiThread
  public static native boolean nativeGetIsSoftwareRenderingEnabled();

  @UiThread
  public static native String nativeGetObservatoryUri();
  
  private Long nativePlatformViewId;
  private FlutterRenderer.RenderSurface renderSurface;
  private AccessibilityDelegate accessibilityDelegate;
  private PlatformMessageHandler platformMessageHandler;
  private final Set<EngineLifecycleListener> engineLifecycleListeners = new HashSet<>();
  private final Set<OnFirstFrameRenderedListener> firstFrameListeners = new HashSet<>();

  /**
   * Sets the {@link FlutterRenderer.RenderSurface} delegate for the attached Flutter context.
   *
   * Flutter expects a user interface to exist on the platform side (Android), and that interface
   * is expected to offer some capabilities that Flutter depends upon. The {@link FlutterRenderer.RenderSurface}
   * interface represents those expectations.
   *
   * If an app includes a user interface that renders a Flutter UI then a {@link FlutterRenderer.RenderSurface}
   * should be set (this is the typical Flutter scenario). If no UI is being rendered, such as a
   * Flutter app that is running Dart code in the background, then no registration may be necessary.
   *
   * If no {@link FlutterRenderer.RenderSurface} is registered then related messages coming from
   * Flutter will be dropped (ignored).
   */
  @UiThread
  public void setRenderSurface(@Nullable FlutterRenderer.RenderSurface renderSurface) {
    this.renderSurface = renderSurface;
  }

  /**
   * Sets the {@link AccessibilityDelegate} for the attached Flutter context.
   *
   * The {@link AccessibilityDelegate} is responsible for maintaining an Android-side cache of
   * Flutter's semantics tree and custom accessibility actions. This cache should be hooked up
   * to Android's accessibility system.
   *
   * See {@link AccessibilityBridge} for an example of an {@link AccessibilityDelegate} and the
   * surrounding responsibilities.
   */
  @UiThread
  public void setAccessibilityDelegate(@Nullable AccessibilityDelegate accessibilityDelegate) {
    this.accessibilityDelegate = accessibilityDelegate;
  }

  /**
   * Invoked by native to send semantics tree updates from Flutter to Android.
   *
   * The {@code buffer} and {@code strings} form a communication protocol that is implemented here:
   * https://github.com/flutter/engine/blob/master/shell/platform/android/platform_view_android.cc#L207
   */
  @SuppressWarnings("unused")
  @UiThread
  private void updateSemantics(ByteBuffer buffer, String[] strings) {
    if (accessibilityDelegate != null) {
      accessibilityDelegate.updateSemantics(buffer, strings);
    }
    // TODO(mattcarroll): log dropped messages when in debug mode (https://github.com/flutter/flutter/issues/25391)
  }

  /**
   * Invoked by native to send new custom accessibility events from Flutter to Android.
   *
   * The {@code buffer} and {@code strings} form a communication protocol that is implemented here:
   * https://github.com/flutter/engine/blob/master/shell/platform/android/platform_view_android.cc#L207
   *
   * // TODO(cbracken): expand these docs to include more actionable information.
   */
  @SuppressWarnings("unused")
  @UiThread
  private void updateCustomAccessibilityActions(ByteBuffer buffer, String[] strings) {
    if (accessibilityDelegate != null) {
      accessibilityDelegate.updateCustomAccessibilityActions(buffer, strings);
    }
    // TODO(mattcarroll): log dropped messages when in debug mode (https://github.com/flutter/flutter/issues/25391)
  }

  // Called by native to notify first Flutter frame rendered.
  @SuppressWarnings("unused")
  @UiThread
  private void onFirstFrame() {
    if (renderSurface != null) {
      renderSurface.onFirstFrameRendered();
    }
    // TODO(mattcarroll): log dropped messages when in debug mode (https://github.com/flutter/flutter/issues/25391)

    for (OnFirstFrameRenderedListener listener : firstFrameListeners) {
      listener.onFirstFrameRendered();
    }
  }

  /**
   * Sets the handler for all platform messages that come from the attached platform view to Java.
   *
   * Communication between a specific Flutter context (Dart) and the host platform (Java) is
   * accomplished by passing messages. Messages can be sent from Java to Dart with the corresponding
   * {@code FlutterJNI} methods:
   * <ul>
   *   <li>{@link #dispatchPlatformMessage(String, ByteBuffer, int, int)}</li>
   *   <li>{@link #dispatchEmptyPlatformMessage(String, int)}</li>
   * </ul>
   *
   * {@code FlutterJNI} is also the recipient of all platform messages sent from its attached
   * Flutter context (AKA platform view). {@code FlutterJNI} does not know what to do with these
   * messages, so a handler is exposed to allow these messages to be processed in whatever manner is
   * desired:
   *
   * {@code setPlatformMessageHandler(PlatformMessageHandler)}
   *
   * If a message is received but no {@link PlatformMessageHandler} is registered, that message will
   * be dropped (ignored). Therefore, when using {@code FlutterJNI} to integrate a Flutter context
   * in an app, a {@link PlatformMessageHandler} must be registered for 2-way Java/Dart communication
   * to operate correctly. Moreover, the handler must be implemented such that fundamental platform
   * messages are handled as expected. See {@link FlutterNativeView} for an example implementation.
   */
  @UiThread
  public void setPlatformMessageHandler(@Nullable PlatformMessageHandler platformMessageHandler) {
    this.platformMessageHandler = platformMessageHandler;
  }

  // Called by native.
  @SuppressWarnings("unused")
  private void handlePlatformMessage(final String channel, byte[] message, final int replyId) {
    if (platformMessageHandler != null) {
      platformMessageHandler.handleMessageFromDart(channel, message, replyId);
    }
    // TODO(mattcarroll): log dropped messages when in debug mode (https://github.com/flutter/flutter/issues/25391)
  }

  // Called by native to respond to a platform message that we sent.
  @SuppressWarnings("unused")
  private void handlePlatformMessageResponse(int replyId, byte[] reply) {
    if (platformMessageHandler != null) {
      platformMessageHandler.handlePlatformMessageResponse(replyId, reply);
    }
    // TODO(mattcarroll): log dropped messages when in debug mode (https://github.com/flutter/flutter/issues/25391)
  }

  @UiThread
  public void addEngineLifecycleListener(@NonNull EngineLifecycleListener engineLifecycleListener) {
    engineLifecycleListeners.add(engineLifecycleListener);
  }

  @UiThread
  public void removeEngineLifecycleListener(@NonNull EngineLifecycleListener engineLifecycleListener) {
    engineLifecycleListeners.remove(engineLifecycleListener);
  }

  @UiThread
  public void addOnFirstFrameRenderedListener(@NonNull OnFirstFrameRenderedListener listener) {
    firstFrameListeners.add(listener);
  }

  @UiThread
  public void removeOnFirstFrameRenderedListener(@NonNull OnFirstFrameRenderedListener listener) {
    firstFrameListeners.remove(listener);
  }

  // TODO(mattcarroll): rename comments after refactor is done and their origin no longer matters (https://github.com/flutter/flutter/issues/25533)
  //----- Start from FlutterView -----
  @UiThread
  public void onSurfaceCreated(@NonNull Surface surface) {
    ensureAttachedToNative();
    nativeSurfaceCreated(nativePlatformViewId, surface);
  }

  private native void nativeSurfaceCreated(long nativePlatformViewId, Surface surface);

  @UiThread
  public void onSurfaceChanged(int width, int height) {
    ensureAttachedToNative();
    nativeSurfaceChanged(nativePlatformViewId, width, height);
  }

  private native void nativeSurfaceChanged(long nativePlatformViewId, int width, int height);

  @UiThread
  public void onSurfaceDestroyed() {
    ensureAttachedToNative();
    nativeSurfaceDestroyed(nativePlatformViewId);
  }

  private native void nativeSurfaceDestroyed(long nativePlatformViewId);

  @UiThread
  public void setViewportMetrics(
      float devicePixelRatio,
      int physicalWidth,
      int physicalHeight,
      int physicalPaddingTop,
      int physicalPaddingRight,
      int physicalPaddingBottom,
      int physicalPaddingLeft,
      int physicalViewInsetTop,
      int physicalViewInsetRight,
      int physicalViewInsetBottom,
      int physicalViewInsetLeft
  ) {
    ensureAttachedToNative();
    nativeSetViewportMetrics(
        nativePlatformViewId,
        devicePixelRatio,
        physicalWidth,
        physicalHeight,
        physicalPaddingTop,
        physicalPaddingRight,
        physicalPaddingBottom,
        physicalPaddingLeft,
        physicalViewInsetTop,
        physicalViewInsetRight,
        physicalViewInsetBottom,
        physicalViewInsetLeft
    );
  }

  private native void nativeSetViewportMetrics(
      long nativePlatformViewId,
      float devicePixelRatio,
      int physicalWidth,
      int physicalHeight,
      int physicalPaddingTop,
      int physicalPaddingRight,
      int physicalPaddingBottom,
      int physicalPaddingLeft,
      int physicalViewInsetTop,
      int physicalViewInsetRight,
      int physicalViewInsetBottom,
      int physicalViewInsetLeft
  );

  @UiThread
  public Bitmap getBitmap() {
    ensureAttachedToNative();
    return nativeGetBitmap(nativePlatformViewId);
  }

  private native Bitmap nativeGetBitmap(long nativePlatformViewId);

  @UiThread
  public void dispatchPointerDataPacket(ByteBuffer buffer, int position) {
    ensureAttachedToNative();
    nativeDispatchPointerDataPacket(nativePlatformViewId, buffer, position);
  }

  private native void nativeDispatchPointerDataPacket(long nativePlatformViewId,
                                                      ByteBuffer buffer,
                                                      int position);

  public void dispatchSemanticsAction(int id, @NonNull AccessibilityBridge.Action action) {
    dispatchSemanticsAction(id, action, null);
  }

  public void dispatchSemanticsAction(int id, @NonNull AccessibilityBridge.Action action, @Nullable Object args) {
    ensureAttachedToNative();

    ByteBuffer encodedArgs = null;
    int position = 0;
    if (args != null) {
      encodedArgs = StandardMessageCodec.INSTANCE.encodeMessage(args);
      position = encodedArgs.position();
    }
    dispatchSemanticsAction(id, action.value, encodedArgs, position);
  }

  @UiThread
  public void dispatchSemanticsAction(int id, int action, ByteBuffer args, int argsPosition) {
    ensureAttachedToNative();
    nativeDispatchSemanticsAction(nativePlatformViewId, id, action, args, argsPosition);
  }

  private native void nativeDispatchSemanticsAction(
      long nativePlatformViewId,
      int id,
      int action,
      ByteBuffer args,
      int argsPosition
  );

  @UiThread
  public void setSemanticsEnabled(boolean enabled) {
    ensureAttachedToNative();
    nativeSetSemanticsEnabled(nativePlatformViewId, enabled);
  }

  private native void nativeSetSemanticsEnabled(long nativePlatformViewId, boolean enabled);

  @UiThread
  public void setAccessibilityFeatures(int flags) {
    ensureAttachedToNative();
    nativeSetAccessibilityFeatures(nativePlatformViewId, flags);
  }

  private native void nativeSetAccessibilityFeatures(long nativePlatformViewId, int flags);

  @UiThread
  public void registerTexture(long textureId, SurfaceTexture surfaceTexture) {
    ensureAttachedToNative();
    nativeRegisterTexture(nativePlatformViewId, textureId, surfaceTexture);
  }

  private native void nativeRegisterTexture(long nativePlatformViewId, long textureId, SurfaceTexture surfaceTexture);

  @UiThread
  public void markTextureFrameAvailable(long textureId) {
    ensureAttachedToNative();
    nativeMarkTextureFrameAvailable(nativePlatformViewId, textureId);
  }

  private native void nativeMarkTextureFrameAvailable(long nativePlatformViewId, long textureId);

  @UiThread
  public void unregisterTexture(long textureId) {
    ensureAttachedToNative();
    nativeUnregisterTexture(nativePlatformViewId, textureId);
  }

  private native void nativeUnregisterTexture(long nativePlatformViewId, long textureId);
  //------- End from FlutterView -----

  // TODO(mattcarroll): rename comments after refactor is done and their origin no longer matters (https://github.com/flutter/flutter/issues/25533)
  //------ Start from FlutterNativeView ----
  public boolean isAttached() {
    return nativePlatformViewId != null;
  }

  @UiThread
  public void attachToNative(boolean isBackgroundView) {
    ensureNotAttachedToNative();
    nativePlatformViewId = nativeAttach(this, isBackgroundView);
  }

  private native long nativeAttach(FlutterJNI flutterJNI, boolean isBackgroundView);

  @UiThread
  public void detachFromNativeAndReleaseResources() {
    ensureAttachedToNative();
    nativeDestroy(nativePlatformViewId);
    nativePlatformViewId = null;
  }

  private native void nativeDestroy(long nativePlatformViewId);

  @UiThread
  public void runBundleAndSnapshotFromLibrary(
      @NonNull String[] prioritizedBundlePaths,
      @Nullable String entrypointFunctionName,
      @Nullable String pathToEntrypointFunction,
      @NonNull AssetManager assetManager
  ) {
    ensureAttachedToNative();
    nativeRunBundleAndSnapshotFromLibrary(
        nativePlatformViewId,
        prioritizedBundlePaths,
        entrypointFunctionName,
        pathToEntrypointFunction,
        assetManager
    );
  }

  private native void nativeRunBundleAndSnapshotFromLibrary(
      long nativePlatformViewId,
      @NonNull String[] prioritizedBundlePaths,
      @Nullable String entrypointFunctionName,
      @Nullable String pathToEntrypointFunction,
      @NonNull AssetManager manager
  );

  @UiThread
  public void dispatchEmptyPlatformMessage(String channel, int responseId) {
    ensureAttachedToNative();
    nativeDispatchEmptyPlatformMessage(nativePlatformViewId, channel, responseId);
  }

  // Send an empty platform message to Dart.
  private native void nativeDispatchEmptyPlatformMessage(
      long nativePlatformViewId,
      String channel,
      int responseId
  );

  @UiThread
  public void dispatchPlatformMessage(String channel, ByteBuffer message, int position, int responseId) {
    ensureAttachedToNative();
    nativeDispatchPlatformMessage(
        nativePlatformViewId,
        channel,
        message,
        position,
        responseId
    );
  }

  // Send a data-carrying platform message to Dart.
  private native void nativeDispatchPlatformMessage(
      long nativePlatformViewId,
      String channel,
      ByteBuffer message,
      int position,
      int responseId
  );

  @UiThread
  public void invokePlatformMessageEmptyResponseCallback(int responseId) {
    ensureAttachedToNative();
    nativeInvokePlatformMessageEmptyResponseCallback(nativePlatformViewId, responseId);
  }

  // Send an empty response to a platform message received from Dart.
  private native void nativeInvokePlatformMessageEmptyResponseCallback(
      long nativePlatformViewId,
      int responseId
  );

  @UiThread
  public void invokePlatformMessageResponseCallback(int responseId, ByteBuffer message, int position) {
    ensureAttachedToNative();
    nativeInvokePlatformMessageResponseCallback(
        nativePlatformViewId,
        responseId,
        message,
        position
    );
  }

  // Send a data-carrying response to a platform message received from Dart.
  private native void nativeInvokePlatformMessageResponseCallback(
      long nativePlatformViewId,
      int responseId,
      ByteBuffer message,
      int position
  );
  //------ End from FlutterNativeView ----

  // TODO(mattcarroll): rename comments after refactor is done and their origin no longer matters (https://github.com/flutter/flutter/issues/25533)
  //------ Start from Engine ---
  // Called by native.
  @SuppressWarnings("unused")
  private void onPreEngineRestart() {
    for (EngineLifecycleListener listener : engineLifecycleListeners) {
      listener.onPreEngineRestart();
    }
  }
  //------ End from Engine ---

  private void ensureNotAttachedToNative() {
    if (nativePlatformViewId != null) {
      throw new RuntimeException("Cannot execute operation because FlutterJNI is attached to native.");
    }
  }

  private void ensureAttachedToNative() {
    if (nativePlatformViewId == null) {
      throw new RuntimeException("Cannot execute operation because FlutterJNI is not attached to native.");
    }
  }

  /**
   * Delegate responsible for creating and updating Android-side caches of Flutter's semantics
   * tree and custom accessibility actions.
   *
   * {@link AccessibilityBridge} is an example of an {@code AccessibilityDelegate}.
   */
  public interface AccessibilityDelegate {
    /**
     * Sends new custom accessibility actions from Flutter to Android.
     *
     * Implementers are expected to maintain an Android-side cache of custom accessibility actions.
     * This method provides new actions to add to that cache.
     */
    void updateCustomAccessibilityActions(ByteBuffer buffer, String[] strings);

    /**
     * Sends new {@code SemanticsNode} information from Flutter to Android.
     *
     * Implementers are expected to maintain an Android-side cache of Flutter's semantics tree.
     * This method provides updates from Flutter for the Android-side semantics tree cache.
     */
    void updateSemantics(ByteBuffer buffer, String[] strings);
  }
}
