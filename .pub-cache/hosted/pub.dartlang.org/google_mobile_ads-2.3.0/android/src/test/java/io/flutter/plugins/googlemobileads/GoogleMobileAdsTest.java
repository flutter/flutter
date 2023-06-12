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

import static org.hamcrest.Matchers.hasEntry;
import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertNotNull;
import static org.junit.Assert.assertNull;
import static org.junit.Assert.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.ArgumentMatchers.isNull;
import static org.mockito.Mockito.doAnswer;
import static org.mockito.Mockito.doReturn;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.spy;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;

import android.app.Activity;
import android.content.Context;
import android.os.Bundle;
import androidx.test.core.app.ApplicationProvider;
import com.google.android.gms.ads.AdError;
import com.google.android.gms.ads.AdInspectorError;
import com.google.android.gms.ads.AdSize;
import com.google.android.gms.ads.AdView;
import com.google.android.gms.ads.AdapterResponseInfo;
import com.google.android.gms.ads.OnAdInspectorClosedListener;
import com.google.android.gms.ads.RequestConfiguration;
import com.google.android.gms.ads.ResponseInfo;
import com.google.android.gms.ads.admanager.AdManagerAdView;
import com.google.android.gms.ads.initialization.InitializationStatus;
import com.google.android.gms.ads.initialization.OnInitializationCompleteListener;
import com.google.android.gms.ads.nativead.NativeAd;
import com.google.android.gms.ads.nativead.NativeAdView;
import io.flutter.embedding.engine.plugins.FlutterPlugin.FlutterPluginBinding;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.StandardMethodCodec;
import io.flutter.plugin.platform.PlatformViewRegistry;
import io.flutter.plugins.googlemobileads.FlutterAd.FlutterResponseInfo;
import java.nio.ByteBuffer;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import org.hamcrest.Matcher;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.mockito.ArgumentCaptor;
import org.mockito.ArgumentMatchers;
import org.mockito.invocation.InvocationOnMock;
import org.mockito.stubbing.Answer;
import org.robolectric.Robolectric;
import org.robolectric.RobolectricTestRunner;

/** Tests {@link AdInstanceManager}. */
@RunWith(RobolectricTestRunner.class)
public class GoogleMobileAdsTest {
  private AdInstanceManager testManager;
  private final FlutterAdRequest request = new FlutterAdRequest.Builder().build();
  private Activity mockActivity;
  private Context mockContext;
  private FlutterPluginBinding mockFlutterPluginBinding;
  private static BinaryMessenger mockMessenger;
  private static FlutterRequestAgentProvider mockFlutterRequestAgentProvider =
      mock(FlutterRequestAgentProvider.class);

  private static MethodCall getLastMethodCall() {
    Robolectric.flushForegroundThreadScheduler();
    final ArgumentCaptor<ByteBuffer> byteBufferCaptor = ArgumentCaptor.forClass(ByteBuffer.class);
    verify(mockMessenger)
        .send(
            eq("plugins.flutter.io/google_mobile_ads"),
            byteBufferCaptor.capture(),
            (BinaryMessenger.BinaryReply) isNull());

    return new StandardMethodCodec(new AdMessageCodec(null, mockFlutterRequestAgentProvider))
        .decodeMethodCall((ByteBuffer) byteBufferCaptor.getValue().position(0));
  }

  @Before
  public void setup() {
    mockMessenger = mock(BinaryMessenger.class);
    mockActivity = mock(Activity.class);
    doAnswer(
            new Answer() {
              @Override
              public Object answer(InvocationOnMock invocation) {
                Runnable runnable = invocation.getArgument(0);
                runnable.run();
                return null;
              }
            })
        .when(mockActivity)
        .runOnUiThread(ArgumentMatchers.any(Runnable.class));
    mockFlutterRequestAgentProvider = mock(FlutterRequestAgentProvider.class);
    MethodChannel methodChannel =
        new MethodChannel(
            mockMessenger,
            "plugins.flutter.io/google_mobile_ads",
            new StandardMethodCodec(
                new AdMessageCodec(mockActivity, mockFlutterRequestAgentProvider)));
    testManager = new AdInstanceManager(methodChannel);
    testManager.setActivity(mockActivity);
    mockContext = mock(Context.class);
    mockFlutterPluginBinding = mock(FlutterPluginBinding.class);
    doReturn(mockContext).when(mockFlutterPluginBinding).getApplicationContext();
  }

  @Test
  public void loadAd() {
    final FlutterBannerAd bannerAd =
        new FlutterBannerAd(
            1,
            testManager,
            "testId",
            request,
            new FlutterAdSize(1, 2),
            mock(BannerAdCreator.class));
    testManager.trackAd(bannerAd, 0);

    assertNotNull(testManager.adForId(0));
    assertEquals(bannerAd, testManager.adForId(0));
    assertEquals(0, testManager.adIdFor(bannerAd).intValue());
  }

  @Test
  public void disposeAd_banner() {
    FlutterBannerAd bannerAd = mock(FlutterBannerAd.class);

    testManager.trackAd(bannerAd, 2);
    assertNotNull(testManager.adForId(2));
    assertNotNull(testManager.adIdFor(bannerAd));
    testManager.disposeAd(2);
    verify(bannerAd).dispose();
    assertNull(testManager.adForId(2));
    assertNull(testManager.adIdFor(bannerAd));
  }

  @Test
  public void disposeAd_adManagerBanner() {
    FlutterAdManagerBannerAd adManagerBannerAd = mock(FlutterAdManagerBannerAd.class);

    testManager.trackAd(adManagerBannerAd, 2);
    assertNotNull(testManager.adForId(2));
    assertNotNull(testManager.adIdFor(adManagerBannerAd));
    testManager.disposeAd(2);
    verify(adManagerBannerAd).dispose();
    assertNull(testManager.adForId(2));
    assertNull(testManager.adIdFor(adManagerBannerAd));
  }

  @Test
  public void disposeAd_native() {
    FlutterNativeAd flutterNativeAd = mock(FlutterNativeAd.class);

    testManager.trackAd(flutterNativeAd, 2);
    assertNotNull(testManager.adForId(2));
    assertNotNull(testManager.adIdFor(flutterNativeAd));
    testManager.disposeAd(2);
    verify(flutterNativeAd).dispose();
    assertNull(testManager.adForId(2));
    assertNull(testManager.adIdFor(flutterNativeAd));
  }

  @Test
  public void flutterAdListener_onAdLoaded() {
    final FlutterBannerAd bannerAd =
        new FlutterBannerAd(
            0,
            testManager,
            "testId",
            request,
            new FlutterAdSize(1, 2),
            mock(BannerAdCreator.class));
    testManager.trackAd(bannerAd, 0);

    AdError adError = mock(AdError.class);
    doReturn(1).when(adError).getCode();
    doReturn("domain").when(adError).getDomain();
    doReturn("message").when(adError).getMessage();

    Bundle credentials = new Bundle();
    credentials.putString("key", "value");

    AdapterResponseInfo adapterInfo = mock(AdapterResponseInfo.class);
    doReturn("adapter-class").when(adapterInfo).getAdapterClassName();
    doReturn(adError).when(adapterInfo).getAdError();
    doReturn(123L).when(adapterInfo).getLatencyMillis();
    doReturn(credentials).when(adapterInfo).getCredentials();
    doReturn("description").when(adapterInfo).toString();

    AdapterResponseInfo adapterInfoWithNullError = mock(AdapterResponseInfo.class);
    doReturn("adapter-class").when(adapterInfoWithNullError).getAdapterClassName();
    doReturn(null).when(adapterInfoWithNullError).getAdError();
    doReturn(123L).when(adapterInfoWithNullError).getLatencyMillis();
    doReturn(null).when(adapterInfoWithNullError).getCredentials();
    doReturn("description").when(adapterInfoWithNullError).toString();

    List<AdapterResponseInfo> adapterResponses = new ArrayList<>();
    adapterResponses.add(adapterInfo);
    adapterResponses.add(adapterInfoWithNullError);

    ResponseInfo responseInfo = mock(ResponseInfo.class);
    doReturn("response-id").when(responseInfo).getResponseId();
    doReturn("class-name").when(responseInfo).getMediationAdapterClassName();
    doReturn(adapterResponses).when(responseInfo).getAdapterResponses();

    testManager.onAdLoaded(0, responseInfo);

    final MethodCall call = getLastMethodCall();
    assertEquals("onAdEvent", call.method);
    //noinspection rawtypes
    assertThat(call.arguments, (Matcher) hasEntry("eventName", "onAdLoaded"));
    //noinspection rawtypes
    assertThat(call.arguments, (Matcher) hasEntry("adId", 0));
    assertThat(
        call.arguments, (Matcher) hasEntry("responseInfo", new FlutterResponseInfo(responseInfo)));
  }

  @Test
  public void flutterAdListener_onAdLoaded_responseInfoNull() {
    final FlutterBannerAd bannerAd =
        new FlutterBannerAd(
            0,
            testManager,
            "testId",
            request,
            new FlutterAdSize(1, 2),
            mock(BannerAdCreator.class));
    testManager.trackAd(bannerAd, 0);

    testManager.onAdLoaded(0, null);

    final MethodCall call = getLastMethodCall();
    assertEquals("onAdEvent", call.method);
    //noinspection rawtypes
    assertThat(call.arguments, (Matcher) hasEntry("eventName", "onAdLoaded"));
    //noinspection rawtypes
    assertThat(call.arguments, (Matcher) hasEntry("adId", 0));
    assertThat(call.arguments, (Matcher) hasEntry("responseInfo", null));
  }

  @Test
  public void flutterAdListener_onAdFailedToLoad() {
    final FlutterBannerAd bannerAd =
        new FlutterBannerAd(
            0,
            testManager,
            "testId",
            request,
            new FlutterAdSize(1, 2),
            mock(BannerAdCreator.class));
    testManager.trackAd(bannerAd, 0);

    testManager.onAdFailedToLoad(0, new FlutterAd.FlutterLoadAdError(1, "hi", "friend", null));

    final MethodCall call = getLastMethodCall();
    assertEquals("onAdEvent", call.method);
    //noinspection rawtypes
    assertThat(call.arguments, (Matcher) hasEntry("eventName", "onAdFailedToLoad"));
    //noinspection rawtypes
    assertThat(call.arguments, (Matcher) hasEntry("adId", 0));
    //noinspection rawtypes
    assertThat(
        call.arguments,
        (Matcher)
            hasEntry("loadAdError", new FlutterAd.FlutterLoadAdError(1, "hi", "friend", null)));
  }

  @Test
  public void flutterAdListener_onAppEvent() {
    final FlutterBannerAd bannerAd =
        new FlutterBannerAd(
            0,
            testManager,
            "testId",
            request,
            new FlutterAdSize(1, 2),
            mock(BannerAdCreator.class));
    testManager.trackAd(bannerAd, 0);

    testManager.onAppEvent(0, "color", "red");

    final MethodCall call = getLastMethodCall();
    assertEquals("onAdEvent", call.method);
    //noinspection rawtypes
    assertThat(call.arguments, (Matcher) hasEntry("eventName", "onAppEvent"));
    //noinspection rawtypes
    assertThat(call.arguments, (Matcher) hasEntry("adId", 0));
    //noinspection rawtypes
    assertThat(call.arguments, (Matcher) hasEntry("name", "color"));
    //noinspection rawtypes
    assertThat(call.arguments, (Matcher) hasEntry("data", "red"));
  }

  @Test
  public void flutterAdListener_onAdOpened() {
    final FlutterBannerAd bannerAd =
        new FlutterBannerAd(
            0,
            testManager,
            "testId",
            request,
            new FlutterAdSize(1, 2),
            mock(BannerAdCreator.class));
    testManager.trackAd(bannerAd, 0);

    testManager.onAdOpened(0);

    final MethodCall call = getLastMethodCall();
    assertEquals("onAdEvent", call.method);
    //noinspection rawtypes
    assertThat(call.arguments, (Matcher) hasEntry("eventName", "onAdOpened"));
    //noinspection rawtypes
    assertThat(call.arguments, (Matcher) hasEntry("adId", 0));
  }

  @Test
  public void flutterAdListener_onNativeAdClicked() {
    final FlutterNativeAd nativeAd =
        new FlutterNativeAd.Builder()
            .setManager(testManager)
            .setAdUnitId("testId")
            .setRequest(request)
            .setAdFactory(
                new GoogleMobileAdsPlugin.NativeAdFactory() {
                  @Override
                  public NativeAdView createNativeAd(
                      NativeAd nativeAd, Map<String, Object> customOptions) {
                    return null;
                  }
                })
            .setId(0)
            .build();
    testManager.trackAd(nativeAd, 0);

    testManager.onAdClicked(0);

    final MethodCall call = getLastMethodCall();
    assertEquals("onAdEvent", call.method);
    //noinspection rawtypes
    assertThat(call.arguments, (Matcher) hasEntry("eventName", "onAdClicked"));
    //noinspection rawtypes
    assertThat(call.arguments, (Matcher) hasEntry("adId", 0));
  }

  @Test
  public void flutterAdListener_onNativeAdImpression() {
    final FlutterNativeAd nativeAd =
        new FlutterNativeAd.Builder()
            .setManager(testManager)
            .setAdUnitId("testId")
            .setRequest(request)
            .setAdFactory(
                new GoogleMobileAdsPlugin.NativeAdFactory() {
                  @Override
                  public NativeAdView createNativeAd(
                      NativeAd nativeAd, Map<String, Object> customOptions) {
                    return null;
                  }
                })
            .setId(0)
            .build();
    testManager.trackAd(nativeAd, 0);

    testManager.onAdImpression(0);

    final MethodCall call = getLastMethodCall();
    assertEquals("onAdEvent", call.method);
    //noinspection rawtypes
    assertThat(call.arguments, (Matcher) hasEntry("eventName", "onAdImpression"));
    //noinspection rawtypes
    assertThat(call.arguments, (Matcher) hasEntry("adId", 0));
  }

  @Test
  public void flutterAdListener_onAdClosed() {
    final FlutterBannerAd bannerAd =
        new FlutterBannerAd(
            0,
            testManager,
            "testId",
            request,
            new FlutterAdSize(1, 2),
            mock(BannerAdCreator.class));
    testManager.trackAd(bannerAd, 0);

    testManager.onAdClosed(0);

    final MethodCall call = getLastMethodCall();
    assertEquals("onAdEvent", call.method);
    //noinspection rawtypes
    assertThat(call.arguments, (Matcher) hasEntry("eventName", "onAdClosed"));
    //noinspection rawtypes
    assertThat(call.arguments, (Matcher) hasEntry("adId", 0));
  }

  @Test
  public void flutterAdListener_onRewardedAdUserEarnedReward() {
    FlutterAdLoader mockFlutterAdLoader = mock(FlutterAdLoader.class);
    final FlutterRewardedAd ad =
        new FlutterRewardedAd(0, testManager, "testId", request, mockFlutterAdLoader);
    testManager.trackAd(ad, 0);

    testManager.onRewardedAdUserEarnedReward(
        0, new FlutterRewardedAd.FlutterRewardItem(23, "coins"));

    final MethodCall call = getLastMethodCall();
    assertEquals("onAdEvent", call.method);
    //noinspection rawtypes
    assertThat(call.arguments, (Matcher) hasEntry("eventName", "onRewardedAdUserEarnedReward"));
    //noinspection rawtypes
    assertThat(call.arguments, (Matcher) hasEntry("adId", 0));
    //noinspection rawtypes
    assertThat(
        call.arguments,
        (Matcher) hasEntry("rewardItem", new FlutterRewardedAd.FlutterRewardItem(23, "coins")));
  }

  @Test
  public void internalInitDisposesAds() {
    // Set up testManager so that two ads have already been loaded and tracked.
    final FlutterRewardedAd rewarded = mock(FlutterRewardedAd.class);
    final FlutterBannerAd banner = mock(FlutterBannerAd.class);

    testManager.trackAd(rewarded, 0);
    testManager.trackAd(banner, 1);

    assertEquals(testManager.adIdFor(rewarded), (Integer) 0);
    assertEquals(testManager.adIdFor(banner), (Integer) 1);
    assertEquals(testManager.adForId(0), rewarded);
    assertEquals(testManager.adForId(1), banner);

    // Check that ads are removed and disposed when "_init" is called.
    AdInstanceManager testManagerSpy = spy(testManager);
    GoogleMobileAdsPlugin plugin =
        new GoogleMobileAdsPlugin(
            mockFlutterPluginBinding, testManagerSpy, new FlutterMobileAdsWrapper());
    Result result = mock(Result.class);
    MethodCall methodCall = new MethodCall("_init", null);
    plugin.onMethodCall(methodCall, result);

    verify(testManagerSpy).disposeAllAds();
    verify(result).success(null);
    verify(rewarded).dispose();
    verify(banner).dispose();
    assertNull(testManager.adForId(0));
    assertNull(testManager.adForId(1));
    assertNull(testManager.adIdFor(rewarded));
    assertNull(testManager.adIdFor(banner));
  }

  @Test
  public void initializeCallbackInvokedTwice() {
    AdInstanceManager testManagerSpy = spy(testManager);
    FlutterMobileAdsWrapper mockMobileAds = mock(FlutterMobileAdsWrapper.class);
    GoogleMobileAdsPlugin plugin =
        new GoogleMobileAdsPlugin(mockFlutterPluginBinding, testManagerSpy, mockMobileAds);
    final InitializationStatus mockInitStatus = mock(InitializationStatus.class);
    doAnswer(
            new Answer() {
              @Override
              public Object answer(InvocationOnMock invocation) {
                // Invoke init listener twice.
                OnInitializationCompleteListener listener = invocation.getArgument(1);
                listener.onInitializationComplete(mockInitStatus);
                listener.onInitializationComplete(mockInitStatus);
                return null;
              }
            })
        .when(mockMobileAds)
        .initialize(
            ArgumentMatchers.any(Context.class),
            ArgumentMatchers.any(OnInitializationCompleteListener.class));

    MethodCall methodCall = new MethodCall("MobileAds#initialize", null);
    Result result = mock(Result.class);
    plugin.onMethodCall(methodCall, result);

    verify(result).success(ArgumentMatchers.any(FlutterInitializationStatus.class));
  }

  @Test
  public void openAdInspector_error() {
    AdInstanceManager testManagerSpy = spy(testManager);
    FlutterMobileAdsWrapper mockMobileAds = mock(FlutterMobileAdsWrapper.class);
    GoogleMobileAdsPlugin plugin =
        new GoogleMobileAdsPlugin(mockFlutterPluginBinding, testManagerSpy, mockMobileAds);

    doAnswer(
            invocation -> {
              OnAdInspectorClosedListener listener = invocation.getArgument(1);
              final AdInspectorError error = mock(AdInspectorError.class);
              doReturn(1).when(error).getCode();
              doReturn("domain").when(error).getDomain();
              doReturn("message").when(error).getMessage();
              listener.onAdInspectorClosed(error);
              return null;
            })
        .when(mockMobileAds)
        .openAdInspector(
            ArgumentMatchers.any(Context.class),
            ArgumentMatchers.any(OnAdInspectorClosedListener.class));

    MethodCall methodCall = new MethodCall("MobileAds#openAdInspector", null);
    Result result = mock(Result.class);
    plugin.onMethodCall(methodCall, result);

    verify(result).error(eq("1"), eq("message"), eq("domain"));
  }

  @Test
  public void openAdInspector_success() {
    AdInstanceManager testManagerSpy = spy(testManager);
    FlutterMobileAdsWrapper mockMobileAds = mock(FlutterMobileAdsWrapper.class);
    GoogleMobileAdsPlugin plugin =
        new GoogleMobileAdsPlugin(mockFlutterPluginBinding, testManagerSpy, mockMobileAds);

    doAnswer(
            invocation -> {
              OnAdInspectorClosedListener listener = invocation.getArgument(1);
              listener.onAdInspectorClosed(null);
              return null;
            })
        .when(mockMobileAds)
        .openAdInspector(
            ArgumentMatchers.any(Context.class),
            ArgumentMatchers.any(OnAdInspectorClosedListener.class));

    MethodCall methodCall = new MethodCall("MobileAds#openAdInspector", null);
    Result result = mock(Result.class);
    plugin.onMethodCall(methodCall, result);

    verify(result).success(null);
  }

  @Test
  public void testPluginUsesActivityWhenAvailable() {
    FlutterMobileAdsWrapper flutterMobileAdsWrapper = mock(FlutterMobileAdsWrapper.class);
    BinaryMessenger mockBinaryMessenger = mock(BinaryMessenger.class);
    doReturn(ApplicationProvider.getApplicationContext())
        .when(mockFlutterPluginBinding)
        .getApplicationContext();
    doReturn(mockBinaryMessenger).when(mockFlutterPluginBinding).getBinaryMessenger();
    PlatformViewRegistry mockPlatformViewRegistry = mock(PlatformViewRegistry.class);

    doReturn(mockPlatformViewRegistry).when(mockFlutterPluginBinding).getPlatformViewRegistry();

    GoogleMobileAdsPlugin plugin = new GoogleMobileAdsPlugin(null, null, flutterMobileAdsWrapper);
    plugin.onAttachedToEngine(mockFlutterPluginBinding);

    MethodCall methodCall = new MethodCall("MobileAds#initialize", null);
    Result result = mock(Result.class);
    plugin.onMethodCall(methodCall, result);

    // Check that we use application context if activity is not available.
    verify(flutterMobileAdsWrapper)
        .initialize(eq(ApplicationProvider.getApplicationContext()), any());

    // Activity should be used instead of application context
    ActivityPluginBinding activityPluginBinding = mock(ActivityPluginBinding.class);
    doReturn(mockActivity).when(activityPluginBinding).getActivity();
    plugin.onAttachedToActivity(activityPluginBinding);

    plugin.onMethodCall(methodCall, result);

    verify(flutterMobileAdsWrapper).initialize(eq(mockActivity), any());
  }

  @Test
  public void testGetRequestConfiguration() {
    AdInstanceManager testManagerSpy = spy(testManager);
    FlutterMobileAdsWrapper mockMobileAds = mock(FlutterMobileAdsWrapper.class);
    GoogleMobileAdsPlugin plugin =
        new GoogleMobileAdsPlugin(mockFlutterPluginBinding, testManagerSpy, mockMobileAds);
    RequestConfiguration.Builder rcb = new RequestConfiguration.Builder();
    rcb.setMaxAdContentRating(RequestConfiguration.MAX_AD_CONTENT_RATING_MA);
    rcb.setTagForChildDirectedTreatment(RequestConfiguration.TAG_FOR_CHILD_DIRECTED_TREATMENT_TRUE);
    rcb.setTagForUnderAgeOfConsent(RequestConfiguration.TAG_FOR_UNDER_AGE_OF_CONSENT_TRUE);
    rcb.setTestDeviceIds(new ArrayList<String>(Arrays.asList("id1", "id2")));
    RequestConfiguration rc = rcb.build();
    doReturn(rc).when(mockMobileAds).getRequestConfiguration();

    MethodCall methodCall = new MethodCall("MobileAds#getRequestConfiguration", null);
    Result result = mock(Result.class);
    plugin.onMethodCall(methodCall, result);

    verify(result).success(rc);
  }

  @Test(expected = IllegalArgumentException.class)
  public void trackAdThrowsErrorForDuplicateId() {
    final FlutterBannerAd banner = mock(FlutterBannerAd.class);
    testManager.trackAd(banner, 0);
    testManager.trackAd(banner, 0);
  }

  @Test
  public void testOnPaidEvent() {
    final FlutterBannerAd banner = mock(FlutterBannerAd.class);
    final FlutterAdValue flutterAdValue = new FlutterAdValue(1, "code", 1L);
    testManager.trackAd(banner, 1);
    testManager.onPaidEvent(banner, flutterAdValue);
    final MethodCall call = getLastMethodCall();
    assertEquals("onAdEvent", call.method);
    //noinspection rawtypes
    Map args = (Map) call.arguments;
    assertEquals(args.get("eventName"), "onPaidEvent");
    assertEquals(args.get("adId"), 1);
    assertEquals(args.get("valueMicros"), 1L);
    assertEquals(args.get("precision"), 1);
    assertEquals(args.get("currencyCode"), "code");
  }

  @Test
  public void testSetAppMuted() {
    AdInstanceManager testManagerSpy = spy(testManager);
    FlutterMobileAdsWrapper mockMobileAds = mock(FlutterMobileAdsWrapper.class);
    GoogleMobileAdsPlugin plugin =
        new GoogleMobileAdsPlugin(mockFlutterPluginBinding, testManagerSpy, mockMobileAds);

    // Create a map for passing arguments to the MethodCall
    HashMap<String, Boolean> trueArguments = new HashMap<>();
    trueArguments.put("muted", true);

    // Invoke the setAppMuted method with the arguments.
    MethodCall methodCall = new MethodCall("MobileAds#setAppMuted", trueArguments);
    Result result = mock(Result.class);
    plugin.onMethodCall(methodCall, result);

    // Verify that mockMobileAds.setAppMuted() was called with the correct value.
    verify(mockMobileAds).setAppMuted(eq(true));

    // Create a map for passing arguments to the MethodCall
    HashMap<String, Boolean> falseArguments = new HashMap<>();
    falseArguments.put("muted", false);

    // Invoke the setAppMuted method with the arguments.
    MethodCall falseMethodCall = new MethodCall("MobileAds#setAppMuted", falseArguments);
    Result falseResult = mock(Result.class);
    plugin.onMethodCall(falseMethodCall, falseResult);

    // Verify that mockMobileAds.setAppMuted() was called with the correct value.
    verify(mockMobileAds).setAppMuted(eq(false));
  }

  @Test
  public void testSetAppVolume() {
    AdInstanceManager testManagerSpy = spy(testManager);
    FlutterMobileAdsWrapper mockMobileAds = mock(FlutterMobileAdsWrapper.class);
    GoogleMobileAdsPlugin plugin =
        new GoogleMobileAdsPlugin(mockFlutterPluginBinding, testManagerSpy, mockMobileAds);

    // Create a map for passing arguments to the MethodCall.
    HashMap<String, Double> fullVolumeArguments = new HashMap<>();
    fullVolumeArguments.put("volume", 1.0);

    // Invoke the setAppVolume method with the arguments.
    MethodCall methodCall = new MethodCall("MobileAds#setAppVolume", fullVolumeArguments);
    Result result = mock(Result.class);
    plugin.onMethodCall(methodCall, result);

    // Verify that mockMobileAds.setAppVolume() was called with the correct value.
    verify(mockMobileAds).setAppVolume(eq(1.0));
  }

  @Test
  public void testDisableMediationInitialization() {
    AdInstanceManager testManagerSpy = spy(testManager);
    FlutterMobileAdsWrapper mockMobileAds = mock(FlutterMobileAdsWrapper.class);
    GoogleMobileAdsPlugin plugin =
        new GoogleMobileAdsPlugin(mockFlutterPluginBinding, testManagerSpy, mockMobileAds);
    // Invoke the disableMediationInitialization method.
    MethodCall methodCall = new MethodCall("MobileAds#disableMediationInitialization", null);
    Result result = mock(Result.class);
    plugin.onMethodCall(methodCall, result);

    Robolectric.flushForegroundThreadScheduler();
    // Verify that mockMobileAds.disableMediationInitialization() was called.
    verify(mockMobileAds).disableMediationInitialization(ArgumentMatchers.any(Context.class));
  }

  @Test
  public void testGetVersionString() {
    AdInstanceManager testManagerSpy = spy(testManager);
    FlutterMobileAdsWrapper mockMobileAds = mock(FlutterMobileAdsWrapper.class);
    GoogleMobileAdsPlugin plugin =
        new GoogleMobileAdsPlugin(mockFlutterPluginBinding, testManagerSpy, mockMobileAds);
    // Stub getVersionString() to return a value.
    doReturn("Test-SDK-Version").when(mockMobileAds).getVersionString();

    // Invoke the getVersionString method.
    MethodCall methodCall = new MethodCall("MobileAds#getVersionString", null);
    Result result = mock(Result.class);
    plugin.onMethodCall(methodCall, result);

    // Verify that mockMobileAds.getVersionString() was called and a value is returned.
    verify(mockMobileAds).getVersionString();
    verify(result).success("Test-SDK-Version");
  }

  @Test
  public void testOpenDebugMenu() {
    AdInstanceManager testManagerSpy = spy(testManager);
    FlutterMobileAdsWrapper mockMobileAds = mock(FlutterMobileAdsWrapper.class);
    GoogleMobileAdsPlugin plugin =
        new GoogleMobileAdsPlugin(mockFlutterPluginBinding, testManagerSpy, mockMobileAds);
    MethodCall methodCall =
        new MethodCall(
            "MobileAds#openDebugMenu", Collections.singletonMap("adUnitId", "test-ad-unit"));
    Result result = mock(Result.class);

    plugin.onMethodCall(methodCall, result);

    verify(mockMobileAds).openDebugMenu(eq(mockActivity), eq("test-ad-unit"));
    verify(result).success(isNull());
  }

  @Test
  public void testGetAnchoredAdaptiveBannerAdSize() {
    // Setup mocks
    AdInstanceManager testManagerSpy = spy(testManager);
    FlutterMobileAdsWrapper mockMobileAds = mock(FlutterMobileAdsWrapper.class);
    GoogleMobileAdsPlugin plugin =
        new GoogleMobileAdsPlugin(mockFlutterPluginBinding, testManagerSpy, mockMobileAds);

    BinaryMessenger mockBinaryMessenger = mock(BinaryMessenger.class);
    FlutterPluginBinding mockActivityPluginBinding = mock(FlutterPluginBinding.class);
    PlatformViewRegistry mockPlatformViewRegistry = mock(PlatformViewRegistry.class);

    Context context = ApplicationProvider.getApplicationContext();

    doReturn(context).when(mockActivityPluginBinding).getApplicationContext();
    doReturn(mockBinaryMessenger).when(mockActivityPluginBinding).getBinaryMessenger();
    doReturn(mockPlatformViewRegistry).when(mockActivityPluginBinding).getPlatformViewRegistry();

    plugin.onAttachedToEngine(mockActivityPluginBinding);

    // Test for portrait Banner AdSize.
    HashMap<String, Object> arguments = new HashMap<>();
    arguments.put("orientation", "portrait");
    arguments.put("width", 23);

    AdSize adSize = AdSize.getPortraitAnchoredAdaptiveBannerAdSize(context, 23);
    MethodCall methodCall = new MethodCall("AdSize#getAnchoredAdaptiveBannerAdSize", arguments);
    Result result = mock(Result.class);
    plugin.onMethodCall(methodCall, result);

    verify(result).success(adSize.getHeight());

    // Test for landscape Banner AdSize.
    arguments = new HashMap<>();
    arguments.put("orientation", "landscape");
    arguments.put("width", 23);

    adSize = AdSize.getLandscapeAnchoredAdaptiveBannerAdSize(context, 23);
    methodCall = new MethodCall("AdSize#getAnchoredAdaptiveBannerAdSize", arguments);
    result = mock(Result.class);
    plugin.onMethodCall(methodCall, result);

    verify(result).success(adSize.getHeight());

    // Test for current orientation (inferred) Banner AdSize.
    arguments = new HashMap<>();
    arguments.put("width", 23);

    adSize = AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(context, 23);
    methodCall = new MethodCall("AdSize#getAnchoredAdaptiveBannerAdSize", arguments);
    result = mock(Result.class);
    plugin.onMethodCall(methodCall, result);

    verify(result).success(adSize.getHeight());
  }

  public void testGetAdSize_bannerAd() {
    // Setup mocks
    AdInstanceManager testManagerSpy = spy(testManager);
    FlutterMobileAdsWrapper mockMobileAds = mock(FlutterMobileAdsWrapper.class);
    GoogleMobileAdsPlugin plugin =
        new GoogleMobileAdsPlugin(mockFlutterPluginBinding, testManagerSpy, mockMobileAds);
    GoogleMobileAdsPlugin pluginSpy = spy(plugin);
    BannerAdCreator bannerAdCreator = mock(BannerAdCreator.class);
    AdView adView = mock(AdView.class);
    doReturn(adView).when(bannerAdCreator).createAdView();
    doReturn(bannerAdCreator)
        .when(pluginSpy)
        .getBannerAdCreator(ArgumentMatchers.any(Context.class));

    // Load a banner ad
    Map<String, Object> loadArgs = new HashMap<>();
    loadArgs.put("adId", 1);
    loadArgs.put("adUnitId", "test-ad-unit");
    loadArgs.put("request", new FlutterAdRequest.Builder().build());
    loadArgs.put("size", new FlutterAdSize(1, 2));

    MethodCall loadBannerMethodCall = new MethodCall("loadBannerAd", loadArgs);
    Result result = mock(Result.class);
    pluginSpy.onMethodCall(loadBannerMethodCall, result);
    verify(result).success(null);

    // Mock response for adView.getAdSize();
    AdSize adSize = mock(AdSize.class);
    doReturn(adSize).when(adView).getAdSize();

    // Method call for getAdSize.
    Result getAdSizeResult = mock(Result.class);
    Map<String, Object> getAdSizeArgs = Collections.singletonMap("adId", (Object) 1);
    MethodCall getAdSizeMethodCall = new MethodCall("getAdSize", getAdSizeArgs);
    pluginSpy.onMethodCall(getAdSizeMethodCall, getAdSizeResult);

    ArgumentCaptor<FlutterAdSize> argumentCaptor = ArgumentCaptor.forClass(FlutterAdSize.class);
    verify(getAdSizeResult).success(argumentCaptor.capture());
    assertEquals(argumentCaptor.getValue().getAdSize(), adSize);
  }

  @Test
  public void testGetAdSize_adManagerBannerAd() {
    // Setup mocks
    AdInstanceManager testManagerSpy = spy(testManager);
    FlutterMobileAdsWrapper mockMobileAds = mock(FlutterMobileAdsWrapper.class);
    GoogleMobileAdsPlugin plugin =
        new GoogleMobileAdsPlugin(mockFlutterPluginBinding, testManagerSpy, mockMobileAds);
    GoogleMobileAdsPlugin pluginSpy = spy(plugin);
    BannerAdCreator bannerAdCreator = mock(BannerAdCreator.class);
    AdManagerAdView adView = mock(AdManagerAdView.class);
    doReturn(adView).when(bannerAdCreator).createAdManagerAdView();
    doReturn(bannerAdCreator)
        .when(pluginSpy)
        .getBannerAdCreator(ArgumentMatchers.any(Context.class));

    // Load a banner ad
    Map<String, Object> loadArgs = new HashMap<>();
    loadArgs.put("adId", 1);
    loadArgs.put("adUnitId", "test-ad-unit");
    loadArgs.put("request", new FlutterAdManagerAdRequest.Builder().build());
    loadArgs.put("sizes", Collections.singletonList(new FlutterAdSize(1, 2)));

    MethodCall loadBannerMethodCall = new MethodCall("loadAdManagerBannerAd", loadArgs);
    Result result = mock(Result.class);
    pluginSpy.onMethodCall(loadBannerMethodCall, result);
    verify(result).success(null);

    // Mock response for adView.getAdSize();
    AdSize adSize = mock(AdSize.class);
    doReturn(adSize).when(adView).getAdSize();

    // Method call for getAdSize.
    Result getAdSizeResult = mock(Result.class);
    Map<String, Object> getAdSizeArgs = Collections.singletonMap("adId", (Object) 1);
    MethodCall getAdSizeMethodCall = new MethodCall("getAdSize", getAdSizeArgs);
    pluginSpy.onMethodCall(getAdSizeMethodCall, getAdSizeResult);

    ArgumentCaptor<FlutterAdSize> argumentCaptor = ArgumentCaptor.forClass(FlutterAdSize.class);
    verify(getAdSizeResult).success(argumentCaptor.capture());
    assertEquals(argumentCaptor.getValue().getAdSize(), adSize);
  }

  @Test
  public void testAppStateNotifyDetachFromEngine() {
    AppStateNotifier notifier = mock(AppStateNotifier.class);
    GoogleMobileAdsPlugin plugin = new GoogleMobileAdsPlugin(notifier);
    plugin.onDetachedFromEngine(null);
    verify(notifier).stop();
  }

  @Test
  public void testServerSideVerificationOptions_rewardedAd() {
    // Setup mocks
    AdInstanceManager mockManager = mock(AdInstanceManager.class);
    FlutterMobileAdsWrapper mockMobileAds = mock(FlutterMobileAdsWrapper.class);
    GoogleMobileAdsPlugin plugin =
        new GoogleMobileAdsPlugin(mockFlutterPluginBinding, mockManager, mockMobileAds);
    GoogleMobileAdsPlugin pluginSpy = spy(plugin);

    // Pretend that a rewarded ad has already been loaded with id 1
    FlutterRewardedAd mockRewardedAd = mock(FlutterRewardedAd.class);
    doReturn(mockRewardedAd).when(mockManager).adForId(1);

    // Make a ssv method call
    Map<String, Object> loadArgs = new HashMap<>();
    loadArgs.put("adId", 1);
    FlutterServerSideVerificationOptions mockFlutterSsv =
        mock(FlutterServerSideVerificationOptions.class);
    loadArgs.put("serverSideVerificationOptions", mockFlutterSsv);

    // Successful call
    MethodCall methodCall = new MethodCall("setServerSideVerificationOptions", loadArgs);
    Result result = mock(Result.class);
    pluginSpy.onMethodCall(methodCall, result);

    verify(mockRewardedAd).setServerSideVerificationOptions(eq(mockFlutterSsv));
    verify(result).success(null);
  }

  @Test
  public void testServerSideVerificationOptions_rewardedInterstitialAd() {
    // Setup mocks
    AdInstanceManager mockManager = mock(AdInstanceManager.class);
    FlutterMobileAdsWrapper mockMobileAds = mock(FlutterMobileAdsWrapper.class);
    GoogleMobileAdsPlugin plugin =
        new GoogleMobileAdsPlugin(mockFlutterPluginBinding, mockManager, mockMobileAds);
    GoogleMobileAdsPlugin pluginSpy = spy(plugin);

    // Pretend that a rewarded interstitial ad has already been loaded with id 1
    FlutterRewardedInterstitialAd mockAd = mock(FlutterRewardedInterstitialAd.class);
    doReturn(mockAd).when(mockManager).adForId(1);

    // Make a ssv method call
    Map<String, Object> loadArgs = new HashMap<>();
    loadArgs.put("adId", 1);
    FlutterServerSideVerificationOptions mockFlutterSsv =
        mock(FlutterServerSideVerificationOptions.class);
    loadArgs.put("serverSideVerificationOptions", mockFlutterSsv);

    // Successful call
    MethodCall methodCall = new MethodCall("setServerSideVerificationOptions", loadArgs);
    Result result = mock(Result.class);
    pluginSpy.onMethodCall(methodCall, result);

    verify(mockAd).setServerSideVerificationOptions(eq(mockFlutterSsv));
    verify(result).success(null);
  }

  @Test
  public void testServerSideVerificationOptions_invalidAdId() {
    // Setup mocks
    AdInstanceManager mockManager = mock(AdInstanceManager.class);
    FlutterMobileAdsWrapper mockMobileAds = mock(FlutterMobileAdsWrapper.class);
    GoogleMobileAdsPlugin plugin =
        new GoogleMobileAdsPlugin(mockFlutterPluginBinding, mockManager, mockMobileAds);
    GoogleMobileAdsPlugin pluginSpy = spy(plugin);

    // AdId matches a banner ad instead of rewarded or rewarded interstitial
    FlutterBannerAd mockAd = mock(FlutterBannerAd.class);
    doReturn(mockAd).when(mockManager).adForId(1);

    // Make a ssv method call without any ads having loaded
    Map<String, Object> loadArgs = new HashMap<>();
    loadArgs.put("adId", 1);
    FlutterServerSideVerificationOptions mockFlutterSsv =
        mock(FlutterServerSideVerificationOptions.class);
    loadArgs.put("serverSideVerificationOptions", mockFlutterSsv);

    // Successful call
    MethodCall methodCall = new MethodCall("setServerSideVerificationOptions", loadArgs);
    Result result = mock(Result.class);
    pluginSpy.onMethodCall(methodCall, result);

    // result.success() still invoked, resulting in no-op
    verifyNoInteractions(mockAd);
    verify(result).success(null);
  }

  @Test
  public void testServerSideVerificationOptions_invalidAdType() {
    // Setup mocks
    AdInstanceManager mockManager = mock(AdInstanceManager.class);
    FlutterMobileAdsWrapper mockMobileAds = mock(FlutterMobileAdsWrapper.class);
    GoogleMobileAdsPlugin plugin =
        new GoogleMobileAdsPlugin(mockFlutterPluginBinding, mockManager, mockMobileAds);
    GoogleMobileAdsPlugin pluginSpy = spy(plugin);

    // Make a ssv method call without any ads having loaded
    Map<String, Object> loadArgs = new HashMap<>();
    loadArgs.put("adId", 1);
    FlutterServerSideVerificationOptions mockFlutterSsv =
        mock(FlutterServerSideVerificationOptions.class);
    loadArgs.put("serverSideVerificationOptions", mockFlutterSsv);

    // Successful call
    MethodCall methodCall = new MethodCall("setServerSideVerificationOptions", loadArgs);
    Result result = mock(Result.class);
    pluginSpy.onMethodCall(methodCall, result);

    // result.success() still invoked, resulting in no-op
    verify(result).success(null);
  }
}
