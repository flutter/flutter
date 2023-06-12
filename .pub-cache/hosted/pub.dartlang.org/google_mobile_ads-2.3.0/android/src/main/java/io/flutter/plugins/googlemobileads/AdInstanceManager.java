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

import android.app.Activity;
import android.os.Handler;
import android.os.Looper;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import com.google.android.gms.ads.AdError;
import com.google.android.gms.ads.ResponseInfo;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugins.googlemobileads.FlutterAd.FlutterAdError;
import io.flutter.plugins.googlemobileads.FlutterAd.FlutterResponseInfo;
import java.util.HashMap;
import java.util.Map;

/**
 * Maintains reference to ad instances for the {@link
 * io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin}.
 *
 * <p>When an Ad is loaded from Dart, an equivalent ad object is created and maintained here to
 * provide access until the ad is disposed.
 */
class AdInstanceManager {
  @Nullable private Activity activity;

  @NonNull private final Map<Integer, FlutterAd> ads;
  @NonNull private final MethodChannel channel;

  /**
   * Initializes the ad instance manager. We only need a method channel to start loading ads, but an
   * activity must be present in order to attach any ads to the view hierarchy.
   */
  AdInstanceManager(@NonNull MethodChannel channel) {
    this.channel = channel;
    this.ads = new HashMap<>();
  }

  void setActivity(@Nullable Activity activity) {
    this.activity = activity;
  }

  @Nullable
  Activity getActivity() {
    return activity;
  }

  @Nullable
  FlutterAd adForId(int id) {
    return ads.get(id);
  }

  @Nullable
  Integer adIdFor(@NonNull FlutterAd ad) {
    for (Integer adId : ads.keySet()) {
      if (ads.get(adId) == ad) {
        return adId;
      }
    }
    return null;
  }

  void trackAd(@NonNull FlutterAd ad, int adId) {
    if (ads.get(adId) != null) {
      throw new IllegalArgumentException(
          String.format("Ad for following adId already exists: %d", adId));
    }
    ads.put(adId, ad);
  }

  void disposeAd(int adId) {
    if (!ads.containsKey(adId)) {
      return;
    }
    FlutterAd ad = ads.get(adId);
    if (ad != null) {
      ad.dispose();
    }
    ads.remove(adId);
  }

  void disposeAllAds() {
    for (Map.Entry<Integer, FlutterAd> entry : ads.entrySet()) {
      if (entry.getValue() != null) {
        entry.getValue().dispose();
      }
    }
    ads.clear();
  }

  void onAdLoaded(int adId, @Nullable ResponseInfo responseInfo) {
    Map<Object, Object> arguments = new HashMap<>();
    arguments.put("adId", adId);
    arguments.put("eventName", "onAdLoaded");
    FlutterResponseInfo flutterResponseInfo =
        (responseInfo == null) ? null : new FlutterResponseInfo(responseInfo);
    arguments.put("responseInfo", flutterResponseInfo);
    invokeOnAdEvent(arguments);
  }

  void onAdFailedToLoad(int adId, @NonNull FlutterAd.FlutterLoadAdError error) {
    Map<Object, Object> arguments = new HashMap<>();
    arguments.put("adId", adId);
    arguments.put("eventName", "onAdFailedToLoad");
    arguments.put("loadAdError", error);
    invokeOnAdEvent(arguments);
  }

  void onAppEvent(int adId, @NonNull String name, @NonNull String data) {
    Map<Object, Object> arguments = new HashMap<>();
    arguments.put("adId", adId);
    arguments.put("eventName", "onAppEvent");
    arguments.put("name", name);
    arguments.put("data", data);
    invokeOnAdEvent(arguments);
  }

  void onAdImpression(int id) {
    Map<Object, Object> arguments = new HashMap<>();
    arguments.put("adId", id);
    arguments.put("eventName", "onAdImpression");
    invokeOnAdEvent(arguments);
  }

  void onAdClicked(int id) {
    Map<Object, Object> arguments = new HashMap<>();
    arguments.put("adId", id);
    arguments.put("eventName", "onAdClicked");
    invokeOnAdEvent(arguments);
  }

  void onAdOpened(int adId) {
    Map<Object, Object> arguments = new HashMap<>();
    arguments.put("adId", adId);
    arguments.put("eventName", "onAdOpened");
    invokeOnAdEvent(arguments);
  }

  void onAdClosed(int adId) {
    Map<Object, Object> arguments = new HashMap<>();
    arguments.put("adId", adId);
    arguments.put("eventName", "onAdClosed");
    invokeOnAdEvent(arguments);
  }

  void onRewardedAdUserEarnedReward(int adId, @NonNull FlutterRewardedAd.FlutterRewardItem reward) {
    final Map<Object, Object> arguments = new HashMap<>();
    arguments.put("adId", adId);
    arguments.put("eventName", "onRewardedAdUserEarnedReward");
    arguments.put("rewardItem", reward);
    invokeOnAdEvent(arguments);
  }

  void onRewardedInterstitialAdUserEarnedReward(
      int adId, @NonNull FlutterRewardedAd.FlutterRewardItem reward) {
    final Map<Object, Object> arguments = new HashMap<>();
    arguments.put("adId", adId);
    arguments.put("eventName", "onRewardedInterstitialAdUserEarnedReward");
    arguments.put("rewardItem", reward);
    invokeOnAdEvent(arguments);
  }

  void onPaidEvent(@NonNull FlutterAd ad, @NonNull FlutterAdValue adValue) {
    final Map<Object, Object> arguments = new HashMap<>();
    arguments.put("adId", adIdFor(ad));
    arguments.put("eventName", "onPaidEvent");
    arguments.put("valueMicros", adValue.valueMicros);
    arguments.put("precision", adValue.precisionType);
    arguments.put("currencyCode", adValue.currencyCode);
    invokeOnAdEvent(arguments);
  }

  void onFailedToShowFullScreenContent(int adId, @NonNull AdError error) {
    final Map<Object, Object> arguments = new HashMap<>();
    arguments.put("adId", adId);
    arguments.put("eventName", "onFailedToShowFullScreenContent");
    arguments.put("error", new FlutterAdError(error));
    invokeOnAdEvent(arguments);
  }

  void onAdShowedFullScreenContent(int adId) {
    final Map<Object, Object> arguments = new HashMap<>();
    arguments.put("adId", adId);
    arguments.put("eventName", "onAdShowedFullScreenContent");
    invokeOnAdEvent(arguments);
  }

  void onAdDismissedFullScreenContent(int adId) {
    final Map<Object, Object> arguments = new HashMap<>();
    arguments.put("adId", adId);
    arguments.put("eventName", "onAdDismissedFullScreenContent");
    invokeOnAdEvent(arguments);
  }

  void onAdMetadataChanged(int adId) {
    final Map<Object, Object> arguments = new HashMap<>();
    arguments.put("adId", adId);
    arguments.put("eventName", "onAdMetadataChanged");
    invokeOnAdEvent(arguments);
  }

  void onFluidAdHeightChanged(int adId, int height) {
    final Map<Object, Object> arguments = new HashMap<>();
    arguments.put("adId", adId);
    arguments.put("eventName", "onFluidAdHeightChanged");
    arguments.put("height", height);
    invokeOnAdEvent(arguments);
  }

  boolean showAdWithId(int id) {
    final FlutterAd.FlutterOverlayAd ad = (FlutterAd.FlutterOverlayAd) adForId(id);

    if (ad == null) {
      return false;
    }

    ad.show();
    return true;
  }

  /** Invoke the method channel using the UI thread. Otherwise the message gets silently dropped. */
  private void invokeOnAdEvent(final Map<Object, Object> arguments) {
    new Handler(Looper.getMainLooper())
        .post(
            new Runnable() {
              @Override
              public void run() {
                channel.invokeMethod("onAdEvent", arguments);
              }
            });
  }
}
