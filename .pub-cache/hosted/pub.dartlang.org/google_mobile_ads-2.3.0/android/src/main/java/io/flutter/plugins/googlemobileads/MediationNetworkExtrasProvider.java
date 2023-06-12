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

import android.os.Bundle;
import androidx.annotation.Nullable;
import com.google.android.gms.ads.mediation.MediationExtrasReceiver;
import io.flutter.embedding.engine.FlutterEngine;
import java.util.Map;

/**
 * Provides network specific parameters when constructing an ad request.
 *
 * <p>After you register a {@code MediationNetworkExtrasProvider} using {@link
 * GoogleMobileAdsPlugin#registerMediationNetworkExtrasProvider(FlutterEngine,
 * MediationNetworkExtrasProvider)}, the plugin will use it to pass extras when constructing ad
 * requests.
 */
public interface MediationNetworkExtrasProvider {

  /**
   * Gets mediation extras that should be included for an ad request with the {@code adUnitId} and
   * {@code identifier}, as a map from adapter classes to their corresponding extras bundle. You can
   * refer to each network's <a
   * href="https://developers.google.com/admob/android/mediation/applovin#network-specific_parameters">documentation</a>
   * to see how to find the corresponding adapter class and create its extras. This will be called
   * whenever the plugin creates an ad request.
   *
   * @param adUnitId The ad unit for the associated ad request.
   * @param identifier An optional identifier that comes from the associated dart ad request object.
   *     This allows for additional control of which extras to include for an ad request, beyond
   *     just the ad unit.
   * @return A map of mediation adapter classes to their extras that should be included in the ad
   *     request. If {@code null} is returned then no extras are added.
   */
  @Nullable
  Map<Class<? extends MediationExtrasReceiver>, Bundle> getMediationExtras(
      String adUnitId, @Nullable String identifier);
}
