// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.embedding.android;

import android.app.Activity;

/**
 * An embedding component whose lifetime is bound to a single {@link Activity}.
 *
 * <p>Some parts of the Android embedding, such as {@link io.flutter.plugin.platform.PlatformPlugin}
 * and {@link io.flutter.plugin.view.SensitiveContentPlugin}, hold a reference to the {@code
 * Activity} that currently hosts the Flutter experience. A {@link
 * io.flutter.embedding.engine.FlutterEngine} can outlive that {@code Activity} and later be
 * attached to a different one, so these components must be created every time the engine is
 * attached to an {@code Activity} and destroyed every time it is detached. Otherwise the destroyed
 * {@code Activity} stays reachable through the engine's channels and leaks.
 *
 * <p>{@code FlutterActivityAndFragmentDelegate} tracks every {@code ActivityScopedPlugin} that was
 * created while attaching to an {@code Activity} and calls {@link #destroy()} on each of them when
 * it detaches, so a component that implements this interface cannot be forgotten on detach.
 *
 * <p>This is not the plugin API used by Flutter plugins from pub.dev. Those implement {@link
 * io.flutter.embedding.engine.plugins.FlutterPlugin} and, when they need an {@code Activity},
 * {@link io.flutter.embedding.engine.plugins.activity.ActivityAware}.
 */
public interface ActivityScopedPlugin {
  /**
   * Unregisters this component from the {@link io.flutter.embedding.engine.FlutterEngine}, for
   * example by removing itself as the handler of the channel it was listening on, so that neither
   * this component nor the {@link Activity} it was created for stays reachable from the engine.
   *
   * <p>Called exactly once, when the hosting {@code Activity} is detached from the engine. No other
   * method may be invoked on this component afterwards.
   */
  void destroy();
}
