// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.util;

import androidx.annotation.NonNull;
import androidx.tracing.Trace;

public final class TraceSection {
  /**
   * Wraps Trace.beginSection to ensure that the line length stays below 127 code units.
   *
   * @param sectionName The string to display as the section name in the trace.
   */
  public static void begin(@NonNull String sectionName) {
    sectionName = sectionName.length() < 124 ? sectionName : sectionName.substring(0, 124) + "...";
    Trace.beginSection(sectionName);
  }

  /** Wraps Trace.endSection. */
  public static void end() throws RuntimeException {
    Trace.endSection();
  }
}
