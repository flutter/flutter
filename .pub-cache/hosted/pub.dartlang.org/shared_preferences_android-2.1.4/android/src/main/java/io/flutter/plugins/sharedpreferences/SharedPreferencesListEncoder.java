// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.sharedpreferences;

import androidx.annotation.NonNull;
import java.util.List;

/**
 * An interface used to provide conversion logic between List<String> and String for
 * SharedPreferencesPlugin.
 */
public interface SharedPreferencesListEncoder {
  /** Converts list to String for storing in shared preferences. */
  @NonNull
  String encode(@NonNull List<String> list);
  /** Converts stored String representing List<String> to List. */
  @NonNull
  List<String> decode(@NonNull String listString);
}
