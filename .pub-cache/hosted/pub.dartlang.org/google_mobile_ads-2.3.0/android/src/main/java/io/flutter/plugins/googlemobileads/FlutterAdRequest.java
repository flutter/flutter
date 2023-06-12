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
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import com.google.ads.mediation.admob.AdMobAdapter;
import com.google.android.gms.ads.AdRequest;
import com.google.android.gms.ads.mediation.MediationExtrasReceiver;
import com.google.errorprone.annotations.CanIgnoreReturnValue;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Map.Entry;
import java.util.Objects;

class FlutterAdRequest {
  @Nullable private final List<String> keywords;
  @Nullable private final String contentUrl;
  @Nullable private final Boolean nonPersonalizedAds;
  @Nullable private final List<String> neighboringContentUrls;
  @Nullable private final Integer httpTimeoutMillis;
  @Nullable private final String mediationExtrasIdentifier;
  @Nullable private final MediationNetworkExtrasProvider mediationNetworkExtrasProvider;
  @Nullable private final Map<String, String> adMobExtras;
  @NonNull private final String requestAgent;

  protected static class Builder {
    @Nullable private List<String> keywords;
    @Nullable private String contentUrl;
    @Nullable private Boolean nonPersonalizedAds;
    @Nullable private List<String> neighboringContentUrls;
    @Nullable private Integer httpTimeoutMillis;
    @Nullable private String mediationExtrasIdentifier;
    @Nullable private MediationNetworkExtrasProvider mediationNetworkExtrasProvider;
    @Nullable private Map<String, String> adMobExtras;
    @NonNull private String requestAgent;

    @CanIgnoreReturnValue
    Builder setRequestAgent(String requestAgent) {
      this.requestAgent = requestAgent;
      return this;
    }

    @CanIgnoreReturnValue
    Builder setKeywords(@Nullable List<String> keywords) {
      this.keywords = keywords;
      return this;
    }

    @CanIgnoreReturnValue
    Builder setContentUrl(@Nullable String contentUrl) {
      this.contentUrl = contentUrl;
      return this;
    }

    @CanIgnoreReturnValue
    Builder setNonPersonalizedAds(@Nullable Boolean nonPersonalizedAds) {
      this.nonPersonalizedAds = nonPersonalizedAds;
      return this;
    }

    @CanIgnoreReturnValue
    Builder setNeighboringContentUrls(@Nullable List<String> neighboringContentUrls) {
      this.neighboringContentUrls = neighboringContentUrls;
      return this;
    }

    @CanIgnoreReturnValue
    Builder setHttpTimeoutMillis(@Nullable Integer httpTimeoutMillis) {
      this.httpTimeoutMillis = httpTimeoutMillis;
      return this;
    }

    @CanIgnoreReturnValue
    Builder setMediationNetworkExtrasIdentifier(@Nullable String mediationExtrasIdentifier) {
      this.mediationExtrasIdentifier = mediationExtrasIdentifier;
      return this;
    }

    @CanIgnoreReturnValue
    Builder setMediationNetworkExtrasProvider(
        @Nullable MediationNetworkExtrasProvider mediationNetworkExtrasProvider) {
      this.mediationNetworkExtrasProvider = mediationNetworkExtrasProvider;
      return this;
    }

    @CanIgnoreReturnValue
    Builder setAdMobExtras(@Nullable Map<String, String> adMobExtras) {
      this.adMobExtras = adMobExtras;
      return this;
    }

    @Nullable
    protected List<String> getKeywords() {
      return keywords;
    }

    @Nullable
    protected String getContentUrl() {
      return contentUrl;
    }

    @Nullable
    protected Boolean getNonPersonalizedAds() {
      return nonPersonalizedAds;
    }

    @Nullable
    protected List<String> getNeighboringContentUrls() {
      return neighboringContentUrls;
    }

    @Nullable
    protected Integer getHttpTimeoutMillis() {
      return httpTimeoutMillis;
    }

    @Nullable
    protected String getMediationExtrasIdentifier() {
      return mediationExtrasIdentifier;
    }

    @Nullable
    protected MediationNetworkExtrasProvider getMediationNetworkExtrasProvider() {
      return mediationNetworkExtrasProvider;
    }

    @Nullable
    protected Map<String, String> getAdMobExtras() {
      return adMobExtras;
    }

    @NonNull
    protected String getRequestAgent() {
      return requestAgent;
    }

    FlutterAdRequest build() {
      return new FlutterAdRequest(
          keywords,
          contentUrl,
          nonPersonalizedAds,
          neighboringContentUrls,
          httpTimeoutMillis,
          mediationExtrasIdentifier,
          mediationNetworkExtrasProvider,
          adMobExtras,
          requestAgent);
    }
  }

  protected FlutterAdRequest(
      @Nullable List<String> keywords,
      @Nullable String contentUrl,
      @Nullable Boolean nonPersonalizedAds,
      @Nullable List<String> neighboringContentUrls,
      @Nullable Integer httpTimeoutMillis,
      @Nullable String mediationExtrasIdentifier,
      @Nullable MediationNetworkExtrasProvider mediationNetworkExtrasProvider,
      @Nullable Map<String, String> adMobExtras,
      String requestAgent) {
    this.keywords = keywords;
    this.contentUrl = contentUrl;
    this.nonPersonalizedAds = nonPersonalizedAds;
    this.neighboringContentUrls = neighboringContentUrls;
    this.httpTimeoutMillis = httpTimeoutMillis;
    this.mediationExtrasIdentifier = mediationExtrasIdentifier;
    this.mediationNetworkExtrasProvider = mediationNetworkExtrasProvider;
    this.adMobExtras = adMobExtras;
    this.requestAgent = requestAgent;
  }

  /** Adds network extras to the ad request builder, if any. */
  private void addNetworkExtras(AdRequest.Builder builder, String adUnitId) {
    Map<Class<? extends MediationExtrasReceiver>, Bundle> networkExtras = new HashMap<>();
    if (mediationNetworkExtrasProvider != null) {
      Map<Class<? extends MediationExtrasReceiver>, Bundle> providedExtras =
          mediationNetworkExtrasProvider.getMediationExtras(adUnitId, mediationExtrasIdentifier);
      networkExtras.putAll(providedExtras);
    }

    if (adMobExtras != null && !adMobExtras.isEmpty()) {
      Bundle adMobBundle = new Bundle();
      for (Map.Entry<String, String> extra : adMobExtras.entrySet()) {
        adMobBundle.putString(extra.getKey(), extra.getValue());
      }
      networkExtras.put(AdMobAdapter.class, adMobBundle);
    }

    if (nonPersonalizedAds != null && nonPersonalizedAds) {
      Bundle adMobBundle = networkExtras.get(AdMobAdapter.class);
      if (adMobBundle == null) {
        adMobBundle = new Bundle();
      }
      adMobBundle.putString("npa", "1");
      networkExtras.put(AdMobAdapter.class, adMobBundle);
    }

    for (Entry<Class<? extends MediationExtrasReceiver>, Bundle> entry : networkExtras.entrySet()) {
      builder.addNetworkExtrasBundle(entry.getKey(), entry.getValue());
    }
  }

  /** Updates the {@link AdRequest.Builder} with the properties in this {@link FlutterAdRequest}. */
  protected AdRequest.Builder updateAdRequestBuilder(AdRequest.Builder builder, String adUnitId) {
    if (keywords != null) {
      for (final String keyword : keywords) {
        builder.addKeyword(keyword);
      }
    }
    if (contentUrl != null) {
      builder.setContentUrl(contentUrl);
    }
    addNetworkExtras(builder, adUnitId);
    if (neighboringContentUrls != null) {
      builder.setNeighboringContentUrls(neighboringContentUrls);
    }
    if (httpTimeoutMillis != null) {
      builder.setHttpTimeoutMillis(httpTimeoutMillis);
    }
    builder.setRequestAgent(requestAgent);
    return builder;
  }

  AdRequest asAdRequest(String adUnitId) {
    return updateAdRequestBuilder(new AdRequest.Builder(), adUnitId).build();
  }

  @Nullable
  protected List<String> getKeywords() {
    return keywords;
  }

  @Nullable
  protected String getContentUrl() {
    return contentUrl;
  }

  @Nullable
  protected Boolean getNonPersonalizedAds() {
    return nonPersonalizedAds;
  }

  @Nullable
  protected List<String> getNeighboringContentUrls() {
    return neighboringContentUrls;
  }

  @Nullable
  protected Integer getHttpTimeoutMillis() {
    return httpTimeoutMillis;
  }

  @Nullable
  protected String getMediationExtrasIdentifier() {
    return mediationExtrasIdentifier;
  }

  @Nullable
  protected Map<String, String> getAdMobExtras() {
    return adMobExtras;
  }

  @NonNull
  protected String getRequestAgent() {
    return requestAgent;
  }

  @Override
  public boolean equals(Object o) {
    if (this == o) {
      return true;
    } else if (!(o instanceof FlutterAdRequest)) {
      return false;
    }

    FlutterAdRequest request = (FlutterAdRequest) o;
    return Objects.equals(keywords, request.keywords)
        && Objects.equals(contentUrl, request.contentUrl)
        && Objects.equals(nonPersonalizedAds, request.nonPersonalizedAds)
        && Objects.equals(neighboringContentUrls, request.neighboringContentUrls)
        && Objects.equals(httpTimeoutMillis, request.httpTimeoutMillis)
        && Objects.equals(mediationExtrasIdentifier, request.mediationExtrasIdentifier)
        && Objects.equals(mediationNetworkExtrasProvider, request.mediationNetworkExtrasProvider)
        && Objects.equals(adMobExtras, request.adMobExtras);
  }

  @Override
  public int hashCode() {
    return Objects.hash(
        keywords,
        contentUrl,
        nonPersonalizedAds,
        neighboringContentUrls,
        httpTimeoutMillis,
        mediationExtrasIdentifier,
        mediationNetworkExtrasProvider);
  }
}
