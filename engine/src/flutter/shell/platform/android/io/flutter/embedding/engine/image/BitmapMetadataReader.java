package io.flutter.embedding.engine.image;

import android.graphics.BitmapFactory;
import androidx.annotation.NonNull;
import androidx.annotation.RequiresApi;
import io.flutter.Log;

@RequiresApi(io.flutter.Build.API_LEVELS.API_28)
public class BitmapMetadataReader {
  private static final String TAG = "BitmapMetadataReader";

  public static void read(byte[] bytes, @NonNull Metadata metadata) {
    try {
      BitmapFactory.Options options = new BitmapFactory.Options();
      options.inJustDecodeBounds = true;
      BitmapFactory.decodeByteArray(bytes, 0, bytes.length, options);
      metadata.mimeType = options.outMimeType;
      // Can't get rotation here - so don't know if this is the final height/width.
      metadata.originalHeight = options.outHeight;
      metadata.originalWidth = options.outWidth;
    } catch (Exception e) {
      Log.e(TAG, "Failed to decode image for mime type", e);
    }
  }
}
