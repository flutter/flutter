// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.embedding.engine.image;

import static org.junit.Assert.assertEquals;

import android.graphics.Bitmap;
import android.graphics.Color;
import androidx.exifinterface.media.ExifInterface;
import androidx.test.ext.junit.runners.AndroidJUnit4;
import io.flutter.Build;
import java.nio.ByteBuffer;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.annotation.Config;
import org.robolectric.annotation.GraphicsMode;

/** Unit tests for {@link ImageDecoderHeifPre36Impl}. */
@RunWith(AndroidJUnit4.class)
@GraphicsMode(GraphicsMode.Mode.NATIVE)
@Config(minSdk = Build.API_LEVELS.API_28, maxSdk = Build.API_LEVELS.API_35)
public class ImageDecoderHeifPre36ImplTest {

  ImageDecoderHeifPre36Impl decoder = new ImageDecoderHeifPre36Impl();

  @Test
  public void decodeImage_withFlip() {
    final int imageWidth = 120;
    final int imageHeight = 250;

    byte[] imageBytes = ImageTestUtils.createTestImageBytes(imageWidth, imageHeight);
    ByteBuffer buffer = ByteBuffer.wrap(imageBytes);

    final Metadata testMetadata = new Metadata();
    testMetadata.orientation = ExifInterface.ORIENTATION_FLIP_HORIZONTAL;
    Bitmap decodedBitmap = decoder.decodeImage(buffer, testMetadata);

    assertEquals("Bitmap width is incorrect", imageWidth, decodedBitmap.getWidth());
    assertEquals("Bitmap height is incorrect", imageHeight, decodedBitmap.getHeight());
    assertEquals(
        "Blue pixel is wrong position", Color.BLUE, decodedBitmap.getPixel(imageWidth - 1, 0));
  }
}
