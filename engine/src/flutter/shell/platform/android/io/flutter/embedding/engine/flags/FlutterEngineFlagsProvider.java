// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.embedding.engine.flags;

import android.content.Intent;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import java.util.List;

public interface FlutterEngineFlagsProvider {
  @NonNull
  List<String> getFlags(@Nullable Intent intent);

  boolean isSoftwareRenderingEnabled(@Nullable Intent intent);
}
