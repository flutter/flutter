// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.camera.types;

/**
 * Wrapper class that provides a container for all {@link Timeout} instances that are required for
 * the capture flow.
 */
public class CaptureTimeoutsWrapper {
  private Timeout preCaptureFocusing;
  private Timeout preCaptureMetering;
  private final long preCaptureFocusingTimeoutMs;
  private final long preCaptureMeteringTimeoutMs;

  /**
   * Create a new wrapper instance with the specified timeout values.
   *
   * @param preCaptureFocusingTimeoutMs focusing timeout milliseconds.
   * @param preCaptureMeteringTimeoutMs metering timeout milliseconds.
   */
  public CaptureTimeoutsWrapper(
      long preCaptureFocusingTimeoutMs, long preCaptureMeteringTimeoutMs) {
    this.preCaptureFocusingTimeoutMs = preCaptureFocusingTimeoutMs;
    this.preCaptureMeteringTimeoutMs = preCaptureMeteringTimeoutMs;
  }

  /** Reset all timeouts to the current timestamp. */
  public void reset() {
    this.preCaptureFocusing = Timeout.create(preCaptureFocusingTimeoutMs);
    this.preCaptureMetering = Timeout.create(preCaptureMeteringTimeoutMs);
  }

  /**
   * Returns the timeout instance related to precapture focusing.
   *
   * @return - The timeout object
   */
  public Timeout getPreCaptureFocusing() {
    return preCaptureFocusing;
  }

  /**
   * Returns the timeout instance related to precapture metering.
   *
   * @return - The timeout object
   */
  public Timeout getPreCaptureMetering() {
    return preCaptureMetering;
  }
}
