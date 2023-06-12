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
import com.google.android.gms.ads.initialization.AdapterStatus;
import com.google.android.gms.ads.initialization.InitializationStatus;
import java.util.HashMap;
import java.util.Map;

/**
 * Wrapper around {@link com.google.android.gms.ads.initialization.InitializationStatus} for the
 * Flutter Google Mobile Ads Plugin.
 */
class FlutterInitializationStatus {
  @NonNull final Map<String, FlutterAdapterStatus> adapterStatuses;

  FlutterInitializationStatus(@NonNull Map<String, FlutterAdapterStatus> adapterStatuses) {
    this.adapterStatuses = adapterStatuses;
  }

  FlutterInitializationStatus(@NonNull InitializationStatus initializationStatus) {
    final HashMap<String, FlutterAdapterStatus> newStatusMap = new HashMap<>();
    final Map<String, AdapterStatus> adapterStatusMap = initializationStatus.getAdapterStatusMap();

    for (Map.Entry<String, AdapterStatus> status : adapterStatusMap.entrySet()) {
      newStatusMap.put(status.getKey(), new FlutterAdapterStatus(status.getValue()));
    }

    this.adapterStatuses = newStatusMap;
  }
}
