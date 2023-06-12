// Copyright 2022 Google LLC
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
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.doReturn;
import static org.mockito.Mockito.mock;

import android.content.Context;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageManager;
import android.content.pm.PackageManager.NameNotFoundException;
import android.os.Bundle;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.RobolectricTestRunner;

/** Tests {@link FlutterRequestAgentProvider}. */
@RunWith(RobolectricTestRunner.class)
public class FlutterRequestAgentProviderTest {

  private Context mockContext;
  private PackageManager mockPackageManager;
  private ApplicationInfo mockApplicationInfo;
  private static final String PACKAGE_NAME = "some.test.package";
  private Bundle metaData;

  @Before
  public void setUp() throws NameNotFoundException {
    mockContext = mock(Context.class);
    mockPackageManager = mock(PackageManager.class);
    mockApplicationInfo = mock(ApplicationInfo.class);
    metaData = new Bundle();
    mockApplicationInfo.metaData = metaData;
    doReturn(mockContext).when(mockContext).getApplicationContext();
    doReturn(mockPackageManager).when(mockContext).getPackageManager();
    doReturn(PACKAGE_NAME).when(mockContext).getPackageName();
    doReturn(mockApplicationInfo)
        .when(mockPackageManager)
        .getApplicationInfo(eq(PACKAGE_NAME), eq(PackageManager.GET_META_DATA));
  }

  @Test
  public void testGetRequestAgent_noTemplateMetadata() {
    FlutterRequestAgentProvider sut = new FlutterRequestAgentProvider(mockContext);
    String requestAgent = sut.getRequestAgent();
    assertEquals(requestAgent, Constants.REQUEST_AGENT_PREFIX_VERSIONED);
  }

  @Test
  public void testGetRequestAgent_newsTemplateMetadata() {
    metaData.putString(FlutterRequestAgentProvider.NEWS_VERSION_KEY, "1.2.54");
    FlutterRequestAgentProvider sut = new FlutterRequestAgentProvider(mockContext);
    String requestAgent = sut.getRequestAgent();
    assertEquals(
        requestAgent,
        Constants.REQUEST_AGENT_PREFIX_VERSIONED
            + "_"
            + Constants.REQUEST_AGENT_NEWS_TEMPLATE_PREFIX
            + "-1.2.54");
  }

  @Test
  public void testGetRequestAgent_gameTemplateMetadata() {
    metaData.putString(FlutterRequestAgentProvider.GAME_VERSION_KEY, "1.2.54");
    FlutterRequestAgentProvider sut = new FlutterRequestAgentProvider(mockContext);
    String requestAgent = sut.getRequestAgent();
    assertEquals(
        requestAgent,
        Constants.REQUEST_AGENT_PREFIX_VERSIONED
            + "_"
            + Constants.REQUEST_AGENT_GAME_TEMPLATE_PREFIX
            + "-1.2.54");
  }

  @Test
  public void testGetRequestAgent_gameAndNewsTemplateMetadata() {
    metaData.putString(FlutterRequestAgentProvider.NEWS_VERSION_KEY, "1.2.54");
    metaData.putString(FlutterRequestAgentProvider.GAME_VERSION_KEY, "asdfg");
    FlutterRequestAgentProvider sut = new FlutterRequestAgentProvider(mockContext);
    String requestAgent = sut.getRequestAgent();
    assertEquals(
        requestAgent,
        Constants.REQUEST_AGENT_PREFIX_VERSIONED
            + "_"
            + Constants.REQUEST_AGENT_NEWS_TEMPLATE_PREFIX
            + "-1.2.54"
            + "_"
            + Constants.REQUEST_AGENT_GAME_TEMPLATE_PREFIX
            + "-asdfg");
  }
}
