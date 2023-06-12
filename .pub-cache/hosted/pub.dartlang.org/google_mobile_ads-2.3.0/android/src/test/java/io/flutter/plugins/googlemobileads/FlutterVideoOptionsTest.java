// Copyright 2021 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package io.flutter.plugins.googlemobileads;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertTrue;

import com.google.android.gms.ads.VideoOptions;
import org.junit.Test;

/** Tests for {@link FlutterVideoOptions}. */
public class FlutterVideoOptionsTest {

  @Test
  public void testVideoOptions_null() {
    FlutterVideoOptions flutterVideoOptions = new FlutterVideoOptions(null, null, null);

    VideoOptions videoOptions = flutterVideoOptions.asVideoOptions();
    VideoOptions defaultOptions = new VideoOptions.Builder().build();
    assertEquals(
        videoOptions.getClickToExpandRequested(), defaultOptions.getClickToExpandRequested());
    assertEquals(
        videoOptions.getCustomControlsRequested(), defaultOptions.getCustomControlsRequested());
    assertEquals(videoOptions.getStartMuted(), defaultOptions.getStartMuted());
  }

  @Test
  public void testVideoOptions() {
    FlutterVideoOptions flutterVideoOptions = new FlutterVideoOptions(true, false, true);

    VideoOptions videoOptions = flutterVideoOptions.asVideoOptions();

    assertTrue(videoOptions.getClickToExpandRequested());
    assertFalse(videoOptions.getCustomControlsRequested());
    assertTrue(videoOptions.getStartMuted());
  }
}
