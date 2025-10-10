package io.flutter.embedding.engine.image;

import android.graphics.Bitmap;
import androidx.annotation.RequiresApi;
import java.nio.ByteBuffer;

@RequiresApi(io.flutter.Build.API_LEVELS.API_28)
class FlutterImageDecoderImplHeifPre36 extends FlutterImageDecoderImplDefault {
  private static final String TAG = "FlutterImageDecoderImplHeifPre36";

  public FlutterImageDecoderImplHeifPre36() {
    super(null);
  }

  /// HEIF flipping (or mirroring) does not work Pre 36.  Need to do it manually.
  public Bitmap decodeImage(ByteBuffer buffer, Metadata metadata) {
    return Utils.applyFlipIfNeeded(super.decodeImage(buffer, metadata), metadata.orientation);
  }
}
