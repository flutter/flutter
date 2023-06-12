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

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertNotNull;
import static org.junit.Assert.assertNull;
import static org.junit.Assert.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.doReturn;
import static org.mockito.Mockito.mock;

import android.content.Context;
import com.google.android.gms.ads.AdSize;
import com.google.android.gms.ads.RequestConfiguration;
import io.flutter.plugins.googlemobileads.FlutterAd.FlutterAdapterResponseInfo;
import io.flutter.plugins.googlemobileads.FlutterAd.FlutterResponseInfo;
import io.flutter.plugins.googlemobileads.FlutterAdSize.AdSizeFactory;
import io.flutter.plugins.googlemobileads.FlutterAdSize.AnchoredAdaptiveBannerAdSize;
import io.flutter.plugins.googlemobileads.FlutterAdSize.InlineAdaptiveBannerAdSize;
import java.nio.ByteBuffer;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;
import java.util.Map;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.RobolectricTestRunner;

/** Tests for {@link AdMessageCodec}. */
@RunWith(RobolectricTestRunner.class)
public class AdMessageCodecTest {
  AdMessageCodec codec;
  AdSizeFactory mockAdSizeFactory;
  FlutterRequestAgentProvider mockFlutterRequestAgentProvider;

  @Before
  public void setup() {
    mockAdSizeFactory = mock(AdSizeFactory.class);
    mockFlutterRequestAgentProvider = mock(FlutterRequestAgentProvider.class);
    codec =
        new AdMessageCodec(mock(Context.class), mockAdSizeFactory, mockFlutterRequestAgentProvider);
  }

  @Test
  public void encodeAdapterInitializationState() {
    final ByteBuffer message =
        codec.encodeMessage(FlutterAdapterStatus.AdapterInitializationState.NOT_READY);

    assertEquals(
        codec.decodeMessage((ByteBuffer) message.position(0)),
        FlutterAdapterStatus.AdapterInitializationState.NOT_READY);
  }

  @Test
  public void encodeAdapterStatus() {
    final ByteBuffer message =
        codec.encodeMessage(
            new FlutterAdapterStatus(
                FlutterAdapterStatus.AdapterInitializationState.READY, "desc", 24));

    final FlutterAdapterStatus result =
        (FlutterAdapterStatus) codec.decodeMessage((ByteBuffer) message.position(0));
    assertEquals(
        result,
        new FlutterAdapterStatus(
            FlutterAdapterStatus.AdapterInitializationState.READY, "desc", 24));
  }

  @Test
  public void encodeInitializationStatus() {
    final ByteBuffer message =
        codec.encodeMessage(
            new FlutterInitializationStatus(
                Collections.singletonMap(
                    "table",
                    new FlutterAdapterStatus(
                        FlutterAdapterStatus.AdapterInitializationState.NOT_READY,
                        "desc",
                        56.66))));

    final FlutterInitializationStatus initStatus =
        (FlutterInitializationStatus) codec.decodeMessage((ByteBuffer) message.position(0));
    assertEquals(initStatus.adapterStatuses.size(), 1);
    final FlutterAdapterStatus adapterStatus = initStatus.adapterStatuses.get("table");
    assertEquals(
        adapterStatus,
        new FlutterAdapterStatus(
            FlutterAdapterStatus.AdapterInitializationState.NOT_READY, "desc", 56.66));
  }

  @Test
  public void decodeServerSideVerificationOptions() {
    FlutterServerSideVerificationOptions options =
        new FlutterServerSideVerificationOptions("user-id", "custom-data");

    ByteBuffer message = codec.encodeMessage(options);

    FlutterServerSideVerificationOptions decodedOptions =
        (FlutterServerSideVerificationOptions)
            codec.decodeMessage((ByteBuffer) message.position(0));
    assertEquals(decodedOptions, options);

    // With userId = null.
    options = new FlutterServerSideVerificationOptions(null, "custom-data");
    message = codec.encodeMessage(options);
    decodedOptions =
        (FlutterServerSideVerificationOptions)
            codec.decodeMessage((ByteBuffer) message.position(0));
    assertEquals(decodedOptions, options);

    // With customData = null.
    options = new FlutterServerSideVerificationOptions("user-Id", null);
    message = codec.encodeMessage(options);
    decodedOptions =
        (FlutterServerSideVerificationOptions)
            codec.decodeMessage((ByteBuffer) message.position(0));
    assertEquals(decodedOptions, options);

    // With userId and customData = null.
    options = new FlutterServerSideVerificationOptions(null, null);
    message = codec.encodeMessage(options);
    decodedOptions =
        (FlutterServerSideVerificationOptions)
            codec.decodeMessage((ByteBuffer) message.position(0));
    assertEquals(decodedOptions, options);
  }

  @Test
  public void encodeAnchoredAdaptiveBannerAdSize() {
    AdSize mockAdSize = mock(AdSize.class);
    doReturn(mockAdSize)
        .when(mockAdSizeFactory)
        .getPortraitAnchoredAdaptiveBannerAdSize(any(Context.class), anyInt());

    doReturn(mockAdSize)
        .when(mockAdSizeFactory)
        .getLandscapeAnchoredAdaptiveBannerAdSize(any(Context.class), anyInt());

    doReturn(mockAdSize)
        .when(mockAdSizeFactory)
        .getCurrentOrientationAnchoredAdaptiveBannerAdSize(any(Context.class), anyInt());

    final AnchoredAdaptiveBannerAdSize portraitAnchoredAdaptiveAdSize =
        new AnchoredAdaptiveBannerAdSize(mock(Context.class), mockAdSizeFactory, "portrait", 23);
    final ByteBuffer portraitData = codec.encodeMessage(portraitAnchoredAdaptiveAdSize);

    final AnchoredAdaptiveBannerAdSize portraitResult =
        (AnchoredAdaptiveBannerAdSize) codec.decodeMessage((ByteBuffer) portraitData.position(0));
    assertEquals(portraitResult.size, mockAdSize);

    final AnchoredAdaptiveBannerAdSize landscapeAnchoredAdaptiveAdSize =
        new AnchoredAdaptiveBannerAdSize(mock(Context.class), mockAdSizeFactory, "landscape", 34);
    final ByteBuffer landscapeData = codec.encodeMessage(landscapeAnchoredAdaptiveAdSize);

    final AnchoredAdaptiveBannerAdSize landscapeResult =
        (AnchoredAdaptiveBannerAdSize) codec.decodeMessage((ByteBuffer) landscapeData.position(0));
    assertEquals(landscapeResult.size, mockAdSize);

    final AnchoredAdaptiveBannerAdSize anchoredAdaptiveAdSize =
        new AnchoredAdaptiveBannerAdSize(mock(Context.class), mockAdSizeFactory, null, 45);
    final ByteBuffer data = codec.encodeMessage(anchoredAdaptiveAdSize);

    final AnchoredAdaptiveBannerAdSize result =
        (AnchoredAdaptiveBannerAdSize) codec.decodeMessage((ByteBuffer) data.position(0));
    assertEquals(result.size, mockAdSize);
  }

  @Test
  public void encodeSmartBannerAdSize() {
    final ByteBuffer data = codec.encodeMessage(new FlutterAdSize.SmartBannerAdSize());

    final FlutterAdSize.SmartBannerAdSize result =
        (FlutterAdSize.SmartBannerAdSize) codec.decodeMessage((ByteBuffer) data.position(0));
    assertEquals(result.size, AdSize.SMART_BANNER);
  }

  @Test
  public void encodeFluidAdSize() {
    final ByteBuffer data = codec.encodeMessage(new FlutterAdSize.FluidAdSize());

    final FlutterAdSize.FluidAdSize result =
        (FlutterAdSize.FluidAdSize) codec.decodeMessage((ByteBuffer) data.position(0));
    assertEquals(result.size, AdSize.FLUID);
  }

  @Test
  public void nativeAdOptionsNull() {
    final ByteBuffer data =
        codec.encodeMessage(new FlutterNativeAdOptions(null, null, null, null, null, null));

    final FlutterNativeAdOptions result =
        (FlutterNativeAdOptions) codec.decodeMessage((ByteBuffer) data.position(0));
    assertNull(result.adChoicesPlacement);
    assertNull(result.mediaAspectRatio);
    assertNull(result.videoOptions);
    assertNull(result.requestCustomMuteThisAd);
    assertNull(result.shouldRequestMultipleImages);
    assertNull(result.shouldReturnUrlsForImageAssets);
  }

  @Test
  public void nativeAdOptions() {
    FlutterVideoOptions videoOptions = new FlutterVideoOptions(true, false, true);

    final ByteBuffer data =
        codec.encodeMessage(new FlutterNativeAdOptions(1, 2, videoOptions, false, true, false));

    final FlutterNativeAdOptions result =
        (FlutterNativeAdOptions) codec.decodeMessage((ByteBuffer) data.position(0));
    assertEquals(result.adChoicesPlacement, (Integer) 1);
    assertEquals(result.mediaAspectRatio, (Integer) 2);
    assertEquals(result.videoOptions.clickToExpandRequested, true);
    assertEquals(result.videoOptions.customControlsRequested, false);
    assertEquals(result.videoOptions.startMuted, true);
    assertFalse(result.requestCustomMuteThisAd);
    assertTrue(result.shouldRequestMultipleImages);
    assertFalse(result.shouldReturnUrlsForImageAssets);
  }

  @Test
  public void videoOptionsNull() {
    final ByteBuffer data = codec.encodeMessage(new FlutterVideoOptions(null, null, null));

    final FlutterVideoOptions result =
        (FlutterVideoOptions) codec.decodeMessage((ByteBuffer) data.position(0));
    assertNull(result.clickToExpandRequested);
    assertNull(result.customControlsRequested);
    assertNull(result.startMuted);
  }

  public void encodeEmptyFlutterAdRequest() {
    FlutterAdRequest adRequest = new FlutterAdRequest.Builder().build();
    final ByteBuffer message = codec.encodeMessage(adRequest);

    final FlutterAdRequest decodedRequest =
        (FlutterAdRequest) codec.decodeMessage((ByteBuffer) message.position(0));
    assertEquals(adRequest, decodedRequest);
  }

  public void encodeEmptyFlutterAdManagerAdRequest() {
    FlutterAdManagerAdRequest adRequest = new FlutterAdManagerAdRequest.Builder().build();
    final ByteBuffer message = codec.encodeMessage(adRequest);

    final FlutterAdManagerAdRequest decodedRequest =
        (FlutterAdManagerAdRequest) codec.decodeMessage((ByteBuffer) message.position(0));
    assertEquals(adRequest, decodedRequest);
  }

  @Test
  public void encodeFlutterAdRequest() {
    Map<String, String> extras = Collections.singletonMap("key", "value");
    FlutterAdRequest adRequest =
        new FlutterAdRequest.Builder()
            .setKeywords(Arrays.asList("1", "2", "3"))
            .setContentUrl("contentUrl")
            .setNonPersonalizedAds(false)
            .setNeighboringContentUrls(Arrays.asList("example.com", "test.com"))
            .setHttpTimeoutMillis(1000)
            .setMediationNetworkExtrasIdentifier("identifier")
            .setAdMobExtras(extras)
            .build();
    final ByteBuffer message = codec.encodeMessage(adRequest);

    final FlutterAdRequest decodedRequest =
        (FlutterAdRequest) codec.decodeMessage((ByteBuffer) message.position(0));
    assertEquals(adRequest, decodedRequest);
  }

  @Test
  public void encodeFlutterAdManagerAdRequest() {
    doReturn("mock-request-agent").when(mockFlutterRequestAgentProvider).getRequestAgent();
    FlutterAdManagerAdRequest.Builder builder = new FlutterAdManagerAdRequest.Builder();
    builder.setKeywords(Arrays.asList("1", "2", "3"));
    builder.setContentUrl("contentUrl");
    builder.setCustomTargeting(Collections.singletonMap("apple", "banana"));
    builder.setCustomTargetingLists(
        Collections.singletonMap("cherry", Collections.singletonList("pie")));
    builder.setNonPersonalizedAds(true);
    builder.setPublisherProvidedId("pub-provided-id");
    builder.setMediationNetworkExtrasIdentifier("identifier");
    builder.setAdMobExtras(Collections.singletonMap("key", "value"));

    FlutterAdManagerAdRequest flutterAdManagerAdRequest = builder.build();

    final ByteBuffer message = codec.encodeMessage(flutterAdManagerAdRequest);
    FlutterAdManagerAdRequest decodedAdRequest =
        (FlutterAdManagerAdRequest) codec.decodeMessage((ByteBuffer) message.position(0));
    assertEquals(decodedAdRequest, flutterAdManagerAdRequest);
    assertEquals(decodedAdRequest.getRequestAgent(), "mock-request-agent");
  }

  @Test
  public void encodeFlutterAdSize() {
    final ByteBuffer message = codec.encodeMessage(new FlutterAdSize(1, 2));

    assertEquals(codec.decodeMessage((ByteBuffer) message.position(0)), new FlutterAdSize(1, 2));
  }

  @Test
  public void encodeFlutterRewardItem() {
    final ByteBuffer message =
        codec.encodeMessage(new FlutterRewardedAd.FlutterRewardItem(23, "coins"));

    assertEquals(
        codec.decodeMessage((ByteBuffer) message.position(0)),
        new FlutterRewardedAd.FlutterRewardItem(23, "coins"));
  }

  @Test
  public void encodeFlutterResponseInfo() {
    List<FlutterAdapterResponseInfo> adapterResponseInfos = new ArrayList<>();
    Map<String, String> adUnitMapping = Collections.singletonMap("key", "value");
    adapterResponseInfos.add(
        new FlutterAdapterResponseInfo(
            "adapter-class",
            9999,
            "description",
            adUnitMapping,
            null,
            "adSourceName",
            "adSourceId",
            "adSourceInstanceName",
            "adSourceInstanceId"));
    FlutterAdapterResponseInfo loadedAdapterResponseInfo =
        new FlutterAdapterResponseInfo(
            "loaded-adapter-class",
            1234,
            "description",
            adUnitMapping,
            null,
            "adSourceName",
            "adSourceId",
            "adSourceInstanceName",
            "adSourceInstanceId");
    Map<String, String> responseExtras = Collections.singletonMap("key", "value");
    FlutterResponseInfo info =
        new FlutterResponseInfo(
            "responseId",
            "className",
            adapterResponseInfos,
            loadedAdapterResponseInfo,
            responseExtras);
    final ByteBuffer message =
        codec.encodeMessage(new FlutterBannerAd.FlutterLoadAdError(1, "domain", "message", info));

    final FlutterAd.FlutterLoadAdError error =
        (FlutterAd.FlutterLoadAdError) codec.decodeMessage((ByteBuffer) message.position(0));
    assertNotNull(error);
    assertEquals(error.code, 1);
    assertEquals(error.domain, "domain");
    assertEquals(error.message, "message");
    assertEquals(error.responseInfo, info);
  }

  public void encodeInlineAdaptiveBanner() {
    AdSize adSize = new AdSize(100, 101);
    doReturn(adSize)
        .when(mockAdSizeFactory)
        .getCurrentOrientationInlineAdaptiveBannerAdSize(any(Context.class), eq(100));

    InlineAdaptiveBannerAdSize size =
        new InlineAdaptiveBannerAdSize(mockAdSizeFactory, mock(Context.class), 100, null, null);
    final ByteBuffer data = codec.encodeMessage(size);
    final InlineAdaptiveBannerAdSize result =
        (InlineAdaptiveBannerAdSize) codec.decodeMessage((ByteBuffer) data.position(0));

    assertEquals(result.width, 100);
    assertNull(result.maxHeight);
    assertNull(result.orientation);
  }

  public void encodeRequestConfiguration() {
    RequestConfiguration.Builder requestConfigurationBuilder = new RequestConfiguration.Builder();
    requestConfigurationBuilder.setMaxAdContentRating(
        RequestConfiguration.MAX_AD_CONTENT_RATING_MA);
    requestConfigurationBuilder.setTagForChildDirectedTreatment(
        RequestConfiguration.TAG_FOR_CHILD_DIRECTED_TREATMENT_TRUE);
    requestConfigurationBuilder.setTagForUnderAgeOfConsent(
        RequestConfiguration.TAG_FOR_UNDER_AGE_OF_CONSENT_FALSE);
    requestConfigurationBuilder.setTestDeviceIds(Arrays.asList("test-device-id"));
    RequestConfiguration requestConfiguration = requestConfigurationBuilder.build();

    final ByteBuffer data = codec.encodeMessage(requestConfiguration);
    final RequestConfiguration result =
        (RequestConfiguration) codec.decodeMessage((ByteBuffer) data.position(0));

    assertEquals(result.getMaxAdContentRating(), RequestConfiguration.MAX_AD_CONTENT_RATING_MA);
    assertEquals(
        result.getTagForChildDirectedTreatment(),
        RequestConfiguration.TAG_FOR_CHILD_DIRECTED_TREATMENT_TRUE);
    assertEquals(
        result.getTagForUnderAgeOfConsent(),
        RequestConfiguration.TAG_FOR_UNDER_AGE_OF_CONSENT_FALSE);
    assertEquals(result.getTestDeviceIds(), Arrays.asList("test-device-id"));
  }
}
