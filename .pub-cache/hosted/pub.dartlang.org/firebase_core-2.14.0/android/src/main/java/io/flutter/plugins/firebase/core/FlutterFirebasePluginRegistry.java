// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
package io.flutter.plugins.firebase.core;

import static io.flutter.plugins.firebase.core.FlutterFirebasePlugin.cachedThreadPool;

import androidx.annotation.Keep;
import com.google.android.gms.tasks.Task;
import com.google.android.gms.tasks.TaskCompletionSource;
import com.google.android.gms.tasks.Tasks;
import com.google.firebase.FirebaseApp;
import java.util.HashMap;
import java.util.Map;
import java.util.WeakHashMap;

@Keep
public class FlutterFirebasePluginRegistry {

  private static final Map<String, FlutterFirebasePlugin> registeredPlugins = new WeakHashMap<>();

  /**
   * Register a Flutter Firebase plugin with the Firebase plugin registry.
   *
   * @param channelName The MethodChannel name for the plugin to be registered, for example:
   *     `plugins.flutter.io/firebase_core`
   * @param flutterFirebasePlugin A FlutterPlugin that implements FlutterFirebasePlugin.
   */
  public static void registerPlugin(
      String channelName, FlutterFirebasePlugin flutterFirebasePlugin) {
    registeredPlugins.put(channelName, flutterFirebasePlugin);
  }

  /**
   * Each FlutterFire plugin implementing FlutterFirebasePlugin provides this method allowing it's
   * constants to be initialized during FirebaseCore.initializeApp in Dart. Here we call this method
   * on each of the registered plugins and gather their constants for use in Dart.
   *
   * @param firebaseApp The Firebase App that the plugin should return constants for.
   * @return A task returning the discovered constants for each plugin (using channelName as the Map
   *     key) for the provided Firebase App.
   */
  static Task<Map<String, Object>> getPluginConstantsForFirebaseApp(FirebaseApp firebaseApp) {
    TaskCompletionSource<Map<String, Object>> taskCompletionSource = new TaskCompletionSource<>();

    cachedThreadPool.execute(
        () -> {
          try {
            Map<String, Object> pluginConstants = new HashMap<>(registeredPlugins.size());

            for (Map.Entry<String, FlutterFirebasePlugin> entry : registeredPlugins.entrySet()) {
              String channelName = entry.getKey();
              FlutterFirebasePlugin plugin = entry.getValue();
              pluginConstants.put(
                  channelName, Tasks.await(plugin.getPluginConstantsForFirebaseApp(firebaseApp)));
            }

            taskCompletionSource.setResult(pluginConstants);
          } catch (Exception e) {
            taskCompletionSource.setException(e);
          }
        });

    return taskCompletionSource.getTask();
  }

  /**
   * Each FlutterFire plugin implementing this method are notified that FirebaseCore#initializeCore
   * was called again.
   *
   * <p>This is used by plugins to know if they need to cleanup previous resources between Hot
   * Restarts as `initializeCore` can only be called once in Dart.
   */
  static Task<Void> didReinitializeFirebaseCore() {
    TaskCompletionSource<Void> taskCompletionSource = new TaskCompletionSource<>();

    cachedThreadPool.execute(
        () -> {
          try {
            for (Map.Entry<String, FlutterFirebasePlugin> entry : registeredPlugins.entrySet()) {
              FlutterFirebasePlugin plugin = entry.getValue();
              Tasks.await(plugin.didReinitializeFirebaseCore());
            }

            taskCompletionSource.setResult(null);
          } catch (Exception e) {
            taskCompletionSource.setException(e);
          }
        });

    return taskCompletionSource.getTask();
  }
}
