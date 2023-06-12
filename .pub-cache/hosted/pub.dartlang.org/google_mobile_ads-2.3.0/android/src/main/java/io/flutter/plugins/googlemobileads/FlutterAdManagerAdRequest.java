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
import androidx.annotation.Nullable;
import com.google.android.gms.ads.admanager.AdManagerAdRequest;
import com.google.errorprone.annotations.CanIgnoreReturnValue;
import java.util.List;
import java.util.Map;
import java.util.Objects;

/**
 * Instantiates and serializes {@link com.google.android.gms.ads.admanager.AdManagerAdRequest} for
 * the Google Mobile Ads Plugin.
 */
class FlutterAdManagerAdRequest extends FlutterAdRequest {

  @Nullable private final Map<String, String> customTargeting;
  @Nullable private final Map<String, List<String>> customTargetingLists;
  @Nullable private final String publisherProvidedId;

  static class Builder extends FlutterAdRequest.Builder {

    @Nullable private Map<String, String> customTargeting;
    @Nullable private Map<String, List<String>> customTargetingLists;
    @Nullable private String publisherProvidedId;

    @CanIgnoreReturnValue
    public Builder setCustomTargeting(@Nullable Map<String, String> customTargeting) {
      this.customTargeting = customTargeting;
      return this;
    }

    @CanIgnoreReturnValue
    public Builder setCustomTargetingLists(
        @Nullable Map<String, List<String>> customTargetingLists) {
      this.customTargetingLists = customTargetingLists;
      return this;
    }

    @CanIgnoreReturnValue
    public Builder setPublisherProvidedId(@Nullable String publisherProvidedId) {
      this.publisherProvidedId = publisherProvidedId;
      return this;
    }

    @Override
    FlutterAdManagerAdRequest build() {
      return new FlutterAdManagerAdRequest(
          getKeywords(),
          getContentUrl(),
          customTargeting,
          customTargetingLists,
          getNonPersonalizedAds(),
          getNeighboringContentUrls(),
          getHttpTimeoutMillis(),
          publisherProvidedId,
          getMediationExtrasIdentifier(),
          getMediationNetworkExtrasProvider(),
          getAdMobExtras(),
          getRequestAgent());
    }
  }

  private FlutterAdManagerAdRequest(
      @Nullable List<String> keywords,
      @Nullable String contentUrl,
      @Nullable Map<String, String> customTargeting,
      @Nullable Map<String, List<String>> customTargetingLists,
      @Nullable Boolean nonPersonalizedAds,
      @Nullable List<String> neighboringContentUrls,
      @Nullable Integer httpTimeoutMillis,
      @Nullable String publisherProvidedId,
      @Nullable String mediationExtrasIdentifier,
      @Nullable MediationNetworkExtrasProvider mediationNetworkExtrasProvider,
      @Nullable Map<String, String> adMobExtras,
      @NonNull String requestAgent) {
    super(
        keywords,
        contentUrl,
        nonPersonalizedAds,
        neighboringContentUrls,
        httpTimeoutMillis,
        mediationExtrasIdentifier,
        mediationNetworkExtrasProvider,
        adMobExtras,
        requestAgent);
    this.customTargeting = customTargeting;
    this.customTargetingLists = customTargetingLists;
    this.publisherProvidedId = publisherProvidedId;
  }

  AdManagerAdRequest asAdManagerAdRequest(String adUnitId) {
    final AdManagerAdRequest.Builder builder = new AdManagerAdRequest.Builder();
    updateAdRequestBuilder(builder, adUnitId);

    if (customTargeting != null) {
      for (final Map.Entry<String, String> entry : customTargeting.entrySet()) {
        builder.addCustomTargeting(entry.getKey(), entry.getValue());
      }
    }
    if (customTargetingLists != null) {
      for (final Map.Entry<String, List<String>> entry : customTargetingLists.entrySet()) {
        builder.addCustomTargeting(entry.getKey(), entry.getValue());
      }
    }
    if (publisherProvidedId != null) {
      builder.setPublisherProvidedId(publisherProvidedId);
    }
    return builder.build();
  }

  @Nullable
  protected Map<String, String> getCustomTargeting() {
    return customTargeting;
  }

  @Nullable
  protected Map<String, List<String>> getCustomTargetingLists() {
    return customTargetingLists;
  }

  @Nullable
  protected String getPublisherProvidedId() {
    return publisherProvidedId;
  }

  @Override
  public boolean equals(Object o) {
    if (this == o) {
      return true;
    } else if (!(o instanceof FlutterAdManagerAdRequest)) {
      return false;
    }

    FlutterAdManagerAdRequest request = (FlutterAdManagerAdRequest) o;
    return super.equals(o)
        && Objects.equals(customTargeting, request.customTargeting)
        && Objects.equals(customTargetingLists, request.customTargetingLists);
  }

  @Override
  public int hashCode() {
    return Objects.hash(super.hashCode(), customTargeting, customTargetingLists);
  }
}
