// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.embedding.engine.image;

import android.graphics.Bitmap;
import android.graphics.ColorSpace;
import android.util.Size;
import androidx.annotation.RequiresApi;
import io.flutter.Log;
import java.io.IOException;
import java.nio.ByteBuffer;

/**
 * The default implementation of {@link ImageDecoder} that uses {@link
 * android.graphics.ImageDecoder} to decode images.
 */
@RequiresApi(io.flutter.Build.API_LEVELS.API_28)
class ImageDecoderDefaultImpl implements ImageDecoder {
  private static final String TAG = "FlutterImageDecoderImplDefault";
  private final FlutterImageDecoder.HeaderListener listener;

  /**
   * Constructs a new {@code FlutterImageDecoderImplDefault}.
   *
   * @param listener A listener to receive image header information.
   */
  public ImageDecoderDefaultImpl(FlutterImageDecoder.HeaderListener listener) {
    this.listener = listener;
  }

  /**
   * Decodes an image from the given {@link ByteBuffer}.
   *
   * @param buffer The {@link ByteBuffer} containing the encoded image.
   * @param metadata The metadata of the image. This is unused here.
   * @return The decoded {@link Bitmap}, or null if decoding fails.
   */
  public Bitmap decodeImage(ByteBuffer buffer, Metadata metadata) {
    android.graphics.ImageDecoder.Source source =
        android.graphics.ImageDecoder.createSource(buffer);
    try {
      return android.graphics.ImageDecoder.decodeBitmap(
          source,
          (decoder, info, src) -> {
            // i.e. ARGB_8888
            decoder.setTargetColorSpace(ColorSpace.get(ColorSpace.Named.SRGB));
            // TODO(bdero): Switch to ALLOCATOR_HARDWARE for devices that have
            // `AndroidBitmap_getHardwareBuffer` (API 30+) available once Skia supports
            // `SkImage::MakeFromAHardwareBuffer` via dynamic lookups:
            // https://skia-review.googlesource.com/c/skia/+/428960
            decoder.setAllocator(android.graphics.ImageDecoder.ALLOCATOR_SOFTWARE);

            if (listener != null) {
              Size size = info.getSize();
              listener.onImageHeader(size.getWidth(), size.getHeight());
            }
          });
    } catch (IOException e) {
      Log.e(TAG, "Failed to decode image", e);
      return null;
    }
  }
}
