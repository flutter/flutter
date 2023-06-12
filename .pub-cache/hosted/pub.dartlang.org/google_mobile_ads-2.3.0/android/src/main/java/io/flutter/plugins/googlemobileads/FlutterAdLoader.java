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
import com.google.android.gms.ads.AdListener;
import com.google.android.gms.ads.AdLoader;
import com.google.android.gms.ads.AdRequest;
import com.google.android.gms.ads.admanager.AdManagerAdRequest;
import com.google.android.gms.ads.admanager.AdManagerInterstitialAd;
import com.google.android.gms.ads.admanager.AdManagerInterstitialAdLoadCallback;
import com.google.android.gms.ads.appopen.AppOpenAd;
import com.google.android.gms.ads.appopen.AppOpenAd.AppOpenAdLoadCallback;
import com.google.android.gms.ads.interstitial.InterstitialAd;
import com.google.android.gms.ads.interstitial.InterstitialAdLoadCallback;
import com.google.android.gms.ads.nativead.NativeAd.OnNativeAdLoadedListener;
import com.google.android.gms.ads.nativead.NativeAdOptions;
import com.google.android.gms.ads.rewarded.RewardedAd;
import com.google.android.gms.ads.rewarded.RewardedAdLoadCallback;
import com.google.android.gms.ads.rewardedinterstitial.RewardedInterstitialAd;
import com.google.android.gms.ads.rewardedinterstitial.RewardedInterstitialAdLoadCallback;

/**
 * A wrapper around load methods in GMA. This exists mainly to make the Android code more testable.
 */
public class FlutterAdLoader {

  @NonNull private final Context context;

  public FlutterAdLoader(@NonNull Context context) {
    this.context = context;
  }

  /** Load an app open ad. */
  public void loadAppOpen(
      @NonNull String adUnitId,
      @NonNull AdRequest adRequest,
      int orientation,
      @NonNull AppOpenAdLoadCallback loadCallback) {
    AppOpenAd.load(context, adUnitId, adRequest, orientation, loadCallback);
  }

  /** Load an ad manager app open ad. */
  public void loadAdManagerAppOpen(
      @NonNull String adUnitId,
      @NonNull AdManagerAdRequest adRequest,
      int orientation,
      @NonNull AppOpenAdLoadCallback loadCallback) {
    AppOpenAd.load(context, adUnitId, adRequest, orientation, loadCallback);
  }

  /** Load an interstitial ad. */
  public void loadInterstitial(
      @NonNull String adUnitId,
      @NonNull AdRequest adRequest,
      @NonNull InterstitialAdLoadCallback loadCallback) {
    InterstitialAd.load(context, adUnitId, adRequest, loadCallback);
  }

  /** Load an ad manager interstitial ad. */
  public void loadAdManagerInterstitial(
      @NonNull String adUnitId,
      @NonNull AdManagerAdRequest adRequest,
      @NonNull AdManagerInterstitialAdLoadCallback loadCallback) {
    AdManagerInterstitialAd.load(context, adUnitId, adRequest, loadCallback);
  }

  /** Load a rewarded ad. */
  public void loadRewarded(
      @NonNull String adUnitId,
      @NonNull AdRequest adRequest,
      @NonNull RewardedAdLoadCallback loadCallback) {
    RewardedAd.load(context, adUnitId, adRequest, loadCallback);
  }

  /** Load a rewarded interstitial ad. */
  public void loadRewardedInterstitial(
      @NonNull String adUnitId,
      @NonNull AdRequest adRequest,
      @NonNull RewardedInterstitialAdLoadCallback loadCallback) {
    RewardedInterstitialAd.load(context, adUnitId, adRequest, loadCallback);
  }

  /** Load an ad manager rewarded ad. */
  public void loadAdManagerRewarded(
      @NonNull String adUnitId,
      @NonNull AdManagerAdRequest adRequest,
      @NonNull RewardedAdLoadCallback loadCallback) {
    RewardedAd.load(context, adUnitId, adRequest, loadCallback);
  }

  /** Load an ad manager rewarded interstitial ad. */
  public void loadAdManagerRewardedInterstitial(
      @NonNull String adUnitId,
      @NonNull AdManagerAdRequest adRequest,
      @NonNull RewardedInterstitialAdLoadCallback loadCallback) {
    RewardedInterstitialAd.load(context, adUnitId, adRequest, loadCallback);
  }

  /** Load a native ad. */
  public void loadNativeAd(
      @NonNull String adUnitId,
      @NonNull OnNativeAdLoadedListener onNativeAdLoadedListener,
      @NonNull NativeAdOptions nativeAdOptions,
      @NonNull AdListener adListener,
      @NonNull AdRequest adRequest) {
    new AdLoader.Builder(context, adUnitId)
        .forNativeAd(onNativeAdLoadedListener)
        .withNativeAdOptions(nativeAdOptions)
        .withAdListener(adListener)
        .build()
        .loadAd(adRequest);
  }

  /** Load an ad manager native ad. */
  public void loadAdManagerNativeAd(
      @NonNull String adUnitId,
      @NonNull OnNativeAdLoadedListener onNativeAdLoadedListener,
      @NonNull NativeAdOptions nativeAdOptions,
      @NonNull AdListener adListener,
      @NonNull AdManagerAdRequest adManagerAdRequest) {
    new AdLoader.Builder(context, adUnitId)
        .forNativeAd(onNativeAdLoadedListener)
        .withNativeAdOptions(nativeAdOptions)
        .withAdListener(adListener)
        .build()
        .loadAd(adManagerAdRequest);
  }
}
