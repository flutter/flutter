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
import com.google.android.gms.ads.AdError;
import com.google.android.gms.ads.AdValue;
import com.google.android.gms.ads.FullScreenContentCallback;
import com.google.android.gms.ads.LoadAdError;
import com.google.android.gms.ads.ResponseInfo;
import com.google.android.gms.ads.admanager.AdManagerAdRequest;
import com.google.android.gms.ads.admanager.AdManagerInterstitialAd;
import com.google.android.gms.ads.admanager.AdManagerInterstitialAdLoadCallback;
import com.google.android.gms.ads.admanager.AppEventListener;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugins.googlemobileads.FlutterAd.FlutterLoadAdError;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.mockito.ArgumentCaptor;
import org.mockito.invocation.InvocationOnMock;
import org.mockito.stubbing.Answer;
import org.robolectric.RobolectricTestRunner;

/** Tests for {@link FlutterAdManagerInterstitialAd}. */
@RunWith(RobolectricTestRunner.class)
public class FlutterAdManagerInterstitialAdTest {

  private AdInstanceManager mockManager;
  private FlutterAdLoader mockFlutterAdLoader;
  private AdManagerAdRequest mockRequest;
  // The system under test.
  private FlutterAdManagerInterstitialAd flutterAdManagerInterstitialAd;

  @Before
  public void setup() {
    mockManager = spy(new AdInstanceManager(mock(MethodChannel.class)));
    doReturn(mock(Activity.class)).when(mockManager).getActivity();
    final FlutterAdManagerAdRequest mockFlutterRequest = mock(FlutterAdManagerAdRequest.class);
    mockRequest = mock(AdManagerAdRequest.class);
    mockFlutterAdLoader = mock(FlutterAdLoader.class);
    when(mockFlutterRequest.asAdManagerAdRequest(anyString())).thenReturn(mockRequest);
    flutterAdManagerInterstitialAd =
        new FlutterAdManagerInterstitialAd(
            1, mockManager, "testId", mockFlutterRequest, mockFlutterAdLoader);
  }

  @Test
  public void loadAdManagerInterstitialAd_failedToLoad() {
    final LoadAdError loadAdError = mock(LoadAdError.class);
    doReturn(1).when(loadAdError).getCode();
    doReturn("2").when(loadAdError).getDomain();
    doReturn("3").when(loadAdError).getMessage();
    doReturn(null).when(loadAdError).getResponseInfo();
    doAnswer(
            new Answer() {
              @Override
              public Object answer(InvocationOnMock invocation) throws Throwable {
                AdManagerInterstitialAdLoadCallback adLoadCallback = invocation.getArgument(2);
                // Pass back null for ad
                adLoadCallback.onAdFailedToLoad(loadAdError);
                return null;
              }
            })
        .when(mockFlutterAdLoader)
        .loadAdManagerInterstitial(
            anyString(),
            any(AdManagerAdRequest.class),
            any(AdManagerInterstitialAdLoadCallback.class));

    flutterAdManagerInterstitialAd.load();

    verify(mockFlutterAdLoader)
        .loadAdManagerInterstitial(
            eq("testId"), eq(mockRequest), any(AdManagerInterstitialAdLoadCallback.class));

    FlutterLoadAdError flutterLoadAdError = new FlutterLoadAdError(loadAdError);
    verify(mockManager).onAdFailedToLoad(eq(1), eq(flutterLoadAdError));
  }

  @Test
  public void loadAdManagerInterstitialAd_showSuccess() {
    final AdManagerInterstitialAd mockAdManagerAd = mock(AdManagerInterstitialAd.class);
    doAnswer(
            new Answer() {
              @Override
              public Object answer(InvocationOnMock invocation) throws Throwable {
                AdManagerInterstitialAdLoadCallback adLoadCallback = invocation.getArgument(2);
                // Pass back null for ad
                adLoadCallback.onAdLoaded(mockAdManagerAd);
                return null;
              }
            })
        .when(mockFlutterAdLoader)
        .loadAdManagerInterstitial(
            anyString(),
            any(AdManagerAdRequest.class),
            any(AdManagerInterstitialAdLoadCallback.class));

    final ResponseInfo responseInfo = mock(ResponseInfo.class);
    doReturn(responseInfo).when(mockAdManagerAd).getResponseInfo();

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
        .when(mockAdManagerAd)
        .setOnPaidEventListener(any(FlutterPaidEventListener.class));

    flutterAdManagerInterstitialAd.load();

    verify(mockFlutterAdLoader)
        .loadAdManagerInterstitial(
            eq("testId"), eq(mockRequest), any(AdManagerInterstitialAdLoadCallback.class));

    verify(mockManager).onAdLoaded(1, responseInfo);
    verify(mockAdManagerAd).setOnPaidEventListener(any(FlutterPaidEventListener.class));
    final ArgumentCaptor<FlutterAdValue> adValueCaptor = forClass(FlutterAdValue.class);
    verify(mockManager).onPaidEvent(eq(flutterAdManagerInterstitialAd), adValueCaptor.capture());
    assertEquals(adValueCaptor.getValue().currencyCode, "Dollars");
    assertEquals(adValueCaptor.getValue().precisionType, 1);
    assertEquals(adValueCaptor.getValue().valueMicros, 1000L);

    // Setup mocks for show().
    doAnswer(
            new Answer() {
              @Override
              public Object answer(InvocationOnMock invocation) throws Throwable {
                FullScreenContentCallback callback = invocation.getArgument(0);
                callback.onAdShowedFullScreenContent();
                callback.onAdImpression();
                callback.onAdDismissedFullScreenContent();
                callback.onAdClicked();
                return null;
              }
            })
        .when(mockAdManagerAd)
        .setFullScreenContentCallback(any(FullScreenContentCallback.class));

    flutterAdManagerInterstitialAd.show();
    verify(mockAdManagerAd).setFullScreenContentCallback(any(FullScreenContentCallback.class));
    verify(mockAdManagerAd).show(mockManager.getActivity());
    verify(mockAdManagerAd).setAppEventListener(any(AppEventListener.class));
    verify(mockManager).onAdShowedFullScreenContent(eq(1));
    verify(mockManager).onAdImpression(eq(1));
    verify(mockManager).onAdClicked(eq(1));
    verify(mockManager).onAdDismissedFullScreenContent(eq(1));
    assertNull(flutterAdManagerInterstitialAd.getPlatformView());
  }

  @Test
  public void loadAdManagerInterstitialAd_setImmersiveMode() {
    final AdManagerInterstitialAd mockAdManagerAd = mock(AdManagerInterstitialAd.class);
    doAnswer(
            new Answer() {
              @Override
              public Object answer(InvocationOnMock invocation) throws Throwable {
                AdManagerInterstitialAdLoadCallback adLoadCallback = invocation.getArgument(2);
                adLoadCallback.onAdLoaded(mockAdManagerAd);
                // Pass back null for ad
                return null;
              }
            })
        .when(mockFlutterAdLoader)
        .loadAdManagerInterstitial(
            anyString(),
            any(AdManagerAdRequest.class),
            any(AdManagerInterstitialAdLoadCallback.class));

    flutterAdManagerInterstitialAd.load();
    flutterAdManagerInterstitialAd.setImmersiveMode(true);
    verify(mockAdManagerAd).setImmersiveMode(true);
  }

  @Test
  public void loadAdManagerInterstitialAd_showFailure() {
    final AdManagerInterstitialAd mockAdManagerAd = mock(AdManagerInterstitialAd.class);
    doAnswer(
            new Answer() {
              @Override
              public Object answer(InvocationOnMock invocation) throws Throwable {
                AdManagerInterstitialAdLoadCallback adLoadCallback = invocation.getArgument(2);
                // Pass back null for ad
                adLoadCallback.onAdLoaded(mockAdManagerAd);
                return null;
              }
            })
        .when(mockFlutterAdLoader)
        .loadAdManagerInterstitial(
            anyString(),
            any(AdManagerAdRequest.class),
            any(AdManagerInterstitialAdLoadCallback.class));
    doReturn(mock(ResponseInfo.class)).when(mockAdManagerAd).getResponseInfo();
    flutterAdManagerInterstitialAd.load();
    final AdError adError = new AdError(-1, "test", "error");
    doAnswer(
            new Answer() {
              @Override
              public Object answer(InvocationOnMock invocation) throws Throwable {
                FullScreenContentCallback callback = invocation.getArgument(0);
                callback.onAdFailedToShowFullScreenContent(adError);
                return null;
              }
            })
        .when(mockAdManagerAd)
        .setFullScreenContentCallback(any(FullScreenContentCallback.class));

    flutterAdManagerInterstitialAd.show();
    verify(mockManager).onFailedToShowFullScreenContent(eq(1), eq(adError));
  }

  @Test
  public void loadAdManagerInterstitialAd_appEvent() {
    final AdManagerInterstitialAd mockAdManagerAd = mock(AdManagerInterstitialAd.class);
    doAnswer(
            new Answer() {
              @Override
              public Object answer(InvocationOnMock invocation) throws Throwable {
                AdManagerInterstitialAdLoadCallback adLoadCallback = invocation.getArgument(2);
                // Pass back null for ad
                adLoadCallback.onAdLoaded(mockAdManagerAd);
                return null;
              }
            })
        .when(mockFlutterAdLoader)
        .loadAdManagerInterstitial(
            anyString(),
            any(AdManagerAdRequest.class),
            any(AdManagerInterstitialAdLoadCallback.class));

    doReturn(mock(ResponseInfo.class)).when(mockAdManagerAd).getResponseInfo();

    doAnswer(
            new Answer() {
              @Override
              public Object answer(InvocationOnMock invocation) throws Throwable {
                AppEventListener listener = invocation.getArgument(0);
                listener.onAppEvent("test", "data");
                return null;
              }
            })
        .when(mockAdManagerAd)
        .setAppEventListener(any(AppEventListener.class));

    flutterAdManagerInterstitialAd.load();

    verify(mockAdManagerAd).setAppEventListener(any(AppEventListener.class));
    verify(mockManager).onAppEvent(eq(1), eq("test"), eq("data"));
  }
}
