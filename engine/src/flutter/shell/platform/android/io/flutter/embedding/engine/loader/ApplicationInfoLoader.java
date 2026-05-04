// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.embedding.engine.loader;

import android.content.Context;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageManager;
import android.os.Bundle;
import androidx.annotation.NonNull;
import io.flutter.embedding.engine.FlutterEngineFlags;

/** Loads application information given a Context. */
public final class ApplicationInfoLoader {

  @NonNull
  private static ApplicationInfo getApplicationInfo(@NonNull Context applicationContext) {
    try {
      return applicationContext
          .getPackageManager()
          .getApplicationInfo(applicationContext.getPackageName(), PackageManager.GET_META_DATA);
    } catch (PackageManager.NameNotFoundException e) {
      throw new RuntimeException(e);
    }
  }

  private static String getString(Bundle metadata, String key) {
    if (metadata == null) {
      return null;
    }
    return metadata.getString(key, null);
  }

  private static String getStringWithFallback(Bundle metadata, String key, String fallbackKey) {
    if (metadata == null) {
      return null;
    }

    String metadataString = metadata.getString(key, null);

    if (metadataString == null) {
      metadataString = metadata.getString(fallbackKey);
    }

    return metadataString;
  }

  private static boolean getBoolean(Bundle metadata, String key, boolean defaultValue) {
    if (metadata == null) {
      return defaultValue;
    }
    return metadata.getBoolean(key, defaultValue);
  }

  /**
   * Initialize our Flutter config values by obtaining them from the manifest XML file, falling back
   * to default values.
   */
  @NonNull
  public static FlutterApplicationInfo load(@NonNull Context applicationContext) {
    ApplicationInfo appInfo = getApplicationInfo(applicationContext);

    // TODO(camsim99): Remove support for DEPRECATED_AOT_SHARED_LIBRARY_NAME and
    // DEPRECATED_FLUTTER_ASSETS_DIR
    // when all usage of the deprecated names has been removed.
    return new FlutterApplicationInfo(
        getStringWithFallback(
            appInfo.metaData,
            FlutterEngineFlags.AOT_SHARED_LIBRARY_NAME.metadataKey,
            FlutterEngineFlags.DEPRECATED_AOT_SHARED_LIBRARY_NAME.metadataKey),
        getString(appInfo.metaData, FlutterEngineFlags.VM_SNAPSHOT_DATA.metadataKey),
        getString(appInfo.metaData, FlutterEngineFlags.ISOLATE_SNAPSHOT_DATA.metadataKey),
        getStringWithFallback(
            appInfo.metaData,
            FlutterEngineFlags.FLUTTER_ASSETS_DIR.metadataKey,
            FlutterEngineFlags.DEPRECATED_FLUTTER_ASSETS_DIR.metadataKey),
        appInfo.nativeLibraryDir);
  }
}
