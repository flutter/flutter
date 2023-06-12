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
import com.google.android.gms.ads.AdRequest;
import com.google.android.gms.ads.AdValue;
import com.google.android.gms.ads.FullScreenContentCallback;
import com.google.android.gms.ads.LoadAdError;
import com.google.android.gms.ads.ResponseInfo;
import com.google.android.gms.ads.interstitial.InterstitialAd;
import com.google.android.gms.ads.interstitial.InterstitialAdLoadCallback;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugins.googlemobileads.FlutterAd.FlutterLoadAdError;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.mockito.ArgumentCaptor;
import org.mockito.invocation.InvocationOnMock;
import org.mockito.stubbing.Answer;
import org.robolectric.RobolectricTestRunner;

/** Tests for {@link FlutterInterstitialAd}. */
@RunWith(RobolectricTestRunner.class)
public class FlutterInterstitialAdTest {

  private AdInstanceManager mockManager;
  private FlutterAdLoader mockFlutterAdLoader;
  private AdRequest mockAdRequest;

  // The system under test.
  private FlutterInterstitialAd flutterInterstitialAd;

  @Before
  public void setup() {
    mockManager = spy(new AdInstanceManager(mock(MethodChannel.class)));
    doReturn(mock(Activity.class)).when(mockManager).getActivity();
    final FlutterAdRequest mockFlutterRequest = mock(FlutterAdRequest.class);
    mockAdRequest = mock(AdRequest.class);
    mockFlutterAdLoader = mock(FlutterAdLoader.class);
    when(mockFlutterRequest.asAdRequest(anyString())).thenReturn(mockAdRequest);

    flutterInterstitialAd =
        new FlutterInterstitialAd(
            1, mockManager, "testId", mockFlutterRequest, mockFlutterAdLoader);
  }

  @Test
  public void loadInterstitialAd_failedToLoad() {
    final LoadAdError loadAdError = mock(LoadAdError.class);
    ResponseInfo responseInfo = mock(ResponseInfo.class);
    doReturn("id").when(responseInfo).getResponseId();
    doReturn("className").when(responseInfo).getMediationAdapterClassName();
    doReturn(1).when(loadAdError).getCode();
    doReturn("2").when(loadAdError).getDomain();
    doReturn("3").when(loadAdError).getMessage();
    doReturn(null).when(loadAdError).getResponseInfo();
    doAnswer(
            new Answer() {
              @Override
              public Object answer(InvocationOnMock invocation) throws Throwable {
                InterstitialAdLoadCallback adLoadCallback = invocation.getArgument(2);
                // Pass back null for ad
                adLoadCallback.onAdFailedToLoad(loadAdError);
                return null;
              }
            })
        .when(mockFlutterAdLoader)
        .loadInterstitial(anyString(), any(AdRequest.class), any(InterstitialAdLoadCallback.class));

    flutterInterstitialAd.load();

    verify(mockFlutterAdLoader)
        .loadInterstitial(eq("testId"), eq(mockAdRequest), any(InterstitialAdLoadCallback.class));

    FlutterLoadAdError expectedError = new FlutterLoadAdError(loadAdError);
    verify(mockManager).onAdFailedToLoad(eq(1), eq(expectedError));
  }

  @Test
  public void loadInterstitialAd_showSuccess() {
    final InterstitialAd mockAd = mock(InterstitialAd.class);
    doAnswer(
            new Answer() {
              @Override
              public Object answer(InvocationOnMock invocation) throws Throwable {
                InterstitialAdLoadCallback adLoadCallback = invocation.getArgument(2);
                // Pass back null for ad
                adLoadCallback.onAdLoaded(mockAd);
                return null;
              }
            })
        .when(mockFlutterAdLoader)
        .loadInterstitial(anyString(), any(AdRequest.class), any(InterstitialAdLoadCallback.class));
    final ResponseInfo responseInfo = mock(ResponseInfo.class);
    doReturn(responseInfo).when(mockAd).getResponseInfo();
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
        .when(mockAd)
        .setOnPaidEventListener(any(FlutterPaidEventListener.class));

    flutterInterstitialAd.load();

    verify(mockFlutterAdLoader)
        .loadInterstitial(eq("testId"), eq(mockAdRequest), any(InterstitialAdLoadCallback.class));

    verify(mockManager).onAdLoaded(eq(1), eq(responseInfo));
    verify(mockAd).setOnPaidEventListener(any(FlutterPaidEventListener.class));

    final ArgumentCaptor<FlutterAdValue> adValueCaptor = forClass(FlutterAdValue.class);
    verify(mockManager).onPaidEvent(eq(flutterInterstitialAd), adValueCaptor.capture());
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
                callback.onAdClicked();
                callback.onAdDismissedFullScreenContent();
                return null;
              }
            })
        .when(mockAd)
        .setFullScreenContentCallback(any(FullScreenContentCallback.class));

    flutterInterstitialAd.show();
    verify(mockAd).setFullScreenContentCallback(any(FullScreenContentCallback.class));
    verify(mockAd).show(eq(mockManager.getActivity()));
    verify(mockManager).onAdShowedFullScreenContent(eq(1));
    verify(mockManager).onAdDismissedFullScreenContent(eq(1));
    verify(mockManager).onAdImpression(eq(1));
    verify(mockManager).onAdClicked(eq(1));
    assertNull(flutterInterstitialAd.getPlatformView());
  }

  @Test
  public void loadInterstitialAd_showFailure() {
    final InterstitialAd mockAd = mock(InterstitialAd.class);
    doAnswer(
            new Answer() {
              @Override
              public Object answer(InvocationOnMock invocation) throws Throwable {
                InterstitialAdLoadCallback adLoadCallback = invocation.getArgument(2);
                // Pass back null for ad
                adLoadCallback.onAdLoaded(mockAd);
                return null;
              }
            })
        .when(mockFlutterAdLoader)
        .loadInterstitial(anyString(), any(AdRequest.class), any(InterstitialAdLoadCallback.class));
    doReturn(mock(ResponseInfo.class)).when(mockAd).getResponseInfo();
    flutterInterstitialAd.load();
    final AdError adError = new AdError(1, "2", "3");

    doAnswer(
            new Answer() {
              @Override
              public Object answer(InvocationOnMock invocation) throws Throwable {
                FullScreenContentCallback callback = invocation.getArgument(0);
                callback.onAdFailedToShowFullScreenContent(adError);
                return null;
              }
            })
        .when(mockAd)
        .setFullScreenContentCallback(any(FullScreenContentCallback.class));

    flutterInterstitialAd.show();
    verify(mockManager).onFailedToShowFullScreenContent(eq(1), eq(adError));
  }

  @Test
  public void loadInterstitialAd_setImmersiveMode() {
    final InterstitialAd mockAd = mock(InterstitialAd.class);
    doAnswer(
            new Answer() {
              @Override
              public Object answer(InvocationOnMock invocation) throws Throwable {
                InterstitialAdLoadCallback adLoadCallback = invocation.getArgument(2);
                adLoadCallback.onAdLoaded(mockAd);
                // Pass back null for ad
                return null;
              }
            })
        .when(mockFlutterAdLoader)
        .loadInterstitial(anyString(), any(AdRequest.class), any(InterstitialAdLoadCallback.class));
    flutterInterstitialAd.load();
    flutterInterstitialAd.setImmersiveMode(true);
    verify(mockAd).setImmersiveMode(true);
  }
}
