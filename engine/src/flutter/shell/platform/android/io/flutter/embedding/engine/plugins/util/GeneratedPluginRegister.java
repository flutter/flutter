// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.embedding.engine.plugins.util;

import androidx.annotation.NonNull;
import io.flutter.Log;
import io.flutter.embedding.engine.FlutterEngine;
import java.lang.reflect.Method;

public class GeneratedPluginRegister {
  private static final String TAG = "GeneratedPluginsRegister";
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
  public static void registerGeneratedPlugins(@NonNull FlutterEngine flutterEngine) {
    try {
      Class<?> generatedPluginRegistrant =
          Class.forName("io.flutter.plugins.GeneratedPluginRegistrant");
      Method registrationMethod =
          generatedPluginRegistrant.getDeclaredMethod("registerWith", FlutterEngine.class);
      registrationMethod.invoke(null, flutterEngine);
    } catch (Exception e) {
      Log.w(
          TAG,
          "Tried to automatically register plugins with FlutterEngine ("
              + flutterEngine
              + ") but could not find and invoke the GeneratedPluginRegistrant.");
    }
  }
}
