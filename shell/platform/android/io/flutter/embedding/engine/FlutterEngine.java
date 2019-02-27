// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.embedding.engine;

import android.content.Context;
import android.support.annotation.NonNull;

import io.flutter.app.FlutterPluginRegistry;
import io.flutter.embedding.engine.dart.DartExecutor;
import io.flutter.embedding.engine.renderer.FlutterRenderer;
import io.flutter.embedding.engine.systemchannels.AccessibilityChannel;
import io.flutter.embedding.engine.systemchannels.KeyEventChannel;
import io.flutter.embedding.engine.systemchannels.LifecycleChannel;
import io.flutter.embedding.engine.systemchannels.LocalizationChannel;
import io.flutter.embedding.engine.systemchannels.NavigationChannel;
import io.flutter.embedding.engine.systemchannels.PlatformChannel;
import io.flutter.embedding.engine.systemchannels.SettingsChannel;
import io.flutter.embedding.engine.systemchannels.SystemChannel;
import io.flutter.embedding.engine.systemchannels.TextInputChannel;

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
// TODO(mattcarroll): re-evaluate system channel APIs - some are not well named or differentiated
public class FlutterEngine {
  private static final String TAG = "FlutterEngine";

  @NonNull
  private final FlutterJNI flutterJNI;
  @NonNull
  private final FlutterRenderer renderer;
  @NonNull
  private final DartExecutor dartExecutor;
  @NonNull
  private final FlutterPluginRegistry pluginRegistry;

  // System channels.
  @NonNull
  private final AccessibilityChannel accessibilityChannel;
  @NonNull
  private final KeyEventChannel keyEventChannel;
  @NonNull
  private final LifecycleChannel lifecycleChannel;
  @NonNull
  private final LocalizationChannel localizationChannel;
  @NonNull
  private final NavigationChannel navigationChannel;
  @NonNull
  private final PlatformChannel platformChannel;
  @NonNull
  private final SettingsChannel settingsChannel;
  @NonNull
  private final SystemChannel systemChannel;
  @NonNull
  private final TextInputChannel textInputChannel;

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

    accessibilityChannel = new AccessibilityChannel(dartExecutor);
    keyEventChannel = new KeyEventChannel(dartExecutor);
    lifecycleChannel = new LifecycleChannel(dartExecutor);
    localizationChannel = new LocalizationChannel(dartExecutor);
    navigationChannel = new NavigationChannel(dartExecutor);
    platformChannel = new PlatformChannel(dartExecutor);
    settingsChannel = new SettingsChannel(dartExecutor);
    systemChannel = new SystemChannel(dartExecutor);
    textInputChannel = new TextInputChannel(dartExecutor);

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

  /**
   * System channel that sends accessibility requests and events from Flutter to Android.
   */
  @NonNull
  public AccessibilityChannel getAccessibilityChannel() {
    return accessibilityChannel;
  }

  /**
   * System channel that sends key events from Android to Flutter.
   */
  @NonNull
  public KeyEventChannel getKeyEventChannel() {
    return keyEventChannel;
  }

  /**
   * System channel that sends Android lifecycle events to Flutter.
   */
  @NonNull
  public LifecycleChannel getLifecycleChannel() {
    return lifecycleChannel;
  }

  /**
   * System channel that sends locale data from Android to Flutter.
   */
  @NonNull
  public LocalizationChannel getLocalizationChannel() {
    return localizationChannel;
  }

  /**
   * System channel that sends Flutter navigation commands from Android to Flutter.
   */
  @NonNull
  public NavigationChannel getNavigationChannel() {
    return navigationChannel;
  }

  /**
   * System channel that sends platform-oriented requests and information to Flutter,
   * e.g., requests to play sounds, requests for haptics, system chrome settings, etc.
   */
  @NonNull
  public PlatformChannel getPlatformChannel() {
    return platformChannel;
  }

  /**
   * System channel that sends platform/user settings from Android to Flutter, e.g.,
   * time format, scale factor, etc.
   */
  @NonNull
  public SettingsChannel getSettingsChannel() {
    return settingsChannel;
  }

  /**
   * System channel that sends memory pressure warnings from Android to Flutter.
   */
  @NonNull
  public SystemChannel getSystemChannel() {
    return systemChannel;
  }

  /**
   * System channel that sends and receives text input requests and state.
   */
  @NonNull
  public TextInputChannel getTextInputChannel() {
    return textInputChannel;
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
