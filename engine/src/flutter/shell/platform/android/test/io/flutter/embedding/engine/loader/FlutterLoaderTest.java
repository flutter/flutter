// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.embedding.engine.loader;

import static android.os.Looper.getMainLooper;
import static junit.framework.TestCase.assertFalse;
import static junit.framework.TestCase.assertTrue;
import static org.junit.Assert.assertNotNull;
import static org.junit.Assert.assertThrows;
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
import io.flutter.embedding.engine.FlutterShellArgs;
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
      Bundle metadata = new Bundle();
      metadata.putString("io.flutter.embedding.android.AOTSharedLibraryName", path);
      ctx.getApplicationInfo().metaData = metadata;

      flutterLoader.ensureInitializationComplete(ctx, null);

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
      String canonicalAotSharedLibraryNameArg = "--aot-shared-library-name=" + canonicalTestPath;
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
      Bundle metadata = new Bundle();
      metadata.putString("io.flutter.embedding.android.AOTSharedLibraryName", path);
      ctx.getApplicationInfo().metaData = metadata;

      flutterLoader.ensureInitializationComplete(ctx, null);

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
      String canonicalAotSharedLibraryNameArg = "--aot-shared-library-name=" + canonicalTestPath;
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

    Bundle metadata = new Bundle();
    metadata.putString("io.flutter.embedding.android.AOTSharedLibraryName", invalidFilePath);
    ctx.getApplicationInfo().metaData = metadata;

    flutterLoader.ensureInitializationComplete(ctx, null);

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
      if (arg.startsWith("--aot-shared-library-name=")) {
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

    Bundle metadata = new Bundle();
    metadata.putString(
        "io.flutter.embedding.android.AOTSharedLibraryName", spySymlinkFile.getPath());
    ctx.getApplicationInfo().metaData = metadata;
    flutterLoader.ensureInitializationComplete(ctx, null);

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
    String aotSharedLibraryNameFlag = "--aot-shared-library-name=";
    String symlinkAotSharedLibraryNameArg = aotSharedLibraryNameFlag + spySymlinkFile.getPath();
    String canonicalAotSharedLibraryNameArg =
        aotSharedLibraryNameFlag + canonicalSymlinkCanonicalizedPath;
    assertFalse(
        "Args sent to FlutterJni.init incorrectly included absolute symlink path: "
            + spySymlinkFile.getAbsolutePath(),
        actualArgs.contains(symlinkAotSharedLibraryNameArg));
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

    Bundle metadata = new Bundle();
    metadata.putString(
        "io.flutter.embedding.android.AOTSharedLibraryName", spySymlinkFile.getAbsolutePath());
    ctx.getApplicationInfo().metaData = metadata;

    for (File unsafeFile : unsafeFiles) {
      // Simulate a symlink since some filesystems do not support symlinks.
      when(flutterLoader.getFileFromPath(spySymlinkFile.getPath())).thenReturn(spySymlinkFile);
      doReturn(unsafeFile.getCanonicalPath()).when(spySymlinkFile).getCanonicalPath();

      flutterLoader.ensureInitializationComplete(ctx, null);

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
      String aotSharedLibraryNameFlag = "--aot-shared-library-name=";
      String symlinkAotSharedLibraryNameArg =
          aotSharedLibraryNameFlag + spySymlinkFile.getAbsolutePath();
      String canonicalAotSharedLibraryNameArg =
          aotSharedLibraryNameFlag + canonicalSymlinkCanonicalizedPath;
      assertFalse(
          "Args sent to FlutterJni.init incorrectly included canonicalized path of symlink: "
              + canonicalSymlinkCanonicalizedPath,
          actualArgs.contains(canonicalAotSharedLibraryNameArg));
      assertFalse(
          "Args sent to FlutterJni.init incorrectly included absolute path of symlink: "
              + spySymlinkFile.getAbsolutePath(),
          actualArgs.contains(symlinkAotSharedLibraryNameArg));

      // Clean up created files.
      spySymlinkFile.delete();
      unsafeFile.delete();

      // Reset FlutterLoader and mockFlutterJNI to make more calls to
      // FlutterLoader.ensureInitialized and mockFlutterJNI.init for testing.
      flutterLoader.initialized = false;
      clearInvocations(mockFlutterJNI);
    }
  }

  @Test
  public void itSetsEnableSoftwareRenderingFromMetadata() {
    testFlagFromMetaData(
        "io.flutter.embedding.android.EnableSoftwareRendering",
        true,
        FlutterShellArgs.ENABLE_SOFTWARE_RENDERING.commandLineArgument);
  }

  @Test
  public void itSetsSkiaDeterministicRenderingFromMetadata() {
    testFlagFromMetaData(
        "io.flutter.embedding.android.SkiaDeterministicRendering",
        true,
        FlutterShellArgs.SKIA_DETERMINISTIC_RENDERING.commandLineArgument);
  }

  @Test
  public void itSetsFlutterAssetsDirFromMetadata() {
    String expectedAssetsDir = "flutter_assets_dir";
    testFlagFromMetaData(
        "io.flutter.embedding.android.FlutterAssetsDir",
        expectedAssetsDir,
        FlutterShellArgs.FLUTTER_ASSETS_DIR.commandLineArgument + expectedAssetsDir);
  }

  @Test
  public void itSetsOldGenHeapSizeFromMetaData() {
    // Test old gen heap size can be set from metadata.
    int expectedOldGenHeapSize = 256;
    testFlagFromMetaData(
        "io.flutter.embedding.android.OldGenHeapSize",
        expectedOldGenHeapSize,
        FlutterShellArgs.OLD_GEN_HEAP_SIZE.commandLineArgument + expectedOldGenHeapSize);

    // Test that default old gen heap size will not be included if it
    // is configured via the manifest.
    ActivityManager activityManager =
        (ActivityManager) ctx.getSystemService(Context.ACTIVITY_SERVICE);
    ActivityManager.MemoryInfo memInfo = new ActivityManager.MemoryInfo();
    activityManager.getMemoryInfo(memInfo);
    int oldGenHeapSizeMegaBytes = (int) (memInfo.totalMem / 1e6 / 2);
    testFlagFromMetaData(
        "io.flutter.embedding.android.OldGenHeapSize",
        expectedOldGenHeapSize,
        FlutterShellArgs.OLD_GEN_HEAP_SIZE.commandLineArgument + oldGenHeapSizeMegaBytes,
        false);
  }

  @Test
  public void itSetsEnableImpellerFromMetaData() {
    testFlagFromMetaData(
        "io.flutter.embedding.android.EnableImpeller",
        true,
        FlutterShellArgs.ENABLE_IMPELLER.commandLineArgument + "true");
  }

  @Test
  public void itSetsImpellerBackendFromMetadata() {
    String expectedImpellerBackend = "Vulkan";
    testFlagFromMetaData(
        "io.flutter.embedding.android.ImpellerBackend",
        expectedImpellerBackend,
        FlutterShellArgs.IMPELLER_BACKEND.commandLineArgument + expectedImpellerBackend);
  }

  @Test
  public void itSetsEnableSurfaceControlFromMetaData() {
    testFlagFromMetaData(
        "io.flutter.embedding.android.EnableSurfaceControl",
        true,
        FlutterShellArgs.ENABLE_SURFACE_CONTROL.commandLineArgument);
  }

  @Test
  public void itSetsEnableFlutterGPUFromMetaData() {
    testFlagFromMetaData(
        "io.flutter.embedding.android.EnableFlutterGPU",
        true,
        FlutterShellArgs.ENABLE_FLUTTER_GPU.commandLineArgument);
  }

  @Test
  public void itSetsImpellerLazyShaderModeFromMetadata() {
    testFlagFromMetaData(
        "io.flutter.embedding.android.ImpellerLazyShaderInitialization",
        true,
        FlutterShellArgs.IMPELLER_LAZY_SHADER_MODE.commandLineArgument + "true");
  }

  @Test
  public void itSetsImpellerAntiAliasLinesFromMetadata() {
    testFlagFromMetaData(
        "io.flutter.embedding.android.ImpellerAntialiasLines",
        true,
        FlutterShellArgs.IMPELLER_ANTIALIAS_LINES.commandLineArgument);
  }

  @Test
  public void itSetsVmSnapshotDataFromMetaData() {
    String expectedVmSnapshotData = "vm_snapshot_data";
    testFlagFromMetaData(
        "io.flutter.embedding.android.VmSnapshotData",
        expectedVmSnapshotData,
        FlutterShellArgs.VM_SNAPSHOT_DATA.commandLineArgument + expectedVmSnapshotData);
  }

  @Test
  public void itSetsIsolateSnapshotDataFromMetaData() {
    String expectedIsolateSnapshotData = "isolate_snapshot_data";
    testFlagFromMetaData(
        "io.flutter.embedding.android.IsolateSnapshotData",
        expectedIsolateSnapshotData,
        FlutterShellArgs.ISOLATE_SNAPSHOT_DATA.commandLineArgument + expectedIsolateSnapshotData);
  }

  @Test
  public void itSetsUseTestFontsFromMetaData() {
    testFlagFromMetaData(
        "io.flutter.embedding.android.UseTestFonts",
        true,
        FlutterShellArgs.USE_TEST_FONTS.commandLineArgument);
  }

  @Test
  public void itSetsVmServicePortFromMetaData() {
    int expectedVmServicePort = 12345;
    testFlagFromMetaData(
        "io.flutter.embedding.android.VMServicePort",
        expectedVmServicePort,
        FlutterShellArgs.VM_SERVICE_PORT.commandLineArgument + expectedVmServicePort);
  }

  @Test
  public void itSetsEnableVulkanValidationFromMetaData() {
    testFlagFromMetaData(
        "io.flutter.embedding.android.EnableVulkanValidation",
        true,
        FlutterShellArgs.ENABLE_VULKAN_VALIDATION.commandLineArgument);
  }

  @Test
  public void itSetsEnableOpenGLGPUTracingFromMetaData() {
    testFlagFromMetaData(
        "io.flutter.embedding.android.EnableOpenGLGPUTracing",
        true,
        FlutterShellArgs.ENABLE_OPENGL_GPU_TRACING.commandLineArgument);
  }

  @Test
  public void itSetsEnableVulkanGPUTracingFromMetaData() {
    testFlagFromMetaData(
        "io.flutter.embedding.android.EnableVulkanGPUTracing",
        true,
        FlutterShellArgs.ENABLE_VULKAN_GPU_TRACING.commandLineArgument);
  }

  @Test
  public void itSetsLeakVMFromMetaData() {
    // Test that LeakVM can be set via manifest.
    testFlagFromMetaData(
        "io.flutter.embedding.android.LeakVM",
        false,
        FlutterShellArgs.LEAK_VM.commandLineArgument + "false");

    // Test that default LeakVM will not be included if it is configured via the manifest.
    testFlagFromMetaData(
        "io.flutter.embedding.android.LeakVM",
        false,
        FlutterShellArgs.LEAK_VM.commandLineArgument + "true",
        false);
  }

  @Test
  public void itSetsTraceStartupFromMetaData() {
    testFlagFromMetaData(
        "io.flutter.embedding.android.TraceStartup",
        true,
        FlutterShellArgs.TRACE_STARTUP.commandLineArgument);
  }

  @Test
  public void itSetsStartPausedFromMetaData() {
    testFlagFromMetaData(
        "io.flutter.embedding.android.StartPaused",
        true,
        FlutterShellArgs.START_PAUSED.commandLineArgument);
  }

  @Test
  public void itSetsDisableServiceAuthCodesFromMetaData() {
    testFlagFromMetaData(
        "io.flutter.embedding.android.DisableServiceAuthCodes",
        true,
        FlutterShellArgs.DISABLE_SERVICE_AUTH_CODES.commandLineArgument);
  }

  @Test
  public void itSetsEndlessTraceBufferFromMetaData() {
    testFlagFromMetaData(
        "io.flutter.embedding.android.EndlessTraceBuffer",
        true,
        FlutterShellArgs.ENDLESS_TRACE_BUFFER.commandLineArgument);
  }

  @Test
  public void itSetsEnableDartProfilingFromMetaData() {
    testFlagFromMetaData(
        "io.flutter.embedding.android.EnableDartProfiling",
        true,
        FlutterShellArgs.ENABLE_DART_PROFILING.commandLineArgument);
  }

  @Test
  public void itSetsProfileStartupFromMetaData() {
    testFlagFromMetaData(
        "io.flutter.embedding.android.ProfileStartup",
        true,
        FlutterShellArgs.PROFILE_STARTUP.commandLineArgument);
  }

  @Test
  public void itSetsTraceSkiaFromMetaData() {
    testFlagFromMetaData(
        "io.flutter.embedding.android.TraceSkia",
        true,
        FlutterShellArgs.TRACE_SKIA.commandLineArgument);
  }

  @Test
  public void itSetsTraceSkiaAllowlistFromMetaData() {
    String expectedTraceSkiaAllowList = "allowed1,allowed2,allowed3";
    testFlagFromMetaData(
        "io.flutter.embedding.android.TraceSkiaAllowList",
        expectedTraceSkiaAllowList,
        FlutterShellArgs.TRACE_SKIA_ALLOWLIST.commandLineArgument + expectedTraceSkiaAllowList);
  }

  @Test
  public void itSetsTraceSystraceFromMetaData() {
    testFlagFromMetaData(
        "io.flutter.embedding.android.TraceSystrace",
        true,
        FlutterShellArgs.TRACE_SYSTRACE.commandLineArgument);
  }

  @Test
  public void itSetsTraceToFileFromMetaData() {
    String expectedTraceToFilePath = "/path/to/trace/file";
    testFlagFromMetaData(
        "io.flutter.embedding.android.TraceToFile",
        expectedTraceToFilePath,
        FlutterShellArgs.TRACE_TO_FILE.commandLineArgument + expectedTraceToFilePath);
  }

  @Test
  public void itSetsProfileMicrotasksFromMetaData() {
    testFlagFromMetaData(
        "io.flutter.embedding.android.ProfileMicrotasks",
        true,
        FlutterShellArgs.PROFILE_MICROTASKS.commandLineArgument);
  }

  @Test
  public void itSetsDumpSkpOnShaderCompilationFromMetaData() {
    testFlagFromMetaData(
        "io.flutter.embedding.android.DumpSkpOnShaderCompilation",
        true,
        FlutterShellArgs.DUMP_SKP_ON_SHADER_COMPILATION.commandLineArgument);
  }

  @Test
  public void itSetsPurgePersistentCacheFromMetaData() {
    testFlagFromMetaData(
        "io.flutter.embedding.android.PurgePersistentCache",
        true,
        FlutterShellArgs.PURGE_PERSISTENT_CACHE.commandLineArgument);
  }

  @Test
  public void itSetsVerboseLoggingFromMetaData() {
    testFlagFromMetaData(
        "io.flutter.embedding.android.VerboseLogging",
        true,
        FlutterShellArgs.VERBOSE_LOGGING.commandLineArgument);
  }

  @Test
  public void itSetsDartFlagsFromMetaData() {
    String expectedDartFlags = "--enable-asserts --enable-vm-service";
    testFlagFromMetaData(
        "io.flutter.embedding.android.DartFlags",
        expectedDartFlags,
        FlutterShellArgs.DART_FLAGS.commandLineArgument + expectedDartFlags);
  }

  @Test
  public void itDoesNotSetDisableMergedPlatformUIThreadFromMetaData() {
    FlutterJNI mockFlutterJNI = mock(FlutterJNI.class);
    FlutterLoader flutterLoader = new FlutterLoader(mockFlutterJNI);
    Bundle metadata = new Bundle();

    metadata.putBoolean("io.flutter.embedding.android.DisableMergedPlatformUIThread", true);
    ctx.getApplicationInfo().metaData = metadata;

    FlutterLoader.Settings settings = new FlutterLoader.Settings();
    assertFalse(flutterLoader.initialized());
    flutterLoader.startInitialization(ctx, settings);

    // Verify that an IllegalArgumentException is thrown when DisableMergedPlatformUIThread is set,
    // as it is no longer supported.
    Exception exception =
        assertThrows(
            RuntimeException.class, () -> flutterLoader.ensureInitializationComplete(ctx, null));
    Throwable cause = exception.getCause();

    assertNotNull(cause);
    assertTrue(
        "Expected cause to be IllegalArgumentException", cause instanceof IllegalArgumentException);
    assertTrue(
        cause
            .getMessage()
            .contains(
                "io.flutter.embedding.android.DisableMergedPlatformUIThread is no longer allowed."));
  }

  @Test
  public void itDoesNotSetUnrecognizedMetadataKey() {
    FlutterJNI mockFlutterJNI = mock(FlutterJNI.class);
    FlutterLoader flutterLoader = new FlutterLoader(mockFlutterJNI);
    Bundle metadata = new Bundle();

    metadata.putBoolean("io.flutter.embedding.android.UnrecognizedKey", true);
    ctx.getApplicationInfo().metaData = metadata;

    FlutterLoader.Settings settings = new FlutterLoader.Settings();
    assertFalse(flutterLoader.initialized());
    flutterLoader.startInitialization(ctx, settings);
    flutterLoader.ensureInitializationComplete(ctx, null);
    shadowOf(getMainLooper()).idle();

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

    // Verify that no unrecognized argument is set.
    assertFalse(
        "Unexpected argument '--unrecognized-key' was found in the arguments passed to FlutterJNI.init",
        arguments.contains("--unrecognized-key"));
  }

  private void testFlagFromMetaData(String metadataKey, Object metadataValue, String expectedArg) {
    testFlagFromMetaData(metadataKey, metadataValue, expectedArg, true);
  }

  // Test that specified shell argument can be set via manifest metadata as expected.
  private void testFlagFromMetaData(
      String metadataKey, Object metadataValue, String expectedArg, boolean shouldBeSet) {
    FlutterJNI mockFlutterJNI = mock(FlutterJNI.class);
    FlutterLoader flutterLoader = new FlutterLoader(mockFlutterJNI);
    Bundle metadata = new Bundle();

    // Place metadata key and value into the metadata bundle used to mock the manifest.
    if (metadataValue instanceof Boolean) {
      metadata.putBoolean(metadataKey, (Boolean) metadataValue);
    } else if (metadataValue instanceof Integer) {
      metadata.putInt(metadataKey, (Integer) metadataValue);
    } else if (metadataValue instanceof String) {
      metadata.putString(metadataKey, (String) metadataValue);
    } else {
      throw new IllegalArgumentException(
          "Unsupported metadataValue type: " + metadataValue.getClass());
    }

    ctx.getApplicationInfo().metaData = metadata;

    FlutterLoader.Settings settings = new FlutterLoader.Settings();
    assertFalse(flutterLoader.initialized());
    flutterLoader.startInitialization(ctx, settings);
    flutterLoader.ensureInitializationComplete(ctx, null);
    shadowOf(getMainLooper()).idle();

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

    if (shouldBeSet) {
      assertTrue(
          "Expected argument '"
              + expectedArg
              + "' was not found in the arguments passed to FlutterJNI.init",
          arguments.contains(expectedArg));
    } else {
      assertFalse(
          "Unexpected argument '"
              + expectedArg
              + "' was found in the arguments passed to FlutterJNI.init",
          arguments.contains(expectedArg));
    }
  }
}