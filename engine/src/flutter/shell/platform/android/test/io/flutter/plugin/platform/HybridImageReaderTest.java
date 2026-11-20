// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugin.platform;

import static io.flutter.Build.API_LEVELS;
import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertNotNull;
import static org.junit.Assert.assertNull;
import static org.junit.Assert.assertSame;
import static org.junit.Assert.assertTrue;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import android.hardware.SyncFence;
import android.media.Image;
import android.media.ImageReader;
import android.view.Surface;
import androidx.test.ext.junit.runners.AndroidJUnit4;
import java.io.IOException;
import java.time.Duration;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.annotation.Config;

@RunWith(AndroidJUnit4.class)
public class HybridImageReaderTest {
  // Standard test buffer dimensions in physical pixels.
  private static final int TEST_WIDTH_PX = 64;
  private static final int TEST_HEIGHT_PX = 48;
  private static final int INVALID_ZERO_PX = 0;
  private static final int INVALID_NEGATIVE_PX = -12;
  private static final int CLAMPED_MIN_PX = 1;

  @Test
  public void allocatesSixSlotImageReaderAndClampsNonPositiveDimensions() {
    final HybridImageReader validReader = new HybridImageReader(TEST_WIDTH_PX, TEST_HEIGHT_PX);
    assertEquals(
        HybridImageReader.MAX_ACQUIRED_IMAGES, validReader.getImageReaderForTest().getMaxImages());
    assertEquals(TEST_WIDTH_PX, validReader.getImageReaderForTest().getWidth());
    assertEquals(TEST_HEIGHT_PX, validReader.getImageReaderForTest().getHeight());
    validReader.retire();
    assertTrue(validReader.isClosed());

    final HybridImageReader clampedReader =
        new HybridImageReader(INVALID_ZERO_PX, INVALID_NEGATIVE_PX);
    assertEquals(CLAMPED_MIN_PX, clampedReader.getImageReaderForTest().getWidth());
    assertEquals(CLAMPED_MIN_PX, clampedReader.getImageReaderForTest().getHeight());
    clampedReader.retire();
    assertTrue(clampedReader.isClosed());
  }

  @Test
  public void retireWithNoOpenImagesClosesReaderImmediatelyAndIsIdempotent() {
    final ImageReader mockImageReader = mock(ImageReader.class);
    final Surface mockSurface = mock(Surface.class);
    when(mockImageReader.getSurface()).thenReturn(mockSurface);

    final HybridImageReader hybridReader = new HybridImageReader(mockImageReader);
    assertSame(mockSurface, hybridReader.getSurface());
    assertFalse(hybridReader.isRetired());
    assertFalse(hybridReader.isClosed());

    hybridReader.retire();
    assertTrue(hybridReader.isRetired());
    assertTrue(hybridReader.isClosed());
    assertNull(hybridReader.getSurface());
    assertNull(hybridReader.acquireLatestImage());
    verify(mockImageReader, times(1)).close();

    // Second retire() is a strict no-op.
    hybridReader.retire();
    verify(mockImageReader, times(1)).close();
  }

  @Test
  public void retireWaitsUntilAllOpenImagesReleaseAndIgnoresDuplicateReleases() {
    final ImageReader mockImageReader = mock(ImageReader.class);
    final Image image1 = mock(Image.class);
    final Image image2 = mock(Image.class);
    final Image untrackedImage = mock(Image.class);
    when(mockImageReader.acquireLatestImage()).thenReturn(image1, image2);

    final HybridImageReader hybridReader = new HybridImageReader(mockImageReader);
    hybridReader.disableFenceForTest();

    assertSame(image1, hybridReader.acquireLatestImage());
    assertSame(image2, hybridReader.acquireLatestImage());
    assertEquals(2, hybridReader.getOpenImageCount());

    // Retiring while two images are still held by UI/Mailbox must NOT close the ImageReader yet.
    hybridReader.retire();
    assertTrue(hybridReader.isRetired());
    assertFalse(hybridReader.isClosed());
    verify(mockImageReader, never()).close();

    // Null and untracked images are ignored without affecting refcount.
    hybridReader.releaseImage(null);
    hybridReader.releaseImage(untrackedImage);
    verify(untrackedImage, never()).close();
    assertEquals(2, hybridReader.getOpenImageCount());

    // Releasing image1 twice closes image1 once and keeps the reader open until image2 releases.
    hybridReader.releaseImage(image1);
    hybridReader.releaseImage(image1);
    verify(image1, times(1)).close();
    assertEquals(1, hybridReader.getOpenImageCount());
    assertFalse(hybridReader.isClosed());
    verify(mockImageReader, never()).close();

    // Releasing the final open image closes image2 and then closes the retired ImageReader.
    hybridReader.releaseImage(image2);
    verify(image2, times(1)).close();
    assertEquals(0, hybridReader.getOpenImageCount());
    assertTrue(hybridReader.isClosed());
    verify(mockImageReader, times(1)).close();
  }

  @Test
  @Config(sdk = API_LEVELS.API_33)
  public void acquireLatestImageAwaitsValidSyncFenceAndClosesFenceOnApi33Plus() throws IOException {
    final ImageReader mockImageReader = mock(ImageReader.class);
    final Image validFenceImage = mock(Image.class);
    final Image timedOutFenceImage = mock(Image.class);
    final Image invalidFenceImage = mock(Image.class);
    final SyncFence validFence = mock(SyncFence.class);
    final SyncFence timedOutFence = mock(SyncFence.class);
    final SyncFence invalidFence = mock(SyncFence.class);
    final Duration expectedTimeout = Duration.ofMillis(HybridImageReader.SYNC_FENCE_TIMEOUT_MS);
    when(validFence.isValid()).thenReturn(true);
    when(validFence.await(expectedTimeout)).thenReturn(true);
    when(timedOutFence.isValid()).thenReturn(true);
    when(timedOutFence.await(expectedTimeout)).thenReturn(false);
    when(invalidFence.isValid()).thenReturn(false);
    when(validFenceImage.getFence()).thenReturn(validFence);
    when(timedOutFenceImage.getFence()).thenReturn(timedOutFence);
    when(invalidFenceImage.getFence()).thenReturn(invalidFence);
    when(mockImageReader.acquireLatestImage())
        .thenReturn(validFenceImage, timedOutFenceImage, invalidFenceImage);

    final HybridImageReader hybridReader = new HybridImageReader(mockImageReader);

    assertSame(validFenceImage, hybridReader.acquireLatestImage());
    verify(validFence, times(1)).await(expectedTimeout);
    verify(validFence, never()).awaitForever();
    verify(validFence, times(1)).close();

    // A timed-out SyncFence logs a warning, closes the fence, and returns without hanging.
    assertSame(timedOutFenceImage, hybridReader.acquireLatestImage());
    verify(timedOutFence, times(1)).await(expectedTimeout);
    verify(timedOutFence, never()).awaitForever();
    verify(timedOutFence, times(1)).close();

    assertSame(invalidFenceImage, hybridReader.acquireLatestImage());
    verify(invalidFence, never()).await(expectedTimeout);
    verify(invalidFence, never()).awaitForever();
    verify(invalidFence, times(1)).close();

    hybridReader.releaseImage(validFenceImage);
    hybridReader.releaseImage(timedOutFenceImage);
    hybridReader.releaseImage(invalidFenceImage);
    hybridReader.retire();
    assertTrue(hybridReader.isClosed());
  }

  @Test
  public void acquireLatestImageHandlesIllegalStateExceptionGracefully() {
    final ImageReader mockImageReader = mock(ImageReader.class);
    when(mockImageReader.acquireLatestImage())
        .thenThrow(new IllegalStateException("No buffer available"));

    final HybridImageReader hybridReader = new HybridImageReader(mockImageReader);
    hybridReader.disableFenceForTest();

    assertNull(hybridReader.acquireLatestImage());
    assertEquals(0, hybridReader.getOpenImageCount());
    hybridReader.retire();
    assertNotNull(hybridReader);
    assertTrue(hybridReader.isClosed());
  }
}
