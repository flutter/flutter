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
import static org.mockito.Mockito.doReturn;
import static org.mockito.Mockito.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.spy;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
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
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
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
  public void itSetsAotSharedLibraryNameIfPathIsInInternalStorage() throws IOException {
    FlutterJNI mockFlutterJNI = mock(FlutterJNI.class);
    FlutterLoader flutterLoader = spy(new FlutterLoader(mockFlutterJNI));
    Context mockApplicationContext = mock(Context.class);
    File internalStorageDir = ctx.getFilesDir();
    Path internalStorageDirAsPathObj = internalStorageDir.toPath();

    ctx.getApplicationInfo().nativeLibraryDir =
        Paths.get("some", "path", "doesnt", "matter").toString();
    assertFalse(flutterLoader.initialized());
    flutterLoader.startInitialization(ctx);

    // Test paths for library living within internal storage.
    String librarySoFileName = "library.so";
    Path pathWithDirectInternalStoragePath = internalStorageDirAsPathObj.resolve(librarySoFileName);
    Path pathWithNestedInternalStoragePath =
        internalStorageDirAsPathObj.resolve(Paths.get("some", "directories", librarySoFileName));
    Path pathWithIndirectInternalStoragePath1 =
        internalStorageDirAsPathObj.resolve(Paths.get("someDirectory", "..", librarySoFileName));
    Path pathWithIndirectInternalStoragePath2 =
        internalStorageDirAsPathObj.resolve(
            Paths.get("some", "directory", "..", "..", librarySoFileName));
    Path pathWithIndirectInternalStoragePath3 =
        internalStorageDirAsPathObj.resolve(
            Paths.get("some", "directory", "..", librarySoFileName));

    Path[] pathsToTest = {
      pathWithDirectInternalStoragePath,
      pathWithNestedInternalStoragePath,
      pathWithIndirectInternalStoragePath1,
      pathWithIndirectInternalStoragePath2,
      pathWithIndirectInternalStoragePath3
    };

    for (Path testPath : pathsToTest) {
      String path = testPath.toString();
      String aotSharedLibraryNameArg = FlutterLoader.aotSharedLibraryNameFlag + path;
      String[] args = {aotSharedLibraryNameArg};
      flutterLoader.ensureInitializationComplete(ctx, args);

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
      // mode, actualArgs would contain the default arguments for AOT shared library name on top
      // of aotSharedLibraryNameArg.
      String canonicalTestPath = testPath.toFile().getCanonicalPath();
      String canonicalAotSharedLibraryNameArg =
          FlutterLoader.aotSharedLibraryNameFlag + canonicalTestPath;
      assertTrue(
          "Args sent to FlutterJni.init incorrectly did not include path " + path,
          actualArgs.contains(canonicalAotSharedLibraryNameArg));

      // Reset FlutterLoader and mockFlutterJNI to make more calls to
      // FlutterLoader.ensureInitialized and mockFlutterJNI.init for testing.
      flutterLoader.initialized = false;
      clearInvocations(mockFlutterJNI);
    }
  }

  @Test
  public void itDoesNotSetAotSharedLibraryNameIfPathOutsideInternalStorage() throws IOException {
    FlutterJNI mockFlutterJNI = mock(FlutterJNI.class);
    FlutterLoader flutterLoader = spy(new FlutterLoader(mockFlutterJNI));
    Context mockApplicationContext = mock(Context.class);
    File internalStorageDir = ctx.getFilesDir();
    Path internalStorageDirAsPathObj = internalStorageDir.toPath();
    String internalStorageDirPath = internalStorageDir.getCanonicalPath();

    ctx.getApplicationInfo().nativeLibraryDir =
        Paths.get("some", "path", "doesnt", "matter").toString();
    assertFalse(flutterLoader.initialized());
    flutterLoader.startInitialization(ctx);

    // Test paths for library living outside internal storage.
    String librarySoFileName = "library.so";
    Path pathThatIsCompletelyUnrelated = Paths.get("please", "do", "fail");
    Path pathWithIndirectOutsideInternalStorage =
        internalStorageDirAsPathObj.resolve(Paths.get("..", librarySoFileName));
    Path pathWithMoreIndirectOutsideInternalStorage =
        internalStorageDirAsPathObj.resolve(
            Paths.get("some", "directory", "..", "..", "..", librarySoFileName));
    Path pathWithoutSoFile =
        internalStorageDirAsPathObj.resolve(Paths.get("library.somethingElse"));
    Path pathWithPartialInternalStoragePath =
        internalStorageDirAsPathObj.getParent().resolve(librarySoFileName);
    String sneakyDirectoryName =
        internalStorageDirAsPathObj.getFileName().toString() + "extraChars";
    Path pathWithSneakyPartialInternalStoragePath =
        internalStorageDirAsPathObj.resolve(
            Paths.get("..", sneakyDirectoryName, librarySoFileName));

    Path[] pathsToTest = {
      pathThatIsCompletelyUnrelated,
      pathWithIndirectOutsideInternalStorage,
      pathWithMoreIndirectOutsideInternalStorage,
      pathWithoutSoFile,
      pathWithPartialInternalStoragePath,
      pathWithSneakyPartialInternalStoragePath
    };

    for (Path testPath : pathsToTest) {
      String path = testPath.toString();
      String aotSharedLibraryNameArg = FlutterLoader.aotSharedLibraryNameFlag + path;
      String[] args = {aotSharedLibraryNameArg};
      flutterLoader.ensureInitializationComplete(ctx, args);

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
      // mode, actualArgs would contain the default arguments for AOT shared library name on top
      // of aotSharedLibraryNameArg.
      String canonicalTestPath = testPath.toFile().getCanonicalPath();
      String canonicalAotSharedLibraryNameArg =
          FlutterLoader.aotSharedLibraryNameFlag + canonicalTestPath;
      assertFalse(
          "Args sent to FlutterJni.init incorrectly included canonical path " + canonicalTestPath,
          actualArgs.contains(canonicalAotSharedLibraryNameArg));

      // Reset FlutterLoader and mockFlutterJNI to make more calls to
      // FlutterLoader.ensureInitialized and mockFlutterJNI.init for testing.
      flutterLoader.initialized = false;
      clearInvocations(mockFlutterJNI);
    }
  }

  @Test
  public void itDoesNotSetAotSharedLibraryNameIfPathIsInvalid() throws IOException {
    FlutterJNI mockFlutterJNI = mock(FlutterJNI.class);
    FlutterLoader flutterLoader = spy(new FlutterLoader(mockFlutterJNI));
    Context mockApplicationContext = mock(Context.class);
    File internalStorageDir = ctx.getFilesDir();
    Path internalStorageDirAsPathObj = internalStorageDir.toPath();

    ctx.getApplicationInfo().nativeLibraryDir =
        Paths.get("some", "path", "doesnt", "matter").toString();
    assertFalse(flutterLoader.initialized());
    flutterLoader.startInitialization(ctx);

    String invalidFilePath = "my\0file.so";

    String[] args = {FlutterLoader.aotSharedLibraryNameFlag + invalidFilePath};
    flutterLoader.ensureInitializationComplete(ctx, args);

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
    // mode, actualArgs would contain the default arguments for AOT shared library name on top
    // of aotSharedLibraryNameArg.
    for (String arg : actualArgs) {
      if (arg.startsWith(FlutterLoader.aotSharedLibraryNameFlag)) {
        fail();
      }
    }
  }

  @Test
  public void itSetsAotSharedLibraryNameAsExpectedIfSymlinkPointsToInternalStorage()
      throws IOException {
    FlutterJNI mockFlutterJNI = mock(FlutterJNI.class);
    FlutterLoader flutterLoader = spy(new FlutterLoader(mockFlutterJNI));
    Context mockApplicationContext = mock(Context.class);
    File internalStorageDir = ctx.getFilesDir();
    Path internalStorageDirAsPathObj = internalStorageDir.toPath();

    ctx.getApplicationInfo().nativeLibraryDir =
        Paths.get("some", "path", "doesnt", "matter").toString();
    assertFalse(flutterLoader.initialized());
    flutterLoader.startInitialization(ctx);

    File realSoFile = File.createTempFile("real", ".so", internalStorageDir);
    File spySymlinkFile = spy(new File(internalStorageDir, "symlink_to_real.so"));
    Files.deleteIfExists(spySymlinkFile.toPath());

    // Simulate a symlink since some filesystems do not support symlinks.
    when(flutterLoader.getFileFromPath(spySymlinkFile.getPath())).thenReturn(spySymlinkFile);
    doReturn(realSoFile.getCanonicalPath()).when(spySymlinkFile).getCanonicalPath();

    String symlinkArg = FlutterLoader.aotSharedLibraryNameFlag + spySymlinkFile.getPath();
    String[] args = {symlinkArg};
    flutterLoader.ensureInitializationComplete(ctx, args);

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

    String canonicalSymlinkCanonicalizedPath = realSoFile.getCanonicalPath();
    String canonicalAotSharedLibraryNameArg =
        FlutterLoader.aotSharedLibraryNameFlag + canonicalSymlinkCanonicalizedPath;
    assertFalse(
        "Args sent to FlutterJni.init incorrectly included absolute symlink path: "
            + spySymlinkFile.getAbsolutePath(),
        actualArgs.contains(symlinkArg));
    assertTrue(
        "Args sent to FlutterJni.init incorrectly did not include canonicalized path of symlink: "
            + canonicalSymlinkCanonicalizedPath,
        actualArgs.contains(canonicalAotSharedLibraryNameArg));

    // Clean up created files.
    spySymlinkFile.delete();
    realSoFile.delete();
  }

  @Test
  public void itSetsAotSharedLibraryNameAsExpectedIfSymlinkIsNotSafe() throws IOException {
    FlutterJNI mockFlutterJNI = mock(FlutterJNI.class);
    FlutterLoader flutterLoader = spy(new FlutterLoader(mockFlutterJNI));
    Context mockApplicationContext = mock(Context.class);
    File internalStorageDir = ctx.getFilesDir();
    Path internalStorageDirAsPathObj = internalStorageDir.toPath();

    ctx.getApplicationInfo().nativeLibraryDir =
        Paths.get("some", "path", "doesnt", "matter").toString();
    assertFalse(flutterLoader.initialized());
    flutterLoader.startInitialization(ctx);

    File nonSoFile = File.createTempFile("real", ".somethingElse", internalStorageDir);
    File fileJustOutsideInternalStorage =
        new File(internalStorageDir.getParentFile(), "not_in_internal_storage.so");
    File spySymlinkFile = spy(new File(internalStorageDir, "symlink.so"));
    List<File> unsafeFiles = Arrays.asList(nonSoFile, fileJustOutsideInternalStorage);
    Files.deleteIfExists(spySymlinkFile.toPath());

    String symlinkArg = FlutterLoader.aotSharedLibraryNameFlag + spySymlinkFile.getAbsolutePath();
    String[] args = {symlinkArg};

    for (File unsafeFile : unsafeFiles) {
      // Simulate a symlink since some filesystems do not support symlinks.
      when(flutterLoader.getFileFromPath(spySymlinkFile.getPath())).thenReturn(spySymlinkFile);
      doReturn(unsafeFile.getCanonicalPath()).when(spySymlinkFile).getCanonicalPath();

      flutterLoader.ensureInitializationComplete(ctx, args);

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

      String canonicalSymlinkCanonicalizedPath = unsafeFile.getCanonicalPath();
      String canonicalAotSharedLibraryNameArg =
          FlutterLoader.aotSharedLibraryNameFlag + canonicalSymlinkCanonicalizedPath;
      assertFalse(
          "Args sent to FlutterJni.init incorrectly included canonicalized path of symlink: "
              + canonicalSymlinkCanonicalizedPath,
          actualArgs.contains(canonicalAotSharedLibraryNameArg));
      assertFalse(
          "Args sent to FlutterJni.init incorrectly included absolute path of symlink: "
              + spySymlinkFile.getAbsolutePath(),
          actualArgs.contains(symlinkArg));

      // Clean up created files.
      spySymlinkFile.delete();
      unsafeFile.delete();

      // Reset FlutterLoader and mockFlutterJNI to make more calls to
      // FlutterLoader.ensureInitialized and mockFlutterJNI.init for testing.
      flutterLoader.initialized = false;
      clearInvocations(mockFlutterJNI);
    }
  }
}