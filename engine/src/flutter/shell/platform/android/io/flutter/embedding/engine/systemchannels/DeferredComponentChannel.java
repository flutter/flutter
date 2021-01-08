// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.embedding.engine.systemchannels;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.annotation.VisibleForTesting;
import io.flutter.FlutterInjector;
import io.flutter.Log;
import io.flutter.embedding.engine.dart.DartExecutor;
import io.flutter.embedding.engine.deferredcomponents.DeferredComponentManager;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.StandardMethodCodec;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Method channel that handles manual installation requests and queries for installation state for
 * deferred component modules.
 *
 * <p>This channel is able to handle multiple simultaneous installation requests
 */
public class DeferredComponentChannel {
  private static final String TAG = "DeferredComponentChannel";

  @NonNull private final MethodChannel channel;
  @Nullable private DeferredComponentManager deferredComponentManager;
  // Track the Result objects to be able to handle multiple install requests of
  // the same module at a time. When installation enters a terminal state, either
  // completeInstallSuccess or completeInstallError can be called.
  @NonNull private Map<String, List<MethodChannel.Result>> moduleNameToResults;

  @NonNull @VisibleForTesting
  final MethodChannel.MethodCallHandler parsingMethodHandler =
      new MethodChannel.MethodCallHandler() {
        @Override
        public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
          if (deferredComponentManager == null) {
            // If no DeferredComponentManager has been injected, then this channel is a no-op.
            return;
          }
          String method = call.method;
          Map<String, Object> args = call.arguments();
          Log.v(TAG, "Received '" + method + "' message.");
          final int loadingUnitId = (int) args.get("loadingUnitId");
          final String moduleName = (String) args.get("moduleName");
          switch (method) {
            case "installDeferredComponent":
              deferredComponentManager.installDeferredComponent(loadingUnitId, moduleName);
              if (!moduleNameToResults.containsKey(moduleName)) {
                moduleNameToResults.put(moduleName, new ArrayList<>());
              }
              moduleNameToResults.get(moduleName).add(result);
              break;
            case "getDeferredComponentInstallState":
              result.success(
                  deferredComponentManager.getDeferredComponentInstallState(
                      loadingUnitId, moduleName));
              break;
            case "uninstallDeferredComponent":
              deferredComponentManager.uninstallDeferredComponent(loadingUnitId, moduleName);
              result.success(null);
              break;
            default:
              result.notImplemented();
              break;
          }
        }
      };

  /**
   * Constructs a {@code DeferredComponentChannel} that connects Android to the Dart code running in
   * {@code dartExecutor}.
   *
   * <p>The given {@code dartExecutor} is permitted to be idle or executing code.
   *
   * <p>See {@link DartExecutor}.
   */
  public DeferredComponentChannel(@NonNull DartExecutor dartExecutor) {
    this.channel =
        new MethodChannel(dartExecutor, "flutter/deferredcomponent", StandardMethodCodec.INSTANCE);
    channel.setMethodCallHandler(parsingMethodHandler);
    deferredComponentManager = FlutterInjector.instance().deferredComponentManager();
    moduleNameToResults = new HashMap<>();
  }

  /**
   * Sets the DeferredComponentManager to exectue method channel calls with.
   *
   * @param deferredComponentManager the DeferredComponentManager to use.
   */
  @VisibleForTesting
  public void setDeferredComponentManager(
      @Nullable DeferredComponentManager deferredComponentManager) {
    this.deferredComponentManager = deferredComponentManager;
  }

  /**
   * Finishes the `installDeferredComponent` method channel call for the specified moduleName with a
   * success.
   *
   * @param moduleName The name of the android deferred component module install request to
   *     complete.
   */
  public void completeInstallSuccess(String moduleName) {
    if (moduleNameToResults.containsKey(moduleName)) {
      for (MethodChannel.Result result : moduleNameToResults.get(moduleName)) {
        result.success(null);
      }
      moduleNameToResults.get(moduleName).clear();
    }
    return;
  }

  /**
   * Finishes the `installDeferredComponent` method channel call for the specified moduleName with
   * an error/failure.
   *
   * @param moduleName The name of the android deferred component module install request to
   *     complete.
   * @param errorMessage The error message to display to complete the future with.
   */
  public void completeInstallError(String moduleName, String errorMessage) {
    if (moduleNameToResults.containsKey(moduleName)) {
      for (MethodChannel.Result result : moduleNameToResults.get(moduleName)) {
        result.error("DeferredComponent Install failure", errorMessage, null);
      }
      moduleNameToResults.get(moduleName).clear();
    }
    return;
  }
}
