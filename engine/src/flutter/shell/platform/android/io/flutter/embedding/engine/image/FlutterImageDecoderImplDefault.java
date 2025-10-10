package io.flutter.embedding.engine.image;

import android.graphics.Bitmap;
import android.graphics.ColorSpace;
import android.graphics.ImageDecoder;
import android.util.Size;
import androidx.annotation.RequiresApi;
import io.flutter.Log;
import java.io.IOException;
import java.nio.ByteBuffer;

@RequiresApi(io.flutter.Build.API_LEVELS.API_28)
class FlutterImageDecoderImplDefault implements FlutterImageDecoderImpl {
  private static final String TAG = "FlutterImageDecoderImplDefault";
  private final FlutterImageDecoder.HeaderListener listener;

  public FlutterImageDecoderImplDefault(FlutterImageDecoder.HeaderListener listener) {
    this.listener = listener;
  }

  public Bitmap decodeImage(ByteBuffer buffer, Metadata metadata) {
    ImageDecoder.Source source = ImageDecoder.createSource(buffer);
    try {
      return ImageDecoder.decodeBitmap(
          source,
          (decoder, info, src) -> {
            // i.e. ARGB_8888
            decoder.setTargetColorSpace(ColorSpace.get(ColorSpace.Named.SRGB));
            // TODO(bdero): Switch to ALLOCATOR_HARDWARE for devices that have
            // `AndroidBitmap_getHardwareBuffer` (API 30+) available once Skia supports
            // `SkImage::MakeFromAHardwareBuffer` via dynamic lookups:
            // https://skia-review.googlesource.com/c/skia/+/428960
            decoder.setAllocator(ImageDecoder.ALLOCATOR_SOFTWARE);

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