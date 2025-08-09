// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.embedding.engine.loader;

import static android.os.Looper.getMainLooper;
import static junit.framework.TestCase.assertFalse;
import static junit.framework.TestCase.assertTrue;
import static org.junit.Assert.assertNotNull;
import static org.junit.Assert.fail;
import static org.mockito.Mockito.any;
import static org.mockito.Mockito.anyInt;
import static org.mockito.Mockito.anyLong;
import static org.mockito.Mockito.anyString;
import static org.mockito.Mockito.clearInvocations;
import static org.mockito.Mockito.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.spy;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.robolectric.Shadows.shadowOf;

import android.app.ActivityManager;
import android.content.Context;
import android.os.Bundle;
import android.util.DisplayMetrics;
import androidx.test.core.app.ApplicationProvider;
import androidx.test.ext.junit.runners.AndroidJUnit4;
import io.flutter.embedding.engine.FlutterJNI;
import java.io.File;
import java.io.IOException;
import java.util.Arrays;
import java.util.List;
import java.util.concurrent.Callable;
import java.util.concurrent.ExecutorService;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mockito;

@RunWith(AndroidJUnit4.class)
public class FlutterLoaderTest {
  private final Context ctx = ApplicationProvider.getApplicationContext();

  @Test
  public void itReportsUninitializedAfterCreating() {
    FlutterLoader flutterLoader = new FlutterLoader();
    assertFalse(flutterLoader.initialized());
  }

  @Test
  public void itReportsInitializedAfterInitializing() {
    FlutterJNI mockFlutterJNI = mock(FlutterJNI.class);
    FlutterLoader flutterLoader = new FlutterLoader(mockFlutterJNI);

    assertFalse(flutterLoader.initialized());
    flutterLoader.startInitialization(ctx);
    flutterLoader.ensureInitializationComplete(ctx, null);
    shadowOf(getMainLooper()).idle();
    assertTrue(flutterLoader.initialized());
    verify(mockFlutterJNI, times(1)).loadLibrary(ctx);
    verify(mockFlutterJNI, times(1)).updateRefreshRate();
  }

  @Test
  public void unsatisfiedLinkErrorPathDoesNotExist() {
    FlutterJNI mockFlutterJNI = mock(FlutterJNI.class);
    String path = "/path/that/doesnt/exist";
    ctx.getApplicationInfo().nativeLibraryDir = path;
    FlutterLoader flutterLoader = new FlutterLoader(mockFlutterJNI);

    Mockito.doThrow(new UnsatisfiedLinkError("couldn't find \"libflutter.so\""))
        .when(mockFlutterJNI)
        .loadLibrary(ctx);
    try {
      flutterLoader.startInitialization(ctx);
      flutterLoader.ensureInitializationComplete(ctx, null);
      shadowOf(getMainLooper()).idle();
      fail(); // Should not get here.
    } catch (RuntimeException re) {
      Throwable e = re.getCause();
      assertNotNull(e);
      assertNotNull(e.getMessage());
      assertTrue(
          e.getMessage()
              .contains(
                  "and the native libraries directory (with path " + path + ") does not exist"));
    }
  }

  @Test
  public void unsatisfiedLinkErrorContainsSplitDirs() {
    FlutterJNI mockFlutterJNI = mock(FlutterJNI.class);
    ctx.getApplicationInfo().nativeLibraryDir = "/path/that/doesnt/exist";
    String splitDir = "/path/to/split/dir";
    ctx.getApplicationInfo().splitSourceDirs = new String[] {splitDir, "/other/split/path/dir"};
    FlutterLoader flutterLoader = new FlutterLoader(mockFlutterJNI);

    Mockito.doThrow(new UnsatisfiedLinkError("couldn't find \"libflutter.so\""))
        .when(mockFlutterJNI)
        .loadLibrary(ctx);
    try {
      flutterLoader.startInitialization(ctx);
      flutterLoader.ensureInitializationComplete(ctx, null);
      shadowOf(getMainLooper()).idle();
      fail(); // Should not get here.
    } catch (RuntimeException re) {
      Throwable e = re.getCause();
      assertNotNull(e);
      assertNotNull(e.getMessage());
      assertTrue(e.getMessage().contains(splitDir));
    }
  }

  @Test
  public void itDefaultsTheOldGenHeapSizeAppropriately() {
    FlutterJNI mockFlutterJNI = mock(FlutterJNI.class);
    FlutterLoader flutterLoader = new FlutterLoader(mockFlutterJNI);

    assertFalse(flutterLoader.initialized());
    flutterLoader.startInitialization(ctx);
    flutterLoader.ensureInitializationComplete(ctx, null);
    shadowOf(getMainLooper()).idle();

    ActivityManager activityManager =
        (ActivityManager) ctx.getSystemService(Context.ACTIVITY_SERVICE);
    ActivityManager.MemoryInfo memInfo = new ActivityManager.MemoryInfo();
    activityManager.getMemoryInfo(memInfo);
    int oldGenHeapSizeMegaBytes = (int) (memInfo.totalMem / 1e6 / 2);
    final String oldGenHeapArg = "--old-gen-heap-size=" + oldGenHeapSizeMegaBytes;
    ArgumentCaptor<String[]> shellArgsCaptor = ArgumentCaptor.forClass(String[].class);
    verify(mockFlutterJNI, times(1))
        .init(
            eq(ctx),
            shellArgsCaptor.capture(),
            anyString(),
            anyString(),
            anyString(),
            anyLong(),
            anyInt());
    List<String> arguments = Arrays.asList(shellArgsCaptor.getValue());
    assertTrue(arguments.contains(oldGenHeapArg));
  }

  @Test
  public void itDefaultsTheResourceCacheMaxBytesThresholdAppropriately() {
    FlutterJNI mockFlutterJNI = mock(FlutterJNI.class);
    FlutterLoader flutterLoader = new FlutterLoader(mockFlutterJNI);

    assertFalse(flutterLoader.initialized());
    flutterLoader.startInitialization(ctx);
    flutterLoader.ensureInitializationComplete(ctx, null);
    shadowOf(getMainLooper()).idle();

    DisplayMetrics displayMetrics = ctx.getResources().getDisplayMetrics();
    int screenWidth = displayMetrics.widthPixels;
    int screenHeight = displayMetrics.heightPixels;
    int resourceCacheMaxBytesThreshold = screenWidth * screenHeight * 12 * 4;
    final String resourceCacheMaxBytesThresholdArg =
        "--resource-cache-max-bytes-threshold=" + resourceCacheMaxBytesThreshold;
    ArgumentCaptor<String[]> shellArgsCaptor = ArgumentCaptor.forClass(String[].class);
    verify(mockFlutterJNI, times(1))
        .init(
            eq(ctx),
            shellArgsCaptor.capture(),
            anyString(),
            anyString(),
            anyString(),
            anyLong(),
            anyInt());
    List<String> arguments = Arrays.asList(shellArgsCaptor.getValue());
    assertTrue(arguments.contains(resourceCacheMaxBytesThresholdArg));
  }

  @Test
  public void itSetsLeakVMToTrueByDefault() {
    FlutterJNI mockFlutterJNI = mock(FlutterJNI.class);
    FlutterLoader flutterLoader = new FlutterLoader(mockFlutterJNI);

    assertFalse(flutterLoader.initialized());
    flutterLoader.startInitialization(ctx);
    flutterLoader.ensureInitializationComplete(ctx, null);
    shadowOf(getMainLooper()).idle();

    final String leakVMArg = "--leak-vm=true";
    ArgumentCaptor<String[]> shellArgsCaptor = ArgumentCaptor.forClass(String[].class);
    verify(mockFlutterJNI, times(1))
        .init(
            eq(ctx),
            shellArgsCaptor.capture(),
            anyString(),
            anyString(),
            anyString(),
            anyLong(),
            anyInt());
    List<String> arguments = Arrays.asList(shellArgsCaptor.getValue());
    assertTrue(arguments.contains(leakVMArg));
  }

  @Test
  public void itSetsTheLeakVMFromMetaData() {
    FlutterJNI mockFlutterJNI = mock(FlutterJNI.class);
    FlutterLoader flutterLoader = new FlutterLoader(mockFlutterJNI);
    Bundle metaData = new Bundle();
    metaData.putBoolean("io.flutter.embedding.android.LeakVM", false);
    ctx.getApplicationInfo().metaData = metaData;

    FlutterLoader.Settings settings = new FlutterLoader.Settings();
    assertFalse(flutterLoader.initialized());
    flutterLoader.startInitialization(ctx, settings);
    flutterLoader.ensureInitializationComplete(ctx, null);
    shadowOf(getMainLooper()).idle();

    final String leakVMArg = "--leak-vm=false";
    ArgumentCaptor<String[]> shellArgsCaptor = ArgumentCaptor.forClass(String[].class);
    verify(mockFlutterJNI, times(1))
        .init(
            eq(ctx),
            shellArgsCaptor.capture(),
            anyString(),
            anyString(),
            anyString(),
            anyLong(),
            anyInt());
    List<String> arguments = Arrays.asList(shellArgsCaptor.getValue());
    assertTrue(arguments.contains(leakVMArg));
  }

  @Test
  public void itUsesCorrectExecutorService() {
    FlutterJNI mockFlutterJNI = mock(FlutterJNI.class);
    ExecutorService mockExecutorService = mock(ExecutorService.class);
    FlutterLoader flutterLoader = new FlutterLoader(mockFlutterJNI, mockExecutorService);

    assertFalse(flutterLoader.initialized());
    flutterLoader.startInitialization(ctx);
    verify(mockExecutorService, times(1)).submit(any(Callable.class));
  }

  @Test
  public void itDoesNotSetEnableImpellerByDefault() {
    FlutterJNI mockFlutterJNI = mock(FlutterJNI.class);
    FlutterLoader flutterLoader = new FlutterLoader(mockFlutterJNI);

    assertFalse(flutterLoader.initialized());
    flutterLoader.startInitialization(ctx);
    flutterLoader.ensureInitializationComplete(ctx, null);
    shadowOf(getMainLooper()).idle();

    final String enableImpellerArg = "--enable-impeller";
    ArgumentCaptor<String[]> shellArgsCaptor = ArgumentCaptor.forClass(String[].class);
    verify(mockFlutterJNI, times(1))
        .init(
            eq(ctx),
            shellArgsCaptor.capture(),
            anyString(),
            anyString(),
            anyString(),
            anyLong(),
            anyInt());
    List<String> arguments = Arrays.asList(shellArgsCaptor.getValue());
    assertFalse(arguments.contains(enableImpellerArg));
  }

  @Test
  public void itDoesNotSetEnableVulkanValidationByDefault() {
    FlutterJNI mockFlutterJNI = mock(FlutterJNI.class);
    FlutterLoader flutterLoader = new FlutterLoader(mockFlutterJNI);

    assertFalse(flutterLoader.initialized());
    flutterLoader.startInitialization(ctx);
    flutterLoader.ensureInitializationComplete(ctx, null);
    shadowOf(getMainLooper()).idle();

    final String enableVulkanValidationArg = "--enable-vulkan-validation";
    ArgumentCaptor<String[]> shellArgsCaptor = ArgumentCaptor.forClass(String[].class);
    verify(mockFlutterJNI, times(1))
        .init(
            eq(ctx),
            shellArgsCaptor.capture(),
            anyString(),
            anyString(),
            anyString(),
            anyLong(),
            anyInt());
    List<String> arguments = Arrays.asList(shellArgsCaptor.getValue());
    assertFalse(arguments.contains(enableVulkanValidationArg));
  }

  @Test
  public void itSetsEnableImpellerFromMetaData() {
    FlutterJNI mockFlutterJNI = mock(FlutterJNI.class);
    FlutterLoader flutterLoader = new FlutterLoader(mockFlutterJNI);
    Bundle metaData = new Bundle();
    metaData.putBoolean("io.flutter.embedding.android.EnableImpeller", true);
    ctx.getApplicationInfo().metaData = metaData;

    FlutterLoader.Settings settings = new FlutterLoader.Settings();
    assertFalse(flutterLoader.initialized());
    flutterLoader.startInitialization(ctx, settings);
    flutterLoader.ensureInitializationComplete(ctx, null);
    shadowOf(getMainLooper()).idle();

    final String enableImpellerArg = "--enable-impeller=true";
    ArgumentCaptor<String[]> shellArgsCaptor = ArgumentCaptor.forClass(String[].class);
    verify(mockFlutterJNI, times(1))
        .init(
            eq(ctx),
            shellArgsCaptor.capture(),
            anyString(),
            anyString(),
            anyString(),
            anyLong(),
            anyInt());
    List<String> arguments = Arrays.asList(shellArgsCaptor.getValue());
    assertTrue(arguments.contains(enableImpellerArg));
  }

  @Test
  public void itSetsEnableFlutterGPUFromMetaData() {
    FlutterJNI mockFlutterJNI = mock(FlutterJNI.class);
    FlutterLoader flutterLoader = new FlutterLoader(mockFlutterJNI);
    Bundle metaData = new Bundle();
    metaData.putBoolean("io.flutter.embedding.android.EnableFlutterGPU", true);
    ctx.getApplicationInfo().metaData = metaData;

    FlutterLoader.Settings settings = new FlutterLoader.Settings();
    assertFalse(flutterLoader.initialized());
    flutterLoader.startInitialization(ctx, settings);
    flutterLoader.ensureInitializationComplete(ctx, null);
    shadowOf(getMainLooper()).idle();

    final String enableImpellerArg = "--enable-flutter-gpu";
    ArgumentCaptor<String[]> shellArgsCaptor = ArgumentCaptor.forClass(String[].class);
    verify(mockFlutterJNI, times(1))
        .init(
            eq(ctx),
            shellArgsCaptor.capture(),
            anyString(),
            anyString(),
            anyString(),
            anyLong(),
            anyInt());
    List<String> arguments = Arrays.asList(shellArgsCaptor.getValue());
    assertTrue(arguments.contains(enableImpellerArg));
  }

  @Test
  public void itSetsEnableSurfaceControlFromMetaData() {
    FlutterJNI mockFlutterJNI = mock(FlutterJNI.class);
    FlutterLoader flutterLoader = new FlutterLoader(mockFlutterJNI);
    Bundle metaData = new Bundle();
    metaData.putBoolean("io.flutter.embedding.android.EnableSurfaceControl", true);
    ctx.getApplicationInfo().metaData = metaData;

    FlutterLoader.Settings settings = new FlutterLoader.Settings();
    assertFalse(flutterLoader.initialized());
    flutterLoader.startInitialization(ctx, settings);
    flutterLoader.ensureInitializationComplete(ctx, null);
    shadowOf(getMainLooper()).idle();

    final String disabledControlArg = "--enable-surface-control";
    ArgumentCaptor<String[]> shellArgsCaptor = ArgumentCaptor.forClass(String[].class);
    verify(mockFlutterJNI, times(1))
        .init(
            eq(ctx),
            shellArgsCaptor.capture(),
            anyString(),
            anyString(),
            anyString(),
            anyLong(),
            anyInt());
    List<String> arguments = Arrays.asList(shellArgsCaptor.getValue());
    assertTrue(arguments.contains(disabledControlArg));
  }

  @Test
  public void itSetsShaderInitModeFromMetaData() {
    FlutterJNI mockFlutterJNI = mock(FlutterJNI.class);
    FlutterLoader flutterLoader = new FlutterLoader(mockFlutterJNI);
    Bundle metaData = new Bundle();
    metaData.putBoolean("io.flutter.embedding.android.ImpellerLazyShaderInitialization", true);
    ctx.getApplicationInfo().metaData = metaData;

    FlutterLoader.Settings settings = new FlutterLoader.Settings();
    assertFalse(flutterLoader.initialized());
    flutterLoader.startInitialization(ctx, settings);
    flutterLoader.ensureInitializationComplete(ctx, null);
    shadowOf(getMainLooper()).idle();

    final String shaderModeArg = "--impeller-lazy-shader-mode";
    ArgumentCaptor<String[]> shellArgsCaptor = ArgumentCaptor.forClass(String[].class);
    verify(mockFlutterJNI, times(1))
        .init(
            eq(ctx),
            shellArgsCaptor.capture(),
            anyString(),
            anyString(),
            anyString(),
            anyLong(),
            anyInt());
    List<String> arguments = Arrays.asList(shellArgsCaptor.getValue());
    assertTrue(arguments.contains(shaderModeArg));
  }

  @Test
  public void itSetsAotSharedLibraryNameIfPathIsInApk() {
    FlutterJNI mockFlutterJNI = mock(FlutterJNI.class);
    FlutterLoader flutterLoader = spy(new FlutterLoader(mockFlutterJNI));
    String nativeLibraryDirPath = "/native/library/dir";

    assertFalse(flutterLoader.initialized());
    ctx.getApplicationInfo().nativeLibraryDir = nativeLibraryDirPath;
    flutterLoader.startInitialization(ctx);

    // Test paths for library living within application APK.
    String pathWithDirectApkPath = nativeLibraryDirPath + "/library.so";
    String pathWithNestedApkPath = nativeLibraryDirPath + "/some/directories/library.so";
    String pathWithIndirectApkPath1 = nativeLibraryDirPath + "/someDirectory/../library.so";
    String pathWithIndirectApkPath2 = nativeLibraryDirPath + "/some/directory/../../library.so";
    String pathWithIndirectApkPath3 = nativeLibraryDirPath + "/some/directory/../library.so";

    String[] pathsToTest = {
      pathWithDirectApkPath,
      pathWithNestedApkPath,
      pathWithIndirectApkPath1,
      pathWithIndirectApkPath2,
      pathWithIndirectApkPath3
    };
    String aotSharedNameArgPrefix = "--aot-shared-library-name=";

    for (String path : pathsToTest) {
      String aotSharedLibraryNameArg = aotSharedNameArgPrefix + path;
      String[] args = {aotSharedLibraryNameArg};
      flutterLoader.ensureInitializationComplete(ctx, args);
      shadowOf(getMainLooper()).idle();

      ArgumentCaptor<String[]> shellArgsCaptor = ArgumentCaptor.forClass(String[].class);
      verify(mockFlutterJNI)
          .init(
              eq(ctx),
              shellArgsCaptor.capture(),
              anyString(),
              anyString(),
              anyString(),
              anyLong(),
              anyInt());

      List<String> actualArgs = Arrays.asList(shellArgsCaptor.getValue());

      // This check works because the tests run in debug mode. If run in release (or JIT release)
      // mode,
      // actualArgs would contain the default arguments for AOT shared library name on top of
      // aotSharedLibraryNameArg.
      assertTrue(actualArgs.contains(aotSharedLibraryNameArg));

      // Reset FlutterLoader and mockFlutterJNI to make more calls to
      // FlutterLoader.ensureInitialized
      // /mockFlutterJNI.init and for testing.
      flutterLoader.initialized = false;
      clearInvocations(mockFlutterJNI);
    }
  }

  @Test
  public void itDoesNotSetAotSharedLibraryNameIfPathOutsideApk() {
    FlutterJNI mockFlutterJNI = mock(FlutterJNI.class);
    FlutterLoader flutterLoader = spy(new FlutterLoader(mockFlutterJNI));
    String nativeLibraryDirPath = "/native/library/dir";

    assertFalse(flutterLoader.initialized());
    ctx.getApplicationInfo().nativeLibraryDir = nativeLibraryDirPath;
    flutterLoader.startInitialization(ctx);

    // Test paths for library living within application APK.
    String pathWithIndirectOutsideApkPath = nativeLibraryDirPath + "/../library.so";
    String pathWithMoreIndirectOutsideApkPath =
        nativeLibraryDirPath + "/some/directories/../../../library.so";
    String pathWithoutSoFile = nativeLibraryDirPath + "/library.somethingElse";
    String pathWithPartialNativeLibraryPath1 = "/native/library.so";
    String pathWithPartialNativeLibraryPath2 = "/native/dir/library.so";
    String pathWithPartialNativeLibraryPath3 = "/native/library/library.so";
    String pathWithPartialNativeLibraryPath4 = "/library/dir/library.so";
    String pathWithPartialNativeLibraryPath5 = "/dir/library.so";

    String[] pathsToTest = {
      pathWithIndirectOutsideApkPath,
      pathWithMoreIndirectOutsideApkPath,
      pathWithoutSoFile,
      pathWithPartialNativeLibraryPath1,
      pathWithPartialNativeLibraryPath2,
      pathWithPartialNativeLibraryPath3,
      pathWithPartialNativeLibraryPath4,
      pathWithPartialNativeLibraryPath5
    };
    String aotSharedNameArgPrefix = "--aot-shared-library-name=";

    for (String path : pathsToTest) {
      String aotSharedLibraryNameArg = aotSharedNameArgPrefix + path;
      String[] args = {aotSharedLibraryNameArg};
      flutterLoader.ensureInitializationComplete(ctx, args);
      shadowOf(getMainLooper()).idle();

      ArgumentCaptor<String[]> shellArgsCaptor = ArgumentCaptor.forClass(String[].class);
      verify(mockFlutterJNI)
          .init(
              eq(ctx),
              shellArgsCaptor.capture(),
              anyString(),
              anyString(),
              anyString(),
              anyLong(),
              anyInt());

      List<String> actualArgs = Arrays.asList(shellArgsCaptor.getValue());

      // This check works because the tests run in debug mode. If run in release (or JIT release)
      // mode,
      // actualArgs would contain  the default arguments for AOT shared library name.
      assertFalse(actualArgs.contains(aotSharedLibraryNameArg));

      // Reset FlutterLoader and mockFlutterJNI to make more calls to
      // FlutterLoader.ensureInitialized
      // /mockFlutterJNI.init and for testing.
      flutterLoader.initialized = false;
      clearInvocations(mockFlutterJNI);
    }
  }

  @Test
  public void itSetsAotSharedLibraryNameIfPathIsInInternalStorage() throws IOException {
    FlutterJNI mockFlutterJNI = mock(FlutterJNI.class);
    FlutterLoader flutterLoader = spy(new FlutterLoader(mockFlutterJNI));
    Context mockApplicationContext = mock(Context.class);
    File internalStorageDir = ctx.getFilesDir();
    String internalStorageDirPath = internalStorageDir.getCanonicalPath();

    ctx.getApplicationInfo().nativeLibraryDir = "some/path/doesnt/matter";
    assertFalse(flutterLoader.initialized());
    flutterLoader.startInitialization(ctx);

    // Test paths for library living within application APK.
    String pathWithDirectInternalStoragePath = internalStorageDirPath + "/library.so";
    String pathWithNestedInternalStoragePath =
        internalStorageDirPath + "/some/directories/library.so";
    String pathWithIndirectInternalStoragePath1 =
        internalStorageDirPath + "/someDirectory/../library.so";
    String pathWithIndirectInternalStoragePath2 =
        internalStorageDirPath + "/some/directory/../../library.so";
    String pathWithIndirectInternalStoragePath3 =
        internalStorageDirPath + "/some/directory/../library.so";

    String[] pathsToTest = {
      pathWithDirectInternalStoragePath,
      pathWithNestedInternalStoragePath,
      pathWithIndirectInternalStoragePath1,
      pathWithIndirectInternalStoragePath2,
      pathWithIndirectInternalStoragePath3
    };
    String aotSharedNameArgPrefix = "--aot-shared-library-name=";

    for (String path : pathsToTest) {
      String aotSharedLibraryNameArg = aotSharedNameArgPrefix + path;
      String[] args = {aotSharedLibraryNameArg};
      flutterLoader.ensureInitializationComplete(ctx, args);
      shadowOf(getMainLooper()).idle();

      ArgumentCaptor<String[]> shellArgsCaptor = ArgumentCaptor.forClass(String[].class);
      verify(mockFlutterJNI)
          .init(
              eq(ctx),
              shellArgsCaptor.capture(),
              anyString(),
              anyString(),
              anyString(),
              anyLong(),
              anyInt());

      List<String> actualArgs = Arrays.asList(shellArgsCaptor.getValue());

      // This check works because the tests run in debug mode. If run in release (or JIT release)
      // mode,
      // actualArgs would contain the default arguments for AOT shared library name on top of
      // aotSharedLibraryNameArg.
      assertTrue(actualArgs.contains(aotSharedLibraryNameArg));

      // Reset FlutterLoader and mockFlutterJNI to make more calls to
      // FlutterLoader.ensureInitialized
      // /mockFlutterJNI.init and for testing.
      flutterLoader.initialized = false;
      clearInvocations(mockFlutterJNI);
    }
  }

  @Test
  public void itDoesNotSetAotSharedLibraryNameIfPathOutsideInternalStorage() {
    FlutterJNI mockFlutterJNI = mock(FlutterJNI.class);
    FlutterLoader flutterLoader = spy(new FlutterLoader(mockFlutterJNI));
    Context mockApplicationContext = mock(Context.class);
    File internalStorageDir = ctx.getFilesDir();
    String internalStorageDirPath = internalStorageDir.getCanonicalPath();

    ctx.getApplicationInfo().nativeLibraryDir = "some/path/doesnt/matter";
    assertFalse(flutterLoader.initialized());
    flutterLoader.startInitialization(ctx);

    // Test paths for library living within application APK.
    String pathWithDirectInternalStoragePath = internalStorageDirPath + "/library.so"; // here :)

    String[] pathsToTest = {};
    String aotSharedNameArgPrefix = "--aot-shared-library-name=";

    for (String path : pathsToTest) {
      String aotSharedLibraryNameArg = aotSharedNameArgPrefix + path;
      String[] args = {aotSharedLibraryNameArg};
      flutterLoader.ensureInitializationComplete(ctx, args);
      shadowOf(getMainLooper()).idle();

      ArgumentCaptor<String[]> shellArgsCaptor = ArgumentCaptor.forClass(String[].class);
      verify(mockFlutterJNI)
          .init(
              eq(ctx),
              shellArgsCaptor.capture(),
              anyString(),
              anyString(),
              anyString(),
              anyLong(),
              anyInt());

      List<String> actualArgs = Arrays.asList(shellArgsCaptor.getValue());

      // This check works because the tests run in debug mode. If run in release (or JIT release)
      // mode,
      // actualArgs would contain the default arguments for AOT shared library name on top of
      // aotSharedLibraryNameArg.
      assertTrue(actualArgs.contains(aotSharedLibraryNameArg));

      // Reset FlutterLoader and mockFlutterJNI to make more calls to
      // FlutterLoader.ensureInitialized
      // /mockFlutterJNI.init and for testing.
      flutterLoader.initialized = false;
      clearInvocations(mockFlutterJNI);
    }
  }
}
