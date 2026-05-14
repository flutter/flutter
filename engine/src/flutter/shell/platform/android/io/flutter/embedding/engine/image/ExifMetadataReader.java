// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.embedding.engine.image;

import androidx.annotation.NonNull;
import androidx.annotation.RequiresApi;
import androidx.exifinterface.media.ExifInterface;
import io.flutter.Log;
import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.io.InputStream;

/** Reads EXIF metadata from an image. */
@RequiresApi(io.flutter.Build.API_LEVELS.API_28)
class ExifMetadataReader {
  private static final String TAG = "ExifMetadataReader";

  /**
   * Reads the EXIF metadata from the given byte array and populates the provided {@link Metadata}
   * object.
   *
   * @param bytes The byte array containing the image data. The supported formats include JPEG, PNG,
   *     WebP, HEIF, and various RAW formats such as DNG, CR2, NEF, ARW, and ORF. See the {@link
   *     ExifInterface} documentation for a complete and up-to-date list.
   * @param metadata The {@link Metadata} object to populate.
   */
  static void read(byte[] bytes, @NonNull Metadata metadata) {
    try {
      try (InputStream inputStream = new ByteArrayInputStream(bytes)) {
        ExifInterface exifInterface = new ExifInterface(inputStream);
        metadata.orientation =
            exifInterface.getAttributeInt(
                ExifInterface.TAG_ORIENTATION, ExifInterface.ORIENTATION_NORMAL);
      }
    } catch (IOException e) {
      Log.e(TAG, "Failed to read EXIF metadata", e);
    }
  }
}
