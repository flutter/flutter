// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.camera;

/**
 * These are the states that the camera can be in. The camera can only take one photo at a time so
 * this state describes the state of the camera itself. The camera works like a pipeline where we
 * feed it requests through. It can only process one tasks at a time.
 */
public enum CameraState {
  /** Idle, showing preview and not capturing anything. */
  STATE_PREVIEW,

  /** Starting and waiting for autofocus to complete. */
  STATE_WAITING_FOCUS,

  /** Start performing autoexposure. */
  STATE_WAITING_PRECAPTURE_START,

  /** waiting for autoexposure to complete. */
  STATE_WAITING_PRECAPTURE_DONE,

  /** Capturing an image. */
  STATE_CAPTURING,
}
