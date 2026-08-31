// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.embedding.engine.flags;

import android.content.Intent;
import android.os.Bundle;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import io.flutter.embedding.engine.FlutterEngineFlags;
import java.util.ArrayList;
import java.util.List;

public final class FlutterEngineFlagsProviderImpl implements FlutterEngineFlagsProvider {
  public static final FlutterEngineFlagsProviderImpl INSTANCE =
      new FlutterEngineFlagsProviderImpl();

  private FlutterEngineFlagsProviderImpl() {}

  @Override
  @NonNull
  public List<String> getFlags(@Nullable Intent intent) {
    if (intent == null) {
      return new ArrayList<>();
    }

    Bundle extras = intent.getExtras();
    if (extras == null) {
      return new ArrayList<>();
    }

    final ArrayList<String> args = new ArrayList<>();
    for (String key : extras.keySet()) {
      FlutterEngineFlags.Flag flag = FlutterEngineFlags.getFlagFromIntentKey(key);
      if (flag != null) {
        Object value = extras.get(key);
        if (value instanceof Boolean) {
          if (flag.engineArgument.endsWith("=")) {
            args.add(flag.engineArgument + value.toString());
          } else {
            if ((Boolean) value) {
              args.add(flag.engineArgument);
            }
          }
        } else if (value instanceof Integer) {
          args.add(flag.engineArgument + value.toString());
        } else if (value instanceof String) {
          args.add(flag.engineArgument + (String) value);
        }
      }
    }

    return args;
  }
}
