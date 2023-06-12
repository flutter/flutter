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
import com.google.android.gms.ads.AdError;
import com.google.android.gms.ads.AdapterResponseInfo;
import com.google.android.gms.ads.LoadAdError;
import com.google.android.gms.ads.ResponseInfo;
import io.flutter.plugin.platform.PlatformView;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;

abstract class FlutterAd {

  protected final int adId;

  FlutterAd(int adId) {
    this.adId = adId;
  }

  /** A {@link FlutterAd} that is overlaid on top of a running application. */
  abstract static class FlutterOverlayAd extends FlutterAd {
    abstract void show();

    abstract void setImmersiveMode(boolean immersiveModeEnabled);

    FlutterOverlayAd(int adId) {
      super(adId);
    }
  }

  /** A wrapper around {@link ResponseInfo}. */
  static class FlutterResponseInfo {

    @Nullable private final String responseId;
    @Nullable private final String mediationAdapterClassName;
    @NonNull private final List<FlutterAdapterResponseInfo> adapterResponses;
    @Nullable private final FlutterAdapterResponseInfo loadedAdapterResponseInfo;
    @NonNull private final Map<String, String> responseExtras;

    FlutterResponseInfo(@NonNull ResponseInfo responseInfo) {
      this.responseId = responseInfo.getResponseId();
      this.mediationAdapterClassName = responseInfo.getMediationAdapterClassName();
      final List<FlutterAdapterResponseInfo> adapterResponseInfos = new ArrayList<>();
      for (AdapterResponseInfo adapterInfo : responseInfo.getAdapterResponses()) {
        adapterResponseInfos.add(new FlutterAdapterResponseInfo(adapterInfo));
      }
      this.adapterResponses = adapterResponseInfos;
      if (responseInfo.getLoadedAdapterResponseInfo() != null) {
        this.loadedAdapterResponseInfo =
            new FlutterAdapterResponseInfo(responseInfo.getLoadedAdapterResponseInfo());
      } else {
        this.loadedAdapterResponseInfo = null;
      }
      Map<String, String> extras = new HashMap<>();
      if (responseInfo.getResponseExtras() != null) {
        for (String key : responseInfo.getResponseExtras().keySet()) {
          Object value = responseInfo.getResponseExtras().get(key);
          extras.put(key, value.toString());
        }
      }

      this.responseExtras = extras;
    }

    FlutterResponseInfo(
        @Nullable String responseId,
        @Nullable String mediationAdapterClassName,
        @NonNull List<FlutterAdapterResponseInfo> adapterResponseInfos,
        @Nullable FlutterAdapterResponseInfo loadedAdapterResponseInfo,
        @NonNull Map<String, String> responseExtras) {
      this.responseId = responseId;
      this.mediationAdapterClassName = mediationAdapterClassName;
      this.adapterResponses = adapterResponseInfos;
      this.loadedAdapterResponseInfo = loadedAdapterResponseInfo;
      this.responseExtras = responseExtras;
    }

    @Nullable
    String getResponseId() {
      return responseId;
    }

    @Nullable
    String getMediationAdapterClassName() {
      return mediationAdapterClassName;
    }

    @NonNull
    List<FlutterAdapterResponseInfo> getAdapterResponses() {
      return adapterResponses;
    }

    @Nullable
    FlutterAdapterResponseInfo getLoadedAdapterResponseInfo() {
      return loadedAdapterResponseInfo;
    }

    @NonNull
    Map<String, String> getResponseExtras() {
      return responseExtras;
    }

    @Override
    public boolean equals(@Nullable Object obj) {
      if (obj == this) {
        return true;
      } else if (!(obj instanceof FlutterResponseInfo)) {
        return false;
      }

      FlutterResponseInfo that = (FlutterResponseInfo) obj;
      return Objects.equals(responseId, that.responseId)
          && Objects.equals(mediationAdapterClassName, that.mediationAdapterClassName)
          && Objects.equals(adapterResponses, that.adapterResponses)
          && Objects.equals(loadedAdapterResponseInfo, that.loadedAdapterResponseInfo);
    }

    @Override
    public int hashCode() {
      return Objects.hash(
          responseId, mediationAdapterClassName, adapterResponses, loadedAdapterResponseInfo);
    }
  }

  /** A wrapper for {@link AdapterResponseInfo}. */
  static class FlutterAdapterResponseInfo {

    @NonNull private final String adapterClassName;
    private final long latencyMillis;
    @NonNull private final String description;
    @NonNull private final Map<String, String> adUnitMapping;
    @Nullable private FlutterAdError error;
    @NonNull private final String adSourceName;
    @NonNull private final String adSourceId;
    @NonNull private final String adSourceInstanceName;
    @NonNull private final String adSourceInstanceId;

    FlutterAdapterResponseInfo(@NonNull AdapterResponseInfo responseInfo) {
      this.adapterClassName = responseInfo.getAdapterClassName();
      this.latencyMillis = responseInfo.getLatencyMillis();
      this.description = responseInfo.toString();
      if (responseInfo.getCredentials() != null) {
        this.adUnitMapping = new HashMap<>();
        for (String key : responseInfo.getCredentials().keySet()) {
          adUnitMapping.put(key, responseInfo.getCredentials().get(key).toString());
        }
      } else {
        adUnitMapping = new HashMap<>();
      }
      if (responseInfo.getAdError() != null) {
        this.error = new FlutterAdError(responseInfo.getAdError());
      }
      adSourceName = responseInfo.getAdSourceName();
      adSourceId = responseInfo.getAdSourceId();
      adSourceInstanceName = responseInfo.getAdSourceInstanceName();
      adSourceInstanceId = responseInfo.getAdSourceInstanceId();
    }

    FlutterAdapterResponseInfo(
        @NonNull String adapterClassName,
        long latencyMillis,
        @NonNull String description,
        @NonNull Map<String, String> adUnitMapping,
        @Nullable FlutterAdError error,
        @NonNull String adSourceName,
        @NonNull String adSourceId,
        @NonNull String adSourceInstanceName,
        @NonNull String adSourceInstanceId) {
      this.adapterClassName = adapterClassName;
      this.latencyMillis = latencyMillis;
      this.description = description;
      this.adUnitMapping = adUnitMapping;
      this.error = error;
      this.adSourceName = adSourceName;
      this.adSourceId = adSourceId;
      this.adSourceInstanceName = adSourceInstanceName;
      this.adSourceInstanceId = adSourceInstanceId;
    }

    @NonNull
    public String getAdapterClassName() {
      return adapterClassName;
    }

    public long getLatencyMillis() {
      return latencyMillis;
    }

    @NonNull
    public String getDescription() {
      return description;
    }

    @NonNull
    public Map<String, String> getAdUnitMapping() {
      return adUnitMapping;
    }

    @Nullable
    public FlutterAdError getError() {
      return error;
    }

    @NonNull
    public String getAdSourceName() {
      return adSourceName;
    }

    @NonNull
    public String getAdSourceId() {
      return adSourceId;
    }

    @NonNull
    public String getAdSourceInstanceName() {
      return adSourceInstanceName;
    }

    @NonNull
    public String getAdSourceInstanceId() {
      return adSourceInstanceId;
    }

    @Override
    public boolean equals(@Nullable Object obj) {
      if (obj == this) {
        return true;
      } else if (!(obj instanceof FlutterAdapterResponseInfo)) {
        return false;
      }

      final FlutterAdapterResponseInfo that = (FlutterAdapterResponseInfo) obj;
      return Objects.equals(adapterClassName, that.adapterClassName)
          && latencyMillis == that.latencyMillis
          && Objects.equals(description, that.description)
          && Objects.equals(error, that.error)
          && Objects.equals(adUnitMapping, that.adUnitMapping)
          && Objects.equals(adSourceName, that.adSourceName)
          && Objects.equals(adSourceId, that.adSourceId)
          && Objects.equals(adSourceInstanceName, that.adSourceInstanceName)
          && Objects.equals(adSourceInstanceId, that.adSourceInstanceId);
    }

    @Override
    public int hashCode() {
      return Objects.hash(
          adapterClassName,
          latencyMillis,
          description,
          error,
          adSourceName,
          adSourceId,
          adSourceInstanceName,
          adSourceInstanceId);
    }
  }

  /** Wrapper for {@link AdError}. */
  static class FlutterAdError {
    final int code;
    @NonNull final String domain;
    @NonNull final String message;

    FlutterAdError(@NonNull AdError error) {
      code = error.getCode();
      domain = error.getDomain();
      message = error.getMessage();
    }

    FlutterAdError(int code, @NonNull String domain, @NonNull String message) {
      this.code = code;
      this.domain = domain;
      this.message = message;
    }

    @Override
    public boolean equals(Object object) {
      if (this == object) {
        return true;
      } else if (!(object instanceof FlutterAdError)) {
        return false;
      }

      final FlutterAdError that = (FlutterAdError) object;

      if (code != that.code) {
        return false;
      } else if (!domain.equals(that.domain)) {
        return false;
      }
      return message.equals(that.message);
    }

    @Override
    public int hashCode() {
      return Objects.hash(code, domain, message);
    }
  }

  /** Wrapper for {@link LoadAdError}. */
  static class FlutterLoadAdError {
    final int code;
    @NonNull final String domain;
    @NonNull final String message;
    @Nullable FlutterResponseInfo responseInfo;

    FlutterLoadAdError(@NonNull LoadAdError error) {
      code = error.getCode();
      domain = error.getDomain();
      message = error.getMessage();

      if (error.getResponseInfo() != null) {
        responseInfo = new FlutterResponseInfo(error.getResponseInfo());
      }
    }

    FlutterLoadAdError(
        int code,
        @NonNull String domain,
        @NonNull String message,
        @Nullable FlutterResponseInfo responseInfo) {
      this.code = code;
      this.domain = domain;
      this.message = message;
      this.responseInfo = responseInfo;
    }

    @Override
    public boolean equals(Object object) {
      if (this == object) {
        return true;
      } else if (!(object instanceof FlutterLoadAdError)) {
        return false;
      }

      final FlutterLoadAdError that = (FlutterLoadAdError) object;

      if (code != that.code) {
        return false;
      } else if (!domain.equals(that.domain)) {
        return false;
      } else if (!Objects.equals(responseInfo, that.responseInfo)) {
        return false;
      }
      return message.equals(that.message);
    }

    @Override
    public int hashCode() {
      return Objects.hash(code, domain, message, responseInfo);
    }
  }

  abstract void load();

  /**
   * Gets the PlatformView for the ad. Default behavior is to return null. Should be overridden by
   * ads with platform views, such as banner and native ads.
   */
  @Nullable
  PlatformView getPlatformView() {
    return null;
  };

  /**
   * Invoked when dispose() is called on the corresponding Flutter ad object. This perform any
   * necessary cleanup.
   */
  abstract void dispose();
}
