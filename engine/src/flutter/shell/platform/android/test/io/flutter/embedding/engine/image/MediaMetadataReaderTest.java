// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.embedding.engine.image;

import static org.junit.Assert.assertEquals;
import static org.mockito.Mockito.*;

import android.media.MediaExtractor;
import android.media.MediaFormat;
import androidx.test.ext.junit.runners.AndroidJUnit4;
import io.flutter.Build;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.annotation.Config;

/** Unit tests for {@link MediaMetadataReader}. */
@RunWith(AndroidJUnit4.class)
@Config(minSdk = Build.API_LEVELS.API_28)
public class MediaMetadataReaderTest {

  @Test
  public void read_handlesRotationAndPopulatesMetadata() {
    byte[] fakeImageBytes = new byte[] {1, 2, 3}; // The content doesn't matter.
    Metadata metadata = new Metadata();
    metadata.originalWidth = 1000;
    metadata.originalHeight = 800;

    MediaExtractor mockExtractor = mock(MediaExtractor.class);
    MediaFormat mockFormat = mock(MediaFormat.class);

    when(mockExtractor.getTrackCount()).thenReturn(1);
    when(mockExtractor.getTrackFormat(0)).thenReturn(mockFormat);
    when(mockFormat.getString(MediaFormat.KEY_MIME)).thenReturn("image/heif");
    when(mockFormat.containsKey(MediaFormat.KEY_ROTATION)).thenReturn(true);
    when(mockFormat.getInteger(MediaFormat.KEY_ROTATION)).thenReturn(90);

    MediaMetadataReader.read(fakeImageBytes, metadata, mockExtractor);

    assertEquals("Rotation was not set correctly", 90, metadata.rotation);
    // For a 90-degree rotation, the width and height should be swapped.
    assertEquals("Width was not updated correctly after rotation", 800, metadata.width);
    assertEquals("Height was not updated correctly after rotation", 1000, metadata.height);
  }

  @Test
  public void read_handlesNoRotation() {
    byte[] fakeImageBytes = new byte[] {1, 2, 3};
    Metadata metadata = new Metadata();
    metadata.originalWidth = 500;
    metadata.originalHeight = 400;

    MediaExtractor mockExtractor = mock(MediaExtractor.class);
    MediaFormat mockFormat = mock(MediaFormat.class);

    when(mockExtractor.getTrackCount()).thenReturn(1);
    when(mockExtractor.getTrackFormat(0)).thenReturn(mockFormat);
    when(mockFormat.getString(MediaFormat.KEY_MIME)).thenReturn("image/heif");
    when(mockFormat.containsKey(MediaFormat.KEY_ROTATION)).thenReturn(false); // No rotation key

    MediaMetadataReader.read(fakeImageBytes, metadata, mockExtractor);

    assertEquals("Rotation should be 0", 0, metadata.rotation);
    // Dimensions should remain unchanged.
    assertEquals("Width should not have changed", 500, metadata.width);
    assertEquals("Height should not have changed", 400, metadata.height);
  }
}
