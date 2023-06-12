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
import com.google.android.gms.ads.AdSize;
import com.google.android.gms.ads.AdValue;
import com.google.android.gms.ads.AdView;
import com.google.android.gms.ads.LoadAdError;
import com.google.android.gms.ads.ResponseInfo;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.platform.PlatformView;
import io.flutter.plugins.googlemobileads.FlutterAd.FlutterLoadAdError;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.mockito.ArgumentCaptor;
import org.mockito.invocation.InvocationOnMock;
import org.mockito.stubbing.Answer;
import org.robolectric.RobolectricTestRunner;

/** Tests for {@link FlutterBannerAd}. */
@RunWith(RobolectricTestRunner.class)
public class FlutterBannerAdTest {

  private AdInstanceManager mockManager;
  private AdView mockAdView;
  private AdRequest mockAdRequest;
  private AdSize adSize;

  // The system under test.
  private FlutterBannerAd flutterBannerAd;

  @Before
  public void setup() {
    mockManager = spy(new AdInstanceManager(mock(MethodChannel.class)));
    doReturn(mock(Activity.class)).when(mockManager).getActivity();
    final FlutterAdRequest mockFlutterRequest = mock(FlutterAdRequest.class);
    mockAdRequest = mock(AdRequest.class);
    final FlutterAdSize mockFlutterAdSize = mock(FlutterAdSize.class);
    adSize = new AdSize(1, 2);
    when(mockFlutterRequest.asAdRequest(anyString())).thenReturn(mockAdRequest);
    when(mockFlutterAdSize.getAdSize()).thenReturn(adSize);
    BannerAdCreator bannerAdCreator = mock(BannerAdCreator.class);
    mockAdView = mock(AdView.class);
    doReturn(mockAdView).when(bannerAdCreator).createAdView();
    flutterBannerAd =
        new FlutterBannerAd(
            1, mockManager, "testId", mockFlutterRequest, mockFlutterAdSize, bannerAdCreator);
  }

  @Test
  public void failedToLoad() {
    final LoadAdError loadError = mock(LoadAdError.class);
    doReturn(1).when(loadError).getCode();
    doReturn("2").when(loadError).getDomain();
    doReturn("3").when(loadError).getMessage();
    doReturn(null).when(loadError).getResponseInfo();
    doAnswer(
            new Answer() {
              @Override
              public Object answer(InvocationOnMock invocation) throws Throwable {
                AdListener listener = invocation.getArgument(0);
                listener.onAdFailedToLoad(loadError);
                return null;
              }
            })
        .when(mockAdView)
        .setAdListener(any(AdListener.class));

    flutterBannerAd.load();
    verify(mockAdView).loadAd(eq(mockAdRequest));
    verify(mockAdView).setAdListener(any(AdListener.class));
    verify(mockAdView).setAdUnitId(eq("testId"));
    verify(mockAdView).setAdSize(adSize);
    FlutterLoadAdError expectedError = new FlutterLoadAdError(loadError);
    verify(mockManager).onAdFailedToLoad(eq(1), eq(expectedError));
  }

  @Test
  public void loadWithListenerCallbacks() {
    doAnswer(
            new Answer() {
              @Override
              public Object answer(InvocationOnMock invocation) throws Throwable {
                AdListener listener = invocation.getArgument(0);
                listener.onAdLoaded();
                listener.onAdImpression();
                listener.onAdClicked();
                listener.onAdClosed();
                listener.onAdOpened();
                return null;
              }
            })
        .when(mockAdView)
        .setAdListener(any(AdListener.class));

    final ResponseInfo responseInfo = mock(ResponseInfo.class);
    doReturn(responseInfo).when(mockAdView).getResponseInfo();

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
        .when(mockAdView)
        .setOnPaidEventListener(any(FlutterPaidEventListener.class));

    flutterBannerAd.load();

    verify(mockAdView).loadAd(eq(mockAdRequest));
    verify(mockAdView).setAdListener(any(AdListener.class));
    verify(mockAdView).setAdUnitId(eq("testId"));
    verify(mockAdView).setAdSize(adSize);
    verify(mockManager).onAdLoaded(eq(1), eq(responseInfo));
    verify(mockManager).onAdImpression(eq(1));
    verify(mockManager).onAdClicked(eq(1));
    verify(mockManager).onAdClosed(eq(1));
    verify(mockManager).onAdOpened(eq(1));
    assertEquals(flutterBannerAd.getPlatformView().getView(), mockAdView);
    verify(mockAdView).setOnPaidEventListener(any(FlutterPaidEventListener.class));
    final ArgumentCaptor<FlutterAdValue> adValueCaptor = forClass(FlutterAdValue.class);
    verify(mockManager).onPaidEvent(eq(flutterBannerAd), adValueCaptor.capture());
    assertEquals(adValueCaptor.getValue().currencyCode, "Dollars");
    assertEquals(adValueCaptor.getValue().precisionType, 1);
    assertEquals(adValueCaptor.getValue().valueMicros, 1000L);
  }

  @Test
  public void dispose() {
    flutterBannerAd.load();

    assertEquals(flutterBannerAd.getPlatformView().getView(), mockAdView);
    PlatformView platformView = flutterBannerAd.getPlatformView();
    assertNotNull(platformView);

    flutterBannerAd.dispose();
    verify(mockAdView).destroy();
    assertNull(flutterBannerAd.getPlatformView());
    // Check that the platform view still retains a reference to the view until
    // dispose is called on it.
    assertNotNull(platformView.getView());
    platformView.dispose();
    assertNull(platformView.getView());
  }
}
