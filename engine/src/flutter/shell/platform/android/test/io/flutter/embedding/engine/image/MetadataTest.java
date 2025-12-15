// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.embedding.engine.image;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;

import io.flutter.Build;
import java.nio.ByteBuffer;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.mockito.ArgumentCaptor;
import org.mockito.MockedStatic;
import org.mockito.Mockito;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.annotation.Config;

/** Unit tests for {@link Metadata}. */
@RunWith(RobolectricTestRunner.class)
@Config(minSdk = Build.API_LEVELS.API_28)
public class MetadataTest {

  @Test
  public void create_usesOnlyBitmapReaderForNonHeif() {
    // 1. Arrange
    ByteBuffer fakeBuffer = ByteBuffer.allocate(1);
    FlutterImageDecoder.HeaderListener mockListener =
        mock(FlutterImageDecoder.HeaderListener.class);

    // Mock the static reader methods
    try (MockedStatic<BitmapMetadataReader> mockedBitmapReader =
            Mockito.mockStatic(BitmapMetadataReader.class);
        MockedStatic<MediaMetadataReader> mockedMediaReader =
            Mockito.mockStatic(MediaMetadataReader.class);
        MockedStatic<ExifMetadataReader> mockedExifReader =
            Mockito.mockStatic(ExifMetadataReader.class)) {

      // Simulate BitmapMetadataReader identifying the image as PNG
      mockedBitmapReader
          .when(() -> BitmapMetadataReader.read(any(byte[].class), any(Metadata.class)))
          .then(
              invocation -> {
                Metadata metadata = invocation.getArgument(1);
                metadata.mimeType = "image/png"; // Simulate finding a non-HEIF mime type
                return null;
              });

      // 2. Act
      Metadata.create(fakeBuffer, mockListener);

      // 3. Assert
      // Verify BitmapMetadataReader was called once.
      mockedBitmapReader.verify(
          () -> BitmapMetadataReader.read(any(byte[].class), any(Metadata.class)));

      // Verify the HEIF-specific readers were NEVER called.
      mockedMediaReader.verify(
          () -> MediaMetadataReader.read(any(byte[].class), any(Metadata.class)), never());
      mockedExifReader.verify(
          () -> ExifMetadataReader.read(any(byte[].class), any(Metadata.class)), never());

      // The listener should NOT be called for non-HEIF images.
      verify(mockListener, never()).onImageHeader(any(int.class), any(int.class));
    }
  }

  @Test
  public void create_usesAllReadersForHeif() {
    // 1. Arrange
    ByteBuffer fakeBuffer = ByteBuffer.allocate(1);
    FlutterImageDecoder.HeaderListener mockListener =
        mock(FlutterImageDecoder.HeaderListener.class);

    try (MockedStatic<BitmapMetadataReader> mockedBitmapReader =
            Mockito.mockStatic(BitmapMetadataReader.class);
        MockedStatic<MediaMetadataReader> mockedMediaReader =
            Mockito.mockStatic(MediaMetadataReader.class);
        MockedStatic<ExifMetadataReader> mockedExifReader =
            Mockito.mockStatic(ExifMetadataReader.class)) {

      // Simulate BitmapMetadataReader identifying the image as HEIF
      mockedBitmapReader
          .when(() -> BitmapMetadataReader.read(any(byte[].class), any(Metadata.class)))
          .then(
              invocation -> {
                Metadata metadata = invocation.getArgument(1);
                metadata.mimeType = "image/heif"; // Mark as HEIF
                return null;
              });

      // Simulate MediaMetadataReader providing final dimensions
      mockedMediaReader
          .when(() -> MediaMetadataReader.read(any(byte[].class), any(Metadata.class)))
          .then(
              invocation -> {
                Metadata metadata = invocation.getArgument(1);
                metadata.width = 100; // Provide final dimensions
                metadata.height = 200;
                return null;
              });

      // 2. Act
      Metadata.create(fakeBuffer, mockListener);

      // 3. Assert
      // Verify all three readers were called exactly once.
      mockedBitmapReader.verify(
          () -> BitmapMetadataReader.read(any(byte[].class), any(Metadata.class)), times(1));
      mockedMediaReader.verify(
          () -> MediaMetadataReader.read(any(byte[].class), any(Metadata.class)), times(1));
      mockedExifReader.verify(
          () -> ExifMetadataReader.read(any(byte[].class), any(Metadata.class)), times(1));

      // Verify the listener was called with the final dimensions from MediaMetadataReader.
      ArgumentCaptor<Integer> widthCaptor = ArgumentCaptor.forClass(Integer.class);
      ArgumentCaptor<Integer> heightCaptor = ArgumentCaptor.forClass(Integer.class);
      verify(mockListener).onImageHeader(widthCaptor.capture(), heightCaptor.capture());

      assertEquals(100, (int) widthCaptor.getValue());
      assertEquals(200, (int) heightCaptor.getValue());
    }
  }

  @Test
  public void isHeif_returnsCorrectValue() {
    // Arrange
    Metadata metadata = new Metadata();

    // Act & Assert for HEIF
    metadata.mimeType = "image/heif";
    assertTrue(metadata.isHeif());

    // Act & Assert for non-HEIF
    metadata.mimeType = "image/png";
    assertFalse(metadata.isHeif());

    // Act & Assert for null mimetype
    metadata.mimeType = null;
    // Should throw NullPointerException
    try {
      metadata.isHeif();
    } catch (NullPointerException e) {
      // Expected
    }
  }

  @Test
  public void isHeif_doesNotCrashWithNullMetatdata() {
    Metadata metadata = new Metadata();
    metadata.mimeType = null;
    assertFalse(metadata.isHeif());
  }
}
