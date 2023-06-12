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
import com.google.android.gms.ads.LoadAdError;
import com.google.android.gms.ads.interstitial.InterstitialAd;
import com.google.android.gms.ads.interstitial.InterstitialAdLoadCallback;
import java.lang.ref.WeakReference;

class FlutterInterstitialAd extends FlutterAd.FlutterOverlayAd {
  private static final String TAG = "FlutterInterstitialAd";

  @NonNull private final AdInstanceManager manager;
  @NonNull private final String adUnitId;
  @NonNull private final FlutterAdRequest request;
  @Nullable private InterstitialAd ad;
  @NonNull private final FlutterAdLoader flutterAdLoader;

  public FlutterInterstitialAd(
      int adId,
      @NonNull AdInstanceManager manager,
      @NonNull String adUnitId,
      @NonNull FlutterAdRequest request,
      @NonNull FlutterAdLoader flutterAdLoader) {
    super(adId);
    this.manager = manager;
    this.adUnitId = adUnitId;
    this.request = request;
    this.flutterAdLoader = flutterAdLoader;
  }

  @Override
  void load() {
    if (manager != null && adUnitId != null && request != null) {
      flutterAdLoader.loadInterstitial(
          adUnitId, request.asAdRequest(adUnitId), new DelegatingInterstitialAdLoadCallback(this));
    }
  }

  void onAdLoaded(InterstitialAd ad) {
    this.ad = ad;
    ad.setOnPaidEventListener(new FlutterPaidEventListener(manager, this));
    manager.onAdLoaded(adId, ad.getResponseInfo());
  }

  void onAdFailedToLoad(LoadAdError loadAdError) {
    manager.onAdFailedToLoad(adId, new FlutterAd.FlutterLoadAdError(loadAdError));
  }

  @Override
  void dispose() {
    ad = null;
  }

  @Override
  public void show() {
    if (ad == null) {
      Log.e(TAG, "Error showing interstitial - the interstitial ad wasn't loaded yet.");
      return;
    }
    if (manager.getActivity() == null) {
      Log.e(TAG, "Tried to show interstitial before activity was bound to the plugin.");
      return;
    }
    ad.setFullScreenContentCallback(new FlutterFullScreenContentCallback(manager, adId));
    ad.show(manager.getActivity());
  }

  @Override
  public void setImmersiveMode(boolean immersiveModeEnabled) {
    if (ad == null) {
      Log.e(
          TAG,
          "Error setting immersive mode in interstitial ad - the interstitial ad wasn't loaded yet.");
      return;
    }
    ad.setImmersiveMode(immersiveModeEnabled);
  }

  /** An InterstitialAdLoadCallback that just forwards events to a delegate. */
  private static final class DelegatingInterstitialAdLoadCallback
      extends InterstitialAdLoadCallback {

    private final WeakReference<FlutterInterstitialAd> delegate;

    DelegatingInterstitialAdLoadCallback(FlutterInterstitialAd delegate) {
      this.delegate = new WeakReference<>(delegate);
    }

    @Override
    public void onAdLoaded(@NonNull InterstitialAd interstitialAd) {
      if (delegate.get() != null) {
        delegate.get().onAdLoaded(interstitialAd);
      }
    }

    @Override
    public void onAdFailedToLoad(@NonNull LoadAdError loadAdError) {
      if (delegate.get() != null) {
        delegate.get().onAdFailedToLoad(loadAdError);
      }
    }
  }
}
