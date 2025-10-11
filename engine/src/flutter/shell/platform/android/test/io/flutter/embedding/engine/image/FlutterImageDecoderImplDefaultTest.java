package io.flutter.embedding.engine.image;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertNotNull;
import static org.junit.Assert.assertNull;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;

import android.graphics.Bitmap;
import android.os.Build;
import androidx.test.ext.junit.runners.AndroidJUnit4;
import java.io.ByteArrayOutputStream;
import java.nio.ByteBuffer;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.mockito.ArgumentCaptor;
import org.robolectric.annotation.Config;

/** Unit tests for {@link FlutterImageDecoderImplDefault}. */
@RunWith(AndroidJUnit4.class)
@Config(manifest = Config.NONE, sdk = Build.VERSION_CODES.P)
public class FlutterImageDecoderImplDefaultTest {

  /**
   * Generates a simple PNG byte array with specified dimensions. This provides valid image data for
   * ImageDecoder to parse.
   */
  private byte[] createTestPng(int width, int height) {
    Bitmap bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888);
    ByteArrayOutputStream stream = new ByteArrayOutputStream();
    bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream);
    bitmap.recycle();
    return stream.toByteArray();
  }

  @Test
  public void decodeImage_succeedsAndNotifiesListener() {
    // 1. Arrange
    final int imageWidth = 120;
    final int imageHeight = 250;
    FlutterImageDecoder.HeaderListener mockListener =
        mock(FlutterImageDecoder.HeaderListener.class);
    FlutterImageDecoderImplDefault decoder = new FlutterImageDecoderImplDefault(mockListener);

    byte[] imageBytes = createTestPng(imageWidth, imageHeight);
    ByteBuffer buffer = ByteBuffer.allocateDirect(imageBytes.length);
    buffer.put(imageBytes);
    buffer.rewind();

    // 2. Act
    Bitmap decodedBitmap = decoder.decodeImage(buffer, new Metadata());

    // 3. Assert
    // Verify the decoded bitmap is valid.
    assertNotNull("Decoded bitmap should not be null", decodedBitmap);
    assertEquals("Bitmap width is incorrect", imageWidth, decodedBitmap.getWidth());
    assertEquals("Bitmap height is incorrect", imageHeight, decodedBitmap.getHeight());

    // Verify the listener was called with the correct dimensions.
    ArgumentCaptor<Integer> widthCaptor = ArgumentCaptor.forClass(Integer.class);
    ArgumentCaptor<Integer> heightCaptor = ArgumentCaptor.forClass(Integer.class);
    verify(mockListener).onImageHeader(widthCaptor.capture(), heightCaptor.capture());

    assertEquals("Listener was called with wrong width", imageWidth, (int) widthCaptor.getValue());
    assertEquals(
        "Listener was called with wrong height", imageHeight, (int) heightCaptor.getValue());
  }

  @Test
  public void decodeImage_failsGracefullyWithInvalidData() {
    // 1. Arrange
    FlutterImageDecoder.HeaderListener mockListener =
        mock(FlutterImageDecoder.HeaderListener.class);
    FlutterImageDecoderImplDefault decoder = new FlutterImageDecoderImplDefault(mockListener);

    byte[] invalidBytes = new byte[] {1, 2, 3, 4, 5}; // Not a valid image
    ByteBuffer buffer = ByteBuffer.allocateDirect(invalidBytes.length);
    buffer.put(invalidBytes);
    buffer.rewind();

    // 2. Act
    // ImageDecoder will throw an IOException internally, which should be caught.
    Bitmap decodedBitmap = decoder.decodeImage(buffer, new Metadata());

    // 3. Assert
    // The method should return null and not crash.
    assertNull("Bitmap should be null for invalid data", decodedBitmap);
  }
}
