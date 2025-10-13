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
class FlutterImageDecoderImplHeifApi36 implements ImageDecoder {

  private final Utils utils;

  public FlutterImageDecoderImplHeifApi36(Utils utils) {
    this.utils = utils;
  }
  /**
   * Decodes an image from the given {@link ByteBuffer}.
   *
   * @param buffer The {@link ByteBuffer} containing the encoded image.
   * @param metadata The metadata of the image.
   * @return The decoded {@link Bitmap}, or null if decoding fails.
   */
  public Bitmap decodeImage(ByteBuffer buffer, Metadata metadata) {
    byte[] bytes = utils.getBytes(buffer);
    BitmapFactory.Options decodeOptions = new BitmapFactory.Options();
    decodeOptions.inPreferredConfig = Bitmap.Config.ARGB_8888;
    Bitmap bitmap = BitmapFactory.decodeByteArray(bytes, 0, bytes.length, decodeOptions);
    if (metadata.rotation != 0) {
      Matrix matrix = new Matrix();
      matrix.postRotate(metadata.rotation);
      Bitmap rotatedBitmap =
          Bitmap.createBitmap(bitmap, 0, 0, bitmap.getWidth(), bitmap.getHeight(), matrix, true);
      bitmap.recycle();
      return utils.applyFlipIfNeeded(rotatedBitmap, metadata.orientation);
    } else {
      return utils.applyFlipIfNeeded(bitmap, metadata.orientation);
    }
  }
}
