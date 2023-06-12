// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.imagepickerexample;

import static org.junit.Assert.assertTrue;

import androidx.test.core.app.ActivityScenario;
import io.flutter.plugins.imagepicker.ImagePickerPlugin;
import org.junit.Test;

public class ImagePickerTest {
  @Test
  public void imagePickerPluginIsAdded() {
    final ActivityScenario<ImagePickerTestActivity> scenario =
        ActivityScenario.launch(ImagePickerTestActivity.class);
    scenario.onActivity(
        activity -> {
          assertTrue(activity.engine.getPlugins().has(ImagePickerPlugin.class));
        });
  }
}
