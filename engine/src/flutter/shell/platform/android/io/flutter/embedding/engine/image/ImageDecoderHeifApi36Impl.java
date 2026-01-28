// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.embedding.engine.image;

import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Matrix;
import androidx.annotation.RequiresApi;
import java.nio.ByteBuffer;

/**
 * An implementation of {@link ImageDecoder} that decodes HEIF images on API 36 using {@link
 * BitmapFactory}.
 *
 * <p>There is a known bug for Android 36 where ImageDecoder will fail to retrieve HEIF images with
 * certain gain maps. The workaround is to use BitmapFactory. Rotation and flipping must be applied
 * manually.
 */
@RequiresApi(io.flutter.Build.API_LEVELS.API_36)
class ImageDecoderHeifApi36Impl extends ImageDecoderDefaultImpl {

  public ImageDecoderHeifApi36Impl() {
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
    // Not all HEIF images fail with ImageDecoder, only the ones with unsupported gain maps.  So try
    // the default implementation before falling back to BitmapFactory.
    Bitmap defaultBitmap = super.decodeImage(buffer, metadata);
    if (defaultBitmap != null) {
      return defaultBitmap;
    }
    return decodeImageFallback(buffer, metadata);
  }

  Bitmap decodeImageFallback(ByteBuffer buffer, Metadata metadata) {
    byte[] bytes = ImageUtils.getBytes(buffer);
    BitmapFactory.Options decodeOptions = new BitmapFactory.Options();
    decodeOptions.inPreferredConfig = Bitmap.Config.ARGB_8888;
    Bitmap bitmap = BitmapFactory.decodeByteArray(bytes, 0, bytes.length, decodeOptions);
    if (metadata.rotation != 0) {
      Matrix matrix = new Matrix();
      matrix.postRotate(metadata.rotation);
      Bitmap rotatedBitmap =
          Bitmap.createBitmap(bitmap, 0, 0, bitmap.getWidth(), bitmap.getHeight(), matrix, true);
      bitmap.recycle();
      return ImageUtils.applyFlipIfNeeded(rotatedBitmap, metadata.orientation);
    } else {
      return ImageUtils.applyFlipIfNeeded(bitmap, metadata.orientation);
    }
  }
}
