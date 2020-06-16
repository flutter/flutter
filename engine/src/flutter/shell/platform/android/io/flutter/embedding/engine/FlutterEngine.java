// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.embedding.engine;

import android.content.Context;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import io.flutter.Log;
import io.flutter.embedding.engine.dart.DartExecutor;
import io.flutter.embedding.engine.loader.FlutterLoader;
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
import io.flutter.embedding.engine.systemchannels.MouseCursorChannel;
import io.flutter.embedding.engine.systemchannels.NavigationChannel;
import io.flutter.embedding.engine.systemchannels.PlatformChannel;
import io.flutter.embedding.engine.systemchannels.RestorationChannel;
import io.flutter.embedding.engine.systemchannels.SettingsChannel;
import io.flutter.embedding.engine.systemchannels.SystemChannel;
import io.flutter.embedding.engine.systemchannels.TextInputChannel;
import io.flutter.plugin.localization.LocalizationPlugin;
import io.flutter.plugin.platform.PlatformViewsController;
import java.lang.reflect.Method;
import java.util.HashSet;
import java.util.Set;

/**
 * A single Flutter execution environment.
 *
 * <p>The {@code FlutterEngine} is the container through which Dart code can be run in an Android
 * application.
 *
 * <p>Dart code in a {@code FlutterEngine} can execute in the background, or it can be render to the
 * screen by using the accompanying {@link FlutterRenderer} and Dart code using the Flutter
 * framework on the Dart side. Rendering can be started and stopped, thus allowing a {@code
 * FlutterEngine} to move from UI interaction to data-only processing and then back to UI
 * interaction.
 *
 * <p>Multiple {@code FlutterEngine}s may exist, execute Dart code, and render UIs within a single
 * Android app. Flutter at this point makes no guarantees on the performance of running multiple
 * engines. Use at your own risk. See https://github.com/flutter/flutter/issues/37644 for details.
 *
 * <p>To start running Dart and/or Flutter within this {@code FlutterEngine}, get a reference to
 * this engine's {@link DartExecutor} and then use {@link
 * DartExecutor#executeDartEntrypoint(DartExecutor.DartEntrypoint)}. The {@link
 * DartExecutor#executeDartEntrypoint(DartExecutor.DartEntrypoint)} method must not be invoked twice
 * on the same {@code FlutterEngine}.
 *
 * <p>To start rendering Flutter content to the screen, use {@link #getRenderer()} to obtain a
 * {@link FlutterRenderer} and then attach a {@link RenderSurface}. Consider using a {@link
 * io.flutter.embedding.android.FlutterView} as a {@link RenderSurface}.
 *
 * <p>Instatiating the first {@code FlutterEngine} per process will also load the Flutter engine's
 * native library and start the Dart VM. Subsequent {@code FlutterEngine}s will run on the same VM
 * instance but will have their own Dart <a
 * href="https://api.dartlang.org/stable/dart-isolate/Isolate-class.html">Isolate</a> when the
 * {@link DartExecutor} is run. Each Isolate is a self-contained Dart environment and cannot
 * communicate with each other except via Isolate ports.
 */
public class FlutterEngine {
  private static final String TAG = "FlutterEngine";

  @NonNull private final FlutterJNI flutterJNI;
  @NonNull private final FlutterRenderer renderer;
  @NonNull private final DartExecutor dartExecutor;
  @NonNull private final FlutterEnginePluginRegistry pluginRegistry;
  @NonNull private final LocalizationPlugin localizationPlugin;

  // System channels.
  @NonNull private final AccessibilityChannel accessibilityChannel;
  @NonNull private final KeyEventChannel keyEventChannel;
  @NonNull private final LifecycleChannel lifecycleChannel;
  @NonNull private final LocalizationChannel localizationChannel;
  @NonNull private final MouseCursorChannel mouseCursorChannel;
  @NonNull private final NavigationChannel navigationChannel;
  @NonNull private final RestorationChannel restorationChannel;
  @NonNull private final PlatformChannel platformChannel;
  @NonNull private final SettingsChannel settingsChannel;
  @NonNull private final SystemChannel systemChannel;
  @NonNull private final TextInputChannel textInputChannel;

  // Platform Views.
  @NonNull private final PlatformViewsController platformViewsController;

  // Engine Lifecycle.
  @NonNull private final Set<EngineLifecycleListener> engineLifecycleListeners = new HashSet<>();

  @NonNull
  private final EngineLifecycleListener engineLifecycleListener =
      new EngineLifecycleListener() {
        @SuppressWarnings("unused")
        public void onPreEngineRestart() {
          Log.v(TAG, "onPreEngineRestart()");
          for (EngineLifecycleListener lifecycleListener : engineLifecycleListeners) {
            lifecycleListener.onPreEngineRestart();
          }

          platformViewsController.onPreEngineRestart();
          restorationChannel.clearData();
        }
      };

  /**
   * Constructs a new {@code FlutterEngine}.
   *
   * <p>A new {@code FlutterEngine} does not execute any Dart code automatically. See {@link
   * #getDartExecutor()} and {@link DartExecutor#executeDartEntrypoint(DartExecutor.DartEntrypoint)}
   * to begin executing Dart code within this {@code FlutterEngine}.
   *
   * <p>A new {@code FlutterEngine} will not display any UI until a {@link RenderSurface} is
   * registered. See {@link #getRenderer()} and {@link
   * FlutterRenderer#startRenderingToSurface(RenderSurface)}.
   *
   * <p>A new {@code FlutterEngine} automatically attaches all plugins. See {@link #getPlugins()}.
   *
   * <p>A new {@code FlutterEngine} does come with all default system channels attached.
   *
   * <p>The first {@code FlutterEngine} instance constructed per process will also load the Flutter
   * native library and start a Dart VM.
   *
   * <p>In order to pass Dart VM initialization arguments (see {@link
   * io.flutter.embedding.engine.FlutterShellArgs}) when creating the VM, manually set the
   * initialization arguments by calling {@link FlutterLoader#startInitialization(Context)} and
   * {@link FlutterLoader#ensureInitializationComplete(Context, String[])}.
   */
  public FlutterEngine(@NonNull Context context) {
    this(context, null);
  }

  /**
   * Same as {@link #FlutterEngine(Context)} with added support for passing Dart VM arguments.
   *
   * <p>If the Dart VM has already started, the given arguments will have no effect.
   */
  public FlutterEngine(@NonNull Context context, @Nullable String[] dartVmArgs) {
    this(context, FlutterLoader.getInstance(), new FlutterJNI(), dartVmArgs, true);
  }

  /**
   * Same as {@link #FlutterEngine(Context)} with added support for passing Dart VM arguments and
   * avoiding automatic plugin registration.
   *
   * <p>If the Dart VM has already started, the given arguments will have no effect.
   */
  public FlutterEngine(
      @NonNull Context context,
      @Nullable String[] dartVmArgs,
      boolean automaticallyRegisterPlugins) {
    this(
        context,
        FlutterLoader.getInstance(),
        new FlutterJNI(),
        dartVmArgs,
        automaticallyRegisterPlugins);
  }

  /**
   * Same as {@link #FlutterEngine(Context, String[], boolean)} with added support for configuring
   * whether the engine will receive restoration data.
   *
   * <p>The {@code waitForRestorationData} flag controls whether the engine delays responding to
   * requests from the framework for restoration data until that data has been provided to the
   * engine via {@code RestorationChannel.setRestorationData(byte[] data)}. If the flag is false,
   * the framework may temporarily initialize itself to default values before the restoration data
   * has been made available to the engine. Setting {@code waitForRestorationData} to true avoids
   * this extra work by delaying initialization until the data is available.
   *
   * <p>When {@code waitForRestorationData} is set, {@code
   * RestorationChannel.setRestorationData(byte[] data)} must be called at a later point in time. If
   * it later turns out that no restoration data is available to restore the framework from, that
   * method must still be called with null as an argument to indicate "no data".
   *
   * <p>If the framework never requests the restoration data, this flag has no effect.
   */
  public FlutterEngine(
      @NonNull Context context,
      @Nullable String[] dartVmArgs,
      boolean automaticallyRegisterPlugins,
      boolean waitForRestorationData) {
    this(
        context,
        FlutterLoader.getInstance(),
        new FlutterJNI(),
        new PlatformViewsController(),
        dartVmArgs,
        automaticallyRegisterPlugins,
        waitForRestorationData);
  }

  /**
   * Same as {@link #FlutterEngine(Context, FlutterLoader, FlutterJNI, String[])} but with no Dart
   * VM flags.
   *
   * <p>{@code flutterJNI} should be a new instance that has never been attached to an engine
   * before.
   */
  public FlutterEngine(
      @NonNull Context context,
      @NonNull FlutterLoader flutterLoader,
      @NonNull FlutterJNI flutterJNI) {
    this(context, flutterLoader, flutterJNI, null, true);
  }

  /**
   * Same as {@link #FlutterEngine(Context, FlutterLoader, FlutterJNI)}, plus Dart VM flags in
   * {@code dartVmArgs}, and control over whether plugins are automatically registered with this
   * {@code FlutterEngine} in {@code automaticallyRegisterPlugins}. If plugins are automatically
   * registered, then they are registered during the execution of this constructor.
   */
  public FlutterEngine(
      @NonNull Context context,
      @NonNull FlutterLoader flutterLoader,
      @NonNull FlutterJNI flutterJNI,
      @Nullable String[] dartVmArgs,
      boolean automaticallyRegisterPlugins) {
    this(
        context,
        flutterLoader,
        flutterJNI,
        new PlatformViewsController(),
        dartVmArgs,
        automaticallyRegisterPlugins);
  }

  /**
   * Same as {@link #FlutterEngine(Context, FlutterLoader, FlutterJNI, String[], boolean)}, plus the
   * ability to provide a custom {@code PlatformViewsController}.
   */
  public FlutterEngine(
      @NonNull Context context,
      @NonNull FlutterLoader flutterLoader,
      @NonNull FlutterJNI flutterJNI,
      @NonNull PlatformViewsController platformViewsController,
      @Nullable String[] dartVmArgs,
      boolean automaticallyRegisterPlugins) {
    this(
        context,
        flutterLoader,
        flutterJNI,
        platformViewsController,
        dartVmArgs,
        automaticallyRegisterPlugins,
        false);
  }

  /** Fully configurable {@code FlutterEngine} constructor. */
  public FlutterEngine(
      @NonNull Context context,
      @NonNull FlutterLoader flutterLoader,
      @NonNull FlutterJNI flutterJNI,
      @NonNull PlatformViewsController platformViewsController,
      @Nullable String[] dartVmArgs,
      boolean automaticallyRegisterPlugins,
      boolean waitForRestorationData) {
    this.dartExecutor = new DartExecutor(flutterJNI, context.getAssets());
    this.dartExecutor.onAttachedToJNI();

    accessibilityChannel = new AccessibilityChannel(dartExecutor, flutterJNI);
    keyEventChannel = new KeyEventChannel(dartExecutor);
    lifecycleChannel = new LifecycleChannel(dartExecutor);
    localizationChannel = new LocalizationChannel(dartExecutor);
    mouseCursorChannel = new MouseCursorChannel(dartExecutor);
    navigationChannel = new NavigationChannel(dartExecutor);
    platformChannel = new PlatformChannel(dartExecutor);
    restorationChannel = new RestorationChannel(dartExecutor, waitForRestorationData);
    settingsChannel = new SettingsChannel(dartExecutor);
    systemChannel = new SystemChannel(dartExecutor);
    textInputChannel = new TextInputChannel(dartExecutor);

    this.localizationPlugin = new LocalizationPlugin(context, localizationChannel);

    this.flutterJNI = flutterJNI;
    flutterLoader.startInitialization(context.getApplicationContext());
    flutterLoader.ensureInitializationComplete(context, dartVmArgs);

    flutterJNI.addEngineLifecycleListener(engineLifecycleListener);
    flutterJNI.setPlatformViewsController(platformViewsController);
    flutterJNI.setLocalizationPlugin(localizationPlugin);
    attachToJni();

    // TODO(mattcarroll): FlutterRenderer is temporally coupled to attach(). Remove that coupling if
    // possible.
    this.renderer = new FlutterRenderer(flutterJNI);

    this.platformViewsController = platformViewsController;
    this.platformViewsController.onAttachedToJNI();

    this.pluginRegistry =
        new FlutterEnginePluginRegistry(context.getApplicationContext(), this, flutterLoader);

    if (automaticallyRegisterPlugins) {
      registerPlugins();
    }
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
   * Registers all plugins that an app lists in its pubspec.yaml.
   *
   * <p>The Flutter tool generates a class called GeneratedPluginRegistrant, which includes the code
   * necessary to register every plugin in the pubspec.yaml with a given {@code FlutterEngine}. The
   * GeneratedPluginRegistrant must be generated per app, because each app uses different sets of
   * plugins. Therefore, the Android embedding cannot place a compile-time dependency on this
   * generated class. This method uses reflection to attempt to locate the generated file and then
   * use it at runtime.
   *
   * <p>This method fizzles if the GeneratedPluginRegistrant cannot be found or invoked. This
   * situation should never occur, but if any eventuality comes up that prevents an app from using
   * this behavior, that app can still write code that explicitly registers plugins.
   */
  private void registerPlugins() {
    try {
      Class<?> generatedPluginRegistrant =
          Class.forName("io.flutter.plugins.GeneratedPluginRegistrant");
      Method registrationMethod =
          generatedPluginRegistrant.getDeclaredMethod("registerWith", FlutterEngine.class);
      registrationMethod.invoke(null, this);
    } catch (Exception e) {
      Log.w(
          TAG,
          "Tried to automatically register plugins with FlutterEngine ("
              + this
              + ") but could not find and invoke the GeneratedPluginRegistrant.");
    }
  }

  /**
   * Cleans up all components within this {@code FlutterEngine} and destroys the associated Dart
   * Isolate. All state held by the Dart Isolate, such as the Flutter Elements tree, is lost.
   *
   * <p>This {@code FlutterEngine} instance should be discarded after invoking this method.
   */
  public void destroy() {
    Log.v(TAG, "Destroying.");
    // The order that these things are destroyed is important.
    pluginRegistry.destroy();
    platformViewsController.onDetachedFromJNI();
    dartExecutor.onDetachedFromJNI();
    flutterJNI.removeEngineLifecycleListener(engineLifecycleListener);
    flutterJNI.detachFromNativeAndReleaseResources();
  }

  /**
   * Adds a {@code listener} to be notified of Flutter engine lifecycle events, e.g., {@code
   * onPreEngineStart()}.
   */
  public void addEngineLifecycleListener(@NonNull EngineLifecycleListener listener) {
    engineLifecycleListeners.add(listener);
  }

  /**
   * Removes a {@code listener} that was previously added with {@link
   * #addEngineLifecycleListener(EngineLifecycleListener)}.
   */
  public void removeEngineLifecycleListener(@NonNull EngineLifecycleListener listener) {
    engineLifecycleListeners.remove(listener);
  }

  /**
   * The Dart execution context associated with this {@code FlutterEngine}.
   *
   * <p>The {@link DartExecutor} can be used to start executing Dart code from a given entrypoint.
   * See {@link DartExecutor#executeDartEntrypoint(DartExecutor.DartEntrypoint)}.
   *
   * <p>Use the {@link DartExecutor} to connect any desired message channels and method channels to
   * facilitate communication between Android and Dart/Flutter.
   */
  @NonNull
  public DartExecutor getDartExecutor() {
    return dartExecutor;
  }

  /**
   * The rendering system associated with this {@code FlutterEngine}.
   *
   * <p>To render a Flutter UI that is produced by this {@code FlutterEngine}'s Dart code, attach a
   * {@link RenderSurface} to this {@link FlutterRenderer}.
   */
  @NonNull
  public FlutterRenderer getRenderer() {
    return renderer;
  }

  /** System channel that sends accessibility requests and events from Flutter to Android. */
  @NonNull
  public AccessibilityChannel getAccessibilityChannel() {
    return accessibilityChannel;
  }

  /** System channel that sends key events from Android to Flutter. */
  @NonNull
  public KeyEventChannel getKeyEventChannel() {
    return keyEventChannel;
  }

  /** System channel that sends Android lifecycle events to Flutter. */
  @NonNull
  public LifecycleChannel getLifecycleChannel() {
    return lifecycleChannel;
  }

  /** System channel that sends locale data from Android to Flutter. */
  @NonNull
  public LocalizationChannel getLocalizationChannel() {
    return localizationChannel;
  }

  /** System channel that sends Flutter navigation commands from Android to Flutter. */
  @NonNull
  public NavigationChannel getNavigationChannel() {
    return navigationChannel;
  }

  /**
   * System channel that sends platform-oriented requests and information to Flutter, e.g., requests
   * to play sounds, requests for haptics, system chrome settings, etc.
   */
  @NonNull
  public PlatformChannel getPlatformChannel() {
    return platformChannel;
  }

  /**
   * System channel to exchange restoration data between framework and engine.
   *
   * <p>The engine can obtain the current restoration data from the framework via this channel to
   * store it on disk and - when the app is relaunched - provide the stored data back to the
   * framework to recreate the original state of the app.
   */
  @NonNull
  public RestorationChannel getRestorationChannel() {
    return restorationChannel;
  }

  /**
   * System channel that sends platform/user settings from Android to Flutter, e.g., time format,
   * scale factor, etc.
   */
  @NonNull
  public SettingsChannel getSettingsChannel() {
    return settingsChannel;
  }

  /** System channel that sends memory pressure warnings from Android to Flutter. */
  @NonNull
  public SystemChannel getSystemChannel() {
    return systemChannel;
  }

  /** System channel that sends and receives text input requests and state. */
  @NonNull
  public MouseCursorChannel getMouseCursorChannel() {
    return mouseCursorChannel;
  }

  /** System channel that sends and receives text input requests and state. */
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

  /** The LocalizationPlugin this FlutterEngine created. */
  @NonNull
  public LocalizationPlugin getLocalizationPlugin() {
    return localizationPlugin;
  }

  /**
   * {@code PlatformViewsController}, which controls all platform views running within this {@code
   * FlutterEngine}.
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

  /** Lifecycle callbacks for Flutter engine lifecycle events. */
  public interface EngineLifecycleListener {
    /** Lifecycle callback invoked before a hot restart of the Flutter engine. */
    void onPreEngineRestart();
  }
}
