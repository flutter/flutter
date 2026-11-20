// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugin.platform;

import static io.flutter.Build.API_LEVELS;

import android.annotation.SuppressLint;
import android.graphics.PixelFormat;
import android.hardware.HardwareBuffer;
import android.hardware.SyncFence;
import android.media.Image;
import android.media.ImageReader;
import android.os.Build;
import android.view.Surface;
import androidx.annotation.Keep;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.annotation.RequiresApi;
import androidx.annotation.VisibleForTesting;
import io.flutter.Log;
import io.flutter.util.TraceSection;
import java.io.IOException;
import java.util.Collections;
import java.util.IdentityHashMap;
import java.util.Locale;
import java.util.Set;

/**
 * Thread-safe, reference-counted {@link ImageReader} wrapper for unmerged Hybrid Composition Frame
 * Packets.
 *
 * <p>Allocated, rendered into, acquired, and retired from the engine's raster thread while acquired
 * {@link Image} instances are handed off to the Android UI thread and released once no longer
 * displayed by {@link io.flutter.embedding.android.FlutterImageView}.
 *
 * <p>The underlying {@link ImageReader} is closed only after {@link #retire()} has been invoked and
 * every uniquely acquired {@link Image} has been returned via {@link #releaseImage(Image)}.
 */
@Keep
public class HybridImageReader {
  private static final String TAG = "HybridImageReader";

  // 4 maximum concurrent consumer-held slots (1 displayed in FlutterImageView + 1 retiring awaiting
  // FrameCommitCallback + 1 pending CommitCallback slot + 1 queued in FramePacketMailbox) plus 2
  // free slots so AOSP ImageReader.acquireLatestImage() probe/drain and GPU producer dequeue never
  // starve.
  @VisibleForTesting static final int MAX_ACQUIRED_IMAGES = 6;

  // Minimum valid pixel dimension accepted by Android ImageReader.newInstance.
  private static final int MIN_IMAGE_DIMENSION_PX = 1;

  // Initial reference count representing ownership by the native ImageLayerPool until retire().
  private static final int INITIAL_OWNER_REF_COUNT = 1;

  @NonNull private final Object lock = new Object();
  @NonNull private final ImageReader imageReader;

  @NonNull private final Set<Image> openImages = Collections.newSetFromMap(new IdentityHashMap<>());

  private int refCount = INITIAL_OWNER_REF_COUNT;
  private boolean retired = false;
  private boolean closed = false;
  private volatile boolean ignoringFence = false;

  public HybridImageReader(int width, int height) {
    this(createImageReader(width, height));
  }

  @VisibleForTesting
  HybridImageReader(@NonNull ImageReader imageReader) {
    this.imageReader = imageReader;
  }

  @SuppressLint("WrongConstant")
  @NonNull
  private static ImageReader createImageReader(int width, int height) {
    if (width < MIN_IMAGE_DIMENSION_PX) {
      Log.w(
          TAG,
          String.format(
              Locale.US,
              "HybridImageReader width must be >= %d, given width=%d; clamping to %d",
              MIN_IMAGE_DIMENSION_PX,
              width,
              MIN_IMAGE_DIMENSION_PX));
      width = MIN_IMAGE_DIMENSION_PX;
    }
    if (height < MIN_IMAGE_DIMENSION_PX) {
      Log.w(
          TAG,
          String.format(
              Locale.US,
              "HybridImageReader height must be >= %d, given height=%d; clamping to %d",
              MIN_IMAGE_DIMENSION_PX,
              height,
              MIN_IMAGE_DIMENSION_PX));
      height = MIN_IMAGE_DIMENSION_PX;
    }
    if (Build.VERSION.SDK_INT >= API_LEVELS.API_29) {
      return ImageReader.newInstance(
          width,
          height,
          PixelFormat.RGBA_8888,
          MAX_ACQUIRED_IMAGES,
          HardwareBuffer.USAGE_GPU_SAMPLED_IMAGE | HardwareBuffer.USAGE_GPU_COLOR_OUTPUT);
    }
    return ImageReader.newInstance(width, height, PixelFormat.RGBA_8888, MAX_ACQUIRED_IMAGES);
  }

  /** Returns the producer {@link Surface}, or {@code null} if this reader has been retired. */
  @Nullable
  public Surface getSurface() {
    synchronized (lock) {
      if (retired || closed) {
        return null;
      }
      return imageReader.getSurface();
    }
  }

  /**
   * Acquires the most recent {@link Image} from the underlying {@link ImageReader}, awaits its GPU
   * {@link SyncFence} on API 33+ when valid, and retains one reference until {@link
   * #releaseImage(Image)} is called.
   */
  @Nullable
  public Image acquireLatestImage() {
    final Image image;
    synchronized (lock) {
      if (retired || closed) {
        return null;
      }
      try {
        image = imageReader.acquireLatestImage();
      } catch (RuntimeException ex) {
        Log.w(TAG, "Failed to acquire latest image from HybridImageReader", ex);
        return null;
      }
      if (image == null) {
        return null;
      }
      if (openImages.add(image)) {
        refCount++;
      }
    }
    maybeWaitOnFence(image);
    return image;
  }

  @RequiresApi(API_LEVELS.API_33)
  private void waitOnFence(@NonNull Image image) {
    try (TraceSection trace = TraceSection.scoped("HybridImageReader.waitOnFence");
        SyncFence fence = image.getFence()) {
      if (fence != null && fence.isValid()) {
        fence.awaitForever();
      }
    } catch (IOException | RuntimeException ex) {
      Log.w(TAG, "Failed waiting on HybridImageReader SyncFence", ex);
    }
  }

  private void maybeWaitOnFence(@NonNull Image image) {
    if (ignoringFence) {
      return;
    }
    if (Build.VERSION.SDK_INT >= API_LEVELS.API_33) {
      waitOnFence(image);
    } else {
      ignoringFence = true;
    }
  }

  /**
   * Releases an {@link Image} previously returned by {@link #acquireLatestImage()}.
   *
   * <p>Idempotent: duplicate or {@code null} calls are ignored. Closes the underlying {@link
   * ImageReader} if {@link #retire()} has already been called and no other acquired images remain
   * open.
   */
  public void releaseImage(@Nullable Image image) {
    if (image == null) {
      return;
    }
    synchronized (lock) {
      if (!openImages.remove(image)) {
        return;
      }
      try {
        image.close();
      } catch (RuntimeException ex) {
        Log.w(TAG, "Failed closing HybridImageReader Image", ex);
      }
      refCount--;
      closeReaderIfUnreferencedLocked();
    }
  }

  /**
   * Releases the pool's ownership reference on this reader.
   *
   * <p>Idempotent. If no acquired {@link Image} instances are open, closes the {@link ImageReader}
   * immediately; otherwise defers {@link ImageReader#close()} until the final open {@link Image} is
   * passed to {@link #releaseImage(Image)}.
   */
  public void retire() {
    synchronized (lock) {
      if (retired) {
        return;
      }
      retired = true;
      refCount--;
      closeReaderIfUnreferencedLocked();
    }
  }

  private void closeReaderIfUnreferencedLocked() {
    if (refCount == 0 && !closed) {
      closed = true;
      try {
        imageReader.close();
      } catch (RuntimeException ex) {
        Log.w(TAG, "Failed closing retired HybridImageReader", ex);
      }
    }
  }

  @VisibleForTesting
  public void disableFenceForTest() {
    ignoringFence = true;
  }

  @VisibleForTesting
  boolean isRetired() {
    synchronized (lock) {
      return retired;
    }
  }

  @VisibleForTesting
  boolean isClosed() {
    synchronized (lock) {
      return closed;
    }
  }

  @VisibleForTesting
  int getOpenImageCount() {
    synchronized (lock) {
      return openImages.size();
    }
  }

  @VisibleForTesting
  @NonNull
  ImageReader getImageReaderForTest() {
    return imageReader;
  }
}
