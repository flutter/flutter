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
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import com.google.android.gms.ads.AdListener;
import com.google.android.gms.ads.admanager.AdManagerAdRequest;
import com.google.android.gms.ads.nativead.NativeAd;
import com.google.android.gms.ads.nativead.NativeAd.OnNativeAdLoadedListener;
import com.google.android.gms.ads.nativead.NativeAdOptions;
import com.google.android.gms.ads.nativead.NativeAdView;
import io.flutter.plugin.platform.PlatformView;
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin.NativeAdFactory;
import java.util.Map;

/** A wrapper for {@link NativeAd}. */
class FlutterNativeAd extends FlutterAd {
  private static final String TAG = "FlutterNativeAd";

  @NonNull private final AdInstanceManager manager;
  @NonNull private final String adUnitId;
  @NonNull private final NativeAdFactory adFactory;
  @NonNull private final FlutterAdLoader flutterAdLoader;
  @Nullable private FlutterAdRequest request;
  @Nullable private FlutterAdManagerAdRequest adManagerRequest;
  @Nullable private Map<String, Object> customOptions;
  @Nullable private NativeAdView nativeAdView;
  @Nullable private final FlutterNativeAdOptions nativeAdOptions;

  static class Builder {
    @Nullable private AdInstanceManager manager;
    @Nullable private String adUnitId;
    @Nullable private NativeAdFactory adFactory;
    @Nullable private FlutterAdRequest request;
    @Nullable private FlutterAdManagerAdRequest adManagerRequest;
    @Nullable private Map<String, Object> customOptions;
    @Nullable private Integer id;
    @Nullable private FlutterNativeAdOptions nativeAdOptions;
    @Nullable private FlutterAdLoader flutterAdLoader;

    public Builder setAdFactory(@NonNull NativeAdFactory adFactory) {
      this.adFactory = adFactory;
      return this;
    }

    public Builder setId(int id) {
      this.id = id;
      return this;
    }

    public Builder setCustomOptions(@Nullable Map<String, Object> customOptions) {
      this.customOptions = customOptions;
      return this;
    }

    public Builder setManager(@NonNull AdInstanceManager manager) {
      this.manager = manager;
      return this;
    }

    public Builder setAdUnitId(@NonNull String adUnitId) {
      this.adUnitId = adUnitId;
      return this;
    }

    public Builder setRequest(@NonNull FlutterAdRequest request) {
      this.request = request;
      return this;
    }

    public Builder setAdManagerRequest(@NonNull FlutterAdManagerAdRequest request) {
      this.adManagerRequest = request;
      return this;
    }

    public Builder setNativeAdOptions(@Nullable FlutterNativeAdOptions nativeAdOptions) {
      this.nativeAdOptions = nativeAdOptions;
      return this;
    }

    public Builder setFlutterAdLoader(@NonNull FlutterAdLoader flutterAdLoader) {
      this.flutterAdLoader = flutterAdLoader;
      return this;
    }

    FlutterNativeAd build() {
      if (manager == null) {
        throw new IllegalStateException("AdInstanceManager cannot be null.");
      } else if (adUnitId == null) {
        throw new IllegalStateException("AdUnitId cannot be null.");
      } else if (adFactory == null) {
        throw new IllegalStateException("NativeAdFactory cannot be null.");
      } else if (request == null && adManagerRequest == null) {
        throw new IllegalStateException("adRequest or addManagerRequest must be non-null.");
      }

      final FlutterNativeAd nativeAd;
      if (request == null) {
        nativeAd =
            new FlutterNativeAd(
                id,
                manager,
                adUnitId,
                adFactory,
                adManagerRequest,
                flutterAdLoader,
                customOptions,
                nativeAdOptions);
      } else {
        nativeAd =
            new FlutterNativeAd(
                id,
                manager,
                adUnitId,
                adFactory,
                request,
                flutterAdLoader,
                customOptions,
                nativeAdOptions);
      }
      return nativeAd;
    }
  }

  protected FlutterNativeAd(
      int adId,
      @NonNull AdInstanceManager manager,
      @NonNull String adUnitId,
      @NonNull NativeAdFactory adFactory,
      @NonNull FlutterAdRequest request,
      @NonNull FlutterAdLoader flutterAdLoader,
      @Nullable Map<String, Object> customOptions,
      @Nullable FlutterNativeAdOptions nativeAdOptions) {
    super(adId);
    this.manager = manager;
    this.adUnitId = adUnitId;
    this.adFactory = adFactory;
    this.request = request;
    this.flutterAdLoader = flutterAdLoader;
    this.customOptions = customOptions;
    this.nativeAdOptions = nativeAdOptions;
  }

  protected FlutterNativeAd(
      int adId,
      @NonNull AdInstanceManager manager,
      @NonNull String adUnitId,
      @NonNull NativeAdFactory adFactory,
      @NonNull FlutterAdManagerAdRequest adManagerRequest,
      @NonNull FlutterAdLoader flutterAdLoader,
      @Nullable Map<String, Object> customOptions,
      @Nullable FlutterNativeAdOptions nativeAdOptions) {
    super(adId);
    this.manager = manager;
    this.adUnitId = adUnitId;
    this.adFactory = adFactory;
    this.adManagerRequest = adManagerRequest;
    this.flutterAdLoader = flutterAdLoader;
    this.customOptions = customOptions;
    this.nativeAdOptions = nativeAdOptions;
  }

  @Override
  void load() {
    final OnNativeAdLoadedListener loadedListener = new FlutterNativeAdLoadedListener(this);
    final AdListener adListener = new FlutterNativeAdListener(adId, manager);
    // Note we delegate loading the ad to FlutterAdLoader mainly for testing purposes.
    // As of 20.0.0 of GMA, mockito is unable to mock AdLoader.
    final NativeAdOptions options =
        this.nativeAdOptions == null
            ? new NativeAdOptions.Builder().build()
            : nativeAdOptions.asNativeAdOptions();
    if (request != null) {
      flutterAdLoader.loadNativeAd(
          adUnitId, loadedListener, options, adListener, request.asAdRequest(adUnitId));
    } else if (adManagerRequest != null) {
      AdManagerAdRequest adManagerAdRequest = adManagerRequest.asAdManagerAdRequest(adUnitId);
      flutterAdLoader.loadAdManagerNativeAd(
          adUnitId, loadedListener, options, adListener, adManagerAdRequest);
    } else {
      Log.e(TAG, "A null or invalid ad request was provided.");
    }
  }

  @Override
  @Nullable
  public PlatformView getPlatformView() {
    if (nativeAdView == null) {
      return null;
    }
    return new FlutterPlatformView(nativeAdView);
  }

  void onNativeAdLoaded(@NonNull NativeAd nativeAd) {
    nativeAdView = adFactory.createNativeAd(nativeAd, customOptions);
    nativeAd.setOnPaidEventListener(new FlutterPaidEventListener(manager, this));
    manager.onAdLoaded(adId, nativeAd.getResponseInfo());
  }

  @Override
  void dispose() {
    if (nativeAdView != null) {
      nativeAdView.destroy();
      nativeAdView = null;
    }
  }
}
