// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.util;

import androidx.annotation.NonNull;
import androidx.tracing.Trace;

public final class TraceSection {
  private static String cropSectionName(@NonNull String sectionName) {
    return sectionName.length() < 124 ? sectionName : sectionName.substring(0, 124) + "...";
  }

  /**
   * Wraps Trace.beginSection to ensure that the line length stays below 127 code units.
   *
   * @param sectionName The string to display as the section name in the trace.
   */
  public static void begin(@NonNull String sectionName) {
    Trace.beginSection(cropSectionName(sectionName));
  }

  /** Wraps Trace.endSection. */
  public static void end() throws RuntimeException {
    Trace.endSection();
  }

  /**
   * Wraps Trace.beginAsyncSection to ensure that the line length stays below 127 code units.
   *
   * @param sectionName The string to display as the section name in the trace.
   * @param cookie Unique integer defining the section.
   */
  public static void beginAsyncSection(String sectionName, int cookie) {
    Trace.beginAsyncSection(cropSectionName(sectionName), cookie);
  }

  /** Wraps Trace.endAsyncSection to ensure that the line length stays below 127 code units. */
  public static void endAsyncSection(String sectionName, int cookie) {
    Trace.endAsyncSection(cropSectionName(sectionName), cookie);
  }
}
