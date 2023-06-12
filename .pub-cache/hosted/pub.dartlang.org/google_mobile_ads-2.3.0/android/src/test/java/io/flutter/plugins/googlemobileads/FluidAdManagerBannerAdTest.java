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
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.doAnswer;
import static org.mockito.Mockito.doReturn;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.spy;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import android.view.View.OnLayoutChangeListener;
import android.view.ViewGroup.LayoutParams;
import android.widget.ScrollView;
import com.google.android.gms.ads.AdListener;
import com.google.android.gms.ads.AdSize;
import com.google.android.gms.ads.LoadAdError;
import com.google.android.gms.ads.ResponseInfo;
import com.google.android.gms.ads.admanager.AdManagerAdRequest;
import com.google.android.gms.ads.admanager.AdManagerAdView;
import com.google.android.gms.ads.admanager.AppEventListener;
import io.flutter.plugin.common.BinaryMessenger;
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

/** Tests for {@link FluidAdManagerBannerAd}. */
@RunWith(RobolectricTestRunner.class)
public class FluidAdManagerBannerAdTest {

  private AdInstanceManager mockManager;
  private AdManagerAdRequest mockAdRequest;
  private AdManagerAdView mockAdView;
  // The system under test.
  private FluidAdManagerBannerAd fluidAd;

  @Before
  public void setup() {
    // Setup mock dependencies for flutterBannerAd.
    BinaryMessenger mockMessenger = mock(BinaryMessenger.class);
    mockManager = spy(new AdInstanceManager(mock(MethodChannel.class)));
    FlutterAdManagerAdRequest mockFlutterAdRequest = mock(FlutterAdManagerAdRequest.class);
    mockAdRequest = mock(AdManagerAdRequest.class);
    when(mockFlutterAdRequest.asAdManagerAdRequest(anyString())).thenReturn(mockAdRequest);
    BannerAdCreator bannerAdCreator = mock(BannerAdCreator.class);
    mockAdView = mock(AdManagerAdView.class);
    doReturn(mockAdView).when(bannerAdCreator).createAdManagerAdView();
    fluidAd =
        new FluidAdManagerBannerAd(1, mockManager, "testId", mockFlutterAdRequest, bannerAdCreator);
  }

  @Test
  public void failedToLoad() {
    final LoadAdError loadError = mock(LoadAdError.class);
    ResponseInfo responseInfo = mock(ResponseInfo.class);
    doReturn("id").when(responseInfo).getResponseId();
    doReturn("className").when(responseInfo).getMediationAdapterClassName();
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

    fluidAd.load();

    verify(mockAdView).setLayoutParams(any(LayoutParams.class));
    verify(mockAdView).loadAd(eq(mockAdRequest));
    verify(mockAdView).setAdListener(any(AdListener.class));
    verify(mockAdView).setAppEventListener(any(AppEventListener.class));
    verify(mockAdView).setAdUnitId(eq("testId"));
    verify(mockAdView).setAdSizes(AdSize.FLUID);
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
                listener.onAdClosed();
                listener.onAdOpened();
                listener.onAdClicked();
                return null;
              }
            })
        .when(mockAdView)
        .setAdListener(any(AdListener.class));
    final ResponseInfo responseInfo = mock(ResponseInfo.class);
    doReturn(responseInfo).when(mockAdView).getResponseInfo();
    fluidAd.load();

    verify(mockAdView).setLayoutParams(any(LayoutParams.class));
    verify(mockAdView).loadAd(eq(mockAdRequest));
    verify(mockAdView).setAdListener(any(AdListener.class));
    verify(mockAdView).setAdUnitId(eq("testId"));
    verify(mockAdView).setAdSizes(AdSize.FLUID);
    verify(mockManager).onAdLoaded(eq(1), eq(responseInfo));
    verify(mockManager).onAdImpression(eq(1));
    verify(mockManager).onAdClosed(eq(1));
    verify(mockManager).onAdOpened(eq(1));
    verify(mockManager).onAdClicked(eq(1));

    // Verify that ad is correctly put into container view.
    FluidAdManagerBannerAd spy = spy(fluidAd);
    ScrollView mockContainer = mock(ScrollView.class);
    doReturn(mockContainer).when(spy).createContainerView();
    assertEquals(spy.getPlatformView().getView(), mockAdView);
    verify(mockContainer).setClipChildren(false);
    verify(mockContainer).setVerticalScrollBarEnabled(false);
    verify(mockContainer).setHorizontalScrollBarEnabled(false);

    // Height changed callback.
    ArgumentCaptor<OnLayoutChangeListener> layoutChangeCaptor =
        ArgumentCaptor.forClass(OnLayoutChangeListener.class);
    verify(mockAdView).addOnLayoutChangeListener(layoutChangeCaptor.capture());
    doReturn(10).when(mockAdView).getMeasuredHeight();

    layoutChangeCaptor.getValue().onLayoutChange(mockAdView, 0, 0, 10, 10, 0, 0, 0, 0);
    verify(mockManager).onFluidAdHeightChanged(eq(1), eq(10));
  }

  @Test
  public void appEventListener() {
    doAnswer(
            new Answer() {
              @Override
              public Object answer(InvocationOnMock invocation) throws Throwable {
                AppEventListener listener = invocation.getArgument(0);
                listener.onAppEvent("appEvent", "data");
                return null;
              }
            })
        .when(mockAdView)
        .setAppEventListener(any(AppEventListener.class));

    fluidAd.load();

    verify(mockManager).onAppEvent(eq(1), eq("appEvent"), eq("data"));
  }

  @Test
  public void dispose() {
    fluidAd.load();

    FluidAdManagerBannerAd spy = spy(fluidAd);
    ScrollView mockContainer = mock(ScrollView.class);
    doReturn(mockContainer).when(spy).createContainerView();

    assertEquals(spy.getPlatformView().getView(), mockAdView);
    PlatformView platformView = spy.getPlatformView();
    assertNotNull(platformView);

    spy.dispose();
    verify(mockAdView).destroy();
    assertNull(spy.getPlatformView());
    // Check that the platform view still retains a reference to the view until
    // dispose is called on it.
    assertNotNull(platformView.getView());
    platformView.dispose();
    assertNull(platformView.getView());
  }
}
