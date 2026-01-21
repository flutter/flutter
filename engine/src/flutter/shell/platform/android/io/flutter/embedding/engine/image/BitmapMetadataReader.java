// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.embedding.engine.image;

import android.graphics.BitmapFactory;
import androidx.annotation.NonNull;
import androidx.annotation.RequiresApi;
import io.flutter.Log;

/** Reads metadata from an image using {@link BitmapFactory}. */
@RequiresApi(io.flutter.Build.API_LEVELS.API_28)
public class BitmapMetadataReader {
  private static final String TAG = "BitmapMetadataReader";

  /**
   * Reads the metadata from the given byte array and populates the provided {@link Metadata}
   * object.
   *
   * @param bytes The byte array containing the image data.
   * @param metadata The {@link Metadata} object to populate.
   */
  static void read(byte[] bytes, @NonNull Metadata metadata) {
    try {
      BitmapFactory.Options options = new BitmapFactory.Options();
      options.inJustDecodeBounds = true;
      BitmapFactory.decodeByteArray(bytes, 0, bytes.length, options);
      metadata.mimeType = options.outMimeType;
      // Can't get rotation here - so don't know if this is the final height/width.
      metadata.originalHeight = options.outHeight;
      metadata.originalWidth = options.outWidth;
    } catch (Exception e) {
      Log.e(TAG, "Failed to decode image for mime type", e);
    }
  }
}
