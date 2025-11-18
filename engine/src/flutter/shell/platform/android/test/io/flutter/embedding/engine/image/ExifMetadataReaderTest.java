// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.embedding.engine.image;

import static org.junit.Assert.assertEquals;

import android.graphics.Bitmap;
import androidx.exifinterface.media.ExifInterface;
import androidx.test.ext.junit.runners.AndroidJUnit4;
import io.flutter.Build;
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
@Config(minSdk = Build.API_LEVELS.API_28)
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
    File tempFile = temporaryFolder.newFile();
    Bitmap bitmap = Bitmap.createBitmap(10, 20, Bitmap.Config.ARGB_8888);

    try (FileOutputStream fos = new FileOutputStream(tempFile)) {
      bitmap.compress(Bitmap.CompressFormat.JPEG, 90, fos);
    }
    bitmap.recycle();

    ExifInterface exifInterface = new ExifInterface(tempFile.getAbsolutePath());
    exifInterface.setAttribute(ExifInterface.TAG_ORIENTATION, String.valueOf(orientation));
    exifInterface.saveAttributes();

    return java.nio.file.Files.readAllBytes(tempFile.toPath());
  }

  @Test
  public void read_populatesOrientationCorrectly() throws IOException {
    byte[] testImageBytes = createTestJpegWithOrientation(ExifInterface.ORIENTATION_ROTATE_90);
    Metadata metadata = new Metadata();
    ExifMetadataReader.read(testImageBytes, metadata);
    assertEquals(ExifInterface.ORIENTATION_ROTATE_90, metadata.orientation);
  }

  @Test
  public void read_defaultsToUndefinedOrientationForInvalidData() {
    byte[] invalidImageBytes = new byte[] {1, 2, 3, 4};
    Metadata metadata = new Metadata();
    ExifMetadataReader.read(invalidImageBytes, metadata);
    assertEquals(ExifInterface.ORIENTATION_UNDEFINED, metadata.orientation);
  }
}
