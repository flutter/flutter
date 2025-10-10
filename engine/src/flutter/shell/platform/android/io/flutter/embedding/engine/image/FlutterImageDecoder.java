package io.flutter.embedding.engine.image;

import android.graphics.Bitmap;
import android.os.Build;
import androidx.annotation.NonNull;
import androidx.annotation.RequiresApi;
import java.nio.ByteBuffer;

interface FlutterImageDecoderImpl {
  Bitmap decodeImage(ByteBuffer buffer, Metadata metadata);
}

@RequiresApi(io.flutter.Build.API_LEVELS.API_28)
public class FlutterImageDecoder {

  public interface HeaderListener {
    void onImageHeader(int width, int height);
  }

  public static Bitmap decodeImage(
      @NonNull ByteBuffer buffer, @NonNull HeaderListener headerListener) {
    Metadata metadata = Metadata.create(buffer, headerListener);
    FlutterImageDecoderImpl impl = null;
    if (metadata.isHeif()) {
      if (Build.VERSION.SDK_INT == io.flutter.Build.API_LEVELS.API_36) {
        impl = new FlutterImageDecoderImplHeifApi36();
      } else if (Build.VERSION.SDK_INT < io.flutter.Build.API_LEVELS.API_36) {
        impl = new FlutterImageDecoderImplHeifPre36();
      }
    }
    if (impl == null) {
      impl = new FlutterImageDecoderImplDefault(headerListener);
    }
    return impl.decodeImage(buffer, metadata);
  }
}
