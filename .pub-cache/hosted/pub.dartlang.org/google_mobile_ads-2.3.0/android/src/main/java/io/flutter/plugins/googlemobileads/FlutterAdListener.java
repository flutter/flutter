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

import androidx.annotation.NonNull;
import com.google.android.gms.ads.AdListener;
import com.google.android.gms.ads.LoadAdError;
import com.google.android.gms.ads.nativead.NativeAd;
import com.google.android.gms.ads.nativead.NativeAd.OnNativeAdLoadedListener;
import java.lang.ref.WeakReference;

/** Callback type to notify when an ad successfully loads. */
interface FlutterAdLoadedListener {
  void onAdLoaded();
}

class FlutterAdListener extends AdListener {
  protected final int adId;
  @NonNull protected final AdInstanceManager manager;

  FlutterAdListener(int adId, @NonNull AdInstanceManager manager) {
    this.adId = adId;
    this.manager = manager;
  }

  @Override
  public void onAdClosed() {
    manager.onAdClosed(adId);
  }

  @Override
  public void onAdFailedToLoad(LoadAdError loadAdError) {
    manager.onAdFailedToLoad(adId, new FlutterAd.FlutterLoadAdError(loadAdError));
  }

  @Override
  public void onAdOpened() {
    manager.onAdOpened(adId);
  }

  @Override
  public void onAdImpression() {
    manager.onAdImpression(adId);
  }

  @Override
  public void onAdClicked() {
    manager.onAdClicked(adId);
  }
}

/**
 * Ad listener for banner ads. Does not override onAdClicked(), since that is only for native ads.
 */
class FlutterBannerAdListener extends FlutterAdListener {

  @NonNull final WeakReference<FlutterAdLoadedListener> adLoadedListenerWeakReference;

  FlutterBannerAdListener(
      int adId, @NonNull AdInstanceManager manager, FlutterAdLoadedListener adLoadedListener) {
    super(adId, manager);
    adLoadedListenerWeakReference = new WeakReference<>(adLoadedListener);
  }

  @Override
  public void onAdLoaded() {
    if (adLoadedListenerWeakReference.get() != null) {
      adLoadedListenerWeakReference.get().onAdLoaded();
    }
  }
}

/** Listener for native ads. */
class FlutterNativeAdListener extends FlutterAdListener {

  FlutterNativeAdListener(int adId, AdInstanceManager manager) {
    super(adId, manager);
  }

  @Override
  public void onAdLoaded() {
    // Do nothing. Loaded event is handled from FlutterNativeAdLoadedListener.
  }
}

/** {@link OnNativeAdLoadedListener} for native ads. */
class FlutterNativeAdLoadedListener implements OnNativeAdLoadedListener {

  private final WeakReference<FlutterNativeAd> nativeAdWeakReference;

  FlutterNativeAdLoadedListener(FlutterNativeAd flutterNativeAd) {
    nativeAdWeakReference = new WeakReference<>(flutterNativeAd);
  }

  @Override
  public void onNativeAdLoaded(@NonNull NativeAd nativeAd) {
    if (nativeAdWeakReference.get() != null) {
      nativeAdWeakReference.get().onNativeAdLoaded(nativeAd);
    }
  }
}
