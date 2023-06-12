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
import com.google.android.gms.ads.appopen.AppOpenAd;
import com.google.android.gms.ads.appopen.AppOpenAd.AppOpenAdLoadCallback;
import io.flutter.util.Preconditions;
import java.lang.ref.WeakReference;

/** A wrapper for {@link com.google.android.gms.ads.appopen.AppOpenAd}. */
class FlutterAppOpenAd extends FlutterAd.FlutterOverlayAd {

  private static final String TAG = "FlutterAppOpenAd";

  @NonNull private final AdInstanceManager manager;
  @NonNull private final String adUnitId;
  private final int orientation;
  @Nullable private final FlutterAdRequest request;
  @Nullable private final FlutterAdManagerAdRequest adManagerAdRequest;
  @Nullable private AppOpenAd ad;
  @NonNull private final FlutterAdLoader flutterAdLoader;

  FlutterAppOpenAd(
      int adId,
      int orientation,
      @NonNull AdInstanceManager manager,
      @NonNull String adUnitId,
      @Nullable FlutterAdRequest request,
      @Nullable FlutterAdManagerAdRequest adManagerAdRequest,
      @NonNull FlutterAdLoader flutterAdLoader) {
    super(adId);
    Preconditions.checkState(
        request != null || adManagerAdRequest != null,
        "One of request and adManagerAdRequest must be non-null.");
    this.manager = manager;
    this.orientation = orientation;
    this.adUnitId = adUnitId;
    this.request = request;
    this.adManagerAdRequest = adManagerAdRequest;
    this.flutterAdLoader = flutterAdLoader;
  }

  @Override
  void load() {
    if (request != null) {
      flutterAdLoader.loadAppOpen(
          adUnitId,
          request.asAdRequest(adUnitId),
          getOrientation(),
          new DelegatingAppOpenAdLoadCallback(this));
    } else if (adManagerAdRequest != null) {
      flutterAdLoader.loadAdManagerAppOpen(
          adUnitId,
          adManagerAdRequest.asAdManagerAdRequest(adUnitId),
          getOrientation(),
          new DelegatingAppOpenAdLoadCallback(this));
    }
  }

  private int getOrientation() {
    if (orientation == 1) {
      return AppOpenAd.APP_OPEN_AD_ORIENTATION_PORTRAIT;
    } else if (orientation == 2 || orientation == 3) {
      return AppOpenAd.APP_OPEN_AD_ORIENTATION_LANDSCAPE;
    }
    Log.e(TAG, "Passed unknown app open orientation: " + orientation);
    return AppOpenAd.APP_OPEN_AD_ORIENTATION_PORTRAIT;
  }

  private void onAdLoaded(@NonNull AppOpenAd ad) {
    this.ad = ad;
    ad.setOnPaidEventListener(new FlutterPaidEventListener(manager, this));
    manager.onAdLoaded(adId, ad.getResponseInfo());
  }

  private void onAdFailedToLoad(@NonNull LoadAdError loadAdError) {
    manager.onAdFailedToLoad(adId, new FlutterLoadAdError(loadAdError));
  }

  @Override
  void show() {
    if (ad == null) {
      Log.w(TAG, "Tried to show app open ad before it was loaded");
      return;
    }
    if (manager.getActivity() == null) {
      Log.e(TAG, "Tried to show app open ad before activity was bound to the plugin.");
      return;
    }
    ad.setFullScreenContentCallback(new FlutterFullScreenContentCallback(manager, adId));
    ad.show(manager.getActivity());
  }

  @Override
  void setImmersiveMode(boolean immersiveModeEnabled) {
    if (ad == null) {
      Log.w(TAG, "Tried to set immersive mode on app open ad before it was loaded");
      return;
    }
    ad.setImmersiveMode(immersiveModeEnabled);
  }

  @Override
  void dispose() {
    ad = null;
  }

  /** An AppOpenAdLoadCallback that just forwards events to a delegate. */
  private static final class DelegatingAppOpenAdLoadCallback extends AppOpenAdLoadCallback {

    private final WeakReference<FlutterAppOpenAd> delegate;

    DelegatingAppOpenAdLoadCallback(FlutterAppOpenAd delegate) {
      this.delegate = new WeakReference<>(delegate);
    }

    @Override
    public void onAdLoaded(@NonNull AppOpenAd appOpenAd) {
      if (delegate.get() != null) {
        delegate.get().onAdLoaded(appOpenAd);
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
