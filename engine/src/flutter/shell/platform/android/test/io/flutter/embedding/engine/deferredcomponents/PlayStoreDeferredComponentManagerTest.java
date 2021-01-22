// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.embedding.engine.deferredcomponents;

import static junit.framework.TestCase.assertEquals;
import static org.mockito.Mockito.any;
import static org.mockito.Mockito.anyInt;
import static org.mockito.Mockito.doReturn;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.spy;
import static org.mockito.Mockito.when;

import android.content.Context;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageManager;
import android.content.pm.PackageManager.NameNotFoundException;
import android.content.res.AssetManager;
import android.os.Bundle;
import androidx.annotation.NonNull;
import io.flutter.embedding.engine.FlutterJNI;
import io.flutter.embedding.engine.loader.ApplicationInfoLoader;
import java.io.File;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.RuntimeEnvironment;
import org.robolectric.annotation.Config;

@Config(manifest = Config.NONE)
@RunWith(RobolectricTestRunner.class)
public class PlayStoreDeferredComponentManagerTest {
  private class TestFlutterJNI extends FlutterJNI {
    public int loadDartDeferredLibraryCalled = 0;
    public int updateAssetManagerCalled = 0;
    public int deferredComponentInstallFailureCalled = 0;
    public String sharedLibraryName;
    public int loadingUnitId;
    public AssetManager assetManager;
    public String assetBundlePath;

    public TestFlutterJNI() {}

    @Override
    public void loadDartDeferredLibrary(int loadingUnitId, @NonNull String sharedLibraryName) {
      loadDartDeferredLibraryCalled++;
      this.sharedLibraryName = sharedLibraryName;
      this.loadingUnitId = loadingUnitId;
    }

    @Override
    public void updateJavaAssetManager(
        @NonNull AssetManager assetManager, @NonNull String assetBundlePath) {
      updateAssetManagerCalled++;
      this.loadingUnitId = loadingUnitId;
      this.assetManager = assetManager;
      this.assetBundlePath = assetBundlePath;
    }

    @Override
    public void deferredComponentInstallFailure(
        int loadingUnitId, @NonNull String error, boolean isTransient) {
      deferredComponentInstallFailureCalled++;
    }
  }

  // Skips the download process to directly call the loadAssets and loadDartLibrary methods.
  private class TestPlayStoreDeferredComponentManager extends PlayStoreDeferredComponentManager {
    public TestPlayStoreDeferredComponentManager(Context context, FlutterJNI jni) {
      super(context, jni);
    }

    @Override
    public void installDeferredComponent(int loadingUnitId, String moduleName) {
      // Override this to skip the online SplitInstallManager portion.
      loadAssets(loadingUnitId, moduleName);
      loadDartLibrary(loadingUnitId, moduleName);
    }
  }

  @Test
  public void downloadCallsJNIFunctions() throws NameNotFoundException {
    TestFlutterJNI jni = new TestFlutterJNI();
    Context spyContext = spy(RuntimeEnvironment.application);
    doReturn(spyContext).when(spyContext).createPackageContext(any(), anyInt());
    doReturn(null).when(spyContext).getAssets();
    String soTestPath = "libapp.so-123.part.so";
    TestPlayStoreDeferredComponentManager playStoreManager =
        new TestPlayStoreDeferredComponentManager(spyContext, jni);
    jni.setDeferredComponentManager(playStoreManager);
    assertEquals(jni.loadingUnitId, 0);

    playStoreManager.installDeferredComponent(123, "TestModuleName");
    assertEquals(jni.loadDartDeferredLibraryCalled, 1);
    assertEquals(jni.updateAssetManagerCalled, 1);
    assertEquals(jni.deferredComponentInstallFailureCalled, 0);

    assertEquals(jni.sharedLibraryName, soTestPath);
    assertEquals(jni.loadingUnitId, 123);
    assertEquals(jni.assetBundlePath, "flutter_assets");
  }

  @Test
  public void downloadCallsJNIFunctionsWithFilenameFromManifest() throws NameNotFoundException {
    TestFlutterJNI jni = new TestFlutterJNI();
    Context spyContext = spy(RuntimeEnvironment.application);
    doReturn(spyContext).when(spyContext).createPackageContext(any(), anyInt());
    doReturn(null).when(spyContext).getAssets();

    Bundle bundle = new Bundle();
    bundle.putString(ApplicationInfoLoader.PUBLIC_AOT_SHARED_LIBRARY_NAME, "custom_name.so");
    bundle.putString(ApplicationInfoLoader.PUBLIC_FLUTTER_ASSETS_DIR_KEY, "custom_assets");
    PackageManager packageManager = mock(PackageManager.class);
    ApplicationInfo applicationInfo = mock(ApplicationInfo.class);
    applicationInfo.metaData = bundle;
    when(packageManager.getApplicationInfo(any(String.class), any(int.class)))
        .thenReturn(applicationInfo);
    doReturn(packageManager).when(spyContext).getPackageManager();

    String soTestPath = "custom_name.so-123.part.so";
    TestPlayStoreDeferredComponentManager playStoreManager =
        new TestPlayStoreDeferredComponentManager(spyContext, jni);
    jni.setDeferredComponentManager(playStoreManager);
    assertEquals(jni.loadingUnitId, 0);

    playStoreManager.installDeferredComponent(123, "TestModuleName");
    assertEquals(jni.loadDartDeferredLibraryCalled, 1);
    assertEquals(jni.updateAssetManagerCalled, 1);
    assertEquals(jni.deferredComponentInstallFailureCalled, 0);

    assertEquals(jni.sharedLibraryName, soTestPath);
    assertEquals(jni.loadingUnitId, 123);
    assertEquals(jni.assetBundlePath, "custom_assets");
  }

  @Test
  public void assetManagerUpdateInvoked() throws NameNotFoundException {
    TestFlutterJNI jni = new TestFlutterJNI();
    Context spyContext = spy(RuntimeEnvironment.application);
    doReturn(spyContext).when(spyContext).createPackageContext(any(), anyInt());
    AssetManager assetManager = spyContext.getAssets();
    String apkTestPath = "blah doesn't matter here";
    doReturn(new File(apkTestPath)).when(spyContext).getFilesDir();
    TestPlayStoreDeferredComponentManager playStoreManager =
        new TestPlayStoreDeferredComponentManager(spyContext, jni);
    jni.setDeferredComponentManager(playStoreManager);

    assertEquals(jni.loadingUnitId, 0);

    playStoreManager.installDeferredComponent(123, "TestModuleName");
    assertEquals(jni.loadDartDeferredLibraryCalled, 1);
    assertEquals(jni.updateAssetManagerCalled, 1);
    assertEquals(jni.deferredComponentInstallFailureCalled, 0);

    assertEquals(jni.assetManager, assetManager);
  }

  @Test
  public void stateGetterReturnsUnknowByDefault() throws NameNotFoundException {
    TestFlutterJNI jni = new TestFlutterJNI();
    Context spyContext = spy(RuntimeEnvironment.application);
    doReturn(spyContext).when(spyContext).createPackageContext(any(), anyInt());
    TestPlayStoreDeferredComponentManager playStoreManager =
        new TestPlayStoreDeferredComponentManager(spyContext, jni);
    assertEquals(playStoreManager.getDeferredComponentInstallState(-1, "invalidName"), "unknown");
  }
}
