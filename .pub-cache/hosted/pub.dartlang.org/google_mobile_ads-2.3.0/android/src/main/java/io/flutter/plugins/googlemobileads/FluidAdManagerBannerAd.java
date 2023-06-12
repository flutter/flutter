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

import android.util.Log;
import android.view.View;
import android.view.View.OnLayoutChangeListener;
import android.view.ViewGroup;
import android.widget.ScrollView;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.annotation.VisibleForTesting;
import com.google.android.gms.ads.AdSize;
import io.flutter.plugin.platform.PlatformView;
import java.util.Collections;

/** A subclass of {@link FlutterAdManagerBannerAd} specifically for fluid ad size. */
final class FluidAdManagerBannerAd extends FlutterAdManagerBannerAd {

  private static final String TAG = "FluidAdManagerBannerAd";

  @Nullable private ViewGroup containerView;

  private int height = -1;

  FluidAdManagerBannerAd(
      int adId,
      @NonNull AdInstanceManager manager,
      @NonNull String adUnitId,
      @NonNull FlutterAdManagerAdRequest request,
      @NonNull BannerAdCreator bannerAdCreator) {
    super(
        adId,
        manager,
        adUnitId,
        Collections.singletonList(new FlutterAdSize(AdSize.FLUID)),
        request,
        bannerAdCreator);
  }

  @Override
  public void onAdLoaded() {
    if (adView != null) {
      adView.addOnLayoutChangeListener(
          new OnLayoutChangeListener() {
            @Override
            public void onLayoutChange(
                View v,
                int left,
                int top,
                int right,
                int bottom,
                int oldLeft,
                int oldTop,
                int oldRight,
                int oldBottom) {
              // Forward the new height to its container.
              int newHeight = v.getMeasuredHeight();
              if (newHeight != height) {
                manager.onFluidAdHeightChanged(adId, newHeight);
              }
              height = newHeight;
            }
          });
      manager.onAdLoaded(adId, adView.getResponseInfo());
    }
  }

  @Nullable
  @Override
  PlatformView getPlatformView() {
    if (adView == null) {
      return null;
    }
    if (containerView != null) {
      return new FlutterPlatformView(containerView);
    }
    // Place the ad view inside a scroll view. This allows the height of the ad view to overflow
    // its container so we can calculate the height and send it back to flutter.
    ScrollView scrollView = createContainerView();
    if (scrollView == null) {
      return null;
    }
    scrollView.setClipChildren(false);
    scrollView.setVerticalScrollBarEnabled(false);
    scrollView.setHorizontalScrollBarEnabled(false);
    containerView = scrollView;
    containerView.addView(adView);
    return new FlutterPlatformView(adView);
  }

  @Nullable
  @VisibleForTesting
  ScrollView createContainerView() {
    if (manager.getActivity() == null) {
      Log.e(TAG, "Tried to create container view before plugin is attached to an activity.");
      return null;
    }
    return new ScrollView(manager.getActivity());
  }

  @Override
  void dispose() {
    if (adView != null) {
      adView.destroy();
      adView = null;
    }
    if (containerView != null) {
      containerView.removeAllViews();
      containerView = null;
    }
  }
}
