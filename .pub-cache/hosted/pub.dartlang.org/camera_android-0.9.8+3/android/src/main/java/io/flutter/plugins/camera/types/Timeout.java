// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.camera.types;

import android.os.SystemClock;

/**
 * This is a simple class for managing a timeout. In the camera we generally keep two timeouts: one
 * for focusing and one for pre-capture metering.
 *
 * <p>We use timeouts to ensure a picture is always captured within a reasonable amount of time even
 * if the settings don't converge and focus can't be locked.
 *
 * <p>You generally check the status of the timeout in the CameraCaptureCallback during the capture
 * sequence and use it to move to the next state if the timeout has passed.
 */
public class Timeout {

  /** The timeout time in milliseconds */
  private final long timeoutMs;

  /** When this timeout was started. Will be used later to check if the timeout has expired yet. */
  private final long timeStarted;

  /**
   * Factory method to create a new Timeout.
   *
   * @param timeoutMs timeout to use.
   * @return returns a new Timeout.
   */
  public static Timeout create(long timeoutMs) {
    return new Timeout(timeoutMs);
  }

  /**
   * Create a new timeout.
   *
   * @param timeoutMs the time in milliseconds for this timeout to lapse.
   */
  private Timeout(long timeoutMs) {
    this.timeoutMs = timeoutMs;
    this.timeStarted = SystemClock.elapsedRealtime();
  }

  /** Will return true when the timeout period has lapsed. */
  public boolean getIsExpired() {
    return (SystemClock.elapsedRealtime() - timeStarted) > timeoutMs;
  }
}
