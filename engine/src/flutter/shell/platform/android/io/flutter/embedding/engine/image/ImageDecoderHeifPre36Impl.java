// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.embedding.engine.image;

import android.graphics.Bitmap;
import androidx.annotation.RequiresApi;
import io.flutter.Build;
import java.nio.ByteBuffer;

/**
 * An implementation of {@link ImageDecoder} that decodes HEIF images on devices running Android
 * versions prior to 36.
 *
 * <p>flipping (or mirroring) from metadata does not work Pre 36 so we need to do it manually.
 */
@RequiresApi(Build.API_LEVELS.API_28)
class ImageDecoderHeifPre36Impl extends ImageDecoderDefaultImpl {
  private static final String TAG = "FlutterImageDecoderImplHeifPre36";

  /** Constructs a new {@code FlutterImageDecoderImplHeifPre36}. */
  public ImageDecoderHeifPre36Impl() {
    super(null);
  }

  /**
   * Decodes an image from the given {@link ByteBuffer}.
   *
   * @param buffer The {@link ByteBuffer} containing the encoded image.
   * @param metadata The metadata of the image.
   * @return The decoded {@link Bitmap}, or null if decoding fails.
   */
  @Override
  public Bitmap decodeImage(ByteBuffer buffer, Metadata metadata) {
    return ImageUtils.applyFlipIfNeeded(super.decodeImage(buffer, metadata), metadata.orientation);
  }
}
