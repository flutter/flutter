package io.flutter.embedding.engine.image;

import androidx.annotation.NonNull;
import androidx.annotation.RequiresApi;
import io.flutter.Build;
import java.nio.ByteBuffer;

@RequiresApi(Build.API_LEVELS.API_28)
public class Metadata {
  public int width;
  public int height;
  public int rotation;
  public String mimeType;
  public int orientation;
  public int originalHeight;
  public int originalWidth;

  Metadata() {}

  static Metadata create(
      @NonNull ByteBuffer buffer, @NonNull FlutterImageDecoder.HeaderListener headerListener) {
    Metadata metadata = new Metadata();
    byte[] bytes = Utils.getBytes(buffer);
    // Use bitmap decode to get the mimetype and original dimensions.
    BitmapMetadataReader.read(bytes, metadata);
    // For non-heif images, we'll let the default implementation ImageDecoder handle the rest.
    if (metadata.isHeif()) {
      // MediaFormat to get the rotation and, if necessary, the rotated dimensions.
      MediaMetadataReader.read(bytes, metadata);
      // With the final dimensions, we can callback.
      headerListener.onImageHeader(metadata.width, metadata.height);
      // Need to use Exif for HEIF flipping.
      ExifMetadataReader.read(bytes, metadata);
    }
    return metadata;
  }

  public boolean isHeif() {
    return mimeType.equals("image/heif");
  }
}
