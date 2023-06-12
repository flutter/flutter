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
import com.google.android.ump.ConsentRequestParameters;
import java.util.Objects;

/** Wrapper for {@link ConsentRequestParameters}. */
class ConsentRequestParametersWrapper {

  @Nullable private final Boolean tfuac;

  @Nullable private final ConsentDebugSettingsWrapper debugSettings;

  ConsentRequestParametersWrapper(
      @Nullable Boolean tfuac, @Nullable ConsentDebugSettingsWrapper debugSettings) {
    this.tfuac = tfuac;
    this.debugSettings = debugSettings;
  }

  @Nullable
  Boolean getTfuac() {
    return tfuac;
  }

  @Nullable
  ConsentDebugSettingsWrapper getDebugSettings() {
    return debugSettings;
  }

  /** Get as {@link ConsentRequestParameters}. */
  ConsentRequestParameters getAsConsentRequestParameters(Context context) {
    ConsentRequestParameters.Builder builder = new ConsentRequestParameters.Builder();
    if (tfuac != null) {
      builder.setTagForUnderAgeOfConsent(tfuac);
    }
    if (debugSettings != null) {
      builder.setConsentDebugSettings(debugSettings.getAsConsentDebugSettings(context));
    }
    return builder.build();
  }

  @Override
  public boolean equals(@Nullable Object obj) {
    if (obj == this) {
      return true;
    } else if (!(obj instanceof ConsentRequestParametersWrapper)) {
      return false;
    }

    ConsentRequestParametersWrapper other = (ConsentRequestParametersWrapper) obj;
    return Objects.equals(tfuac, other.getTfuac())
        && Objects.equals(debugSettings, other.getDebugSettings());
  }

  @Override
  public int hashCode() {
    return Objects.hash(tfuac, debugSettings);
  }
}
