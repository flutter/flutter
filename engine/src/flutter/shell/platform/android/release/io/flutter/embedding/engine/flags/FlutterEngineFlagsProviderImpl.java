// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.embedding.engine.flags;

import android.content.Intent;
import android.os.Bundle;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import io.flutter.Log;
import java.util.Collections;
import java.util.List;

public final class FlutterEngineFlagsProviderImpl implements FlutterEngineFlagsProvider {
  private static final String TAG = "FlutterEngineFlagsProvider";

  public static final FlutterEngineFlagsProviderImpl INSTANCE =
      new FlutterEngineFlagsProviderImpl();

  private FlutterEngineFlagsProviderImpl() {}

  @Override
  @NonNull
  public List<String> getFlags(@Nullable Intent intent) {
    warnIfFlagsPresent(intent);
    // Release builds do not support engine flag configuration via Intent.
    return Collections.emptyList();
  }

  @Override
  public boolean isSoftwareRenderingEnabled(@Nullable Intent intent) {
    warnIfFlagsPresent(intent);
    // Release builds do not support engine flag configuration via Intent.
    return false;
  }

  private void warnIfFlagsPresent(@Nullable Intent intent) {
    if (intent == null || intent.getExtras() == null) {
      return;
    }
    Bundle extras = intent.getExtras();
    for (String key : extras.keySet()) {
      FlutterEngineFlags.Flag flag = FlutterEngineFlags.getFlagFromIntentKey(key);
      if (flag != null) {
        Log.w(
            TAG,
            "Engine flag "
                + flag.engineArgument
                + " was specified via Intent extras. Setting engine flags via Intent is not supported in release mode and will be ignored. "
                + "To set engine flags, specify them on the command line or see https://docs.flutter.dev/release/breaking-changes/restrict-command-line-flags-prebuilt-android-release-binaries for alternative methods.");
        break;
      }
    }
  }
}
