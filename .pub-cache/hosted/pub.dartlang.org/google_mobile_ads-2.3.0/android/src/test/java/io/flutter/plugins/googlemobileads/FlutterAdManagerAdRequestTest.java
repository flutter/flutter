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
import static org.junit.Assert.assertNull;
import static org.junit.Assert.assertTrue;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.doReturn;
import static org.mockito.Mockito.mock;

import android.os.Bundle;
import com.google.ads.mediation.admob.AdMobAdapter;
import com.google.android.gms.ads.admanager.AdManagerAdRequest;
import io.flutter.plugins.googlemobileads.FlutterAdManagerAdRequest.Builder;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.RobolectricTestRunner;

/** Tests for {@link FlutterAdManagerAdRequest}. */
@RunWith(RobolectricTestRunner.class)
public class FlutterAdManagerAdRequestTest {

  @Test
  public void testAsAdRequest_noParams() {
    FlutterAdManagerAdRequest flutterAdRequest = new Builder().build();
    AdManagerAdRequest adRequest = flutterAdRequest.asAdManagerAdRequest("test-ad-unit");
    assertNull(adRequest.getContentUrl());
    assertTrue(adRequest.getNeighboringContentUrls().isEmpty());
    assertTrue(adRequest.getKeywords().isEmpty());
    assertTrue(adRequest.getCustomTargeting().isEmpty());
    assertNull(adRequest.getPublisherProvidedId());
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

    Builder builder = new Builder();
    builder.setKeywords(Collections.singletonList("keyword"));
    builder.setContentUrl("content-url");
    builder.setNeighboringContentUrls(Collections.singletonList("neighbor"));
    builder.setHttpTimeoutMillis(100);
    builder.setNonPersonalizedAds(true);
    builder.setMediationNetworkExtrasIdentifier("identifier");
    builder.setMediationNetworkExtrasProvider(provider);
    builder.setCustomTargeting(Collections.singletonMap("targetingKey", "targetingValue"));
    List<String> targetingList = new ArrayList<>();
    targetingList.add("targetingValue1");
    targetingList.add("targetingValue2");

    builder.setCustomTargetingLists(Collections.singletonMap("targetingKey", targetingList));
    builder.setPublisherProvidedId("pubProvidedId");
    builder.build();

    AdManagerAdRequest adRequest = builder.build().asAdManagerAdRequest("test-ad-unit");

    assertEquals(adRequest.getKeywords(), Collections.singleton("keyword"));
    assertEquals(adRequest.getContentUrl(), "content-url");
    assertEquals(adRequest.getNeighboringContentUrls(), Collections.singletonList("neighbor"));
    // Previous value of "npa" should get overridden.
    assertEquals(adRequest.getNetworkExtrasBundle(AdMobAdapter.class).get("npa"), "1");
    assertEquals(adRequest.getPublisherProvidedId(), "pubProvidedId");
    assertFalse(adRequest.getCustomTargeting().isEmpty());
    // If custom targeting keys match, the values are overwritten.
    assertEquals(
        adRequest.getCustomTargeting().get("targetingKey"), "targetingValue1,targetingValue2");
  }

  @Test
  public void testAsAdRequestMediationNetworkExtras() {
    MediationNetworkExtrasProvider provider = mock(MediationNetworkExtrasProvider.class);
    Bundle bundle = new Bundle();
    bundle.putString("key", "value");
    doReturn(Collections.singletonMap(AdMobAdapter.class, bundle))
        .when(provider)
        .getMediationExtras(eq("test-ad-unit"), eq("identifier"));

    Builder builder = new Builder();
    builder
        .setMediationNetworkExtrasIdentifier("identifier")
        .setMediationNetworkExtrasProvider(provider)
        .setNonPersonalizedAds(true);

    AdManagerAdRequest adRequest = builder.build().asAdManagerAdRequest("test-ad-unit");
    assertEquals(adRequest.getNetworkExtrasBundle(AdMobAdapter.class).get("key"), "value");
    assertEquals(adRequest.getNetworkExtrasBundle(AdMobAdapter.class).get("npa"), "1");
  }
}
