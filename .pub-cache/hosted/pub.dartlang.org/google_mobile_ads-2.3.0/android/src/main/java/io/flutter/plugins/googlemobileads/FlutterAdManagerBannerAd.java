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

import static android.view.ViewGroup.LayoutParams.MATCH_PARENT;
import static android.view.ViewGroup.LayoutParams.WRAP_CONTENT;

import android.view.ViewGroup.LayoutParams;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import com.google.android.gms.ads.AdSize;
import com.google.android.gms.ads.admanager.AdManagerAdView;
import com.google.android.gms.ads.admanager.AppEventListener;
import io.flutter.plugin.platform.PlatformView;
import io.flutter.util.Preconditions;
import java.util.List;

/**
 * Wrapper around {@link com.google.android.gms.ads.admanager.AdManagerAdView} for the Google Mobile
 * Ads Plugin.
 */
class FlutterAdManagerBannerAd extends FlutterAd implements FlutterAdLoadedListener {

  @NonNull protected final AdInstanceManager manager;
  @NonNull private final String adUnitId;
  @NonNull private final List<FlutterAdSize> sizes;
  @NonNull private final FlutterAdManagerAdRequest request;
  @NonNull private final BannerAdCreator bannerAdCreator;
  @Nullable protected AdManagerAdView adView;

  /**
   * Constructs a `FlutterAdManagerBannerAd`.
   *
   * <p>Call `load()` to instantiate the `AdView` and load the `AdRequest`. `getView()` will return
   * null only until `load` is called.
   */
  public FlutterAdManagerBannerAd(
      int adId,
      @NonNull AdInstanceManager manager,
      @NonNull String adUnitId,
      @NonNull List<FlutterAdSize> sizes,
      @NonNull FlutterAdManagerAdRequest request,
      @NonNull BannerAdCreator bannerAdCreator) {
    super(adId);
    Preconditions.checkNotNull(manager);
    Preconditions.checkNotNull(adUnitId);
    Preconditions.checkNotNull(sizes);
    Preconditions.checkNotNull(request);
    this.manager = manager;
    this.adUnitId = adUnitId;
    this.sizes = sizes;
    this.request = request;
    this.bannerAdCreator = bannerAdCreator;
  }

  @Override
  void load() {
    adView = bannerAdCreator.createAdManagerAdView();
    if (this instanceof FluidAdManagerBannerAd) {
      adView.setLayoutParams(new LayoutParams(MATCH_PARENT, WRAP_CONTENT));
    }
    adView.setAdUnitId(adUnitId);
    adView.setAppEventListener(
        new AppEventListener() {
          @Override
          public void onAppEvent(String name, String data) {
            manager.onAppEvent(adId, name, data);
          }
        });

    final AdSize[] allSizes = new AdSize[sizes.size()];
    for (int i = 0; i < sizes.size(); i++) {
      allSizes[i] = sizes.get(i).getAdSize();
    }
    adView.setAdSizes(allSizes);
    adView.setAdListener(new FlutterBannerAdListener(adId, manager, this));
    adView.loadAd(request.asAdManagerAdRequest(adUnitId));
  }

  @Override
  public void onAdLoaded() {
    if (adView != null) {
      manager.onAdLoaded(adId, adView.getResponseInfo());
    }
  }

  @Nullable
  @Override
  PlatformView getPlatformView() {
    if (adView == null) {
      return null;
    }
    return new FlutterPlatformView(adView);
  }

  @Override
  void dispose() {
    if (adView != null) {
      adView.destroy();
      adView = null;
    }
  }

  @Nullable
  FlutterAdSize getAdSize() {
    if (adView == null || adView.getAdSize() == null) {
      return null;
    }
    return new FlutterAdSize(adView.getAdSize());
  }
}
