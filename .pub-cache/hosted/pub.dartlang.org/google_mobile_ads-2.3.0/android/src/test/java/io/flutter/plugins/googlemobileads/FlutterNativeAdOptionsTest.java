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
import static org.mockito.Mockito.doReturn;

import com.google.android.gms.ads.VideoOptions;
import com.google.android.gms.ads.nativead.NativeAdOptions;
import org.junit.Test;
import org.mockito.Mockito;

/** Tests for {@link FlutterNativeAdOptions}. */
public class FlutterNativeAdOptionsTest {

  @Test
  public void testAsAdOptions_null() {
    FlutterNativeAdOptions flutterNativeAdOptions =
        new FlutterNativeAdOptions(null, null, null, null, null, null);

    NativeAdOptions nativeAdOptions = flutterNativeAdOptions.asNativeAdOptions();
    NativeAdOptions defaultOptions = new NativeAdOptions.Builder().build();
    assertEquals(nativeAdOptions.getAdChoicesPlacement(), defaultOptions.getAdChoicesPlacement());
    assertEquals(nativeAdOptions.getMediaAspectRatio(), defaultOptions.getMediaAspectRatio());
    assertEquals(nativeAdOptions.getVideoOptions(), defaultOptions.getVideoOptions());
    assertEquals(
        nativeAdOptions.shouldRequestMultipleImages(),
        defaultOptions.shouldRequestMultipleImages());
    assertEquals(
        nativeAdOptions.shouldReturnUrlsForImageAssets(),
        defaultOptions.shouldReturnUrlsForImageAssets());
  }

  @Test
  public void testAsAdOptions() {
    FlutterVideoOptions mockFlutterVideoOptions = Mockito.mock(FlutterVideoOptions.class);
    VideoOptions mockVideoOptions = Mockito.mock(VideoOptions.class);
    doReturn(mockVideoOptions).when(mockFlutterVideoOptions).asVideoOptions();

    FlutterNativeAdOptions flutterNativeAdOptions =
        new FlutterNativeAdOptions(1, 2, mockFlutterVideoOptions, true, false, true);

    NativeAdOptions nativeAdOptions = flutterNativeAdOptions.asNativeAdOptions();
    assertEquals(nativeAdOptions.getAdChoicesPlacement(), 1);
    assertEquals(nativeAdOptions.getMediaAspectRatio(), 2);
    assertFalse(nativeAdOptions.shouldRequestMultipleImages());
    assertTrue(nativeAdOptions.shouldReturnUrlsForImageAssets());
    assertEquals(nativeAdOptions.getVideoOptions(), mockVideoOptions);
  }
}
