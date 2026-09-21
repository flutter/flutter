// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.embedding.engine.loader;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertNotNull;
import static org.junit.Assert.assertNull;
import static org.mockito.Mockito.anyInt;
import static org.mockito.Mockito.anyString;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import android.content.Context;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageManager;
import android.content.res.Resources;
import android.os.Bundle;
import androidx.test.core.app.ApplicationProvider;
import androidx.test.ext.junit.runners.AndroidJUnit4;
import io.flutter.embedding.engine.FlutterEngineFlags;
import org.junit.Test;
import org.junit.runner.RunWith;

@RunWith(AndroidJUnit4.class)
public class ApplicationInfoLoaderTest {

  @Test
  public void itGeneratesCorrectApplicationInfoWithDefaultManifest() {
    FlutterApplicationInfo info =
        ApplicationInfoLoader.load(ApplicationProvider.getApplicationContext());
    assertNotNull(info);
    assertEquals("libapp.so", info.aotSharedLibraryName);
    assertEquals("vm_snapshot_data", info.vmSnapshotData);
    assertEquals("isolate_snapshot_data", info.isolateSnapshotData);
    assertEquals("flutter_assets", info.flutterAssetsDir);
    assertEquals("", info.domainNetworkPolicy);
    assertNull(info.nativeLibraryDir);
  }

  @SuppressWarnings("deprecation")
  // getApplicationInfo
  private Context generateMockContext(Bundle metadata, String networkPolicyXml) throws Exception {
    Context context = mock(Context.class);
    PackageManager packageManager = mock(PackageManager.class);
    ApplicationInfo applicationInfo = mock(ApplicationInfo.class);
    applicationInfo.metaData = metadata;
    Resources resources = mock(Resources.class);
    when(context.getPackageManager()).thenReturn(packageManager);
    when(context.getResources()).thenReturn(resources);
    when(context.getPackageName()).thenReturn("");
    when(packageManager.getApplicationInfo(anyString(), anyInt())).thenReturn(applicationInfo);
    return context;
  }

  @Test
  public void itGeneratesCorrectApplicationInfoWithCustomValues() throws Exception {
    Bundle bundle = new Bundle();
    bundle.putString(FlutterEngineFlags.AOT_SHARED_LIBRARY_NAME.metadataKey, "testaot");
    bundle.putString(FlutterEngineFlags.VM_SNAPSHOT_DATA.metadataKey, "testvmsnapshot");
    bundle.putString(FlutterEngineFlags.ISOLATE_SNAPSHOT_DATA.metadataKey, "testisolatesnapshot");
    bundle.putString(FlutterEngineFlags.FLUTTER_ASSETS_DIR.metadataKey, "testassets");
    Context context = generateMockContext(bundle, null);
    FlutterApplicationInfo info = ApplicationInfoLoader.load(context);
    assertNotNull(info);
    assertEquals("testaot", info.aotSharedLibraryName);
    assertEquals("testvmsnapshot", info.vmSnapshotData);
    assertEquals("testisolatesnapshot", info.isolateSnapshotData);
    assertEquals("testassets", info.flutterAssetsDir);
    assertNull(info.nativeLibraryDir);
    assertEquals("", info.domainNetworkPolicy);
  }
}
