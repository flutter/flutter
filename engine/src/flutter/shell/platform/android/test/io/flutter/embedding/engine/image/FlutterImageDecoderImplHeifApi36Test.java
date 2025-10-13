package io.flutter.embedding.engine.image;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertNotNull;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.Mockito.spy;
import static org.mockito.Mockito.verify;

import android.graphics.Bitmap;
import android.graphics.Color;
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

/** Unit tests for {@link FlutterImageDecoderImplHeifApi36}. */
@RunWith(AndroidJUnit4.class)
@Config(minSdk = Build.API_LEVELS.API_36)
public class FlutterImageDecoderImplHeifApi36Test {

  private FlutterImageDecoderImplHeifApi36 decoder;
  private Utils spiedUtils;

  // This helper generates a valid PNG byte array. For this test, the actual image format
  // doesn't matter, only that BitmapFactory can decode it into a Bitmap object.
  private byte[] createTestImageBytes(int width, int height) {
    Bitmap bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888);
    ByteArrayOutputStream stream = new ByteArrayOutputStream();
    bitmap.setPixel(0, 0, Color.BLUE);
    bitmap.setPixel(0, height - 1, Color.WHITE);
    bitmap.setPixel(width - 1, 0, Color.BLACK);
    bitmap.setPixel(width - 1, height - 1, Color.RED);
    bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream);
    bitmap.recycle();
    return stream.toByteArray();
  }

  @Before
  public void setUp() {
    spiedUtils = spy(new Utils());
    decoder = new FlutterImageDecoderImplHeifApi36(spiedUtils);
  }

  @Test
  public void decodeImage_noRotationOrFlip() {
    // 1. Arrange
    byte[] imageBytes = createTestImageBytes(100, 200);
    ByteBuffer buffer = ByteBuffer.wrap(imageBytes);
    Metadata metadata = new Metadata();
    metadata.rotation = 0;
    metadata.orientation = ExifInterface.ORIENTATION_NORMAL;

    // 2. Act
    Bitmap result = decoder.decodeImage(buffer, metadata);

    // 3. Assert
    assertNotNull(result);
    assertEquals(100, result.getWidth());
    assertEquals(200, result.getHeight());
    assertEquals(Color.BLUE, result.getPixel(0, 0));

    // Verify applyFlipIfNeeded was called with the original bitmap.
    ArgumentCaptor<Bitmap> bitmapCaptor = ArgumentCaptor.forClass(Bitmap.class);
    verify(spiedUtils).applyFlipIfNeeded(bitmapCaptor.capture(), anyInt());
    assertEquals(100, bitmapCaptor.getValue().getWidth()); // Check it's the original bitmap
  }

  @Test
  public void decodeImage_withRotation() {
    // 1. Arrange
    byte[] imageBytes = createTestImageBytes(100, 200);
    ByteBuffer buffer = ByteBuffer.wrap(imageBytes);
    Metadata metadata = new Metadata();
    metadata.rotation = 90;
    metadata.orientation = ExifInterface.ORIENTATION_NORMAL; // No flip

    // 2. Act
    Bitmap result = decoder.decodeImage(buffer, metadata);

    // 3. Assert
    assertNotNull(result);
    // Would expect blue to be at top right now
    assertEquals(Color.BLUE, result.getPixel(200 - 1, 0));
    // After a 90-degree rotation, width and height are swapped.
    assertEquals(200, result.getWidth());
    assertEquals(100, result.getHeight());

    // Verify that applyFlipIfNeeded was called with the *rotated* bitmap.
    ArgumentCaptor<Bitmap> bitmapCaptor = ArgumentCaptor.forClass(Bitmap.class);
    verify(spiedUtils).applyFlipIfNeeded(bitmapCaptor.capture(), anyInt());
    assertEquals(200, bitmapCaptor.getValue().getWidth()); // Check it's the rotated bitmap
  }

  @Test
  public void decodeImage_withFlip() {
    // 1. Arrange
    byte[] imageBytes = createTestImageBytes(100, 200);
    ByteBuffer buffer = ByteBuffer.wrap(imageBytes);
    Metadata metadata = new Metadata();
    metadata.rotation = 0; // No rotation
    metadata.orientation = ExifInterface.ORIENTATION_FLIP_HORIZONTAL;

    // 2. Act
    Bitmap result = decoder.decodeImage(buffer, metadata);

    // 3. Assert
    assertNotNull(result);
    assertEquals(100, result.getWidth());
    assertEquals(200, result.getHeight());

    // Verify applyFlipIfNeeded was called with the correct orientation.
    ArgumentCaptor<Integer> orientationCaptor = ArgumentCaptor.forClass(Integer.class);
    verify(spiedUtils).applyFlipIfNeeded(any(Bitmap.class), orientationCaptor.capture());
    assertEquals((Integer) ExifInterface.ORIENTATION_FLIP_HORIZONTAL, orientationCaptor.getValue());
  }
}
