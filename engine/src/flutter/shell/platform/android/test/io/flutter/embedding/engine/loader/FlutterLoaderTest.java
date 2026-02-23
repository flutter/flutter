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
  public void itSetsDeprecatedAotSharedLibraryNameIfPathIsInInternalStorage() throws IOException {
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
    Path testPath = internalStorageDirAsPathObj.resolve(librarySoFileName);

    String path = testPath.toString();
    Bundle metadata = new Bundle();
    metadata.putString(
        "io.flutter.embedding.engine.loader.FlutterLoader.aot-shared-library-name", path);
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

  @Test
  public void itSetsAotSharedLibraryNameIfPathIsInInternalStorageInReleaseMode()
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

    // Test paths for library living within internal storage.
    String librarySoFileName = "library.so";
    Path testPath = internalStorageDirAsPathObj.resolve(librarySoFileName);

    String path = testPath.toString();
    Bundle metadata = new Bundle();
    metadata.putString("io.flutter.embedding.android.AOTSharedLibraryName", path);
    ctx.getApplicationInfo().metaData = metadata;

    flutterLoader.ensureInitializationComplete(ctx, null, true);

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
    testFlagFromMetadataPresent(
        "io.flutter.embedding.android.EnableSoftwareRendering",
        true,
        "--enable-software-rendering");
  }

  @Test
  public void getSofwareRenderingEnabledViaManifest_returnsExpectedValueWhenSetViaManifest() {
    FlutterJNI mockFlutterJNI = mock(FlutterJNI.class);
    FlutterLoader flutterLoader = new FlutterLoader(mockFlutterJNI);
    Bundle metadata = new Bundle();

    metadata.putBoolean("io.flutter.embedding.android.EnableSoftwareRendering", true);

    ctx.getApplicationInfo().metaData = metadata;

    FlutterLoader.Settings settings = new FlutterLoader.Settings();
    assertFalse(flutterLoader.initialized());
    flutterLoader.startInitialization(ctx, settings);
    flutterLoader.ensureInitializationComplete(ctx, null);
    shadowOf(getMainLooper()).idle();

    assertTrue(flutterLoader.getSofwareRenderingEnabledViaManifest());
  }

  @Test
  public void itSetsSkiaDeterministicRenderingFromMetadata() {
    testFlagFromMetadataPresent(
        "io.flutter.embedding.android.SkiaDeterministicRendering",
        true,
        "--skia-deterministic-rendering");
  }

  @Test
  public void itSetsFlutterAssetsDirFromMetadata() {
    String expectedAssetsDir = "flutter_assets_dir";
    // Test debug mode
    testFlagFromMetadataPresent(
        "io.flutter.embedding.android.FlutterAssetsDir",
        expectedAssetsDir,
        "--flutter-assets-dir=" + expectedAssetsDir);

    // Test release mode.
    testFlagFromMetadataPresentInReleaseMode(
        "io.flutter.embedding.android.FlutterAssetsDir",
        expectedAssetsDir,
        "--flutter-assets-dir=" + expectedAssetsDir);
  }

  @Test
  public void itSetsDeprecatedFlutterAssetsDirFromMetadata() {
    String expectedAssetsDir = "flutter_assets_dir";

    // Test debug mode.
    testFlagFromMetadataPresent(
        "io.flutter.embedding.engine.loader.FlutterLoader.flutter-assets-dir",
        expectedAssetsDir,
        "--flutter-assets-dir=" + expectedAssetsDir);

    // Test release mode.
    testFlagFromMetadataPresentInReleaseMode(
        "io.flutter.embedding.engine.loader.FlutterLoader.flutter-assets-dir",
        expectedAssetsDir,
        "--flutter-assets-dir=" + expectedAssetsDir);
  }

  @Test
  public void itSetsOldGenHeapSizeFromMetadata() {
    // Test old gen heap size can be set from metadata in debug mode.
    int expectedOldGenHeapSize = 256;
    testFlagFromMetadataPresent(
        "io.flutter.embedding.android.OldGenHeapSize",
        expectedOldGenHeapSize,
        "--old-gen-heap-size=" + expectedOldGenHeapSize);

    // Test old gen heap size can be set from metadta in release mode.
    testFlagFromMetadataPresentInReleaseMode(
        "io.flutter.embedding.android.OldGenHeapSize",
        expectedOldGenHeapSize,
        "--old-gen-heap-size=" + expectedOldGenHeapSize);

    // Test that default old gen heap size will not be included if it
    // is configured via the manifest.
    ActivityManager activityManager =
        (ActivityManager) ctx.getSystemService(Context.ACTIVITY_SERVICE);
    ActivityManager.MemoryInfo memInfo = new ActivityManager.MemoryInfo();
    activityManager.getMemoryInfo(memInfo);
    int oldGenHeapSizeMegaBytes = (int) (memInfo.totalMem / 1e6 / 2);
    testFlagFromMetadataNotPresent(
        "io.flutter.embedding.android.OldGenHeapSize",
        expectedOldGenHeapSize,
        "--old-gen-heap-size=" + oldGenHeapSizeMegaBytes);
  }

  @Test
  public void itSetsEnableImpellerFromMetadata() {
    // Test debug mode.
    testFlagFromMetadataPresent(
        "io.flutter.embedding.android.EnableImpeller", true, "--enable-impeller=true");

    // Test release mode.
    testFlagFromMetadataPresentInReleaseMode(
        "io.flutter.embedding.android.EnableImpeller", true, "--enable-impeller=true");
  }

  @Test
  public void itSetsImpellerBackendFromMetadata() {
    String expectedImpellerBackend = "Vulkan";

    // Test debug mode.
    testFlagFromMetadataPresent(
        "io.flutter.embedding.android.ImpellerBackend",
        expectedImpellerBackend,
        "--impeller-backend=" + expectedImpellerBackend);

    // Test release mode.
    testFlagFromMetadataPresentInReleaseMode(
        "io.flutter.embedding.android.ImpellerBackend",
        expectedImpellerBackend,
        "--impeller-backend=" + expectedImpellerBackend);
  }

  @Test
  public void itSetsEnableSurfaceControlFromMetadata() {
    // Test debug mode.
    testFlagFromMetadataPresent(
        "io.flutter.embedding.android.EnableSurfaceControl", true, "--enable-surface-control");

    // Test release mode.
    testFlagFromMetadataPresentInReleaseMode(
        "io.flutter.embedding.android.EnableSurfaceControl", true, "--enable-surface-control");
  }

  @Test
  public void itSetsEnableFlutterGPUFromMetadata() {
    // Test debug mode.
    testFlagFromMetadataPresent(
        "io.flutter.embedding.android.EnableFlutterGPU", true, "--enable-flutter-gpu");

    // Test release mode.
    testFlagFromMetadataPresentInReleaseMode(
        "io.flutter.embedding.android.EnableFlutterGPU", true, "--enable-flutter-gpu");
  }

  @Test
  public void itSetsImpellerLazyShaderModeFromMetadata() {
    // Test debug mode.
    testFlagFromMetadataPresent(
        "io.flutter.embedding.android.ImpellerLazyShaderInitialization",
        true,
        "--impeller-lazy-shader-mode=true");

    // Test release mode.
    testFlagFromMetadataPresentInReleaseMode(
        "io.flutter.embedding.android.ImpellerLazyShaderInitialization",
        true,
        "--impeller-lazy-shader-mode=true");
  }

  @Test
  public void itSetsImpellerAntiAliasLinesFromMetadata() {
    // Test debug mode.
    testFlagFromMetadataPresent(
        "io.flutter.embedding.android.ImpellerAntialiasLines", true, "--impeller-antialias-lines");

    // Test release mode.
    testFlagFromMetadataPresentInReleaseMode(
        "io.flutter.embedding.android.ImpellerAntialiasLines", true, "--impeller-antialias-lines");
  }

  @Test
  public void itSetsVmSnapshotDataFromMetadata() {
    String expectedVmSnapshotData = "vm_snapshot_data";

    // Test debug mode.
    testFlagFromMetadataPresent(
        "io.flutter.embedding.android.VmSnapshotData",
        expectedVmSnapshotData,
        "--vm-snapshot-data=" + expectedVmSnapshotData);

    // Test release mode.
    testFlagFromMetadataPresentInReleaseMode(
        "io.flutter.embedding.android.VmSnapshotData",
        expectedVmSnapshotData,
        "--vm-snapshot-data=" + expectedVmSnapshotData);
  }

  @Test
  public void itSetsIsolateSnapshotDataFromMetadata() {
    String expectedIsolateSnapshotData = "isolate_snapshot_data";

    // Test debug mode.
    testFlagFromMetadataPresent(
        "io.flutter.embedding.android.IsolateSnapshotData",
        expectedIsolateSnapshotData,
        "--isolate-snapshot-data=" + expectedIsolateSnapshotData);

    // Test release mode.
    testFlagFromMetadataPresentInReleaseMode(
        "io.flutter.embedding.android.IsolateSnapshotData",
        expectedIsolateSnapshotData,
        "--isolate-snapshot-data=" + expectedIsolateSnapshotData);
  }

  @Test
  public void itSetsUseTestFontsFromMetadata() {
    testFlagFromMetadataPresent(
        "io.flutter.embedding.android.UseTestFonts", true, "--use-test-fonts");
  }

  @Test
  public void itSetsVmServicePortFromMetadata() {
    int expectedVmServicePort = 12345;
    testFlagFromMetadataPresent(
        "io.flutter.embedding.android.VMServicePort",
        expectedVmServicePort,
        "--vm-service-port=" + expectedVmServicePort);
  }

  @Test
  public void itSetsEnableVulkanValidationFromMetadata() {
    testFlagFromMetadataPresent(
        "io.flutter.embedding.android.EnableVulkanValidation", true, "--enable-vulkan-validation");
  }

  @Test
  public void itSetsEnableOpenGLGPUTracingFromMetadata() {
    testFlagFromMetadataPresent(
        "io.flutter.embedding.android.EnableOpenGLGPUTracing", true, "--enable-opengl-gpu-tracing");
  }

  @Test
  public void itSetsEnableVulkanGPUTracingFromMetadata() {
    testFlagFromMetadataPresent(
        "io.flutter.embedding.android.EnableVulkanGPUTracing", true, "--enable-vulkan-gpu-tracing");
  }

  @Test
  public void itSetsLeakVMFromMetadata() {
    // Test that LeakVM can be set via manifest.
    testFlagFromMetadataPresent("io.flutter.embedding.android.LeakVM", false, "--leak-vm=false");

    // Test that default LeakVM will not be included if it is configured via the manifest.
    testFlagFromMetadataNotPresent("io.flutter.embedding.android.LeakVM", false, "--leak-vm=true");
  }

  @Test
  public void itSetsTraceStartupFromMetadata() {
    testFlagFromMetadataPresent(
        "io.flutter.embedding.android.TraceStartup", true, "--trace-startup");
  }

  @Test
  public void itSetsStartPausedFromMetadata() {
    testFlagFromMetadataPresent("io.flutter.embedding.android.StartPaused", true, "--start-paused");
  }

  @Test
  public void itSetsDisableServiceAuthCodesFromMetadata() {
    testFlagFromMetadataPresent(
        "io.flutter.embedding.android.DisableServiceAuthCodes",
        true,
        "--disable-service-auth-codes");
  }

  @Test
  public void itSetsEndlessTraceBufferFromMetadata() {
    testFlagFromMetadataPresent(
        "io.flutter.embedding.android.EndlessTraceBuffer", true, "--endless-trace-buffer");
  }

  @Test
  public void itSetsEnableDartProfilingFromMetadata() {
    testFlagFromMetadataPresent(
        "io.flutter.embedding.android.EnableDartProfiling", true, "--enable-dart-profiling");
  }

  @Test
  public void itSetsProfileStartupFromMetadata() {
    testFlagFromMetadataPresent(
        "io.flutter.embedding.android.ProfileStartup", true, "--profile-startup");
  }

  @Test
  public void itSetsTraceSkiaFromMetadata() {
    testFlagFromMetadataPresent("io.flutter.embedding.android.TraceSkia", true, "--trace-skia");
  }

  @Test
  public void itSetsTraceSkiaAllowlistFromMetadata() {
    String expectedTraceSkiaAllowList = "allowed1,allowed2,allowed3";
    testFlagFromMetadataPresent(
        "io.flutter.embedding.android.TraceSkiaAllowList",
        expectedTraceSkiaAllowList,
        "--trace-skia-allowlist=" + expectedTraceSkiaAllowList);
  }

  @Test
  public void itSetsTraceSystraceFromMetadata() {
    testFlagFromMetadataPresent(
        "io.flutter.embedding.android.TraceSystrace", true, "--trace-systrace");
  }

  @Test
  public void itSetsTraceToFileFromMetadata() {
    String expectedTraceToFilePath = "/path/to/trace/file";
    testFlagFromMetadataPresent(
        "io.flutter.embedding.android.TraceToFile",
        expectedTraceToFilePath,
        "--trace-to-file=" + expectedTraceToFilePath);
  }

  @Test
  public void itSetsProfileMicrotasksFromMetadata() {
    testFlagFromMetadataPresent(
        "io.flutter.embedding.android.ProfileMicrotasks", true, "--profile-microtasks");
  }

  @Test
  public void itSetsDumpSkpOnShaderCompilationFromMetadata() {
    testFlagFromMetadataPresent(
        "io.flutter.embedding.android.DumpSkpOnShaderCompilation",
        true,
        "--dump-skp-on-shader-compilation");
  }

  @Test
  public void itSetsPurgePersistentCacheFromMetadata() {
    testFlagFromMetadataPresent(
        "io.flutter.embedding.android.PurgePersistentCache", true, "--purge-persistent-cache");
  }

  @Test
  public void itSetsVerboseLoggingFromMetadata() {
    testFlagFromMetadataPresent(
        "io.flutter.embedding.android.VerboseLogging", true, "--verbose-logging");
  }

  @Test
  public void itSetsDartFlagsFromMetadata() {
    String expectedDartFlags = "--enable-asserts --enable-vm-service";
    testFlagFromMetadataPresent(
        "io.flutter.embedding.android.DartFlags",
        expectedDartFlags,
        "--dart-flags=" + expectedDartFlags);
  }

  @Test
  public void itDoesNotSetDisableMergedPlatformUIThreadFromMetadata() {
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
                "io.flutter.embedding.android.DisableMergedPlatformUIThread is disabled and no longer allowed."));
  }

  @Test
  public void itDoesNotSetUnrecognizedCommandLineArgument() {
    FlutterJNI mockFlutterJNI = mock(FlutterJNI.class);
    FlutterLoader flutterLoader = new FlutterLoader(mockFlutterJNI);
    Bundle metadata = new Bundle();

    String[] unrecognizedArg = {"--unrecognized-argument"};

    FlutterLoader.Settings settings = new FlutterLoader.Settings();
    assertFalse(flutterLoader.initialized());
    flutterLoader.startInitialization(ctx, settings);
    flutterLoader.ensureInitializationComplete(ctx, unrecognizedArg);
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

    assertFalse(
        "Unrecognized argument '"
            + unrecognizedArg[0]
            + "' was found in the arguments passed to FlutterJNI.init",
        arguments.contains(unrecognizedArg[0]));
  }

  @Test
  public void itDoesSetRecognizedCommandLineArgument() {
    FlutterJNI mockFlutterJNI = mock(FlutterJNI.class);
    FlutterLoader flutterLoader = new FlutterLoader(mockFlutterJNI);
    Bundle metadata = new Bundle();

    String[] recognizedArg = {"--enable-impeller=true"};

    FlutterLoader.Settings settings = new FlutterLoader.Settings();
    assertFalse(flutterLoader.initialized());
    flutterLoader.startInitialization(ctx, settings);
    flutterLoader.ensureInitializationComplete(ctx, recognizedArg);
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

    assertTrue(
        "Recognized argument '"
            + recognizedArg[0]
            + "' was not found in the arguments passed to FlutterJNI.init",
        arguments.contains(recognizedArg[0]));
  }

  @Test
  public void ifFlagSetViaManifestAndCommandLineThenCommandLineTakesPrecedence() {
    String expectedImpellerArgFromMetadata = "--enable-impeller=true";
    String expectedImpellerArgFromCommandLine = "--enable-impeller=false";

    FlutterJNI mockFlutterJNI = mock(FlutterJNI.class);
    FlutterLoader flutterLoader = new FlutterLoader(mockFlutterJNI);
    Bundle metadata = new Bundle();

    // Place metadata key and value into the metadata bundle used to mock the manifest.
    metadata.putBoolean("io.flutter.embedding.android.EnableImpeller", true);
    ctx.getApplicationInfo().metaData = metadata;

    FlutterLoader.Settings settings = new FlutterLoader.Settings();
    assertFalse(flutterLoader.initialized());
    flutterLoader.startInitialization(ctx, settings);
    flutterLoader.ensureInitializationComplete(
        ctx, new String[] {expectedImpellerArgFromCommandLine});
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

    // Verify that the command line argument takes precedence over the manifest metadata.
    assertTrue(
        arguments.indexOf(expectedImpellerArgFromMetadata)
            < arguments.indexOf(expectedImpellerArgFromCommandLine));
  }

  @Test
  public void ifAOTSharedLibraryNameSetViaManifestAndCommandLineThenCommandLineTakesPrecedence()
      throws IOException {
    FlutterJNI mockFlutterJNI = mock(FlutterJNI.class);
    FlutterLoader flutterLoader = spy(new FlutterLoader(mockFlutterJNI));
    File internalStorageDir = ctx.getFilesDir();
    Path internalStorageDirAsPathObj = internalStorageDir.toPath();

    ctx.getApplicationInfo().nativeLibraryDir =
        Paths.get("some", "path", "doesnt", "matter").toString();
    assertFalse(flutterLoader.initialized());
    flutterLoader.startInitialization(ctx);

    // Test paths for library living within internal storage.
    Path pathWithDirectInternalStoragePath1 = internalStorageDirAsPathObj.resolve("library1.so");
    Path pathWithDirectInternalStoragePath2 = internalStorageDirAsPathObj.resolve("library2.so");

    String expectedAotSharedLibraryNameFromMetadata =
        "--aot-shared-library-name="
            + pathWithDirectInternalStoragePath1.toFile().getCanonicalPath();
    String expectedAotSharedLibraryNameFromCommandLine =
        "--aot-shared-library-name="
            + pathWithDirectInternalStoragePath2.toFile().getCanonicalPath();

    Bundle metadata = new Bundle();

    // Place metadata key and value into the metadata bundle used to mock the manifest.
    metadata.putString(
        "io.flutter.embedding.android.AOTSharedLibraryName",
        pathWithDirectInternalStoragePath1.toFile().getCanonicalPath());
    ctx.getApplicationInfo().metaData = metadata;

    FlutterLoader.Settings settings = new FlutterLoader.Settings();
    assertFalse(flutterLoader.initialized());
    flutterLoader.startInitialization(ctx, settings);
    flutterLoader.ensureInitializationComplete(
        ctx,
        new String[] {expectedAotSharedLibraryNameFromCommandLine, "--enable-opengl-gpu-tracing"});
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

    // Verify that the command line argument takes precedence over the manifest metadata.
    assertTrue(
        arguments.indexOf(expectedAotSharedLibraryNameFromCommandLine)
            < arguments.indexOf(expectedAotSharedLibraryNameFromMetadata));

    // Verify other command line arguments are still passed through.
    assertTrue(
        "Expected argument --enable-opengl-gpu-tracing was not found in the arguments passed to FlutterJNI.init",
        arguments.contains("--enable-opengl-gpu-tracing"));
  }

  private void testFlagFromMetadataPresentInReleaseMode(
      String metadataKey, Object metadataValue, String expectedArg) {
    testFlagFromMetadata(metadataKey, metadataValue, expectedArg, true, true);
  }

  private void testFlagFromMetadataNotPresent(
      String metadataKey, Object metadataValue, String expectedArg) {
    testFlagFromMetadata(metadataKey, metadataValue, expectedArg, false, false);
  }

  private void testFlagFromMetadataPresent(
      String metadataKey, Object metadataValue, String expectedArg) {
    testFlagFromMetadata(metadataKey, metadataValue, expectedArg, true, false);
  }

  // Test that specified shell argument can be set via manifest metadata as expected.
  private void testFlagFromMetadata(
      String metadataKey,
      Object metadataValue,
      String expectedArg,
      boolean shouldBeSet,
      boolean isReleaseMode) {
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
    flutterLoader.ensureInitializationComplete(ctx, null, isReleaseMode);
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
