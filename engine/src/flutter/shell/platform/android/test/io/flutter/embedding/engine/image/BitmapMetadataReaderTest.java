package io.flutter.embedding.engine.image;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertNotNull;
import static org.junit.Assert.assertNull;

import android.graphics.Bitmap;
import androidx.test.ext.junit.runners.AndroidJUnit4;
import java.io.ByteArrayOutputStream;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.annotation.Config;

/** Unit tests for {@link BitmapMetadataReader}. */
@RunWith(AndroidJUnit4.class)
@Config(manifest = Config.NONE, sdk = 28)
public class BitmapMetadataReaderTest {

  /**
   * Generates a simple PNG byte array with specified dimensions.
   *
   * @param width The width of the bitmap.
   * @param height The height of the bitmap.
   * @return A byte array representing a compressed PNG image.
   */
  private byte[] createTestPng(int width, int height) {
    Bitmap bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888);
    ByteArrayOutputStream stream = new ByteArrayOutputStream();
    bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream);
    bitmap.recycle();
    return stream.toByteArray();
  }

  @Test
  public void read_populatesMetadataCorrectly() {
    // 1. Arrange
    // Create a real PNG byte array to be parsed.
    // BitmapFactory needs valid image data to extract dimensions and mime type.
    byte[] testImageBytes = createTestPng(100, 200);
    Metadata metadata = new Metadata();

    // 2. Act
    BitmapMetadataReader.read(testImageBytes, metadata);

    // 3. Assert
    // Check that the metadata object was populated with the correct values.
    assertNotNull(metadata);
    assertEquals("image/png", metadata.mimeType);
    assertEquals(100, metadata.originalWidth);
    assertEquals(200, metadata.originalHeight);
  }

  @Test
  public void read_handlesInvalidDataGracefully() {
    // 1. Arrange
    // Create an invalid byte array that is not a real image.
    byte[] invalidImageBytes = new byte[] {1, 2, 3, 4};
    Metadata metadata = new Metadata();

    // 2. Act
    // This call should catch an exception internally and not crash.
    BitmapMetadataReader.read(invalidImageBytes, metadata);

    // 3. Assert
    // Check that the metadata fields were not populated, as decoding failed.
    assertNull(metadata.mimeType);
    assertEquals(0, metadata.originalWidth);
    assertEquals(0, metadata.originalHeight);
  }
}
