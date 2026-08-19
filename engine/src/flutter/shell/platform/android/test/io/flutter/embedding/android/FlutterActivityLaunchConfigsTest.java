// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.embedding.android;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertNull;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import android.content.Context;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageManager;
import android.os.Bundle;
import androidx.test.ext.junit.runners.AndroidJUnit4;
import org.junit.Test;
import org.junit.runner.RunWith;

@RunWith(AndroidJUnit4.class)
public class FlutterActivityLaunchConfigsTest {
  @Test
  public void getInitialRouteFromManifest_extractsRouteFlag() throws Exception {
    Context mockContext = mock(Context.class);
    PackageManager mockPackageManager = mock(PackageManager.class);
    when(mockContext.getPackageManager()).thenReturn(mockPackageManager);
    when(mockContext.getPackageName()).thenReturn("io.flutter.test");

    ApplicationInfo applicationInfo = new ApplicationInfo();
    applicationInfo.metaData = new Bundle();
    applicationInfo.metaData.putString(
        "io.flutter.app.androidEngineShellArgs", "[\"--foo=bar\", \"--route=/custom_route\"]");
    when(mockPackageManager.getApplicationInfo(
            eq("io.flutter.test"), eq(PackageManager.GET_META_DATA)))
        .thenReturn(applicationInfo);

    String route = FlutterActivityLaunchConfigs.getInitialRouteFromManifest(mockContext);
    assertEquals("/custom_route", route);
  }

  @Test
  public void getInitialRouteFromManifest_returnsNullWhenNotFoundOrMissing() throws Exception {
    Context mockContext = mock(Context.class);
    PackageManager mockPackageManager = mock(PackageManager.class);
    when(mockContext.getPackageManager()).thenReturn(mockPackageManager);
    when(mockContext.getPackageName()).thenReturn("io.flutter.test");

    // No metadata
    ApplicationInfo applicationInfo = new ApplicationInfo();
    when(mockPackageManager.getApplicationInfo(
            eq("io.flutter.test"), eq(PackageManager.GET_META_DATA)))
        .thenReturn(applicationInfo);
    assertNull(FlutterActivityLaunchConfigs.getInitialRouteFromManifest(mockContext));

    // Metadata without --route
    applicationInfo.metaData = new Bundle();
    applicationInfo.metaData.putString("io.flutter.app.androidEngineShellArgs", "[\"--foo=bar\"]");
    assertNull(FlutterActivityLaunchConfigs.getInitialRouteFromManifest(mockContext));

    // NameNotFoundException
    when(mockPackageManager.getApplicationInfo(
            eq("io.flutter.test"), eq(PackageManager.GET_META_DATA)))
        .thenThrow(new PackageManager.NameNotFoundException());
    assertNull(FlutterActivityLaunchConfigs.getInitialRouteFromManifest(mockContext));
  }
}
