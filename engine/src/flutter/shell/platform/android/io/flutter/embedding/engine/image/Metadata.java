// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.embedding.engine.image;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.annotation.RequiresApi;
import androidx.annotation.VisibleForTesting;
import io.flutter.Build;
import java.nio.ByteBuffer;

/**
 * Represents the metadata of an image.
 *
 * <p>This class is populated by the various metadata reader classes.
 */
@RequiresApi(Build.API_LEVELS.API_28)
class Metadata {
  int width;
  int height;
  int rotation;
  @Nullable String mimeType;
  int orientation;
  int originalHeight;
  int originalWidth;

  @VisibleForTesting
  Metadata() {}

  static Metadata create(
      @NonNull ByteBuffer buffer, @NonNull FlutterImageDecoder.HeaderListener headerListener) {
    Metadata metadata = new Metadata();
    byte[] bytes = ImageUtils.getBytes(buffer);
    // Use bitmap decode to get the mimetype and original dimensions.
    BitmapMetadataReader.read(bytes, metadata);
    // For non-heif images, we'll let the default implementation ImageDecoder handle the rest.
    if (metadata.isHeif()) {
      // MediaFormat to get the rotation and, if necessary, the rotated dimensions.
      MediaMetadataReader.read(bytes, metadata);
      // With the final dimensions, we can callback.
      headerListener.onImageHeader(metadata.width, metadata.height);
      // Need to use Exif for HEIF flipping.
      ExifMetadataReader.read(bytes, metadata);
    }
    return metadata;
  }

  /**
   * Returns whether the image is in HEIF format.
   *
   * @return True if the image is HEIF, false otherwise.
   */
  boolean isHeif() {
    return "image/heif".equals(mimeType);
  }
}
