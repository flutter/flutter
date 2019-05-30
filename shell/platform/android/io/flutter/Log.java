// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter;

import android.support.annotation.NonNull;

import io.flutter.BuildConfig;

/**
 * Port of {@link android.util.Log} that only logs in {@link BuildConfig#DEBUG} mode.
 */
public class Log {
  public static void v(@NonNull String tag, @NonNull String message) {
    if (BuildConfig.DEBUG) {
      android.util.Log.v(tag, message);
    }
  }

  public static void v(@NonNull String tag, @NonNull String message, @NonNull Throwable tr) {
    if (BuildConfig.DEBUG) {
      android.util.Log.v(tag, message, tr);
    }
  }

  public static void i(@NonNull String tag, @NonNull String message) {
    if (BuildConfig.DEBUG) {
      android.util.Log.i(tag, message);
    }
  }

  public static void i(@NonNull String tag, @NonNull String message, @NonNull Throwable tr) {
    if (BuildConfig.DEBUG) {
      android.util.Log.i(tag, message, tr);
    }
  }

  public static void d(@NonNull String tag, @NonNull String message) {
    if (BuildConfig.DEBUG) {
      android.util.Log.d(tag, message);
    }
  }

  public static void d(@NonNull String tag, @NonNull String message, @NonNull Throwable tr) {
    if (BuildConfig.DEBUG) {
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
