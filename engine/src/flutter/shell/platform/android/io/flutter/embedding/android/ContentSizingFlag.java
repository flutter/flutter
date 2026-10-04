// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.embedding.android;

import android.content.Context;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageManager;
import android.content.pm.PackageManager.NameNotFoundException;
import android.os.Bundle;
import io.flutter.Log;

class ContentSizingFlag {

  private static final String TAG = "ContentSizingFlag";

  // Default to DISABLED
  private static final boolean DEFAULT = false;

  private static final String ENABLE_CONTENT_SIZING =
      "io.flutter.embedding.android.EnableContentSizing";

  static boolean isEnabled(Context context) {
    // Ensure that the context is actually the application context.
    final Context appContext = context.getApplicationContext();
    Bundle metaData = null;
    try {
      ApplicationInfo applicationInfo =
          appContext
              .getPackageManager()
              .getApplicationInfo(appContext.getPackageName(), PackageManager.GET_META_DATA);
      metaData = applicationInfo.metaData;
    } catch (NameNotFoundException ex) {
      Log.e(TAG, "Could not get metadata", ex);
    }
    return metaData != null ? metaData.getBoolean(ENABLE_CONTENT_SIZING, DEFAULT) : DEFAULT;
  }
}
