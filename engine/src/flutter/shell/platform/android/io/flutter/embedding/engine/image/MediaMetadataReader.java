// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.embedding.engine.image;

import android.media.MediaDataSource;
import android.media.MediaExtractor;
import android.media.MediaFormat;
import androidx.annotation.NonNull;
import androidx.annotation.RequiresApi;
import androidx.annotation.VisibleForTesting;
import io.flutter.Log;
import java.io.IOException;

/** Reads metadata from an image using {@link MediaExtractor}. */
@RequiresApi(io.flutter.Build.API_LEVELS.API_28)
class MediaMetadataReader {

  private static final String TAG = "MediaMetadataReader";

  @NonNull
  private static MediaExtractor getMediaExtractor(byte[] bytes) throws IOException {
    final MediaDataSource dataSource =
        new MediaDataSource() {
          @Override
          public long getSize() throws IOException {
            return bytes.length;
          }

          @Override
          public int readAt(long position, byte[] buffer, int offset, int size) throws IOException {
            if (position >= bytes.length) {
              return -1;
            }
            if (position + size > bytes.length) {
              size = (int) (bytes.length - position);
            }
            System.arraycopy(bytes, (int) position, buffer, offset, size);
            return size;
          }

          @Override
          public void close() throws IOException {
            // no-op
          }
        };
    MediaExtractor extractor = new MediaExtractor();
    extractor.setDataSource(dataSource);
    return extractor;
  }

  /**
   * Reads the metadata from the given byte array and populates the provided {@link Metadata}
   * object.
   *
   * @param bytes The byte array containing the image data.
   * @param metadata The {@link Metadata} object to populate.
   */
  static void read(byte[] bytes, @NonNull Metadata metadata) {
    try {
      MediaExtractor extractor = getMediaExtractor(bytes);
      read(bytes, metadata, extractor);
    } catch (Exception e) {
      Log.e(TAG, "Failed to decode HEIF image using MediaExtractor", e);
    }
  }

  @VisibleForTesting
  static void read(byte[] bytes, @NonNull Metadata metadata, MediaExtractor extractor) {
    int rotation = 0;
    try {
      int trackCount = extractor.getTrackCount();
      for (int i = 0; i < trackCount; i++) {
        MediaFormat format = extractor.getTrackFormat(i);
        // This is different from the mimeType already gathered.
        String mime = format.getString(MediaFormat.KEY_MIME);
        if (mime != null && mime.startsWith("image/")) {
          if (format.containsKey(MediaFormat.KEY_ROTATION)) {
            rotation = format.getInteger(MediaFormat.KEY_ROTATION);
          }

          int finalWidth = metadata.originalWidth;
          int finalHeight = metadata.originalHeight;
          if (rotation == 90 || rotation == 270) {
            finalHeight = metadata.originalWidth;
            finalWidth = metadata.originalHeight;
          }
          metadata.height = finalHeight;
          metadata.width = finalWidth;
          metadata.rotation = rotation;
          break;
        }
      }
    } catch (Exception e) {
      Log.e(TAG, "Failed to decode HEIF image using MediaExtractor", e);
    }
  }
}
