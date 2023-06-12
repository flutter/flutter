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
import com.google.android.gms.ads.OnUserEarnedRewardListener;
import com.google.android.gms.ads.rewarded.OnAdMetadataChangedListener;
import com.google.android.gms.ads.rewarded.RewardItem;
import com.google.android.gms.ads.rewarded.RewardedAd;
import com.google.android.gms.ads.rewarded.RewardedAdLoadCallback;
import java.lang.ref.WeakReference;

/** A wrapper for {@link RewardedAd}. */
class FlutterRewardedAd extends FlutterAd.FlutterOverlayAd {
  private static final String TAG = "FlutterRewardedAd";

  @NonNull private final AdInstanceManager manager;
  @NonNull private final String adUnitId;
  @NonNull private final FlutterAdLoader flutterAdLoader;
  @Nullable private final FlutterAdRequest request;
  @Nullable private final FlutterAdManagerAdRequest adManagerRequest;
  @Nullable RewardedAd rewardedAd;

  /** A wrapper for {@link RewardItem}. */
  static class FlutterRewardItem {
    @NonNull final Integer amount;
    @NonNull final String type;

    FlutterRewardItem(@NonNull Integer amount, @NonNull String type) {
      this.amount = amount;
      this.type = type;
    }

    @Override
    public boolean equals(Object other) {
      if (this == other) {
        return true;
      } else if (!(other instanceof FlutterRewardItem)) {
        return false;
      }

      final FlutterRewardItem that = (FlutterRewardItem) other;
      if (!amount.equals(that.amount)) {
        return false;
      }
      return type.equals(that.type);
    }

    @Override
    public int hashCode() {
      int result = amount.hashCode();
      result = 31 * result + type.hashCode();
      return result;
    }
  }

  /** Constructor for AdMob Ad Request. */
  public FlutterRewardedAd(
      int adId,
      @NonNull AdInstanceManager manager,
      @NonNull String adUnitId,
      @NonNull FlutterAdRequest request,
      @NonNull FlutterAdLoader flutterAdLoader) {
    super(adId);
    this.manager = manager;
    this.adUnitId = adUnitId;
    this.request = request;
    this.adManagerRequest = null;
    this.flutterAdLoader = flutterAdLoader;
  }

  /** Constructor for Ad Manager Ad request. */
  public FlutterRewardedAd(
      int adId,
      @NonNull AdInstanceManager manager,
      @NonNull String adUnitId,
      @NonNull FlutterAdManagerAdRequest adManagerRequest,
      @NonNull FlutterAdLoader flutterAdLoader) {
    super(adId);
    this.manager = manager;
    this.adUnitId = adUnitId;
    this.adManagerRequest = adManagerRequest;
    this.request = null;
    this.flutterAdLoader = flutterAdLoader;
  }

  @Override
  void load() {
    final RewardedAdLoadCallback adLoadCallback = new DelegatingRewardedCallback(this);
    if (request != null) {
      flutterAdLoader.loadRewarded(adUnitId, request.asAdRequest(adUnitId), adLoadCallback);
    } else if (adManagerRequest != null) {
      flutterAdLoader.loadAdManagerRewarded(
          adUnitId, adManagerRequest.asAdManagerAdRequest(adUnitId), adLoadCallback);
    } else {
      Log.e(TAG, "A null or invalid ad request was provided.");
    }
  }

  void onAdLoaded(@NonNull RewardedAd rewardedAd) {
    FlutterRewardedAd.this.rewardedAd = rewardedAd;
    rewardedAd.setOnPaidEventListener(new FlutterPaidEventListener(manager, this));
    manager.onAdLoaded(adId, rewardedAd.getResponseInfo());
  }

  void onAdFailedToLoad(@NonNull LoadAdError loadAdError) {
    manager.onAdFailedToLoad(adId, new FlutterLoadAdError(loadAdError));
  }

  @Override
  public void show() {
    if (rewardedAd == null) {
      Log.e(TAG, "Error showing rewarded - the rewarded ad wasn't loaded yet.");
      return;
    }
    if (manager.getActivity() == null) {
      Log.e(TAG, "Tried to show rewarded ad before activity was bound to the plugin.");
      return;
    }
    rewardedAd.setFullScreenContentCallback(new FlutterFullScreenContentCallback(manager, adId));
    rewardedAd.setOnAdMetadataChangedListener(new DelegatingRewardedCallback(this));
    rewardedAd.show(manager.getActivity(), new DelegatingRewardedCallback(this));
  }

  @Override
  public void setImmersiveMode(boolean immersiveModeEnabled) {
    if (rewardedAd == null) {
      Log.e(
          TAG, "Error setting immersive mode in rewarded ad - the rewarded ad wasn't loaded yet.");
      return;
    }
    rewardedAd.setImmersiveMode(immersiveModeEnabled);
  }

  void onAdMetadataChanged() {
    manager.onAdMetadataChanged(adId);
  }

  void onUserEarnedReward(@NonNull RewardItem rewardItem) {
    manager.onRewardedAdUserEarnedReward(
        adId, new FlutterRewardItem(rewardItem.getAmount(), rewardItem.getType()));
  }

  @Override
  void dispose() {
    rewardedAd = null;
  }

  public void setServerSideVerificationOptions(FlutterServerSideVerificationOptions options) {
    if (rewardedAd != null) {
      rewardedAd.setServerSideVerificationOptions(options.asServerSideVerificationOptions());
    } else {
      Log.e(TAG, "RewardedAd is null in setServerSideVerificationOptions");
    }
  }

  /**
   * This class delegates various rewarded ad callbacks to FlutterRewardedAd. Maintains a weak
   * reference to avoid memory leaks.
   */
  private static final class DelegatingRewardedCallback extends RewardedAdLoadCallback
      implements OnAdMetadataChangedListener, OnUserEarnedRewardListener {

    private final WeakReference<FlutterRewardedAd> delegate;

    DelegatingRewardedCallback(FlutterRewardedAd delegate) {
      this.delegate = new WeakReference<>(delegate);
    }

    @Override
    public void onAdLoaded(@NonNull RewardedAd rewardedAd) {
      if (delegate.get() != null) {
        delegate.get().onAdLoaded(rewardedAd);
      }
    }

    @Override
    public void onAdFailedToLoad(@NonNull LoadAdError loadAdError) {
      if (delegate.get() != null) {
        delegate.get().onAdFailedToLoad(loadAdError);
      }
    }

    @Override
    public void onUserEarnedReward(@NonNull RewardItem rewardItem) {
      if (delegate.get() != null) {
        delegate.get().onUserEarnedReward(rewardItem);
      }
    }

    @Override
    public void onAdMetadataChanged() {
      if (delegate.get() != null) {
        delegate.get().onAdMetadataChanged();
      }
    }
  }
}
