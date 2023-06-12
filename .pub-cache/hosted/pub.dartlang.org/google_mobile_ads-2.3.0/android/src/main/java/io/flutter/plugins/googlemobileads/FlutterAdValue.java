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

/** A wrapper for {@link com.google.android.gms.ads.AdValue}. */
public class FlutterAdValue {
  final int precisionType;
  @NonNull final String currencyCode;
  final long valueMicros;

  public FlutterAdValue(int precisionType, @NonNull String currencyCode, long valueMicros) {
    this.precisionType = precisionType;
    this.currencyCode = currencyCode;
    this.valueMicros = valueMicros;
  }
}
