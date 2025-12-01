// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.embedding.engine.image;

import android.graphics.Bitmap;
import android.graphics.Matrix;
import androidx.annotation.NonNull;
import androidx.exifinterface.media.ExifInterface;
import io.flutter.Log;
import java.nio.ByteBuffer;

/** Utility methods for image decoding. */
class ImageUtils {
  private static final String TAG = "ImageUtils";

  /**
   * Returns a byte array containing the remaining bytes of the given {@link ByteBuffer}.
   *
   * <p>The buffer's position is rewound after the bytes are read.
   *
   * @param buffer The {@link ByteBuffer} to read from.
   * @return A byte array containing the remaining bytes of the buffer.
   */
  @NonNull
  static byte[] getBytes(@NonNull ByteBuffer buffer) {
    byte[] bytes = new byte[buffer.remaining()];
    buffer.get(bytes);
    // Rewind the buffer so it can be used again.
    buffer.rewind();
    return bytes;
  }

  /**
   * Returns whether the given EXIF orientation indicates horizontal or vertical flip.
   *
   * @param orientation The EXIF orientation.
   * @return True if the orientation is a flip case, false otherwise.
   */
  static boolean isFlipCase(int orientation) {
    switch (orientation) {
      case ExifInterface.ORIENTATION_FLIP_HORIZONTAL: // 2
      case ExifInterface.ORIENTATION_FLIP_VERTICAL: // 4
      case ExifInterface.ORIENTATION_TRANSPOSE: // 5 (rotate 90 + flip H)
      case ExifInterface.ORIENTATION_TRANSVERSE: // 7 (rotate 270 + flip H)
        return true;
      case ExifInterface.ORIENTATION_NORMAL:
      case ExifInterface.ORIENTATION_ROTATE_90:
      case ExifInterface.ORIENTATION_ROTATE_180:
      case ExifInterface.ORIENTATION_ROTATE_270:
        return false;
      default:
        Log.e(TAG, "Unknown EXIF orientation: " + orientation);
        return false;
    }
  }

  /**
   * Applies a flip to the given {@link Bitmap} if needed, based on the EXIF orientation.
   *
   * <p>This method only applies the flip based on the Exif data, as the rotation should be handled
   * by ImageDecoder.
   *
   * @param decoded The {@link Bitmap} to potentially flip.
   * @param exifOrientation The EXIF orientation of the image.
   * @return The flipped {@link Bitmap}, or the original if no flip was needed.
   */
  static Bitmap applyFlipIfNeeded(Bitmap decoded, int exifOrientation) {
    if (decoded == null || !isFlipCase(exifOrientation)) {
      return decoded;
    }

    int w = decoded.getWidth();
    int h = decoded.getHeight();
    Matrix m = new Matrix();

    switch (exifOrientation) {
      case ExifInterface.ORIENTATION_FLIP_HORIZONTAL: // 2
        m.setScale(-1f, 1f, w / 2f, h / 2f);
        break;
      case ExifInterface.ORIENTATION_FLIP_VERTICAL: // 4
        m.setScale(1f, -1f, w / 2f, h / 2f);
        break;
      case ExifInterface.ORIENTATION_TRANSPOSE: // 5
        m.setScale(1f, -1f, w / 2f, h / 2f);
        break;
      case ExifInterface.ORIENTATION_TRANSVERSE: // 7
        m.setScale(-1f, 1f, w / 2f, h / 2f);
        break;
      default:
        return decoded;
    }

    Bitmap flipped = Bitmap.createBitmap(decoded, 0, 0, w, h, m, /*filter=*/ true);
    if (flipped != decoded) {
      decoded.recycle();
    }
    return flipped;
  }
}
