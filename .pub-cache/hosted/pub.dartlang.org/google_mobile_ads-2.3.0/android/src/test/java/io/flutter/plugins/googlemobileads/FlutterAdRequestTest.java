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
import static org.junit.Assert.assertTrue;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.doReturn;
import static org.mockito.Mockito.mock;

import android.os.Bundle;
import com.google.ads.mediation.admob.AdMobAdapter;
import com.google.android.gms.ads.AdRequest;
import io.flutter.plugins.googlemobileads.FlutterAdRequest.Builder;
import java.util.Collections;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.RobolectricTestRunner;

/** Tests for {@link FlutterAdRequest}. */
@RunWith(RobolectricTestRunner.class)
public class FlutterAdRequestTest {

  @Test
  public void testAsAdRequest_noParams() {
    FlutterAdRequest flutterAdRequest = new Builder().build();
    AdRequest adRequest = flutterAdRequest.asAdRequest("test-ad-unit");
    assertNull(adRequest.getContentUrl());
    assertTrue(adRequest.getNeighboringContentUrls().isEmpty());
    assertTrue(adRequest.getKeywords().isEmpty());
    assertNull(adRequest.getNetworkExtrasBundle(AdMobAdapter.class));
  }

  @Test
  public void testAsAdRequest_allParams() {
    MediationNetworkExtrasProvider provider = mock(MediationNetworkExtrasProvider.class);
    Bundle bundle = new Bundle();
    bundle.putString("npa", "0");
    doReturn(Collections.singletonMap(AdMobAdapter.class, bundle))
        .when(provider)
        .getMediationExtras(eq("test-ad-unit"), eq("identifier"));

    FlutterAdRequest flutterAdRequest =
        new Builder()
            .setKeywords(Collections.singletonList("keyword"))
            .setContentUrl("content-url")
            .setNeighboringContentUrls(Collections.singletonList("neighbor"))
            .setHttpTimeoutMillis(100)
            .setNonPersonalizedAds(true)
            .setMediationNetworkExtrasIdentifier("identifier")
            .setMediationNetworkExtrasProvider(provider)
            .build();

    AdRequest adRequest = flutterAdRequest.asAdRequest("test-ad-unit");

    assertEquals(adRequest.getKeywords(), Collections.singleton("keyword"));
    assertEquals(adRequest.getContentUrl(), "content-url");
    assertEquals(adRequest.getNeighboringContentUrls(), Collections.singletonList("neighbor"));
    // Previous value of "npa" should get overridden.
    assertEquals(adRequest.getNetworkExtrasBundle(AdMobAdapter.class).get("npa"), "1");
  }

  @Test
  public void testAsAdRequestMediationNetworkExtras() {
    MediationNetworkExtrasProvider provider = mock(MediationNetworkExtrasProvider.class);
    Bundle bundle = new Bundle();
    bundle.putString("key", "value");
    doReturn(Collections.singletonMap(AdMobAdapter.class, bundle))
        .when(provider)
        .getMediationExtras(eq("test-ad-unit"), eq("identifier"));

    FlutterAdRequest flutterAdRequest =
        new Builder()
            .setMediationNetworkExtrasIdentifier("identifier")
            .setMediationNetworkExtrasProvider(provider)
            .setNonPersonalizedAds(true)
            .build();

    AdRequest adRequest = flutterAdRequest.asAdRequest("test-ad-unit");
    assertEquals(adRequest.getNetworkExtrasBundle(AdMobAdapter.class).get("key"), "value");
    assertEquals(adRequest.getNetworkExtrasBundle(AdMobAdapter.class).get("npa"), "1");
  }
}
