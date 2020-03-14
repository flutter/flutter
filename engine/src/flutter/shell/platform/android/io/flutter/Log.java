// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter;

import androidx.annotation.NonNull;

/**
 * Port of {@link android.util.Log} that only logs in {@link io.flutter.BuildConfig#DEBUG} mode and
 * internally filters logs based on a {@link #logLevel}.
 */
public class Log {
  private static int logLevel = android.util.Log.DEBUG;

  /**
   * Sets a log cutoff such that a log level of lower priority than {@code logLevel} is filtered
   * out.
   *
   * <p>See {@link android.util.Log} for log level constants.
   */
  public static void setLogLevel(int logLevel) {
    Log.logLevel = logLevel;
  }

  public static void v(@NonNull String tag, @NonNull String message) {
    if (BuildConfig.DEBUG && logLevel <= android.util.Log.VERBOSE) {
      android.util.Log.v(tag, message);
    }
  }

  public static void v(@NonNull String tag, @NonNull String message, @NonNull Throwable tr) {
    if (BuildConfig.DEBUG && logLevel <= android.util.Log.VERBOSE) {
      android.util.Log.v(tag, message, tr);
    }
  }

  public static void i(@NonNull String tag, @NonNull String message) {
    if (BuildConfig.DEBUG && logLevel <= android.util.Log.INFO) {
      android.util.Log.i(tag, message);
    }
  }

  public static void i(@NonNull String tag, @NonNull String message, @NonNull Throwable tr) {
    if (BuildConfig.DEBUG && logLevel <= android.util.Log.INFO) {
      android.util.Log.i(tag, message, tr);
    }
  }

  public static void d(@NonNull String tag, @NonNull String message) {
    if (BuildConfig.DEBUG && logLevel <= android.util.Log.DEBUG) {
      android.util.Log.d(tag, message);
    }
  }

  public static void d(@NonNull String tag, @NonNull String message, @NonNull Throwable tr) {
    if (BuildConfig.DEBUG && logLevel <= android.util.Log.DEBUG) {
      android.util.Log.d(tag, message, tr);
    }
  }

  public static void w(@NonNull String tag, @NonNull String message) {
    android.util.Log.w(tag, message);
  }

  public static void w(@NonNull String tag, @NonNull String message, @NonNull Throwable tr) {
    android.util.Log.w(tag, message, tr);
  }

  public static void e(@NonNull String tag, @NonNull String message) {
    android.util.Log.e(tag, message);
  }

  public static void e(@NonNull String tag, @NonNull String message, @NonNull Throwable tr) {
    android.util.Log.e(tag, message, tr);
  }

  public static void wtf(@NonNull String tag, @NonNull String message) {
    android.util.Log.wtf(tag, message);
  }

  public static void wtf(@NonNull String tag, @NonNull String message, @NonNull Throwable tr) {
    android.util.Log.wtf(tag, message, tr);
  }
}
