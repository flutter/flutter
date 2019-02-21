// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.embedding.engine;

import android.content.Context;
import android.support.annotation.NonNull;
import android.support.annotation.Nullable;

import io.flutter.app.FlutterPluginRegistry;
import io.flutter.embedding.engine.dart.DartExecutor;
import io.flutter.embedding.engine.renderer.FlutterRenderer;

/**
 * A single Flutter execution environment.
 *
 * WARNING: THIS CLASS IS EXPERIMENTAL. DO NOT SHIP A DEPENDENCY ON THIS CODE.
 * IF YOU USE IT, WE WILL BREAK YOU.
 *
 * A {@code FlutterEngine} can execute in the background, or it can be rendered to the screen by
 * using the accompanying {@link FlutterRenderer}.  Rendering can be started and stopped, thus
 * allowing a {@code FlutterEngine} to move from UI interaction to data-only processing and then
 * back to UI interaction.
 *
 * Multiple {@code FlutterEngine}s may exist, execute Dart code, and render UIs within a single
 * Android app.
 *
 * To start running Flutter within this {@code FlutterEngine}, get a reference to this engine's
 * {@link DartExecutor} and then use {@link DartExecutor#executeDartEntrypoint(DartExecutor.DartEntrypoint)}.
 * The {@link DartExecutor#executeDartEntrypoint(DartExecutor.DartEntrypoint)} method must not be
 * invoked twice on the same {@code FlutterEngine}.
 *
 * To start rendering Flutter content to the screen, use {@link #getRenderer()} to obtain a
 * {@link FlutterRenderer} and then attach a {@link FlutterRenderer.RenderSurface}.  Consider using
 * a {@link io.flutter.embedding.android.FlutterView} as a {@link FlutterRenderer.RenderSurface}.
 */
public class FlutterEngine {
  private static final String TAG = "FlutterEngine";

  @NonNull
  private final FlutterJNI flutterJNI;
  @NonNull
  private final FlutterRenderer renderer;
  @NonNull
  private final DartExecutor dartExecutor;
  // TODO(mattcarroll): integrate system channels with FlutterEngine
  @NonNull
  private final FlutterPluginRegistry pluginRegistry;

  private final EngineLifecycleListener engineLifecycleListener = new EngineLifecycleListener() {
    @SuppressWarnings("unused")
    public void onPreEngineRestart() {
      pluginRegistry.onPreEngineRestart();
    }
  };

  /**
   * Constructs a new {@code FlutterEngine}.
   *
   * A new {@code FlutterEngine} does not execute any Dart code automatically. See
   * {@link #getDartExecutor()} and {@link DartExecutor#executeDartEntrypoint(DartExecutor.DartEntrypoint)}
   * to begin executing Dart code within this {@code FlutterEngine}.
   *
   * A new {@code FlutterEngine} will not display any UI until a
   * {@link io.flutter.embedding.engine.renderer.FlutterRenderer.RenderSurface} is registered. See
   * {@link #getRenderer()} and {@link FlutterRenderer#attachToRenderSurface(FlutterRenderer.RenderSurface)}.
   *
   * A new {@code FlutterEngine} does not come with any Flutter plugins attached. To attach plugins,
   * see {@link #getPluginRegistry()}.
   *
   * A new {@code FlutterEngine} does come with all default system channels attached.
   */
  public FlutterEngine(@NonNull Context context) {
    this.flutterJNI = new FlutterJNI();
    flutterJNI.addEngineLifecycleListener(engineLifecycleListener);
    attachToJni();

    this.dartExecutor = new DartExecutor(flutterJNI);
    this.dartExecutor.onAttachedToJNI();

    // TODO(mattcarroll): FlutterRenderer is temporally coupled to attach(). Remove that coupling if possible.
    this.renderer = new FlutterRenderer(flutterJNI);

    this.pluginRegistry = new FlutterPluginRegistry(this, context);
  }

  private void attachToJni() {
    // TODO(mattcarroll): update native call to not take in "isBackgroundView"
    flutterJNI.attachToNative(false);

    if (!isAttachedToJni()) {
      throw new RuntimeException("FlutterEngine failed to attach to its native Object reference.");
    }
  }

  @SuppressWarnings("BooleanMethodIsAlwaysInverted")
  private boolean isAttachedToJni() {
    return flutterJNI.isAttached();
  }

  /**
   * Detaches this {@code FlutterEngine} from Flutter's native implementation, but allows
   * reattachment later.
   *
   * // TODO(mattcarroll): document use-cases for this behavior.
   */
  public void detachFromJni() {
    pluginRegistry.detach();
    dartExecutor.onDetachedFromJNI();
    flutterJNI.removeEngineLifecycleListener(engineLifecycleListener);
    // TODO(mattcarroll): investigate detach vs destroy. document user-cases. update code if needed.
    flutterJNI.detachFromNativeButKeepNativeResources();
  }

  /**
   * Cleans up all components within this {@code FlutterEngine} and then detaches from Flutter's
   * native implementation.
   *
   * This {@code FlutterEngine} instance should be discarded after invoking this method.
   */
  public void destroy() {
    pluginRegistry.destroy();
    dartExecutor.onDetachedFromJNI();
    flutterJNI.removeEngineLifecycleListener(engineLifecycleListener);
    flutterJNI.detachFromNativeAndReleaseResources();
  }

  /**
   * The Dart execution context associated with this {@code FlutterEngine}.
   *
   * The {@link DartExecutor} can be used to start executing Dart code from a given entrypoint.
   * See {@link DartExecutor#executeDartEntrypoint(DartExecutor.DartEntrypoint)}.
   *
   * Use the {@link DartExecutor} to connect any desired message channels and method channels
   * to facilitate communication between Android and Dart/Flutter.
   */
  @NonNull
  public DartExecutor getDartExecutor() {
    return dartExecutor;
  }

  /**
   * The rendering system associated with this {@code FlutterEngine}.
   *
   * To render a Flutter UI that is produced by this {@code FlutterEngine}'s Dart code, attach
   * a {@link io.flutter.embedding.engine.renderer.FlutterRenderer.RenderSurface} to this
   * {@link FlutterRenderer}.
   */
  @NonNull
  public FlutterRenderer getRenderer() {
    return renderer;
  }

  // TODO(mattcarroll): propose a robust story for plugin backward compability and future facing API.
  @NonNull
  public FlutterPluginRegistry getPluginRegistry() {
    return pluginRegistry;
  }

  /**
   * Lifecycle callbacks for Flutter engine lifecycle events.
   */
  public interface EngineLifecycleListener {
    /**
     * Lifecycle callback invoked before a hot restart of the Flutter engine.
     */
    void onPreEngineRestart();
  }
}
