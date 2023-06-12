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
// limitations under the License.c language governing permissions and
//   limitations under the License.

package io.flutter.plugins.googlemobileads;

import androidx.annotation.Nullable;
import com.google.android.gms.ads.VideoOptions;

/** A wrapper for {@link com.google.android.gms.ads.VideoOptions}. */
class FlutterVideoOptions {
  @Nullable final Boolean clickToExpandRequested;
  @Nullable final Boolean customControlsRequested;
  @Nullable final Boolean startMuted;

  FlutterVideoOptions(
      @Nullable Boolean clickToExpandRequested,
      @Nullable Boolean customControlsRequested,
      @Nullable Boolean startMuted) {
    this.clickToExpandRequested = clickToExpandRequested;
    this.customControlsRequested = customControlsRequested;
    this.startMuted = startMuted;
  }

  VideoOptions asVideoOptions() {
    VideoOptions.Builder builder = new VideoOptions.Builder();
    if (clickToExpandRequested != null) {
      builder.setClickToExpandRequested(clickToExpandRequested);
    }
    if (customControlsRequested != null) {
      builder.setCustomControlsRequested(customControlsRequested);
    }
    if (startMuted != null) {
      builder.setStartMuted(startMuted);
    }
    return builder.build();
  }
}
