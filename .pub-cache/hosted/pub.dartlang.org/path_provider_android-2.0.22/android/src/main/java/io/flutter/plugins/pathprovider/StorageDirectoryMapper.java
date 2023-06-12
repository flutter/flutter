// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.pathprovider;

import android.os.Build.VERSION;
import android.os.Build.VERSION_CODES;
import android.os.Environment;

/** Helps to map the Dart `StorageDirectory` enum to a Android system constant. */
class StorageDirectoryMapper {
  /**
   * Return a Android Environment constant for a Dart Index.
   *
   * @return The correct Android Environment constant or null, if the index is null.
   * @throws IllegalArgumentException If `dartIndex` is not null but also not matches any known
   *     index.
   */
  static String androidType(Integer dartIndex) throws IllegalArgumentException {
    if (dartIndex == null) {
      return null;
    }

    switch (dartIndex) {
      case 0:
        return Environment.DIRECTORY_MUSIC;
      case 1:
        return Environment.DIRECTORY_PODCASTS;
      case 2:
        return Environment.DIRECTORY_RINGTONES;
      case 3:
        return Environment.DIRECTORY_ALARMS;
      case 4:
        return Environment.DIRECTORY_NOTIFICATIONS;
      case 5:
        return Environment.DIRECTORY_PICTURES;
      case 6:
        return Environment.DIRECTORY_MOVIES;
      case 7:
        return Environment.DIRECTORY_DOWNLOADS;
      case 8:
        return Environment.DIRECTORY_DCIM;
      case 9:
        if (VERSION.SDK_INT >= VERSION_CODES.KITKAT) {
          return Environment.DIRECTORY_DOCUMENTS;
        } else {
          throw new IllegalArgumentException("Documents directory is unsupported.");
        }
      default:
        throw new IllegalArgumentException("Unknown index: " + dartIndex);
    }
  }
}
