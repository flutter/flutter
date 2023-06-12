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
import com.google.android.gms.ads.AdValue;
import com.google.android.gms.ads.OnPaidEventListener;

/** Implementation of {@link OnPaidEventListener} that sends events to {@link AdInstanceManager}. */
public class FlutterPaidEventListener implements OnPaidEventListener {
  @NonNull private final AdInstanceManager manager;
  @NonNull private final FlutterAd ad;

  FlutterPaidEventListener(@NonNull AdInstanceManager manager, @NonNull FlutterAd ad) {
    this.manager = manager;
    this.ad = ad;
  }

  @Override
  public void onPaidEvent(AdValue adValue) {
    FlutterAdValue value =
        new FlutterAdValue(
            adValue.getPrecisionType(), adValue.getCurrencyCode(), adValue.getValueMicros());
    manager.onPaidEvent(ad, value);
  }
}
