// Copyright 2022 Google LLC
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

package io.flutter.plugins.googlemobileads.usermessagingplatform;

import android.content.Context;
import androidx.annotation.Nullable;
import com.google.android.ump.ConsentDebugSettings;
import java.util.List;
import java.util.Objects;

/** Wrapper for {@link ConsentDebugSettings}. */
class ConsentDebugSettingsWrapper {

  @Nullable private final Integer debugGeography;

  @Nullable private final List<String> testIdentifiers;

  ConsentDebugSettingsWrapper(
      @Nullable Integer debugGeography, @Nullable List<String> testIdentifiers) {
    this.debugGeography = debugGeography;
    this.testIdentifiers = testIdentifiers;
  }

  @Nullable
  Integer getDebugGeography() {
    return debugGeography;
  }

  @Nullable
  List<String> getTestIdentifiers() {
    return testIdentifiers;
  }

  /** Get the corresponding {@link ConsentDebugSettings}. */
  ConsentDebugSettings getAsConsentDebugSettings(Context context) {
    ConsentDebugSettings.Builder builder = new ConsentDebugSettings.Builder(context);
    if (debugGeography != null) {
      builder.setDebugGeography(debugGeography);
    }
    if (testIdentifiers != null) {
      for (String testIdentifier : testIdentifiers) {
        builder.addTestDeviceHashedId(testIdentifier);
      }
    }
    return builder.build();
  }

  @Override
  public boolean equals(@Nullable Object obj) {
    if (obj == this) {
      return true;
    } else if (!(obj instanceof ConsentDebugSettingsWrapper)) {
      return false;
    }

    ConsentDebugSettingsWrapper other = (ConsentDebugSettingsWrapper) obj;
    return Objects.equals(debugGeography, other.getDebugGeography())
        && Objects.equals(testIdentifiers, other.getTestIdentifiers());
  }

  @Override
  public int hashCode() {
    return Objects.hash(debugGeography, testIdentifiers);
  }
}
