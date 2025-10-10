package io.flutter.embedding.engine.image;

import static org.junit.Assert.assertEquals;
import static org.mockito.Mockito.spy;
import static org.mockito.Mockito.verify;

import android.graphics.Bitmap;
import android.media.ExifInterface;
import androidx.test.ext.junit.runners.AndroidJUnit4;
import io.flutter.Build;
import java.io.ByteArrayOutputStream;
import java.nio.ByteBuffer;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.mockito.ArgumentCaptor;
import org.robolectric.annotation.Config;

/** Unit tests for {@link FlutterImageDecoderImplHeifPre36}. */
@RunWith(AndroidJUnit4.class)
@Config(minSdk = Build.API_LEVELS.API_28, maxSdk = Build.API_LEVELS.API_35)
public class FlutterImageDecoderImplHeifPre36Test {
  private Utils spiedUtils;

  private byte[] createTestPng(int width, int height) {
    Bitmap bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888);
    ByteArrayOutputStream stream = new ByteArrayOutputStream();
    bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream);
    bitmap.recycle();
    return stream.toByteArray();
  }

  @Before
  public void setUp() {
    spiedUtils = spy(new Utils());
  }

  @Test
  public void decodeImage_callsSuperAndThenApplyFlip() {
    final int imageWidth = 120;
    final int imageHeight = 250;
    FlutterImageDecoderImplHeifPre36 decoder = new FlutterImageDecoderImplHeifPre36(spiedUtils);

    byte[] imageBytes = createTestPng(imageWidth, imageHeight);
    ByteBuffer buffer = ByteBuffer.wrap(imageBytes);

    final Metadata testMetadata = new Metadata();
    testMetadata.orientation = ExifInterface.ORIENTATION_FLIP_HORIZONTAL;
    Bitmap decodedBitmap = decoder.decodeImage(buffer, testMetadata);

    assertEquals("Bitmap width is incorrect", imageWidth, decodedBitmap.getWidth());
    assertEquals("Bitmap height is incorrect", imageHeight, decodedBitmap.getHeight());

    ArgumentCaptor<Bitmap> flipBitmapCaptor = ArgumentCaptor.forClass(Bitmap.class);
    ArgumentCaptor<Integer> orientationCaptor = ArgumentCaptor.forClass(Integer.class);
    verify(spiedUtils).applyFlipIfNeeded(flipBitmapCaptor.capture(), orientationCaptor.capture());

    // Check that the orientation passed to the flip utility is correct.
    assertEquals((Integer) testMetadata.orientation, orientationCaptor.getValue());
  }
}
