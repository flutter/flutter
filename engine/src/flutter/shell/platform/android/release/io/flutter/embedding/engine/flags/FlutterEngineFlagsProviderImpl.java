// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.embedding.engine.flags;

import android.content.Intent;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import java.util.Collections;
import java.util.List;

public final class FlutterEngineFlagsProviderImpl implements FlutterEngineFlagsProvider {
  public static final FlutterEngineFlagsProviderImpl INSTANCE =
      new FlutterEngineFlagsProviderImpl();

  private FlutterEngineFlagsProviderImpl() {}

  @Override
  @NonNull
  public List<String> getFlags(@Nullable Intent intent) {
    // Release builds do not support engine flag configuration via Intent.
    return Collections.emptyList();
  }
}
