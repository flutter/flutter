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
import com.google.android.gms.ads.nativead.NativeAdOptions;

/** A wrapper for {@link com.google.android.gms.ads.nativead.NativeAdOptions}. */
class FlutterNativeAdOptions {

  @Nullable final Integer adChoicesPlacement;
  @Nullable final Integer mediaAspectRatio;
  @Nullable final FlutterVideoOptions videoOptions;
  @Nullable final Boolean requestCustomMuteThisAd;
  @Nullable final Boolean shouldRequestMultipleImages;
  @Nullable final Boolean shouldReturnUrlsForImageAssets;

  FlutterNativeAdOptions(
      @Nullable Integer adChoicesPlacement,
      @Nullable Integer mediaAspectRatio,
      @Nullable FlutterVideoOptions videoOptions,
      @Nullable Boolean requestCustomMuteThisAd,
      @Nullable Boolean shouldRequestMultipleImages,
      @Nullable Boolean shouldReturnUrlsForImageAssets) {
    this.adChoicesPlacement = adChoicesPlacement;
    this.mediaAspectRatio = mediaAspectRatio;
    this.videoOptions = videoOptions;
    this.requestCustomMuteThisAd = requestCustomMuteThisAd;
    this.shouldRequestMultipleImages = shouldRequestMultipleImages;
    this.shouldReturnUrlsForImageAssets = shouldReturnUrlsForImageAssets;
  }

  NativeAdOptions asNativeAdOptions() {
    NativeAdOptions.Builder builder = new NativeAdOptions.Builder();
    if (adChoicesPlacement != null) {
      builder.setAdChoicesPlacement(adChoicesPlacement);
    }
    if (mediaAspectRatio != null) {
      builder.setMediaAspectRatio(mediaAspectRatio);
    }
    if (videoOptions != null) {
      builder.setVideoOptions(videoOptions.asVideoOptions());
    }
    if (requestCustomMuteThisAd != null) {
      builder.setRequestCustomMuteThisAd(requestCustomMuteThisAd);
    }
    if (shouldRequestMultipleImages != null) {
      builder.setRequestMultipleImages(shouldRequestMultipleImages);
    }
    if (shouldReturnUrlsForImageAssets != null) {
      builder.setReturnUrlsForImageAssets(shouldReturnUrlsForImageAssets);
    }
    return builder.build();
  }
}
