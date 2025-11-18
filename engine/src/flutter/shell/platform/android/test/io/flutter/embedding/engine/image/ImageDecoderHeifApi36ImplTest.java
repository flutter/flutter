// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.embedding.engine.image;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertNotNull;

import android.graphics.Bitmap;
import android.graphics.Color;
import androidx.exifinterface.media.ExifInterface;
import androidx.test.ext.junit.runners.AndroidJUnit4;
import io.flutter.Build;
import java.nio.ByteBuffer;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.annotation.Config;
import org.robolectric.annotation.GraphicsMode;

/** Unit tests for {@link ImageDecoderHeifApi36Impl}. */
@RunWith(AndroidJUnit4.class)
@GraphicsMode(GraphicsMode.Mode.NATIVE)
@Config(minSdk = Build.API_LEVELS.API_36)
public class ImageDecoderHeifApi36ImplTest {

  private ImageDecoderHeifApi36Impl decoder;

  @Before
  public void setUp() {
    decoder = new ImageDecoderHeifApi36Impl();
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
