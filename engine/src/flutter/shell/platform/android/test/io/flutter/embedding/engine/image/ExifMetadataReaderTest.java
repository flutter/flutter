package io.flutter.embedding.engine.image;

import static org.junit.Assert.assertEquals;

import android.graphics.Bitmap;
import android.media.ExifInterface;
import androidx.test.ext.junit.runners.AndroidJUnit4;
import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import org.junit.Rule;
import org.junit.Test;
import org.junit.rules.TemporaryFolder;
import org.junit.runner.RunWith;
import org.robolectric.annotation.Config;

/** Unit tests for {@link ExifMetadataReader}. */
@RunWith(AndroidJUnit4.class)
@Config(manifest = Config.NONE, sdk = 28)
public class ExifMetadataReaderTest {

  @Rule public TemporaryFolder temporaryFolder = new TemporaryFolder();

  /**
   * Helper to create a JPEG image file and then read its bytes. It first saves a bitmap, then loads
   * it into an {@link ExifInterface} to set the orientation tag, and saves it again.
   *
   * @param orientation The EXIF orientation to bake into the image file.
   * @return A byte array of the JPEG image with the specified EXIF orientation.
   */
  private byte[] createTestJpegWithOrientation(int orientation) throws IOException {
    // Step 1: Create a temporary file to work with.
    File tempFile = temporaryFolder.newFile();
    Bitmap bitmap = Bitmap.createBitmap(10, 20, Bitmap.Config.ARGB_8888);

    // Step 2: Save the initial bitmap to the file.
    try (FileOutputStream fos = new FileOutputStream(tempFile)) {
      bitmap.compress(Bitmap.CompressFormat.JPEG, 90, fos);
    }
    bitmap.recycle();

    // Step 3: Load the file into ExifInterface, set the orientation, and save.
    ExifInterface exifInterface = new ExifInterface(tempFile.getAbsolutePath());
    exifInterface.setAttribute(ExifInterface.TAG_ORIENTATION, String.valueOf(orientation));
    exifInterface.saveAttributes();

    // Step 4: Read the final bytes of the modified file.
    return java.nio.file.Files.readAllBytes(tempFile.toPath());
  }

  @Test
  public void read_populatesOrientationCorrectly() throws IOException {
    // 1. Arrange
    // Create a JPEG byte array with a specific EXIF orientation (e.g., rotated 90 degrees).
    byte[] testImageBytes = createTestJpegWithOrientation(ExifInterface.ORIENTATION_ROTATE_90);
    Metadata metadata = new Metadata();

    // 2. Act
    ExifMetadataReader.read(testImageBytes, metadata);

    // 3. Assert
    // Verify that the metadata object's orientation field is correctly populated.
    assertEquals(ExifInterface.ORIENTATION_ROTATE_90, metadata.orientation);
  }

  @Test
  public void read_defaultsToNormalOrientationForInvalidData() {
    // 1. Arrange
    // Create an invalid byte array that doesn't represent an image.
    byte[] invalidImageBytes = new byte[] {1, 2, 3, 4};
    Metadata metadata = new Metadata();

    // 2. Act
    // This call should log an error internally but not crash.
    ExifMetadataReader.read(invalidImageBytes, metadata);

    // 3. Assert
    // Check that the orientation defaults to ORIENTATION_NORMAL as per the implementation.
    // The getAttributeInt method in ExifInterface defaults to the provided default value.
    assertEquals(ExifInterface.ORIENTATION_NORMAL, metadata.orientation);
  }

  @Test
  public void read_defaultsToNormalOrientationForImageWithoutExif() throws IOException {
    // 1. Arrange
    // Create a simple bitmap and compress it to a byte stream without setting any EXIF data.
    Bitmap bitmap = Bitmap.createBitmap(10, 20, Bitmap.Config.ARGB_8888);
    ByteArrayOutputStream stream = new ByteArrayOutputStream();
    bitmap.compress(Bitmap.CompressFormat.JPEG, 90, stream);
    byte[] imageBytesWithoutExif = stream.toByteArray();
    Metadata metadata = new Metadata();

    // 2. Act
    ExifMetadataReader.read(imageBytesWithoutExif, metadata);

    // 3. Assert
    assertEquals(ExifInterface.ORIENTATION_NORMAL, metadata.orientation);
  }
}
