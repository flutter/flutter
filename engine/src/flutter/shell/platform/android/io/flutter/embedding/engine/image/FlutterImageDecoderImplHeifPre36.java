package io.flutter.embedding.engine.image;

import android.graphics.Bitmap;
import androidx.annotation.RequiresApi;
import java.nio.ByteBuffer;

/**
 * An implementation of {@link FlutterImageDecoderImpl} that decodes HEIF images on devices running
 * Android versions prior to 36.
 *
 * <p>flipping (or mirroring) does not work Pre 36. Need to do it manually.
 */
@RequiresApi(io.flutter.Build.API_LEVELS.API_28)
class FlutterImageDecoderImplHeifPre36 extends FlutterImageDecoderImplDefault {
  private static final String TAG = "FlutterImageDecoderImplHeifPre36";

  /** Constructs a new {@code FlutterImageDecoderImplHeifPre36}. */
  public FlutterImageDecoderImplHeifPre36() {
    super(null);
  }

  /**
   * Decodes an image from the given {@link ByteBuffer}.
   *
   * @param buffer The {@link ByteBuffer} containing the encoded image.
   * @param metadata The metadata of the image.
   * @return The decoded {@link Bitmap}, or null if decoding fails.
   */
  public Bitmap decodeImage(ByteBuffer buffer, Metadata metadata) {
    return Utils.applyFlipIfNeeded(super.decodeImage(buffer, metadata), metadata.orientation);
  }
}
