// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.embedding.engine;

import android.arch.lifecycle.Lifecycle;
import android.arch.lifecycle.LifecycleOwner;
import android.content.Context;
import android.support.annotation.NonNull;

import java.util.HashSet;
import java.util.Set;

import io.flutter.Log;
import io.flutter.embedding.engine.dart.DartExecutor;
import io.flutter.embedding.engine.plugins.PluginRegistry;
import io.flutter.embedding.engine.plugins.activity.ActivityControlSurface;
import io.flutter.embedding.engine.plugins.broadcastreceiver.BroadcastReceiverControlSurface;
import io.flutter.embedding.engine.plugins.contentprovider.ContentProviderControlSurface;
import io.flutter.embedding.engine.plugins.service.ServiceControlSurface;
import io.flutter.embedding.engine.renderer.FlutterRenderer;
import io.flutter.embedding.engine.renderer.RenderSurface;
import io.flutter.embedding.engine.systemchannels.AccessibilityChannel;
import io.flutter.embedding.engine.systemchannels.KeyEventChannel;
import io.flutter.embedding.engine.systemchannels.LifecycleChannel;
import io.flutter.embedding.engine.systemchannels.LocalizationChannel;
import io.flutter.embedding.engine.systemchannels.NavigationChannel;
import io.flutter.embedding.engine.systemchannels.PlatformChannel;
import io.flutter.embedding.engine.systemchannels.SettingsChannel;
import io.flutter.embedding.engine.systemchannels.SystemChannel;
import io.flutter.embedding.engine.systemchannels.TextInputChannel;
import io.flutter.plugin.platform.PlatformViewsController;

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
 * {@link FlutterRenderer} and then attach a {@link RenderSurface}.  Consider using
 * a {@link io.flutter.embedding.android.FlutterView} as a {@link RenderSurface}.
 */
// TODO(mattcarroll): re-evaluate system channel APIs - some are not well named or differentiated
public class FlutterEngine implements LifecycleOwner {
  private static final String TAG = "FlutterEngine";

  @NonNull
  private final FlutterJNI flutterJNI;
  @NonNull
  private final FlutterRenderer renderer;
  @NonNull
  private final DartExecutor dartExecutor;
  @NonNull
  private final FlutterEnginePluginRegistry pluginRegistry;
  @NonNull
  private final FlutterEngineAndroidLifecycle androidLifecycle;

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

  // Platform Views.
  @NonNull
  private final PlatformViewsController platformViewsController;

  // Engine Lifecycle.
  @NonNull
  private final Set<EngineLifecycleListener> engineLifecycleListeners = new HashSet<>();
  @NonNull
  private final EngineLifecycleListener engineLifecycleListener = new EngineLifecycleListener() {
    @SuppressWarnings("unused")
    public void onPreEngineRestart() {
      Log.v(TAG, "onPreEngineRestart()");
      for (EngineLifecycleListener lifecycleListener : engineLifecycleListeners) {
        lifecycleListener.onPreEngineRestart();
      }
    }
  };

  /**
   * Constructs a new {@code FlutterEngine}.
   *
   * {@code FlutterMain.startInitialization} must be called before constructing a {@code FlutterEngine}
   * to load the native libraries needed to attach to JNI.
   *
   * A new {@code FlutterEngine} does not execute any Dart code automatically. See
   * {@link #getDartExecutor()} and {@link DartExecutor#executeDartEntrypoint(DartExecutor.DartEntrypoint)}
   * to begin executing Dart code within this {@code FlutterEngine}.
   *
   * A new {@code FlutterEngine} will not display any UI until a
   * {@link RenderSurface} is registered. See
   * {@link #getRenderer()} and {@link FlutterRenderer#startRenderingToSurface(RenderSurface)}.
   *
   * A new {@code FlutterEngine} does not come with any Flutter plugins attached. To attach plugins,
   * see {@link #getPlugins()}.
   *
   * A new {@code FlutterEngine} does come with all default system channels attached.
   */
  public FlutterEngine(@NonNull Context context) {
    this.flutterJNI = new FlutterJNI();
    flutterJNI.addEngineLifecycleListener(engineLifecycleListener);
    attachToJni();

    this.dartExecutor = new DartExecutor(flutterJNI, context.getAssets());
    this.dartExecutor.onAttachedToJNI();

    // TODO(mattcarroll): FlutterRenderer is temporally coupled to attach(). Remove that coupling if possible.
    this.renderer = new FlutterRenderer(flutterJNI);

    accessibilityChannel = new AccessibilityChannel(dartExecutor, flutterJNI);
    keyEventChannel = new KeyEventChannel(dartExecutor);
    lifecycleChannel = new LifecycleChannel(dartExecutor);
    localizationChannel = new LocalizationChannel(dartExecutor);
    navigationChannel = new NavigationChannel(dartExecutor);
    platformChannel = new PlatformChannel(dartExecutor);
    settingsChannel = new SettingsChannel(dartExecutor);
    systemChannel = new SystemChannel(dartExecutor);
    textInputChannel = new TextInputChannel(dartExecutor);

    platformViewsController = new PlatformViewsController();

    androidLifecycle = new FlutterEngineAndroidLifecycle(this);
    this.pluginRegistry = new FlutterEnginePluginRegistry(
      context.getApplicationContext(),
      this,
        androidLifecycle
    );
  }

  private void attachToJni() {
    Log.v(TAG, "Attaching to JNI.");
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
   * Cleans up all components within this {@code FlutterEngine} and then detaches from Flutter's
   * native implementation.
   *
   * This {@code FlutterEngine} instance should be discarded after invoking this method.
   */
  public void destroy() {
    Log.d(TAG, "Destroying.");
    // The order that these things are destroyed is important.
    pluginRegistry.destroy();
    dartExecutor.onDetachedFromJNI();
    flutterJNI.removeEngineLifecycleListener(engineLifecycleListener);
    flutterJNI.detachFromNativeAndReleaseResources();
  }

  /**
   * Adds a {@code listener} to be notified of Flutter engine lifecycle events, e.g.,
   * {@code onPreEngineStart()}.
   */
  public void addEngineLifecycleListener(@NonNull EngineLifecycleListener listener) {
    engineLifecycleListeners.add(listener);
  }

  /**
   * Removes a {@code listener} that was previously added with
   * {@link #addEngineLifecycleListener(EngineLifecycleListener)}.
   */
  public void removeEngineLifecycleListener(@NonNull EngineLifecycleListener listener) {
    engineLifecycleListeners.remove(listener);
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
   * a {@link RenderSurface} to this
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

  /**
   * Plugin registry, which registers plugins that want to be applied to this {@code FlutterEngine}.
   */
  @NonNull
  public PluginRegistry getPlugins() {
    return pluginRegistry;
  }

  /**
   * {@code PlatformViewsController}, which controls all platform views running within
   * this {@code FlutterEngine}.
   */
  @NonNull
  public PlatformViewsController getPlatformViewsController() {
    return platformViewsController;
  }

  @NonNull
  public ActivityControlSurface getActivityControlSurface() {
    return pluginRegistry;
  }

  @NonNull
  public ServiceControlSurface getServiceControlSurface() {
    return pluginRegistry;
  }

  @NonNull
  public BroadcastReceiverControlSurface getBroadcastReceiverControlSurface() {
    return pluginRegistry;
  }

  @NonNull
  public ContentProviderControlSurface getContentProviderControlSurface() {
    return pluginRegistry;
  }

  // TODO(mattcarroll): determine if we really need to expose this from FlutterEngine vs making PluginBinding a LifecycleOwner
  @NonNull
  @Override
  public Lifecycle getLifecycle() {
    return androidLifecycle;
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
