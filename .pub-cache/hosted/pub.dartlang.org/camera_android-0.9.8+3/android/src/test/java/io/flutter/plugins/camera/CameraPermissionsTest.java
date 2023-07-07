// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.camera;

import static junit.framework.TestCase.assertEquals;

import android.content.pm.PackageManager;
import io.flutter.plugins.camera.CameraPermissions.CameraRequestPermissionsListener;
import org.junit.Test;

public class CameraPermissionsTest {
  @Test
  public void listener_respondsOnce() {
    final int[] calledCounter = {0};
    CameraRequestPermissionsListener permissionsListener =
        new CameraRequestPermissionsListener((String code, String desc) -> calledCounter[0]++);

    permissionsListener.onRequestPermissionsResult(
        9796, null, new int[] {PackageManager.PERMISSION_DENIED});
    permissionsListener.onRequestPermissionsResult(
        9796, null, new int[] {PackageManager.PERMISSION_GRANTED});

    assertEquals(1, calledCounter[0]);
  }
}
