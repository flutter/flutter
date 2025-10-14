package io.flutter.embedding.engine.image;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertNotNull;

import android.graphics.Bitmap;
import android.graphics.Color;
import android.media.ExifInterface;
import androidx.test.ext.junit.runners.AndroidJUnit4;
import io.flutter.Build;
import java.nio.ByteBuffer;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.annotation.Config;
import org.robolectric.annotation.GraphicsMode;

/** Unit tests for {@link FlutterImageDecoderImplHeifApi36}. */
@RunWith(AndroidJUnit4.class)
@GraphicsMode(GraphicsMode.Mode.NATIVE)
@Config(minSdk = Build.API_LEVELS.API_36)
public class FlutterImageDecoderImplHeifApi36Test {

  private FlutterImageDecoderImplHeifApi36 decoder;

  @Before
  public void setUp() {
    decoder = new FlutterImageDecoderImplHeifApi36();
  }

  @Test
  public void decodeImage_noRotationOrFlip() {
    byte[] imageBytes = ImageTestUtils.createTestImageBytes(100, 200);
    ByteBuffer buffer = ByteBuffer.wrap(imageBytes);
    Metadata metadata = new Metadata();
    metadata.rotation = 0;
    metadata.orientation = ExifInterface.ORIENTATION_NORMAL;

    Bitmap result = decoder.decodeImageFallback(buffer, metadata);

    assertNotNull(result);
    assertEquals(100, result.getWidth());
    assertEquals(200, result.getHeight());
    assertEquals(Color.BLUE, result.getPixel(0, 0));
  }

  @Test
  public void decodeImage_withRotation() {
    byte[] imageBytes = ImageTestUtils.createTestImageBytes(100, 200);
    ByteBuffer buffer = ByteBuffer.wrap(imageBytes);
    Metadata metadata = new Metadata();
    metadata.rotation = 90;
    metadata.orientation = ExifInterface.ORIENTATION_NORMAL; // No flip

    Bitmap result = decoder.decodeImageFallback(buffer, metadata);

    assertNotNull(result);
    // After a 90-degree rotation, width and height are swapped.
    assertEquals(200, result.getWidth());
    assertEquals(100, result.getHeight());
    assertEquals(Color.BLUE, result.getPixel(200 - 1, 0));
  }

  @Test
  public void decodeImage_withFlip() {
    byte[] imageBytes = ImageTestUtils.createTestImageBytes(100, 200);
    ByteBuffer buffer = ByteBuffer.wrap(imageBytes);
    Metadata metadata = new Metadata();
    metadata.rotation = 0; // No rotation
    metadata.orientation = ExifInterface.ORIENTATION_FLIP_HORIZONTAL;

    Bitmap result = decoder.decodeImageFallback(buffer, metadata);

    assertNotNull(result);
    assertEquals(100, result.getWidth());
    assertEquals(200, result.getHeight());
    assertEquals(Color.BLUE, result.getPixel(100 - 1, 0));
  }
}
