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
import com.google.android.gms.ads.MobileAds;
import com.google.android.gms.ads.OnAdInspectorClosedListener;
import com.google.android.gms.ads.RequestConfiguration;
import com.google.android.gms.ads.initialization.OnInitializationCompleteListener;

/** A wrapper around static methods in {@link com.google.android.gms.ads.MobileAds}. */
public class FlutterMobileAdsWrapper {

  public FlutterMobileAdsWrapper() {}

  /** Initializes the sdk. */
  public void initialize(
      @NonNull Context context, @NonNull OnInitializationCompleteListener listener) {
    MobileAds.initialize(context, listener);
  }

  /** Wrapper for setAppMuted. */
  public void setAppMuted(boolean muted) {
    MobileAds.setAppMuted(muted);
  }

  /** Wrapper for setAppVolume. */
  public void setAppVolume(double volume) {
    MobileAds.setAppVolume((float) volume);
  }

  /** Wrapper for disableMediationInitialization. */
  public void disableMediationInitialization(@NonNull Context context) {
    MobileAds.disableMediationAdapterInitialization(context);
  }

  /** Wrapper for getVersionString. */
  public String getVersionString() {
    return MobileAds.getVersion().toString();
  }

  /** Wrapper for getRequestConfiguration. */
  public RequestConfiguration getRequestConfiguration() {
    return MobileAds.getRequestConfiguration();
  }

  /** Wrapper for openDebugMenu. */
  public void openDebugMenu(Context context, String adUnitId) {
    MobileAds.openDebugMenu(context, adUnitId);
  }

  /** Open the ad inspector. */
  public void openAdInspector(Context context, OnAdInspectorClosedListener listener) {
    MobileAds.openAdInspector(context, listener);
  }
}
