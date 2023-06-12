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
import static org.mockito.ArgumentMatchers.anyInt;
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
import com.google.android.gms.ads.admanager.AdManagerAdRequest;
import com.google.android.gms.ads.appopen.AppOpenAd;
import com.google.android.gms.ads.appopen.AppOpenAd.AppOpenAdLoadCallback;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugins.googlemobileads.FlutterAd.FlutterLoadAdError;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.mockito.ArgumentCaptor;
import org.mockito.invocation.InvocationOnMock;
import org.mockito.stubbing.Answer;
import org.robolectric.RobolectricTestRunner;

/** Tests for {@link FlutterAppOpenAd}. */
@RunWith(RobolectricTestRunner.class)
public class FlutterAppOpenAdTest {

  private FlutterAdLoader mockFlutterAdLoader;
  private AdInstanceManager mockManager;
  private AdManagerAdRequest mockAdManagerAdRequest;
  private AdRequest mockAdRequest;
  private AppOpenAd mockAd;

  // The system under test.
  private FlutterAppOpenAd flutterAppOpenAd;

  @Before
  public void setup() {
    mockManager = spy(new AdInstanceManager(mock(MethodChannel.class)));
    doReturn(mock(Activity.class)).when(mockManager).getActivity();
    mockFlutterAdLoader = mock(FlutterAdLoader.class);
    mockAd = mock(AppOpenAd.class);
  }

  private void setupAdmobMocks() {
    FlutterAdRequest mockFlutterAdRequest = mock(FlutterAdRequest.class);
    mockAdRequest = mock(AdRequest.class);
    when(mockFlutterAdRequest.asAdRequest(anyString())).thenReturn(mockAdRequest);
    flutterAppOpenAd =
        new FlutterAppOpenAd(
            1, 2, mockManager, "testId", mockFlutterAdRequest, null, mockFlutterAdLoader);
  }

  private void setupAdManagerMocks() {
    FlutterAdManagerAdRequest mockAdManagerFlutterRequest = mock(FlutterAdManagerAdRequest.class);
    mockAdManagerAdRequest = mock(AdManagerAdRequest.class);
    when(mockAdManagerFlutterRequest.asAdManagerAdRequest(anyString()))
        .thenReturn(mockAdManagerAdRequest);
    flutterAppOpenAd =
        new FlutterAppOpenAd(
            1, 2, mockManager, "testId", null, mockAdManagerFlutterRequest, mockFlutterAdLoader);
  }

  @Test
  public void loadAdManager_failedToLoad() {
    setupAdManagerMocks();
    final LoadAdError loadAdError = mock(LoadAdError.class);
    doReturn(1).when(loadAdError).getCode();
    doReturn("2").when(loadAdError).getDomain();
    doReturn("3").when(loadAdError).getMessage();
    doReturn(null).when(loadAdError).getResponseInfo();
    doAnswer(
            new Answer() {
              @Override
              public Object answer(InvocationOnMock invocation) throws Throwable {
                AppOpenAdLoadCallback adLoadCallback = invocation.getArgument(3);
                // Pass back null for ad
                adLoadCallback.onAdFailedToLoad(loadAdError);
                return null;
              }
            })
        .when(mockFlutterAdLoader)
        .loadAdManagerAppOpen(
            anyString(), any(AdManagerAdRequest.class), anyInt(), any(AppOpenAdLoadCallback.class));

    flutterAppOpenAd.load();

    verify(mockFlutterAdLoader)
        .loadAdManagerAppOpen(
            eq("testId"), eq(mockAdManagerAdRequest), eq(2), any(AppOpenAdLoadCallback.class));

    FlutterLoadAdError expectedError = new FlutterLoadAdError(loadAdError);
    verify(mockManager).onAdFailedToLoad(eq(1), eq(expectedError));
  }

  @Test
  public void loadAdmob_failedToLoad() {
    setupAdmobMocks();
    final LoadAdError loadAdError = mock(LoadAdError.class);
    doReturn(1).when(loadAdError).getCode();
    doReturn("2").when(loadAdError).getDomain();
    doReturn("3").when(loadAdError).getMessage();
    doReturn(null).when(loadAdError).getResponseInfo();
    doAnswer(
            new Answer() {
              @Override
              public Object answer(InvocationOnMock invocation) throws Throwable {
                AppOpenAdLoadCallback adLoadCallback = invocation.getArgument(3);
                // Pass back null for ad
                adLoadCallback.onAdFailedToLoad(loadAdError);
                return null;
              }
            })
        .when(mockFlutterAdLoader)
        .loadAppOpen(anyString(), any(AdRequest.class), anyInt(), any(AppOpenAdLoadCallback.class));

    flutterAppOpenAd.load();

    verify(mockFlutterAdLoader)
        .loadAppOpen(eq("testId"), eq(mockAdRequest), eq(2), any(AppOpenAdLoadCallback.class));

    FlutterLoadAdError expectedError = new FlutterLoadAdError(loadAdError);
    verify(mockManager).onAdFailedToLoad(eq(1), eq(expectedError));
  }

  @Test
  public void loadAdManager_success() {
    // Setup mocks for loading.
    setupAdManagerMocks();

    final AppOpenAd mockAd = mock(AppOpenAd.class);
    doAnswer(
            new Answer() {
              @Override
              public Object answer(InvocationOnMock invocation) throws Throwable {
                AppOpenAdLoadCallback adLoadCallback = invocation.getArgument(3);
                // Pass back null for ad
                adLoadCallback.onAdLoaded(mockAd);
                return null;
              }
            })
        .when(mockFlutterAdLoader)
        .loadAdManagerAppOpen(
            anyString(), any(AdManagerAdRequest.class), anyInt(), any(AppOpenAdLoadCallback.class));
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

    // Load an ad and verify correct ad loader method is called.
    flutterAppOpenAd.load();

    verify(mockFlutterAdLoader)
        .loadAdManagerAppOpen(
            eq("testId"), eq(mockAdManagerAdRequest), eq(2), any(AppOpenAdLoadCallback.class));

    verify(mockManager).onAdLoaded(eq(1), eq(responseInfo));
    verify(mockAd).setOnPaidEventListener(any(FlutterPaidEventListener.class));
    final ArgumentCaptor<FlutterAdValue> adValueCaptor = forClass(FlutterAdValue.class);
    verify(mockManager).onPaidEvent(eq(flutterAppOpenAd), adValueCaptor.capture());
    assertEquals(adValueCaptor.getValue().currencyCode, "Dollars");
    assertEquals(adValueCaptor.getValue().precisionType, 1);
    assertEquals(adValueCaptor.getValue().valueMicros, 1000L);
  }

  @Test
  public void loadAdmob_success() {
    // Setup mocks for loading.
    setupAdmobMocks();

    final AppOpenAd mockAd = mock(AppOpenAd.class);
    doAnswer(
            new Answer() {
              @Override
              public Object answer(InvocationOnMock invocation) throws Throwable {
                AppOpenAdLoadCallback adLoadCallback = invocation.getArgument(3);
                // Pass back null for ad
                adLoadCallback.onAdLoaded(mockAd);
                return null;
              }
            })
        .when(mockFlutterAdLoader)
        .loadAppOpen(anyString(), any(AdRequest.class), anyInt(), any(AppOpenAdLoadCallback.class));
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

    // Load an ad and verify correct ad loader method is called.
    flutterAppOpenAd.load();

    verify(mockFlutterAdLoader)
        .loadAppOpen(eq("testId"), eq(mockAdRequest), eq(2), any(AppOpenAdLoadCallback.class));

    verify(mockManager).onAdLoaded(eq(1), eq(responseInfo));
    verify(mockAd).setOnPaidEventListener(any(FlutterPaidEventListener.class));
    final ArgumentCaptor<FlutterAdValue> adValueCaptor = forClass(FlutterAdValue.class);
    verify(mockManager).onPaidEvent(eq(flutterAppOpenAd), adValueCaptor.capture());
    assertEquals(adValueCaptor.getValue().currencyCode, "Dollars");
    assertEquals(adValueCaptor.getValue().precisionType, 1);
    assertEquals(adValueCaptor.getValue().valueMicros, 1000L);
  }

  /** Helper for loading an ad manager ad. */
  private void loadAdManagerAd() {
    setupAdManagerMocks();
    doAnswer(
            new Answer() {
              @Override
              public Object answer(InvocationOnMock invocation) throws Throwable {
                AppOpenAdLoadCallback adLoadCallback = invocation.getArgument(3);
                // Pass back null for ad
                adLoadCallback.onAdLoaded(mockAd);
                return null;
              }
            })
        .when(mockFlutterAdLoader)
        .loadAdManagerAppOpen(
            anyString(), any(AdManagerAdRequest.class), anyInt(), any(AppOpenAdLoadCallback.class));
    final ResponseInfo responseInfo = mock(ResponseInfo.class);
    doReturn(responseInfo).when(mockAd).getResponseInfo();

    // Load an ad and verify correct ad loader method is called.
    flutterAppOpenAd.load();
  }

  /** Helper for loading an admob ad. */
  private void loadAdmobAd() {
    // Setup mocks for loading.
    setupAdmobMocks();

    doAnswer(
            new Answer() {
              @Override
              public Object answer(InvocationOnMock invocation) throws Throwable {
                AppOpenAdLoadCallback adLoadCallback = invocation.getArgument(3);
                // Pass back null for ad
                adLoadCallback.onAdLoaded(mockAd);
                return null;
              }
            })
        .when(mockFlutterAdLoader)
        .loadAppOpen(anyString(), any(AdRequest.class), anyInt(), any(AppOpenAdLoadCallback.class));
    final ResponseInfo responseInfo = mock(ResponseInfo.class);
    doReturn(responseInfo).when(mockAd).getResponseInfo();

    flutterAppOpenAd.load();
  }

  @Test
  public void loadAdManager_showSuccess() {
    loadAdManagerAd();

    // Setup mocks for show().
    final FullScreenContentCallback[] fullScreenContentCallback = new FullScreenContentCallback[1];
    doAnswer(
            new Answer() {
              @Override
              public Object answer(InvocationOnMock invocation) throws Throwable {
                fullScreenContentCallback[0] = invocation.getArgument(0);
                return null;
              }
            })
        .when(mockAd)
        .setFullScreenContentCallback(any(FullScreenContentCallback.class));

    doAnswer(
            new Answer() {
              @Override
              public Object answer(InvocationOnMock invocation) throws Throwable {
                FullScreenContentCallback callback = fullScreenContentCallback[0];
                callback.onAdShowedFullScreenContent();
                callback.onAdImpression();
                callback.onAdClicked();
                callback.onAdDismissedFullScreenContent();
                return null;
              }
            })
        .when(mockAd)
        .show(any(Activity.class));

    // Show the ad and verify callbacks are set up properly.
    flutterAppOpenAd.show();
    verify(mockAd).setFullScreenContentCallback(any(FullScreenContentCallback.class));
    verify(mockAd).show(eq(mockManager.getActivity()));

    verify(mockManager).onAdShowedFullScreenContent(eq(1));
    verify(mockManager).onAdImpression(eq(1));
    verify(mockManager).onAdClicked(eq(1));
    verify(mockManager).onAdDismissedFullScreenContent(eq(1));

    assertNull(flutterAppOpenAd.getPlatformView());
  }

  @Test
  public void loadAdmob_showSuccess() {
    loadAdmobAd();
    // Setup mocks for show().
    final FullScreenContentCallback[] fullScreenContentCallback = new FullScreenContentCallback[1];
    doAnswer(
            new Answer() {
              @Override
              public Object answer(InvocationOnMock invocation) throws Throwable {
                fullScreenContentCallback[0] = invocation.getArgument(0);
                return null;
              }
            })
        .when(mockAd)
        .setFullScreenContentCallback(any(FullScreenContentCallback.class));

    doAnswer(
            new Answer() {
              @Override
              public Object answer(InvocationOnMock invocation) throws Throwable {
                FullScreenContentCallback callback = fullScreenContentCallback[0];
                callback.onAdShowedFullScreenContent();
                callback.onAdImpression();
                callback.onAdDismissedFullScreenContent();
                ;
                return null;
              }
            })
        .when(mockAd)
        .show(any(Activity.class));

    // Show the ad and verify callbacks are set up properly.
    flutterAppOpenAd.show();
    verify(mockAd).setFullScreenContentCallback(any(FullScreenContentCallback.class));
    verify(mockAd).show(eq(mockManager.getActivity()));

    verify(mockManager).onAdShowedFullScreenContent(eq(1));
    verify(mockManager).onAdImpression(eq(1));
    verify(mockManager).onAdDismissedFullScreenContent(eq(1));

    assertNull(flutterAppOpenAd.getPlatformView());
  }

  @Test
  public void loadAdmob_failToShow() {
    loadAdmobAd();

    // Setup mocks for triggering fail to show callback.
    final AdError adError = new AdError(0, "ad", "error");
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

    flutterAppOpenAd.show();
    verify(mockAd).setFullScreenContentCallback(any(FullScreenContentCallback.class));
    verify(mockManager).onFailedToShowFullScreenContent(eq(1), eq(adError));
  }

  @Test
  public void loadAdManager_failToShow() {
    loadAdManagerAd();

    // Setup mocks for triggering fail to show callback.
    final AdError adError = new AdError(0, "ad", "error");
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

    flutterAppOpenAd.show();
    verify(mockAd).setFullScreenContentCallback(any(FullScreenContentCallback.class));
    verify(mockManager).onFailedToShowFullScreenContent(eq(1), eq(adError));
  }

  @Test
  public void setImmersiveMode() {
    setupAdmobMocks();
    final AppOpenAd mockAd = mock(AppOpenAd.class);
    doAnswer(
            new Answer() {
              @Override
              public Object answer(InvocationOnMock invocation) throws Throwable {
                AppOpenAdLoadCallback adLoadCallback = invocation.getArgument(3);
                adLoadCallback.onAdLoaded(mockAd);
                // Pass back null for ad
                return null;
              }
            })
        .when(mockFlutterAdLoader)
        .loadAppOpen(anyString(), any(AdRequest.class), anyInt(), any(AppOpenAdLoadCallback.class));
    flutterAppOpenAd.load();
    flutterAppOpenAd.setImmersiveMode(false);
    verify(mockAd).setImmersiveMode(eq(false));
  }
}
