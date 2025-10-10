package io.flutter.embedding.engine.image;

import android.media.ExifInterface;
import androidx.annotation.NonNull;
import androidx.annotation.RequiresApi;
import io.flutter.Log;
import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.io.InputStream;

@RequiresApi(io.flutter.Build.API_LEVELS.API_28)
class ExifMetadataReader {
  private static final String TAG = "ExifMetadataReader";

  public static void read(byte[] bytes, @NonNull Metadata metadata) {
    try {
      try (InputStream inputStream = new ByteArrayInputStream(bytes)) {
        ExifInterface exifInterface = new ExifInterface(inputStream);
        metadata.orientation =
            exifInterface.getAttributeInt(
                ExifInterface.TAG_ORIENTATION, ExifInterface.ORIENTATION_NORMAL);
      }
    } catch (IOException e) {
      Log.e(TAG, "Failed to read EXIF metadata", e);
    }
  }
}
