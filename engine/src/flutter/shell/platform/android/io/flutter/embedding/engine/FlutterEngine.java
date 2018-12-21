// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.embedding.engine;

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
 * {@link DartExecutor} and then use {@link DartExecutor#runFromBundle(FlutterRunArguments)}.
 * The {@link DartExecutor#runFromBundle(FlutterRunArguments)} method must not be invoked twice on the same
 * {@code FlutterEngine}.
 *
 * To start rendering Flutter content to the screen, use {@link #getRenderer()} to obtain a
 * {@link FlutterRenderer} and then attach a {@link FlutterRenderer.RenderSurface}.  Consider using
 * a {@link io.flutter.embedding.android.FlutterView} as a {@link FlutterRenderer.RenderSurface}.
 */
public class FlutterEngine {
  // TODO(mattcarroll): bring in FlutterEngine implementation in future PR

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
