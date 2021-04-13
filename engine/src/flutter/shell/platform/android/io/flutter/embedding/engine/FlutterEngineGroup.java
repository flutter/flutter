// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.embedding.engine;

import android.content.Context;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.annotation.VisibleForTesting;
import io.flutter.FlutterInjector;
import io.flutter.embedding.engine.dart.DartExecutor.DartEntrypoint;
import io.flutter.embedding.engine.loader.FlutterLoader;
import java.util.ArrayList;
import java.util.List;

/**
 * This class is available experimentally and the API may change. Use at your own risk.
 *
 * <p>Represents a collection of {@link io.flutter.embedding.engine.FlutterEngine}s who share
 * resources to allow them to be created faster and with less memory than calling the {@link
 * io.flutter.embedding.engine.FlutterEngine}'s constructor multiple times.
 *
 * <p>When creating or recreating the first {@link io.flutter.embedding.engine.FlutterEngine} in the
 * FlutterEngineGroup, the behavior is the same as creating a {@link
 * io.flutter.embedding.engine.FlutterEngine} via its constructor. When subsequent {@link
 * io.flutter.embedding.engine.FlutterEngine}s are created, resources from an existing living {@link
 * io.flutter.embedding.engine.FlutterEngine} is re-used.
 *
 * <p>The shared resources are kept until the last surviving {@link
 * io.flutter.embedding.engine.FlutterEngine} is destroyed.
 *
 * <p>Deleting a FlutterEngineGroup doesn't invalidate its existing {@link
 * io.flutter.embedding.engine.FlutterEngine}s, but it eliminates the possibility to create more
 * {@link io.flutter.embedding.engine.FlutterEngine}s in that group.
 */
public class FlutterEngineGroup {

  /* package */ @VisibleForTesting final List<FlutterEngine> activeEngines = new ArrayList<>();

  /** Create a FlutterEngineGroup whose child engines will share resources. */
  public FlutterEngineGroup(@NonNull Context context) {
    this(context, null);
  }

  /**
   * Create a FlutterEngineGroup whose child engines will share resources. Use {@code dartVmArgs} to
   * pass flags to the Dart VM during initialization.
   */
  public FlutterEngineGroup(@NonNull Context context, @Nullable String[] dartVmArgs) {
    FlutterLoader loader = FlutterInjector.instance().flutterLoader();
    if (!loader.initialized()) {
      loader.startInitialization(context.getApplicationContext());
      loader.ensureInitializationComplete(context, dartVmArgs);
    }
  }

  /**
   * Creates a {@link io.flutter.embedding.engine.FlutterEngine} in this group and run its {@link
   * io.flutter.embedding.engine.dart.DartExecutor} with a default entrypoint of the "main" function
   * in the "lib/main.dart" file.
   *
   * <p>If no prior {@link io.flutter.embedding.engine.FlutterEngine} were created in this group,
   * the initialization cost will be slightly higher than subsequent engines. The very first {@link
   * io.flutter.embedding.engine.FlutterEngine} created per program, regardless of
   * FlutterEngineGroup, also incurs the Dart VM creation time.
   *
   * <p>Subsequent engine creations will share resources with existing engines. However, if all
   * existing engines were {@link io.flutter.embedding.engine.FlutterEngine#destroy()}ed, the next
   * engine created will recreate its dependencies.
   */
  public FlutterEngine createAndRunDefaultEngine(@NonNull Context context) {
    return createAndRunEngine(context, null);
  }

  /**
   * Creates a {@link io.flutter.embedding.engine.FlutterEngine} in this group and run its {@link
   * io.flutter.embedding.engine.dart.DartExecutor} with the specified {@link DartEntrypoint}.
   *
   * <p>If no prior {@link io.flutter.embedding.engine.FlutterEngine} were created in this group,
   * the initialization cost will be slightly higher than subsequent engines. The very first {@link
   * io.flutter.embedding.engine.FlutterEngine} created per program, regardless of
   * FlutterEngineGroup, also incurs the Dart VM creation time.
   *
   * <p>Subsequent engine creations will share resources with existing engines. However, if all
   * existing engines were {@link io.flutter.embedding.engine.FlutterEngine#destroy()}ed, the next
   * engine created will recreate its dependencies.
   */
  public FlutterEngine createAndRunEngine(
      @NonNull Context context, @Nullable DartEntrypoint dartEntrypoint) {
    FlutterEngine engine = null;

    if (dartEntrypoint == null) {
      dartEntrypoint = DartEntrypoint.createDefault();
    }

    if (activeEngines.size() == 0) {
      engine = createEngine(context);
      engine.getDartExecutor().executeDartEntrypoint(dartEntrypoint);
    } else {
      engine = activeEngines.get(0).spawn(context, dartEntrypoint);
    }

    activeEngines.add(engine);

    final FlutterEngine engineToCleanUpOnDestroy = engine;
    engine.addEngineLifecycleListener(
        new FlutterEngine.EngineLifecycleListener() {

          @Override
          public void onPreEngineRestart() {
            // No-op. Not interested.
          }

          @Override
          public void onEngineWillDestroy() {
            activeEngines.remove(engineToCleanUpOnDestroy);
          }
        });
    return engine;
  }

  @VisibleForTesting
  /* package */ FlutterEngine createEngine(Context context) {
    return new FlutterEngine(context);
  }
}
