package io.flutter.embedding.engine.image;

import android.graphics.Bitmap;
import android.graphics.Matrix;
import android.media.ExifInterface;
import androidx.annotation.NonNull;
import java.nio.ByteBuffer;

class Utils {
  static @NonNull byte[] getBytes(@NonNull ByteBuffer buffer) {
    byte[] bytes = new byte[buffer.remaining()];
    buffer.get(bytes);
    // Rewind the buffer so it can be used again.
    buffer.rewind();
    return bytes;
  }

  ///  Only interested in the Flip.
  static boolean isFlipCase(int orientation) {
    switch (orientation) {
      case ExifInterface.ORIENTATION_FLIP_HORIZONTAL: // 2
      case ExifInterface.ORIENTATION_FLIP_VERTICAL: // 4
      case ExifInterface.ORIENTATION_TRANSPOSE: // 5 (rotate 90 + flip H)
      case ExifInterface.ORIENTATION_TRANSVERSE: // 7 (rotate 270 + flip H)
        return true;
      default:
        return false;
    }
  }

  ///  This only applies the flip based on the Exif data, as the rotation should be handled by
  // ImageDecoder.
  static Bitmap applyFlipIfNeeded(Bitmap decoded, int exifOrientation) {
    if (decoded == null || !Utils.isFlipCase(exifOrientation)) {
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
