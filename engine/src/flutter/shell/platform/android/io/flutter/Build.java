// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter;

import androidx.annotation.VisibleForTesting;

/** A replacement of utilities from android.os.Build. */
public class Build {
  /** For use in place of the Android Build.VERSION_CODES class. */
  public static class API_LEVELS {
    @VisibleForTesting public static final int FLUTTER_MIN = 24;
    /** Android 5.0 (Lollipop) */
    public static final int API_21 = 21;
    /** Android 5.1 (Lollipop MR1) */
    public static final int API_22 = 22;
    /** Android 6.0 (Marshmallow) */
    public static final int API_23 = 23;
    /** Android 7.0 (Nougat) */
    public static final int API_24 = 24;
    /** Android 7.1 (Nougat MR1) */
    public static final int API_25 = 25;
    /** Android 8.0 (Oreo) */
    public static final int API_26 = 26;
    /** Android 8.1 (Oreo MR1) */
    public static final int API_27 = 27;
    /** Android 9 (Pie) */
    public static final int API_28 = 28;
    /** Android 10 (Q) */
    public static final int API_29 = 29;
    /** Android 11 (R) */
    public static final int API_30 = 30;
    /** Android 12 (S) */
    public static final int API_31 = 31;
    /** Android 12L (Sv2) */
    public static final int API_32 = 32;
    /** Android 13 (Tiramisu) */
    public static final int API_33 = 33;
    /** Android 14 (Upside Down Cake) */
    public static final int API_34 = 34;
    /** Android 15 (Vanilla Ice Cream) */
    public static final int API_35 = 35;
    /** Android 16 */
    public static final int API_36 = 36;
  }
}
