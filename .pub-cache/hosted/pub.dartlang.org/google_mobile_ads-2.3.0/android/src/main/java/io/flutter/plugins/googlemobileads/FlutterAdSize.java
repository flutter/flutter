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

import android.content.Context;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import com.google.android.gms.ads.AdSize;

class FlutterAdSize {
  @NonNull final AdSize size;
  final int width;
  final int height;

  /** Wrapper around static methods for {@link com.google.android.gms.ads.AdSize}. */
  static class AdSizeFactory {

    AdSize getPortraitAnchoredAdaptiveBannerAdSize(Context context, int width) {
      return AdSize.getPortraitAnchoredAdaptiveBannerAdSize(context, width);
    }

    AdSize getLandscapeAnchoredAdaptiveBannerAdSize(Context context, int width) {
      return AdSize.getLandscapeAnchoredAdaptiveBannerAdSize(context, width);
    }

    AdSize getCurrentOrientationAnchoredAdaptiveBannerAdSize(Context context, int width) {
      return AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(context, width);
    }

    AdSize getCurrentOrientationInlineAdaptiveBannerAdSize(Context context, int width) {
      return AdSize.getCurrentOrientationInlineAdaptiveBannerAdSize(context, width);
    }

    AdSize getLandscapeInlineAdaptiveBannerAdSize(Context context, int width) {
      return AdSize.getLandscapeInlineAdaptiveBannerAdSize(context, width);
    }

    AdSize getPortraitInlineAdaptiveBannerAdSize(Context context, int width) {
      return AdSize.getPortraitInlineAdaptiveBannerAdSize(context, width);
    }

    AdSize getInlineAdaptiveBannerAdSize(int width, int maxHeight) {
      return AdSize.getInlineAdaptiveBannerAdSize(width, maxHeight);
    }
  }

  static class AnchoredAdaptiveBannerAdSize extends FlutterAdSize {
    final String orientation;

    @NonNull
    private static AdSize getAdSize(
        @NonNull Context context,
        @NonNull AdSizeFactory factory,
        @Nullable String orientation,
        int width) {
      final AdSize adSize;
      if (orientation == null) {
        adSize = factory.getCurrentOrientationAnchoredAdaptiveBannerAdSize(context, width);
      } else if (orientation.equals("portrait")) {
        adSize = factory.getPortraitAnchoredAdaptiveBannerAdSize(context, width);
      } else if (orientation.equals("landscape")) {
        adSize = factory.getLandscapeAnchoredAdaptiveBannerAdSize(context, width);
      } else {
        throw new IllegalArgumentException("Unexpected value for orientation: " + orientation);
      }
      return adSize;
    }

    AnchoredAdaptiveBannerAdSize(
        @NonNull Context context,
        @NonNull AdSizeFactory factory,
        @Nullable String orientation,
        int width) {
      super(getAdSize(context, factory, orientation, width));
      this.orientation = orientation;
    }
  }

  static class SmartBannerAdSize extends FlutterAdSize {

    @SuppressWarnings("deprecation") // Smart banner is already deprecated in Dart.
    SmartBannerAdSize() {
      super(AdSize.SMART_BANNER);
    }
  }

  static class FluidAdSize extends FlutterAdSize {

    FluidAdSize() {
      super(AdSize.FLUID);
    }
  }

  static class InlineAdaptiveBannerAdSize extends FlutterAdSize {

    @Nullable final Integer orientation;
    @Nullable final Integer maxHeight;

    private static AdSize getAdSize(
        @NonNull AdSizeFactory adSizeFactory,
        @NonNull Context context,
        int width,
        @Nullable Integer orientation,
        @Nullable Integer maxHeight) {
      if (orientation != null) {
        return orientation == 0
            ? adSizeFactory.getPortraitInlineAdaptiveBannerAdSize(context, width)
            : adSizeFactory.getLandscapeInlineAdaptiveBannerAdSize(context, width);
      } else if (maxHeight != null) {
        return adSizeFactory.getInlineAdaptiveBannerAdSize(width, maxHeight);
      } else {
        return adSizeFactory.getCurrentOrientationInlineAdaptiveBannerAdSize(context, width);
      }
    }

    InlineAdaptiveBannerAdSize(
        @NonNull AdSizeFactory adSizeFactory,
        @NonNull Context context,
        int width,
        @Nullable Integer orientation,
        @Nullable Integer maxHeight) {
      super(getAdSize(adSizeFactory, context, width, orientation, maxHeight));
      this.orientation = orientation;
      this.maxHeight = maxHeight;
    }
  }

  FlutterAdSize(int width, int height) {
    this(new AdSize(width, height));
  }

  FlutterAdSize(@NonNull AdSize size) {
    this.size = size;
    this.width = size.getWidth();
    this.height = size.getHeight();
  }

  @Override
  public boolean equals(Object o) {
    if (this == o) {
      return true;
    } else if (!(o instanceof FlutterAdSize)) {
      return false;
    }

    final FlutterAdSize that = (FlutterAdSize) o;

    if (width != that.width) {
      return false;
    }
    return height == that.height;
  }

  @Override
  public int hashCode() {
    int result = width;
    result = 31 * result + height;
    return result;
  }

  public AdSize getAdSize() {
    return size;
  }
}
