// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.embedding.engine.image;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertNotNull;

import android.graphics.Bitmap;
import androidx.test.ext.junit.runners.AndroidJUnit4;
import io.flutter.Build;
import java.io.ByteArrayOutputStream;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.annotation.Config;

/** Unit tests for {@link BitmapMetadataReader}. */
@RunWith(AndroidJUnit4.class)
@Config(minSdk = Build.API_LEVELS.API_28)
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
    int width = 200;
    int height = 300;
    byte[] testImageBytes = createTestPng(width, height);
    Metadata metadata = new Metadata();

    BitmapMetadataReader.read(testImageBytes, metadata);

    assertNotNull(metadata);
    assertEquals(width, metadata.originalWidth);
    assertEquals(height, metadata.originalHeight);
  }
}
