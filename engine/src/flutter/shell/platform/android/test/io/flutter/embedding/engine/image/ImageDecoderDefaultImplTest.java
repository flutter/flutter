// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.embedding.engine.image;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertNotNull;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;

import android.graphics.Bitmap;
import androidx.test.ext.junit.runners.AndroidJUnit4;
import io.flutter.Build;
import java.io.ByteArrayOutputStream;
import java.nio.ByteBuffer;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.mockito.ArgumentCaptor;
import org.robolectric.annotation.Config;

/** Unit tests for {@link ImageDecoderDefaultImpl}. */
@RunWith(AndroidJUnit4.class)
@Config(minSdk = Build.API_LEVELS.API_28)
public class ImageDecoderDefaultImplTest {

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
    final int imageWidth = 120;
    final int imageHeight = 250;
    FlutterImageDecoder.HeaderListener mockListener =
        mock(FlutterImageDecoder.HeaderListener.class);
    ImageDecoderDefaultImpl decoder = new ImageDecoderDefaultImpl(mockListener);

    byte[] imageBytes = createTestPng(imageWidth, imageHeight);
    ByteBuffer buffer = ByteBuffer.wrap(imageBytes);

    Bitmap decodedBitmap = decoder.decodeImage(buffer, new Metadata());

    assertNotNull("Decoded bitmap should not be null", decodedBitmap);
    assertEquals("Bitmap width is incorrect", imageWidth, decodedBitmap.getWidth());
    assertEquals("Bitmap height is incorrect", imageHeight, decodedBitmap.getHeight());

    ArgumentCaptor<Integer> widthCaptor = ArgumentCaptor.forClass(Integer.class);
    ArgumentCaptor<Integer> heightCaptor = ArgumentCaptor.forClass(Integer.class);
    verify(mockListener).onImageHeader(widthCaptor.capture(), heightCaptor.capture());

    assertEquals("Listener was called with wrong width", imageWidth, (int) widthCaptor.getValue());
    assertEquals(
        "Listener was called with wrong height", imageHeight, (int) heightCaptor.getValue());
  }
}
