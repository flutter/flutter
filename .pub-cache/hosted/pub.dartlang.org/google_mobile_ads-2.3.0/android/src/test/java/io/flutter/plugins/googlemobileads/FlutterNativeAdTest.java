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
import static org.junit.Assert.assertNotNull;
import static org.junit.Assert.assertNull;
import static org.mockito.ArgumentCaptor.forClass;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.doAnswer;
import static org.mockito.Mockito.doReturn;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.spy;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import android.app.Activity;
import com.google.android.gms.ads.AdListener;
import com.google.android.gms.ads.AdRequest;
import com.google.android.gms.ads.AdValue;
import com.google.android.gms.ads.LoadAdError;
import com.google.android.gms.ads.ResponseInfo;
import com.google.android.gms.ads.admanager.AdManagerAdRequest;
import com.google.android.gms.ads.nativead.NativeAd;
import com.google.android.gms.ads.nativead.NativeAd.OnNativeAdLoadedListener;
import com.google.android.gms.ads.nativead.NativeAdOptions;
import com.google.android.gms.ads.nativead.NativeAdView;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.platform.PlatformView;
import io.flutter.plugins.googlemobileads.FlutterAd.FlutterLoadAdError;
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin.NativeAdFactory;
import java.util.Map;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.mockito.ArgumentCaptor;
import org.mockito.invocation.InvocationOnMock;
import org.mockito.stubbing.Answer;
import org.robolectric.RobolectricTestRunner;

/** Tests for {@link FlutterNativeAd}. */
@RunWith(RobolectricTestRunner.class)
public class FlutterNativeAdTest {

  private AdInstanceManager testManager;
  private final FlutterAdRequest request = new FlutterAdRequest.Builder().build();

  @Before
  public void setup() {
    testManager = spy(new AdInstanceManager(mock(MethodChannel.class)));
    doReturn(mock(Activity.class)).when(testManager).getActivity();
  }

  @Test
  public void loadNativeAdWithAdManagerAdRequest() {
    final FlutterAdManagerAdRequest mockFlutterRequest = mock(FlutterAdManagerAdRequest.class);
    final AdManagerAdRequest mockRequest = mock(AdManagerAdRequest.class);
    when(mockFlutterRequest.asAdManagerAdRequest(anyString())).thenReturn(mockRequest);
    FlutterAdLoader mockLoader = mock(FlutterAdLoader.class);
    NativeAdFactory mockNativeAdFactory = mock(NativeAdFactory.class);
    @SuppressWarnings("unchecked")
    Map<String, Object> mockOptions = mock(Map.class);
    FlutterNativeAdOptions mockFlutterNativeAdOptions = mock(FlutterNativeAdOptions.class);
    NativeAdOptions mockNativeAdOptions = mock(NativeAdOptions.class);
    doReturn(mockNativeAdOptions).when(mockFlutterNativeAdOptions).asNativeAdOptions();
    final FlutterNativeAd nativeAd =
        new FlutterNativeAd(
            1,
            testManager,
            "testId",
            mockNativeAdFactory,
            mockFlutterRequest,
            mockLoader,
            mockOptions,
            mockFlutterNativeAdOptions);

    final ResponseInfo responseInfo = mock(ResponseInfo.class);
    final NativeAd mockNativeAd = mock(NativeAd.class);
    doReturn(responseInfo).when(mockNativeAd).getResponseInfo();
    final LoadAdError loadAdError = mock(LoadAdError.class);
    doReturn(1).when(loadAdError).getCode();
    doReturn("2").when(loadAdError).getDomain();
    doReturn("3").when(loadAdError).getMessage();
    doReturn(null).when(loadAdError).getResponseInfo();
    doAnswer(
            new Answer() {
              @Override
              public Object answer(InvocationOnMock invocation) {
                OnNativeAdLoadedListener adLoadCallback = invocation.getArgument(1);
                adLoadCallback.onNativeAdLoaded(mockNativeAd);

                AdListener listener = invocation.getArgument(3);
                listener.onAdOpened();
                listener.onAdClosed();
                listener.onAdClicked();
                listener.onAdImpression();
                listener.onAdLoaded();
                listener.onAdFailedToLoad(loadAdError);
                return null;
              }
            })
        .when(mockLoader)
        .loadAdManagerNativeAd(
            eq("testId"),
            any(OnNativeAdLoadedListener.class),
            any(NativeAdOptions.class),
            any(AdListener.class),
            eq(mockRequest));

    final AdValue adValue = mock(AdValue.class);
    doReturn(1).when(adValue).getPrecisionType();
    doReturn("Dollars").when(adValue).getCurrencyCode();
    doReturn(1000L).when(adValue).getValueMicros();
    doAnswer(
            new Answer() {
              @Override
              public Object answer(InvocationOnMock invocation) {
                FlutterPaidEventListener listener = invocation.getArgument(0);
                listener.onPaidEvent(adValue);
                return null;
              }
            })
        .when(mockNativeAd)
        .setOnPaidEventListener(any(FlutterPaidEventListener.class));

    nativeAd.load();
    verify(mockLoader)
        .loadAdManagerNativeAd(
            eq("testId"),
            any(OnNativeAdLoadedListener.class),
            eq(mockNativeAdOptions),
            any(AdListener.class),
            eq(mockRequest));

    verify(mockNativeAd).setOnPaidEventListener(any(FlutterPaidEventListener.class));

    verify(mockNativeAdFactory).createNativeAd(eq(mockNativeAd), eq(mockOptions));
    verify(testManager).onAdOpened(eq(1));
    verify(testManager).onAdClosed(eq(1));
    verify(testManager).onAdClicked(eq(1));
    verify(testManager).onAdImpression(eq(1));
    verify(testManager).onAdLoaded(eq(1), eq(responseInfo));
    FlutterLoadAdError expectedError = new FlutterLoadAdError(loadAdError);
    verify(testManager).onAdFailedToLoad(eq(1), eq(expectedError));
    final ArgumentCaptor<FlutterAdValue> adValueCaptor = forClass(FlutterAdValue.class);
    verify(testManager).onPaidEvent(eq(nativeAd), adValueCaptor.capture());
    assertEquals(adValueCaptor.getValue().currencyCode, "Dollars");
    assertEquals(adValueCaptor.getValue().precisionType, 1);
    assertEquals(adValueCaptor.getValue().valueMicros, 1000L);
  }

  @Test
  public void loadNativeAdWithAdRequest() {
    final FlutterAdRequest mockFlutterRequest = mock(FlutterAdRequest.class);
    final AdRequest mockRequest = mock(AdRequest.class);
    when(mockFlutterRequest.asAdRequest(anyString())).thenReturn(mockRequest);
    FlutterAdLoader mockLoader = mock(FlutterAdLoader.class);
    NativeAdFactory mockNativeAdFactory = mock(GoogleMobileAdsPlugin.NativeAdFactory.class);
    NativeAdView mockNativeAdView = mock(NativeAdView.class);
    doReturn(mockNativeAdView)
        .when(mockNativeAdFactory)
        .createNativeAd(any(NativeAd.class), any(Map.class));
    @SuppressWarnings("unchecked")
    Map<String, Object> mockOptions = mock(Map.class);
    FlutterNativeAdOptions mockFlutterNativeAdOptions = mock(FlutterNativeAdOptions.class);
    NativeAdOptions mockNativeAdOptions = mock(NativeAdOptions.class);
    doReturn(mockNativeAdOptions).when(mockFlutterNativeAdOptions).asNativeAdOptions();
    final FlutterNativeAd nativeAd =
        new FlutterNativeAd(
            1,
            testManager,
            "testId",
            mockNativeAdFactory,
            mockFlutterRequest,
            mockLoader,
            mockOptions,
            mockFlutterNativeAdOptions);

    final ResponseInfo responseInfo = mock(ResponseInfo.class);
    final NativeAd mockNativeAd = mock(NativeAd.class);
    doReturn(responseInfo).when(mockNativeAd).getResponseInfo();
    final LoadAdError loadAdError = mock(LoadAdError.class);
    doReturn(1).when(loadAdError).getCode();
    doReturn("2").when(loadAdError).getDomain();
    doReturn("3").when(loadAdError).getMessage();
    doReturn(null).when(loadAdError).getResponseInfo();

    doAnswer(
            new Answer() {
              @Override
              public Object answer(InvocationOnMock invocation) throws Throwable {
                OnNativeAdLoadedListener adLoadCallback = invocation.getArgument(1);
                adLoadCallback.onNativeAdLoaded(mockNativeAd);

                AdListener listener = invocation.getArgument(3);
                listener.onAdOpened();
                listener.onAdClosed();
                listener.onAdClicked();
                listener.onAdImpression();
                listener.onAdLoaded();
                listener.onAdFailedToLoad(loadAdError);
                return null;
              }
            })
        .when(mockLoader)
        .loadNativeAd(
            eq("testId"),
            any(OnNativeAdLoadedListener.class),
            any(NativeAdOptions.class),
            any(AdListener.class),
            eq(mockRequest));

    nativeAd.load();
    verify(mockLoader)
        .loadNativeAd(
            eq("testId"),
            any(OnNativeAdLoadedListener.class),
            eq(mockNativeAdOptions),
            any(AdListener.class),
            eq(mockRequest));

    verify(mockNativeAdFactory).createNativeAd(eq(mockNativeAd), eq(mockOptions));
    verify(testManager).onAdLoaded(eq(1), eq(responseInfo));
    verify(testManager).onAdOpened(eq(1));
    verify(testManager).onAdClosed(eq(1));
    verify(testManager).onAdClicked(eq(1));
    verify(testManager).onAdImpression(eq(1));
    FlutterLoadAdError expectedError = new FlutterLoadAdError(loadAdError);
    verify(testManager).onAdFailedToLoad(eq(1), eq(expectedError));

    // Check that platform view is defined.
    PlatformView platformView = nativeAd.getPlatformView();
    assertEquals(platformView.getView(), mockNativeAdView);
    // getPlatformView() should be null after dispose() is invoked, but the platform view should
    // still return the view.
    nativeAd.dispose();
    assertNull(nativeAd.getPlatformView());
    assertNotNull(platformView.getView());
    // Platform view's reference to the view isn't cleared until dispose() is invoked on it.
    platformView.dispose();
    assertNull(platformView.getView());
  }

  @Test(expected = IllegalStateException.class)
  public void nativeAdBuilderNullManager() {
    new FlutterNativeAd.Builder()
        .setManager(null)
        .setAdUnitId("testId")
        .setAdFactory(mock(GoogleMobileAdsPlugin.NativeAdFactory.class))
        .setRequest(request)
        .build();
  }

  @Test(expected = IllegalStateException.class)
  public void nativeAdBuilderNullAdUnitId() {
    new FlutterNativeAd.Builder()
        .setManager(testManager)
        .setAdUnitId(null)
        .setAdFactory(mock(GoogleMobileAdsPlugin.NativeAdFactory.class))
        .setRequest(request)
        .build();
  }

  @Test(expected = IllegalStateException.class)
  public void nativeAdBuilderNullAdFactory() {
    new FlutterNativeAd.Builder()
        .setManager(testManager)
        .setAdUnitId("testId")
        .setAdFactory(null)
        .setRequest(request)
        .build();
  }

  @Test(expected = IllegalStateException.class)
  public void nativeAdBuilderNullRequest() {
    new FlutterNativeAd.Builder()
        .setManager(testManager)
        .setAdUnitId("testId")
        .setAdFactory(mock(GoogleMobileAdsPlugin.NativeAdFactory.class))
        .build();
  }

  public void paidEvent() {
    FlutterNativeAd nativeAd =
        new FlutterNativeAd.Builder()
            .setManager(testManager)
            .setAdUnitId("adUnitId")
            .setRequest(request)
            .setAdFactory(mock(GoogleMobileAdsPlugin.NativeAdFactory.class))
            .build();
    nativeAd.load();
  }
}
