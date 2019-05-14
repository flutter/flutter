// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.embedding.engine;

import android.app.Activity;
import android.arch.lifecycle.Lifecycle;
import android.content.Context;
import android.content.Intent;
import android.support.annotation.NonNull;
import android.support.annotation.Nullable;
import android.util.Log;

import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;
import java.util.Set;

import io.flutter.embedding.engine.dart.DartExecutor;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.PluginRegistry;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityControlSurface;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
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
  private final FlutterEnginePluginRegistry pluginRegistry;

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
      // TODO(mattcarroll): work into plugin API. should probably loop through each plugin.
//      pluginRegistry.onPreEngineRestart();
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
   * see {@link #getPlugins()}.
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

    accessibilityChannel = new AccessibilityChannel(dartExecutor, flutterJNI);
    keyEventChannel = new KeyEventChannel(dartExecutor);
    lifecycleChannel = new LifecycleChannel(dartExecutor);
    localizationChannel = new LocalizationChannel(dartExecutor);
    navigationChannel = new NavigationChannel(dartExecutor);
    platformChannel = new PlatformChannel(dartExecutor);
    settingsChannel = new SettingsChannel(dartExecutor);
    systemChannel = new SystemChannel(dartExecutor);
    textInputChannel = new TextInputChannel(dartExecutor);

    // TODO(mattcarroll): bring in Lifecycle.
    this.pluginRegistry = new FlutterEnginePluginRegistry(
      context.getApplicationContext(),
      this,
      null
    );
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
   * Cleans up all components within this {@code FlutterEngine} and then detaches from Flutter's
   * native implementation.
   *
   * This {@code FlutterEngine} instance should be discarded after invoking this method.
   */
  public void destroy() {
    pluginRegistry.removeAll();
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

  /**
   * Plugin registry, which registers plugins that want to be applied to this {@code FlutterEngine}.
   */
  @NonNull
  public PluginRegistry getPlugins() {
    return pluginRegistry;
  }

  @NonNull
  public ActivityControlSurface getActivityControlSurface() {
    return pluginRegistry;
  }

  private static class FlutterEnginePluginRegistry implements PluginRegistry, ActivityControlSurface {
    private final Map<Class<? extends FlutterPlugin>, FlutterPlugin> plugins = new HashMap<>();
    private final FlutterPlugin.FlutterPluginBinding pluginBinding;

    private final Map<Class<? extends FlutterPlugin>, ActivityAware> activityAwarePlugins = new HashMap<>();
    private Activity activity;
    private FlutterEngineActivityPluginBinding activityPluginBinding;

    FlutterEnginePluginRegistry(
      @NonNull Context appContext,
      @NonNull FlutterEngine flutterEngine,
      @NonNull Lifecycle lifecycle
    ) {
      pluginBinding = new FlutterPlugin.FlutterPluginBinding(
        appContext,
        flutterEngine,
        lifecycle
      );
    }

    public void add(@NonNull FlutterPlugin plugin) {
      // Add the plugin to our generic set of plugins and notify the plugin
      // that is has been attached to an engine.
      plugins.put(plugin.getClass(), plugin);
      plugin.onAttachedToEngine(pluginBinding);

      // For ActivityAware plugins, add the plugin to our set of ActivityAware
      // plugins, and if this engine is currently attached to an Activity,
      // notify the ActivityAware plugin that it is now attached to an Activity.
      if (plugin instanceof ActivityAware) {
        ActivityAware activityAware = (ActivityAware) plugin;
        activityAwarePlugins.put(plugin.getClass(), activityAware);

        if (isAttachedToActivity()) {
          activityAware.onAttachedToActivity(activityPluginBinding);
        }
      }

      // TODO(mattcarroll): ServiceAware
      // TODO(mattcarroll): BroadcastReceiverAware
      // TODO(mattcarroll): ContentProviderAware
    }

    public void add(@NonNull Set<FlutterPlugin> plugins) {
      for (FlutterPlugin plugin : plugins) {
        add(plugin);
      }
    }

    public boolean has(@NonNull Class<? extends FlutterPlugin> pluginClass) {
      return plugins.containsKey(pluginClass);
    }

    public FlutterPlugin get(@NonNull Class<? extends FlutterPlugin> pluginClass) {
      return plugins.get(pluginClass);
    }

    public void remove(@NonNull Class<? extends FlutterPlugin> pluginClass) {
      FlutterPlugin plugin = plugins.get(pluginClass);
      if (plugin != null) {
        // For ActivityAware plugins, notify the plugin that it is detached from
        // an Activity if an Activity is currently attached to this engine. Then
        // remove the plugin from our set of ActivityAware plugins.
        if (plugin instanceof ActivityAware) {
          if (isAttachedToActivity()) {
            ActivityAware activityAware = (ActivityAware) plugin;
            activityAware.onDetachedFromActivity();
          }
          activityAwarePlugins.remove(pluginClass);
        }

        // TODO(mattcarroll): ServiceAware
        // TODO(mattcarroll): BroadcastReceiverAware
        // TODO(mattcarroll): ContentProviderAware

        // Notify the plugin that is now detached from this engine. Then remove
        // it from our set of generic plugins.
        plugin.onDetachedFromEngine(pluginBinding);
        plugins.remove(pluginClass);
      }
    }

    public void remove(@NonNull Set<Class<? extends FlutterPlugin>> pluginClasses) {
      for (Class<? extends FlutterPlugin> pluginClass : pluginClasses) {
        remove(pluginClass);
      }
    }

    public void removeAll() {
      // We copy the keys to a new set so that we can mutate the set while using
      // the keys.
      remove(new HashSet<>(plugins.keySet()));
      plugins.clear();
    }

    //-------- Start ActivityControlSurface -------
    boolean isAttachedToActivity() {
      return activity != null;
    }

    @Override
    public void attachToActivity(@NonNull Activity activity, @NonNull Lifecycle lifecycle) {
      Log.d(TAG, "Attaching to an Activity.");
      // If we were already attached to an Activity, detach from it before attaching to
      // the new Activity.
      if (isAttachedToActivity()) {
        for (ActivityAware activityAware : activityAwarePlugins.values()) {
          activityAware.onDetachedFromActivity();
        }
      }

      this.activity = activity;
      this.activityPluginBinding = new FlutterEngineActivityPluginBinding(activity);
      // TODO(mattcarroll): resolve possibility of different lifecycles between this and engine attachment

      // Notify all ActivityAware plugins that they are now attached to a new Activity.
      for (ActivityAware activityAware : activityAwarePlugins.values()) {
        activityAware.onAttachedToActivity(activityPluginBinding);
      }
    }

    @Override
    public void detachFromActivityForConfigChanges() {
      Log.d(TAG, "Detaching from an Activity for config changes.");
      if (isAttachedToActivity()) {
        for (ActivityAware activityAware : activityAwarePlugins.values()) {
          activityAware.onDetachedFromActivityForConfigChanges();
        }

        activity = null;
        activityPluginBinding = null;
      } else {
        Log.e(TAG, "Attempted to detach plugins from an Activity when no Activity was attached.");
      }
    }

    @Override
    public void reattachToActivityAfterConfigChange(@NonNull Activity activity) {
      Log.d(TAG, "Re-attaching to an Activity after config change.");
      if (!isAttachedToActivity()) {
        this.activity = activity;
        activityPluginBinding = new FlutterEngineActivityPluginBinding(activity);

        for (ActivityAware activityAware : activityAwarePlugins.values()) {
          activityAware.onReattachedToActivityForConfigChanges(activityPluginBinding);
        }
      } else {
        Log.e(TAG, "Attempted to reattach plugins to an Activity after config changes, but an Activity was already attached.");
      }
    }

    @Override
    public void detachFromActivity() {
      Log.d(TAG, "Detaching from an Activity.");
      if (isAttachedToActivity()) {
        for (ActivityAware activityAware : activityAwarePlugins.values()) {
          activityAware.onDetachedFromActivity();
        }

        activity = null;
        activityPluginBinding = null;
      } else {
        Log.e(TAG, "Attempted to detach plugins from an Activity when no Activity was attached.");
      }
    }

    @Override
    public boolean onRequestPermissionsResult(int requestCode, @NonNull String[] permissions, @NonNull int[] grantResult) {
      Log.d(TAG, "Forwarding onRequestPermissionsResult() to plugins.");
      if (isAttachedToActivity()) {
        return activityPluginBinding.onRequestPermissionsResult(requestCode, permissions, grantResult);
      } else {
        Log.e(TAG, "Attempted to notify ActivityAware plugins of onRequestPermissionsResult, but no Activity was attached.");
        return false;
      }
    }

    @Override
    public boolean onActivityResult(int requestCode, int resultCode, @NonNull Intent data) {
      Log.d(TAG, "Forwarding onActivityResult() to plugins.");
      if (isAttachedToActivity()) {
        return activityPluginBinding.onActivityResult(requestCode, resultCode, data);
      } else {
        Log.e(TAG, "Attempted to notify ActivityAware plugins of onActivityResult, but no Activity was attached.");
        return false;
      }
    }

    @Override
    public void onNewIntent(@NonNull Intent intent) {
      Log.d(TAG, "Forwarding onNewIntent() to plugins.");
      if (isAttachedToActivity()) {
        activityPluginBinding.onNewIntent(intent);
      } else {
        Log.e(TAG, "Attempted to notify ActivityAware plugins of onNewIntent, but no Activity was attached.");
      }
    }

    @Override
    public void onUserLeaveHint() {
      Log.d(TAG, "Forwarding onUserLeaveHint() to plugins.");
      if (isAttachedToActivity()) {
        activityPluginBinding.onUserLeaveHint();
      } else {
        Log.e(TAG, "Attempted to notify ActivityAware plugins of onUserLeaveHint, but no Activity was attached.");
      }
    }
    //------- End ActivityControlSurface -----
  }

  private static class FlutterEngineActivityPluginBinding implements ActivityPluginBinding {
    private final Activity activity;
    private final Set<io.flutter.plugin.common.PluginRegistry.RequestPermissionsResultListener> onRequestPermissionsResultListeners = new HashSet<>();
    private final Set<io.flutter.plugin.common.PluginRegistry.ActivityResultListener> onActivityResultListeners = new HashSet<>();
    private final Set<io.flutter.plugin.common.PluginRegistry.NewIntentListener> onNewIntentListeners = new HashSet<>();
    private final Set<io.flutter.plugin.common.PluginRegistry.UserLeaveHintListener> onUserLeaveHintListeners = new HashSet<>();

    public FlutterEngineActivityPluginBinding(@NonNull Activity activity) {
      this.activity = activity;
    }

    /**
     * Returns the {@link Activity} that is currently attached to the {@link FlutterEngine} that
     * owns this {@code ActivityPluginBinding}.
     */
    @NonNull
    public Activity getActivity() {
      return activity;
    }

    /**
     * Adds a listener that is invoked whenever the associated {@link Activity}'s
     * {@code onRequestPermissionsResult(...)} method is invoked.
     */
    public void addRequestPermissionsResultListener(@NonNull io.flutter.plugin.common.PluginRegistry.RequestPermissionsResultListener listener) {
      onRequestPermissionsResultListeners.add(listener);
    }

    /**
     * Removes a listener that was added in {@link #addRequestPermissionsResultListener(io.flutter.plugin.common.PluginRegistry.RequestPermissionsResultListener)}.
     */
    public void removeRequestPermissionsResultListener(@NonNull io.flutter.plugin.common.PluginRegistry.RequestPermissionsResultListener listener) {
      onRequestPermissionsResultListeners.remove(listener);
    }

    /**
     * Invoked by the {@link FlutterEngine} that owns this {@code ActivityPluginBinding} when its
     * associated {@link Activity} has its {@code onRequestPermissionsResult(...)} method invoked.
     */
    boolean onRequestPermissionsResult(int requestCode, @NonNull String[] permissions, @NonNull int[] grantResult) {
      boolean didConsumeResult = false;
      for (io.flutter.plugin.common.PluginRegistry.RequestPermissionsResultListener listener : onRequestPermissionsResultListeners) {
        didConsumeResult = listener.onRequestPermissionsResult(requestCode, permissions, grantResult) || didConsumeResult;
      }
      return didConsumeResult;
    }

    /**
     * Adds a listener that is invoked whenever the associated {@link Activity}'s
     * {@code onActivityResult(...)} method is invoked.
     */
    public void addActivityResultListener(@NonNull io.flutter.plugin.common.PluginRegistry.ActivityResultListener listener) {
      onActivityResultListeners.add(listener);
    }

    /**
     * Removes a listener that was added in {@link #addActivityResultListener(io.flutter.plugin.common.PluginRegistry.ActivityResultListener)}.
     */
    public void removeActivityResultListener(@NonNull io.flutter.plugin.common.PluginRegistry.ActivityResultListener listener) {
      onActivityResultListeners.remove(listener);
    }

    /**
     * Invoked by the {@link FlutterEngine} that owns this {@code ActivityPluginBinding} when its
     * associated {@link Activity} has its {@code onActivityResult(...)} method invoked.
     */
    boolean onActivityResult(int requestCode, int resultCode, @NonNull Intent data) {
      boolean didConsumeResult = false;
      for (io.flutter.plugin.common.PluginRegistry.ActivityResultListener listener : onActivityResultListeners) {
        didConsumeResult = listener.onActivityResult(requestCode, resultCode, data) || didConsumeResult;
      }
      return didConsumeResult;
    }

    /**
     * Adds a listener that is invoked whenever the associated {@link Activity}'s
     * {@code onNewIntent(...)} method is invoked.
     */
    public void addOnNewIntentListener(@NonNull io.flutter.plugin.common.PluginRegistry.NewIntentListener listener) {
      onNewIntentListeners.add(listener);
    }

    /**
     * Removes a listener that was added in {@link #addOnNewIntentListener(io.flutter.plugin.common.PluginRegistry.NewIntentListener)}.
     */
    public void removeOnNewIntentListener(@NonNull io.flutter.plugin.common.PluginRegistry.NewIntentListener listener) {
      onNewIntentListeners.remove(listener);
    }

    /**
     * Invoked by the {@link FlutterEngine} that owns this {@code ActivityPluginBinding} when its
     * associated {@link Activity} has its {@code onNewIntent(...)} method invoked.
     */
    void onNewIntent(@Nullable Intent intent) {
      for (io.flutter.plugin.common.PluginRegistry.NewIntentListener listener : onNewIntentListeners) {
        listener.onNewIntent(intent);
      }
    }

    /**
     * Adds a listener that is invoked whenever the associated {@link Activity}'s
     * {@code onUserLeaveHint()} method is invoked.
     */
    public void addOnUserLeaveHintListener(@NonNull io.flutter.plugin.common.PluginRegistry.UserLeaveHintListener listener) {
      onUserLeaveHintListeners.add(listener);
    }

    /**
     * Removes a listener that was added in {@link #addOnUserLeaveHintListener(io.flutter.plugin.common.PluginRegistry.UserLeaveHintListener)}.
     */
    public void removeOnUserLeaveHintListener(@NonNull io.flutter.plugin.common.PluginRegistry.UserLeaveHintListener listener) {
      onUserLeaveHintListeners.remove(listener);
    }

    /**
     * Invoked by the {@link FlutterEngine} that owns this {@code ActivityPluginBinding} when its
     * associated {@link Activity} has its {@code onUserLeaveHint()} method invoked.
     */
    void onUserLeaveHint() {
      for (io.flutter.plugin.common.PluginRegistry.UserLeaveHintListener listener : onUserLeaveHintListeners) {
        listener.onUserLeaveHint();
      }
    }
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
