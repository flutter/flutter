// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugin.common;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.platform.PlatformViewRegistry;
import io.flutter.view.FlutterNativeView;
import io.flutter.view.FlutterView;
import io.flutter.view.TextureRegistry;

/**
 * Registry used by plugins to set up interaction with Android APIs.
 *
 * <p>Flutter applications by default include an auto-generated and auto-updated plugin registrant
 * class (GeneratedPluginRegistrant) that makes use of a {@link PluginRegistry} to register
 * contributions from each plugin mentioned in the application's pubspec file. The generated
 * registrant class is, again by default, called from the application's main {@link Activity}, which
 * defaults to an instance of {@link io.flutter.app.FlutterActivity}, itself a {@link
 * PluginRegistry}.
 *
 * <p>This class is now deprecated. See https://flutter.dev/go/android-project-migration for
 * migration details.
 */
public interface PluginRegistry {
  /**
   * Returns a {@link Registrar} for receiving the registrations pertaining to the specified plugin.
   *
   * @param pluginKey a unique String identifying the plugin; typically the fully qualified name of
   *     the plugin's main class.
   */
  Registrar registrarFor(String pluginKey);

  /**
   * Returns whether the specified plugin is known to this registry.
   *
   * @param pluginKey a unique String identifying the plugin; typically the fully qualified name of
   *     the plugin's main class.
   * @return true if this registry has handed out a registrar for the specified plugin.
   */
  boolean hasPlugin(String pluginKey);

  /**
   * Returns the value published by the specified plugin, if any.
   *
   * <p>Plugins may publish a single value, such as an instance of the plugin's main class, for
   * situations where external control or interaction is needed. Clients are expected to know the
   * value's type.
   *
   * @param pluginKey a unique String identifying the plugin; typically the fully qualified name of
   *     the plugin's main class.
   * @return the published value, possibly null.
   */
  <T> T valuePublishedByPlugin(String pluginKey);

  /**
   * Receiver of registrations from a single plugin.
   *
   * <p>This registrar is for Flutter's v1 embedding. For instructions on migrating a plugin from
   * Flutter's v1 Android embedding to v2, visit http://flutter.dev/go/android-plugin-migration
   */
  interface Registrar {
    /**
     * Returns the {@link Activity} that forms the plugin's operating context.
     *
     * <p>Plugin authors should not assume the type returned by this method is any specific subclass
     * of {@code Activity} (such as {@link io.flutter.app.FlutterActivity} or {@link
     * io.flutter.app.FlutterFragmentActivity}), as applications are free to use any activity
     * subclass.
     *
     * <p>When there is no foreground activity in the application, this will return null. If a
     * {@link Context} is needed, use context() to get the application's context.
     *
     * <p>This registrar is for Flutter's v1 embedding. To access an {@code Activity} from a plugin
     * using the v2 embedding, see {@link ActivityPluginBinding#getActivity()}. To obtain an
     * instance of an {@link ActivityPluginBinding} in a Flutter plugin, implement the {@link
     * ActivityAware} interface. A binding is provided in {@link
     * ActivityAware#onAttachedToActivity(ActivityPluginBinding)} and {@link
     * ActivityAware#onReattachedToActivityForConfigChanges(ActivityPluginBinding)}.
     *
     * <p>For instructions on migrating a plugin from Flutter's v1 Android embedding to v2, visit
     * http://flutter.dev/go/android-plugin-migration
     */
    Activity activity();

    /**
     * Returns the {@link android.app.Application}'s {@link Context}.
     *
     * <p>This registrar is for Flutter's v1 embedding. To access a {@code Context} from a plugin
     * using the v2 embedding, see {@link
     * FlutterPlugin.FlutterPluginBinding#getApplicationContext()}
     *
     * <p>For instructions on migrating a plugin from Flutter's v1 Android embedding to v2, visit
     * http://flutter.dev/go/android-plugin-migration
     */
    Context context();

    /**
     * Returns the active {@link Context}.
     *
     * <p>This registrar is for Flutter's v1 embedding. In the v2 embedding, there is no concept of
     * an "active context". Either use the application {@code Context} or an attached {@code
     * Activity}. See {@link #context()} and {@link #activity()} for more details.
     *
     * <p>For instructions on migrating a plugin from Flutter's v1 Android embedding to v2, visit
     * http://flutter.dev/go/android-plugin-migration
     *
     * @return the current {@link #activity() Activity}, if not null, otherwise the {@link
     *     #context() Application}.
     */
    Context activeContext();

    /**
     * Returns a {@link BinaryMessenger} which the plugin can use for creating channels for
     * communicating with the Dart side.
     *
     * <p>This registrar is for Flutter's v1 embedding. To access a {@code BinaryMessenger} from a
     * plugin using the v2 embedding, see {@link
     * FlutterPlugin.FlutterPluginBinding#getBinaryMessenger()}
     *
     * <p>For instructions on migrating a plugin from Flutter's v1 Android embedding to v2, visit
     * http://flutter.dev/go/android-plugin-migration
     */
    BinaryMessenger messenger();

    /**
     * Returns a {@link TextureRegistry} which the plugin can use for managing backend textures.
     *
     * <p>This registrar is for Flutter's v1 embedding. To access a {@code TextureRegistry} from a
     * plugin using the v2 embedding, see {@link
     * FlutterPlugin.FlutterPluginBinding#getTextureRegistry()}
     *
     * <p>For instructions on migrating a plugin from Flutter's v1 Android embedding to v2, visit
     * http://flutter.dev/go/android-plugin-migration
     */
    TextureRegistry textures();

    /**
     * Returns the application's {@link PlatformViewRegistry}.
     *
     * <p>Plugins can use the platform registry to register their view factories.
     *
     * <p>This registrar is for Flutter's v1 embedding. To access a {@code PlatformViewRegistry}
     * from a plugin using the v2 embedding, see {@link
     * FlutterPlugin.FlutterPluginBinding#getPlatformViewRegistry()}
     *
     * <p>For instructions on migrating a plugin from Flutter's v1 Android embedding to v2, visit
     * http://flutter.dev/go/android-plugin-migration
     */
    PlatformViewRegistry platformViewRegistry();

    /**
     * Returns the {@link FlutterView} that's instantiated by this plugin's {@link #activity()
     * activity}.
     *
     * <p>This registrar is for Flutter's v1 embedding. The {@link FlutterView} referenced by this
     * method does not exist in the v2 embedding. Additionally, no {@code View} is exposed to any
     * plugins in the v2 embedding. Platform views can access their containing {@code View} using
     * the platform views APIs. If you have a use-case that absolutely requires a plugin to access
     * an Android {@code View}, please file a ticket on GitHub.
     *
     * <p>For instructions on migrating a plugin from Flutter's v1 Android embedding to v2, visit
     * http://flutter.dev/go/android-plugin-migration
     */
    FlutterView view();

    /**
     * Returns the file name for the given asset. The returned file name can be used to access the
     * asset in the APK through the {@link android.content.res.AssetManager} API.
     *
     * <p>TODO(mattcarroll): point this method towards new lookup method.
     *
     * @param asset the name of the asset. The name can be hierarchical
     * @return the filename to be used with {@link android.content.res.AssetManager}
     */
    String lookupKeyForAsset(String asset);

    /**
     * Returns the file name for the given asset which originates from the specified packageName.
     * The returned file name can be used to access the asset in the APK through the {@link
     * android.content.res.AssetManager} API.
     *
     * <p>TODO(mattcarroll): point this method towards new lookup method.
     *
     * @param asset the name of the asset. The name can be hierarchical
     * @param packageName the name of the package from which the asset originates
     * @return the file name to be used with {@link android.content.res.AssetManager}
     */
    String lookupKeyForAsset(String asset, String packageName);

    /**
     * Publishes a value associated with the plugin being registered.
     *
     * <p>The published value is available to interested clients via {@link
     * PluginRegistry#valuePublishedByPlugin(String)}.
     *
     * <p>Publication should be done only when client code needs to interact with the plugin in a
     * way that cannot be accomplished by the plugin registering callbacks with client APIs.
     *
     * <p>Overwrites any previously published value.
     *
     * <p>This registrar is for Flutter's v1 embedding. The concept of publishing values from
     * plugins is not supported in the v2 embedding.
     *
     * <p>For instructions on migrating a plugin from Flutter's v1 Android embedding to v2, visit
     * http://flutter.dev/go/android-plugin-migration
     *
     * @param value the value, possibly null.
     * @return this {@link Registrar}.
     */
    Registrar publish(Object value);

    /**
     * Adds a callback allowing the plugin to take part in handling incoming calls to {@code
     * Activity#onRequestPermissionsResult(int, String[], int[])} or {@code
     * androidx.core.app.ActivityCompat.OnRequestPermissionsResultCallback#onRequestPermissionsResult(int,
     * String[], int[])}.
     *
     * <p>This registrar is for Flutter's v1 embedding. To listen for permission results in the v2
     * embedding, use {@link
     * ActivityPluginBinding#addRequestPermissionsResultListener(RequestPermissionsResultListener)}.
     *
     * <p>For instructions on migrating a plugin from Flutter's v1 Android embedding to v2, visit
     * http://flutter.dev/go/android-plugin-migration
     *
     * @param listener a {@link RequestPermissionsResultListener} callback.
     * @return this {@link Registrar}.
     */
    Registrar addRequestPermissionsResultListener(RequestPermissionsResultListener listener);

    /**
     * Adds a callback allowing the plugin to take part in handling incoming calls to {@link
     * Activity#onActivityResult(int, int, Intent)}.
     *
     * <p>This registrar is for Flutter's v1 embedding. To listen for {@code Activity} results in
     * the v2 embedding, use {@link
     * ActivityPluginBinding#addActivityResultListener(ActivityResultListener)}.
     *
     * <p>For instructions on migrating a plugin from Flutter's v1 Android embedding to v2, visit
     * http://flutter.dev/go/android-plugin-migration
     *
     * @param listener an {@link ActivityResultListener} callback.
     * @return this {@link Registrar}.
     */
    Registrar addActivityResultListener(ActivityResultListener listener);

    /**
     * Adds a callback allowing the plugin to take part in handling incoming calls to {@link
     * Activity#onNewIntent(Intent)}.
     *
     * <p>This registrar is for Flutter's v1 embedding. To listen for new {@code Intent}s in the v2
     * embedding, use {@link ActivityPluginBinding#addOnNewIntentListener(NewIntentListener)}.
     *
     * <p>For instructions on migrating a plugin from Flutter's v1 Android embedding to v2, visit
     * http://flutter.dev/go/android-plugin-migration
     *
     * @param listener a {@link NewIntentListener} callback.
     * @return this {@link Registrar}.
     */
    Registrar addNewIntentListener(NewIntentListener listener);

    /**
     * Adds a callback allowing the plugin to take part in handling incoming calls to {@link
     * Activity#onUserLeaveHint()}.
     *
     * <p>This registrar is for Flutter's v1 embedding. To listen for leave hints in the v2
     * embedding, use {@link
     * ActivityPluginBinding#addOnUserLeaveHintListener(UserLeaveHintListener)}.
     *
     * <p>For instructions on migrating a plugin from Flutter's v1 Android embedding to v2, visit
     * http://flutter.dev/go/android-plugin-migration
     *
     * @param listener a {@link UserLeaveHintListener} callback.
     * @return this {@link Registrar}.
     */
    Registrar addUserLeaveHintListener(UserLeaveHintListener listener);

    /**
     * Adds a callback allowing the plugin to take part in handling incoming calls to {@link
     * Activity#onDestroy()}.
     *
     * <p>This registrar is for Flutter's v1 embedding. The concept of {@code View} destruction does
     * not exist in the v2 embedding. However, plugins in the v2 embedding can respond to {@link
     * ActivityAware#onDetachedFromActivityForConfigChanges()} and {@link
     * ActivityAware#onDetachedFromActivity()}, which indicate the loss of a visual context for the
     * running Flutter experience. Developers should implement {@link ActivityAware} for their
     * {@link FlutterPlugin} if such callbacks are needed. Also, plugins can respond to {@link
     * FlutterPlugin#onDetachedFromEngine(FlutterPlugin.FlutterPluginBinding)}, which indicates that
     * the given plugin has been completely disconnected from the associated Flutter experience and
     * should clean up any resources.
     *
     * <p>For instructions on migrating a plugin from Flutter's v1 Android embedding to v2, visit
     * http://flutter.dev/go/android-plugin-migration
     *
     * @param listener a {@link ViewDestroyListener} callback.
     * @return this {@link Registrar}.
     */
    // TODO(amirh): Add a line in the javadoc above that points to a Platform Views website guide
    // when one is available (but not a website API doc)
    Registrar addViewDestroyListener(ViewDestroyListener listener);
  }

  /**
   * Delegate interface for handling result of permissions requests on behalf of the main {@link
   * Activity}.
   */
  interface RequestPermissionsResultListener {
    /** @return true if the result has been handled. */
    boolean onRequestPermissionsResult(int requestCode, String[] permissions, int[] grantResults);
  }

  /** Delegate interface for handling activity results on behalf of the main {@link Activity}. */
  interface ActivityResultListener {
    /** @return true if the result has been handled. */
    boolean onActivityResult(int requestCode, int resultCode, Intent data);
  }

  /** Delegate interface for handling new intents on behalf of the main {@link Activity}. */
  interface NewIntentListener {
    /** @return true if the new intent has been handled. */
    boolean onNewIntent(Intent intent);
  }

  /** Delegate interface for handling user leave hints on behalf of the main {@link Activity}. */
  interface UserLeaveHintListener {
    void onUserLeaveHint();
  }

  /**
   * Delegate interface for handling an {@link Activity}'s onDestroy method being called. A plugin
   * that implements this interface can adopt the FlutterNativeView by retaining a reference and
   * returning true.
   */
  interface ViewDestroyListener {
    boolean onViewDestroy(FlutterNativeView view);
  }

  /**
   * Callback interface for registering plugins with a plugin registry.
   *
   * <p>For example, an Application may use this callback interface to provide a background service
   * with a callback for calling its GeneratedPluginRegistrant.registerWith method.
   */
  interface PluginRegistrantCallback {
    void registerWith(PluginRegistry registry);
  }
}
