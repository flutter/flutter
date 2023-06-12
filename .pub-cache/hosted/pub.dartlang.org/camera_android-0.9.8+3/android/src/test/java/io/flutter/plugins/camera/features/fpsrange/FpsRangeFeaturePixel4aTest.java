// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.camera.features.fpsrange;

import static org.junit.Assert.assertEquals;
import static org.mockito.Mockito.mock;

import android.os.Build;
import android.util.Range;
import io.flutter.plugins.camera.CameraProperties;
import io.flutter.plugins.camera.utils.TestUtils;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.RobolectricTestRunner;

@RunWith(RobolectricTestRunner.class)
public class FpsRangeFeaturePixel4aTest {
  @Test
  public void ctor_shouldInitializeFpsRangeWith30WhenDeviceIsPixel4a() {
    TestUtils.setFinalStatic(Build.class, "BRAND", "google");
    TestUtils.setFinalStatic(Build.class, "MODEL", "Pixel 4a");

    FpsRangeFeature fpsRangeFeature = new FpsRangeFeature(mock(CameraProperties.class));
    Range<Integer> range = fpsRangeFeature.getValue();
    assertEquals(30, (int) range.getLower());
    assertEquals(30, (int) range.getUpper());
  }
}
