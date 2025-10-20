// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.embedding.engine.image;

import android.graphics.Bitmap;
import android.os.Build;
import androidx.annotation.NonNull;
import androidx.annotation.RequiresApi;
import java.nio.ByteBuffer;

interface ImageDecoder {
  Bitmap decodeImage(ByteBuffer buffer, Metadata metadata);
}

/**
 * Decodes images from a {@link ByteBuffer}.
 *
 * <p>This class selects the appropriate decoder implementation based on the image format and
 * Android API level.
 */
@RequiresApi(io.flutter.Build.API_LEVELS.API_28)
public class FlutterImageDecoder {

  /** A listener to be notified when image header information has been parsed. */
  public interface HeaderListener {
    /**
     * Callback invoked when the image dimensions are available.
     *
     * @param width The width of the image.
     * @param height The height of the image.
     */
    void onImageHeader(int width, int height);
  }

  /**
   * Decodes an image from the given {@link ByteBuffer}.
   *
   * @param buffer The {@link ByteBuffer} containing the encoded image.
   * @param headerListener A listener to receive image header information.
   * @return The decoded {@link Bitmap}, or null if decoding fails.
   */
  public static Bitmap decodeImage(
      @NonNull ByteBuffer buffer, @NonNull HeaderListener headerListener) {
    Metadata metadata = Metadata.create(buffer, headerListener);
    ImageDecoder impl = null;
    if (metadata.isHeif()) {
      if (Build.VERSION.SDK_INT == io.flutter.Build.API_LEVELS.API_36) {
        impl = new ImageDecoderHeifApi36Impl();
      } else if (Build.VERSION.SDK_INT < io.flutter.Build.API_LEVELS.API_36) {
        impl = new ImageDecoderHeifPre36Impl();
      }
    }
    if (impl == null) {
      impl = new ImageDecoderDefaultImpl(headerListener);
    }
    return impl.decodeImage(buffer, metadata);
  }
}